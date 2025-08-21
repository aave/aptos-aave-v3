#[test_only]
module aave_pool::pool_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::option::Option;
    use std::signer::Self;
    use std::string::{String, utf8, bytes};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage::Self;
    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;
    use aave_pool::supply_logic;
    use aave_pool::token_helper;
    use aave_pool::borrow_logic;
    use aave_pool::events::IsolationModeTotalDebtUpdated;
    use aave_pool::a_token_factory::Self;
    use aave_pool::collector;
    use aave_pool::pool_token_logic::ReserveInitialized;
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::pool::{
        get_flashloan_premium_to_protocol,
        get_flashloan_premium_total,
        get_reserve_a_token_address,
        get_reserve_accrued_to_treasury,
        get_reserve_address_by_id,
        get_reserve_configuration,
        get_reserve_configuration_by_reserve_data,
        get_reserve_current_liquidity_rate,
        get_reserve_current_variable_borrow_rate,
        get_reserve_data,
        get_reserve_id,
        get_reserve_isolation_mode_total_debt,
        get_reserve_liquidity_index,
        get_reserve_variable_borrow_index,
        get_reserve_variable_debt_token_address,
        number_of_active_and_dropped_reserves,
        get_reserves_list,
        get_user_configuration,
        set_reserve_accrued_to_treasury,
        set_reserve_current_liquidity_rate_for_testing,
        set_reserve_current_variable_borrow_rate_for_testing,
        set_reserve_isolation_mode_total_debt,
        set_reserve_liquidity_index_for_testing,
        set_reserve_variable_borrow_index_for_testing,
        set_user_configuration,
        test_set_reserve_configuration,
        update_flashloan_premiums,
        get_reserve_deficit,
        get_liquidation_grace_period,
        get_reserve_virtual_underlying_balance,
        number_of_active_reserves,
        get_reserve_last_update_timestamp,
        get_siloed_borrowing_state,
        get_isolation_mode_state,
        cumulate_to_liquidity_index,
        get_reserve_normalized_variable_debt,
        get_reserve_normalized_income,
        get_normalized_debt_by_reserve_data,
        get_normalized_income_by_reserve_data,
        asset_exists,
        max_number_reserves,
        set_reserve_configuration_with_guard,
        set_reserve_last_update_timestamp,
        reset_isolation_mode_total_debt,
        set_reserve_configuration,
        set_reserve_virtual_underlying_balance,
        set_liquidation_grace_period,
        set_reserve_deficit,
        test_init_pool,
        assert_reserves_initialized_for_testing,
        delete_reserve_data,
        delete_reserve_address_by_id,
        set_reserves_count
    };
    use aave_pool::pool_configurator;
    use aave_pool::variable_debt_token_factory::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
    const TEST_ASSETS_COUNT: u8 = 3;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens = @aave_mock_underlyings
        )
    ]
    fun test_default_state(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(underlying_tokens);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init input data for creating pool reserves
        // create underlyings
        let underlying_assets: vector<address> = vector[];
        let treasuries: vector<address> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];
        let optimal_usage_ratios: vector<u256> = vector[];
        let base_variable_borrow_rates: vector<u256> = vector[];
        let variable_rate_slope1s: vector<u256> = vector[];
        let variable_rate_slope2s: vector<u256> = vector[];

        for (i in 0..TEST_ASSETS_COUNT) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 6;
            let max_supply = 10000;
            mock_underlying_token_factory::create_token(
                underlying_tokens,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names, string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
            vector::push_back(&mut incentives_controllers, option::none());
            vector::push_back(&mut optimal_usage_ratios, 400);
            vector::push_back(&mut base_variable_borrow_rates, 100);
            vector::push_back(&mut variable_rate_slope1s, 200);
            vector::push_back(&mut variable_rate_slope2s, 300);
        };

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols,
            incentives_controllers,
            optimal_usage_ratios,
            base_variable_borrow_rates,
            variable_rate_slope1s,
            variable_rate_slope2s
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveInitialized>();
        // make sure event of type was emitted
        assert!(
            vector::length(&emitted_events) == (TEST_ASSETS_COUNT as u64), TEST_SUCCESS
        );

        // test reserves count
        assert!(
            number_of_active_and_dropped_reserves() == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );

        // get the reserve config for the first underlying and assert
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let underlying_asset_decimals =
            mock_underlying_token_factory::decimals(underlying_asset_addr);
        let reserve_config_map = get_reserve_configuration(underlying_asset_addr);

        // test reserve config
        assert!(reserve_config::get_ltv(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(
            reserve_config::get_liquidation_threshold(&reserve_config_map) == 0,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_liquidation_bonus(&reserve_config_map) == 0,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_decimals(&reserve_config_map)
                == (underlying_asset_decimals as u256),
            TEST_SUCCESS
        );
        assert!(reserve_config::get_active(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(reserve_config::get_frozen(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(reserve_config::get_paused(&reserve_config_map) == false, TEST_SUCCESS);
        assert!(
            reserve_config::get_borrowable_in_isolation(&reserve_config_map) == false,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_siloed_borrowing(&reserve_config_map) == false,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == false,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_reserve_factor(&reserve_config_map) == 0, TEST_SUCCESS
        );
        assert!(reserve_config::get_borrow_cap(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(reserve_config::get_supply_cap(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(reserve_config::get_debt_ceiling(&reserve_config_map) == 0, TEST_SUCCESS);
        assert!(
            reserve_config::get_liquidation_protocol_fee(&reserve_config_map) == 0,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_emode_category(&reserve_config_map) == 0, TEST_SUCCESS
        );
        assert!(
            reserve_config::get_flash_loan_enabled(&reserve_config_map) == false,
            TEST_SUCCESS
        );

        // get the reserve data
        let reserve_data = get_reserve_data(underlying_asset_addr);
        let reserve_config_map1 = get_reserve_configuration_by_reserve_data(reserve_data);
        assert!(reserve_config_map == reserve_config_map1, TEST_SUCCESS);

        let reserve_data1 = get_reserve_data(underlying_asset_addr);
        let count = number_of_active_and_dropped_reserves();
        assert!(count == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        let reserve_id = get_reserve_id(reserve_data);
        let reserve_data2 = get_reserve_address_by_id((reserve_id as u256));

        // assert counts
        assert!(reserve_data == reserve_data1, TEST_SUCCESS);
        assert!(reserve_data2 == underlying_asset_addr, TEST_SUCCESS);
        assert!(count == number_of_active_and_dropped_reserves(), TEST_SUCCESS);

        // assert reserves list
        let reserves_list = get_reserves_list();
        assert!(
            vector::length(&reserves_list) == (TEST_ASSETS_COUNT as u64), TEST_SUCCESS
        );
        assert!(vector::contains(&reserves_list, &underlying_asset_addr), TEST_SUCCESS);

        // test reserve data
        let a_token_address = get_reserve_a_token_address(reserve_data);
        let var_token_address = get_reserve_variable_debt_token_address(reserve_data);
        assert!(
            get_reserve_a_token_address(reserve_data) == a_token_address, TEST_SUCCESS
        );
        assert!(get_reserve_accrued_to_treasury(reserve_data) == 0, TEST_SUCCESS);
        assert!(
            get_reserve_variable_borrow_index(reserve_data)
                == (wad_ray_math::ray() as u128),
            TEST_SUCCESS
        );
        assert!(
            get_reserve_liquidity_index(reserve_data) == (wad_ray_math::ray() as u128),
            TEST_SUCCESS
        );
        assert!(get_reserve_current_liquidity_rate(reserve_data) == 0, TEST_SUCCESS);
        assert!(
            get_reserve_current_variable_borrow_rate(reserve_data) == 0, TEST_SUCCESS
        );
        assert!(
            get_reserve_variable_debt_token_address(reserve_data) == var_token_address,
            TEST_SUCCESS
        );
        assert!(get_reserve_isolation_mode_total_debt(reserve_data) == 0, TEST_SUCCESS);

        // test default extended config
        assert!(get_flashloan_premium_total() == 0, TEST_SUCCESS);
        assert!(get_flashloan_premium_to_protocol() == 0, TEST_SUCCESS);

        // test default user config
        let random_user = @0x42;
        let user_config_map = get_user_configuration(random_user);
        assert!(user_config::is_empty(&user_config_map), TEST_SUCCESS);
        assert!(!user_config::is_borrowing_any(&user_config_map), TEST_SUCCESS);
        assert!(
            !user_config::is_using_as_collateral_any(&user_config_map), TEST_SUCCESS
        );

        // test edge
        assert!(
            (max_number_reserves() as u256) == reserve_config::get_max_reserves_count(),
            TEST_SUCCESS
        );

        assert!(asset_exists(underlying_asset_addr) == true, TEST_SUCCESS);
        assert!(asset_exists(@0x66) == false, TEST_SUCCESS);

        let liquidity_index = get_normalized_income_by_reserve_data(reserve_data);
        assert!(liquidity_index == wad_ray_math::ray(), TEST_SUCCESS);

        let liquidity_index = get_reserve_normalized_income(underlying_asset_addr);
        assert!(liquidity_index == wad_ray_math::ray(), TEST_SUCCESS);

        let variable_borrow_index =
            get_reserve_normalized_variable_debt(underlying_asset_addr);
        assert!(variable_borrow_index == wad_ray_math::ray(), TEST_SUCCESS);

        let variable_borrow_index = get_normalized_debt_by_reserve_data(reserve_data);
        assert!(variable_borrow_index == wad_ray_math::ray(), TEST_SUCCESS);

        // calculate
        timestamp::fast_forward_seconds(100);
        let liquidity_index = get_reserve_normalized_income(underlying_asset_addr);
        assert!(liquidity_index == wad_ray_math::ray(), TEST_SUCCESS);

        // set global time
        timestamp::fast_forward_seconds(100);
        let variable_borrow_index =
            get_reserve_normalized_variable_debt(underlying_asset_addr);
        assert!(variable_borrow_index == wad_ray_math::ray(), TEST_SUCCESS);

        let cacl_liquidity_index = cumulate_to_liquidity_index(reserve_data, 1000, 0);
        assert!(cacl_liquidity_index == wad_ray_math::ray(), TEST_SUCCESS);

        let (
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        ) = get_isolation_mode_state(&user_config_map);
        assert!(isolation_mode_active == false, TEST_SUCCESS);
        assert!(isolation_mode_collateral_address == @0x0, TEST_SUCCESS);
        assert!(isolation_mode_debt_ceiling == 0, TEST_SUCCESS);

        let (siloed_borrowing_enabled, siloed_borrowing_address) =
            get_siloed_borrowing_state(signer::address_of(aave_pool));
        assert!(siloed_borrowing_enabled == false, TEST_SUCCESS);
        assert!(siloed_borrowing_address == @0x0, TEST_SUCCESS);

        let last_update_timestamp = get_reserve_last_update_timestamp(reserve_data);
        assert!(last_update_timestamp == 0, TEST_SUCCESS);

        // check number of active reserves
        assert!(number_of_active_reserves() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // reserve id not exists
        assert!(get_reserve_address_by_id(100) == @0x0, TEST_SUCCESS);
        // get reserve virtual underlying balance is 0
        assert!(get_reserve_virtual_underlying_balance(reserve_data) == 0, TEST_SUCCESS);
        // get liquidation grace period is 0
        assert!(get_liquidation_grace_period(reserve_data) == 0, TEST_SUCCESS);
        // get reserve deficit is 0
        assert!(get_reserve_deficit(reserve_data) == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens = @aave_mock_underlyings
        )
    ]
    fun test_modified_state(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens: &signer
    ) {
        // create test accounts
        account::create_account_for_test(signer::address_of(aave_pool));

        // init the acl module and make aave_pool the asset listing/pool admin
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);

        // init collector
        collector::init_module_test(aave_pool);
        let collector_address = collector::collector_address();

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(underlying_tokens);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init input data for creating pool reserves
        // create underlyings
        let underlying_assets: vector<address> = vector[];
        let treasuries: vector<address> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];
        let optimal_usage_ratios: vector<u256> = vector[];
        let base_variable_borrow_rates: vector<u256> = vector[];
        let variable_rate_slope1s: vector<u256> = vector[];
        let variable_rate_slope2s: vector<u256> = vector[];

        for (i in 0..TEST_ASSETS_COUNT) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 6;
            let max_supply = 10000;
            mock_underlying_token_factory::create_token(
                underlying_tokens,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names, string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
            vector::push_back(&mut incentives_controllers, option::none());
            vector::push_back(&mut optimal_usage_ratios, 400);
            vector::push_back(&mut base_variable_borrow_rates, 100);
            vector::push_back(&mut variable_rate_slope1s, 200);
            vector::push_back(&mut variable_rate_slope2s, 300);
        };

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols,
            incentives_controllers,
            optimal_usage_ratios,
            base_variable_borrow_rates,
            variable_rate_slope1s,
            variable_rate_slope2s
        );

        // get tokens data
        let underlying_asset_addr = *vector::borrow(&underlying_assets, 0);
        let reserve_data = get_reserve_data(underlying_asset_addr);
        let a_token_address = get_reserve_a_token_address(reserve_data);
        let var_token_address = get_reserve_variable_debt_token_address(reserve_data);

        // test reserve config
        let reserve_config_new = reserve_config::init();
        reserve_config::set_ltv(&mut reserve_config_new, 100);
        reserve_config::set_liquidation_threshold(&mut reserve_config_new, 101);
        reserve_config::set_liquidation_bonus(&mut reserve_config_new, 102);
        reserve_config::set_decimals(&mut reserve_config_new, 18);
        reserve_config::set_active(&mut reserve_config_new, true);
        reserve_config::set_frozen(&mut reserve_config_new, true);
        reserve_config::set_paused(&mut reserve_config_new, true);
        reserve_config::set_borrowable_in_isolation(&mut reserve_config_new, true);
        reserve_config::set_siloed_borrowing(&mut reserve_config_new, true);
        reserve_config::set_borrowing_enabled(&mut reserve_config_new, true);
        reserve_config::set_reserve_factor(&mut reserve_config_new, 104);
        reserve_config::set_borrow_cap(&mut reserve_config_new, 105);
        reserve_config::set_supply_cap(&mut reserve_config_new, 106);
        reserve_config::set_debt_ceiling(&mut reserve_config_new, 107);
        reserve_config::set_liquidation_protocol_fee(&mut reserve_config_new, 108);
        reserve_config::set_emode_category(&mut reserve_config_new, 110);
        reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true);

        // set the reserve configuration
        test_set_reserve_configuration(underlying_asset_addr, reserve_config_new);
        set_reserve_configuration_with_guard(
            aave_pool, underlying_asset_addr, reserve_config_new
        );

        let reserve_data = get_reserve_data(underlying_asset_addr);
        let reserve_config_map = get_reserve_configuration_by_reserve_data(reserve_data);

        assert!(reserve_config::get_ltv(&reserve_config_map) == 100, TEST_SUCCESS);
        assert!(
            reserve_config::get_liquidation_threshold(&reserve_config_map) == 101,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_liquidation_bonus(&reserve_config_map) == 102,
            TEST_SUCCESS
        );
        assert!(reserve_config::get_decimals(&reserve_config_map) == 18, TEST_SUCCESS);
        assert!(reserve_config::get_active(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(reserve_config::get_frozen(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(reserve_config::get_paused(&reserve_config_map) == true, TEST_SUCCESS);
        assert!(
            reserve_config::get_borrowable_in_isolation(&reserve_config_map) == true,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_siloed_borrowing(&reserve_config_map) == true,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == true,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_reserve_factor(&reserve_config_map) == 104,
            TEST_SUCCESS
        );
        assert!(reserve_config::get_borrow_cap(&reserve_config_map) == 105, TEST_SUCCESS);
        assert!(reserve_config::get_supply_cap(&reserve_config_map) == 106, TEST_SUCCESS);
        assert!(
            reserve_config::get_debt_ceiling(&reserve_config_map) == 107, TEST_SUCCESS
        );
        assert!(
            reserve_config::get_liquidation_protocol_fee(&reserve_config_map) == 108,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_emode_category(&reserve_config_map) == 110,
            TEST_SUCCESS
        );
        assert!(
            reserve_config::get_flash_loan_enabled(&reserve_config_map) == true,
            TEST_SUCCESS
        );

        // test reserve data
        set_reserve_isolation_mode_total_debt(reserve_data, 200);
        set_reserve_current_variable_borrow_rate_for_testing(underlying_asset_addr, 202);
        set_reserve_current_liquidity_rate_for_testing(underlying_asset_addr, 204);
        set_reserve_liquidity_index_for_testing(underlying_asset_addr, 205);
        set_reserve_variable_borrow_index_for_testing(underlying_asset_addr, 206);
        set_reserve_accrued_to_treasury(reserve_data, 207);

        let reserve_data = get_reserve_data(underlying_asset_addr);
        assert!(get_reserve_isolation_mode_total_debt(reserve_data) == 200, TEST_SUCCESS);
        assert!(
            get_reserve_current_variable_borrow_rate(reserve_data) == 202,
            TEST_SUCCESS
        );
        assert!(get_reserve_current_liquidity_rate(reserve_data) == 204, TEST_SUCCESS);
        assert!(get_reserve_liquidity_index(reserve_data) == 205, TEST_SUCCESS);
        assert!(get_reserve_variable_borrow_index(reserve_data) == 206, TEST_SUCCESS);
        assert!(get_reserve_accrued_to_treasury(reserve_data) == 207, TEST_SUCCESS);
        assert!(
            get_reserve_a_token_address(reserve_data) == a_token_address, TEST_SUCCESS
        );
        assert!(
            get_reserve_variable_debt_token_address(reserve_data) == var_token_address,
            TEST_SUCCESS
        );

        // test reserve extended config
        update_flashloan_premiums(1000, 2000);
        assert!(get_flashloan_premium_total() == 1000, TEST_SUCCESS);
        assert!(get_flashloan_premium_to_protocol() == 2000, TEST_SUCCESS);

        // test reserve user config
        let random_user = @0x42;
        let reserve_index = get_reserve_id(reserve_data);
        let user_config_map = get_user_configuration(random_user);

        user_config::set_borrowing(&mut user_config_map, (reserve_index as u256), true);
        user_config::set_using_as_collateral(
            &mut user_config_map, (reserve_index as u256), true
        );
        set_user_configuration(random_user, user_config_map);

        assert!(
            user_config::is_borrowing(&user_config_map, (reserve_index as u256)) == true,
            TEST_SUCCESS
        );
        assert!(user_config::is_borrowing_any(&user_config_map) == true, TEST_SUCCESS);
        assert!(user_config::is_borrowing_one(&user_config_map) == true, TEST_SUCCESS);
        assert!(
            user_config::is_using_as_collateral_or_borrowing(
                &user_config_map, (reserve_index as u256)
            ) == true,
            TEST_SUCCESS
        );
        assert!(
            user_config::is_using_as_collateral(&user_config_map, (reserve_index as u256))
                == true,
            TEST_SUCCESS
        );
        assert!(
            user_config::is_using_as_collateral_any(&user_config_map) == true,
            TEST_SUCCESS
        );
        assert!(
            user_config::is_using_as_collateral_one(&user_config_map) == true,
            TEST_SUCCESS
        );
        assert!(
            user_config::is_using_as_collateral_or_borrowing(
                &user_config_map, (reserve_index as u256)
            ) == true,
            TEST_SUCCESS
        );

        // test create reserve data
        let reserve_data = get_reserve_data(underlying_asset_addr);
        let reserve_config_map = get_reserve_configuration_by_reserve_data(reserve_data);
        // reset isolation mode total debt
        reserve_config::set_debt_ceiling(&mut reserve_config_map, 0);
        set_reserve_configuration(underlying_asset_addr, reserve_config_map);
        reset_isolation_mode_total_debt(underlying_asset_addr);

        // check emitted events
        let emitted_events = emitted_events<IsolationModeTotalDebtUpdated>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        set_reserve_last_update_timestamp(reserve_data, 1735660800);
        assert!(
            get_reserve_last_update_timestamp(reserve_data) == 1735660800, TEST_SUCCESS
        );

        // Tests for fields added after aave V3.1
        set_reserve_virtual_underlying_balance(reserve_data, 100);
        assert!(
            get_reserve_virtual_underlying_balance(reserve_data) == 100, TEST_SUCCESS
        );

        set_liquidation_grace_period(reserve_data, 200);
        assert!(get_liquidation_grace_period(reserve_data) == 200, TEST_SUCCESS);

        set_reserve_deficit(reserve_data, 300);
        assert!(get_reserve_deficit(reserve_data) == 300, TEST_SUCCESS);
    }

    public fun create_user_config_for_reserve(
        user: address,
        reserve_index: u256,
        is_borrowing: Option<bool>,
        is_using_as_collateral: Option<bool>
    ) {
        let user_config_map = get_user_configuration(user);
        user_config::set_borrowing(
            &mut user_config_map,
            reserve_index,
            option::get_with_default(&is_borrowing, false)
        );
        user_config::set_using_as_collateral(
            &mut user_config_map,
            reserve_index,
            option::get_with_default(&is_using_as_collateral, false)
        );
        // set the user configuration
        set_user_configuration(user, user_config_map);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_isolation_mode_and_siloed_borrowing(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // test isolation mode
        // mint 100 underlying tokens
        let aave_pool_address = signer::address_of(aave_pool);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            (
                token_helper::convert_to_currency_decimals(
                    underlying_u1_token_address, 100
                ) as u64
            ),
            underlying_u1_token_address
        );
        // supply 100 underlying tokens to aave_pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            token_helper::convert_to_currency_decimals(underlying_u1_token_address, 100),
            aave_pool_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            aave_pool, underlying_u1_token_address, true
        );

        // set debt ceiling
        let user_config_map = get_user_configuration(aave_pool_address);
        let reserve_config_map = get_reserve_configuration(underlying_u1_token_address);
        let debt_ceiling = 10000;
        reserve_config::set_debt_ceiling(&mut reserve_config_map, debt_ceiling);
        set_reserve_configuration(underlying_u1_token_address, reserve_config_map);

        let (
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        ) = get_isolation_mode_state(&user_config_map);

        assert!(isolation_mode_active == true, TEST_SUCCESS);
        assert!(
            isolation_mode_collateral_address == underlying_u1_token_address,
            TEST_SUCCESS
        );
        assert!(isolation_mode_debt_ceiling == debt_ceiling, TEST_SUCCESS);

        // Cancel isolation_mode
        let debt_ceiling = 0;
        reserve_config::set_debt_ceiling(&mut reserve_config_map, debt_ceiling);
        set_reserve_configuration(underlying_u1_token_address, reserve_config_map);

        // test siloed borrowing
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
        // set asset price for U_1 token
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // set siloed borrowing
        reserve_config::set_siloed_borrowing(&mut reserve_config_map, true);
        set_reserve_configuration(underlying_u1_token_address, reserve_config_map);

        // borrow 10 underlying tokens
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            token_helper::convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            aave_pool_address
        );
        let (siloed_borrowing_enabled, siloed_borrowing_address) =
            get_siloed_borrowing_state(aave_pool_address);
        assert!(siloed_borrowing_enabled == true, TEST_SUCCESS);
        assert!(siloed_borrowing_address == underlying_u1_token_address, TEST_SUCCESS);
    }

    //  =======================  Test exceptions  =======================
    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::pool)]
    fun test_init_pool_with_non_pool_owner(user1: &signer) {
        test_init_pool(user1);
    }

    #[test]
    #[expected_failure(abort_code = 1408, location = aave_pool::pool)]
    fun test_reserves_not_initialized() {
        assert_reserves_initialized_for_testing();
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 82, location = aave_pool::pool)]
    fun test_get_reserve_data_when_asset_not_listed(aave_pool: &signer) {
        test_init_pool(aave_pool);
        get_reserve_data(@0x33);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 82, location = aave_pool::pool)]
    fun test_delete_reserve_data_when_asset_not_listed(
        aave_pool: &signer
    ) {
        test_init_pool(aave_pool);
        delete_reserve_data(@0x33);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1403, location = aave_pool::pool)]
    // NOTE: In actual business, the assertions are invariants and should not be triggered
    fun test_number_of_active_reserves_when_reserves_length_not_equal_reserves_list_length(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        assert!(number_of_active_reserves() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = get_reserve_data(underlying_u1_token_address);
        let reserve_id = get_reserve_id(reserve_data);
        // delete reserve address by id
        delete_reserve_address_by_id(reserve_id);

        assert!(
            number_of_active_reserves() == (TEST_ASSETS_COUNT as u256) - 1,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1403, location = aave_pool::pool)]
    // NOTE: In actual business, the assertions are invariants and should not be triggered
    fun test_number_of_active_reserves_when_reserves_length_not_equal_reserves_count(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        assert!(number_of_active_reserves() == (TEST_ASSETS_COUNT as u256), TEST_SUCCESS);

        // set reserves count to 1
        set_reserves_count(1);

        assert!(
            number_of_active_reserves() == (TEST_ASSETS_COUNT as u256) - 1,
            TEST_SUCCESS
        );
    }

    #[test(aave_pool = @aave_pool, aave_acl = @aave_acl)]
    #[expected_failure(abort_code = 5, location = aave_pool::pool)]
    fun test_set_reserve_configuration_with_guard_with_non_pool_admin_and_non_asset_listing_admin(
        aave_pool: &signer, aave_acl: &signer
    ) {
        acl_manage::test_init_module(aave_acl);
        test_init_pool(aave_pool);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map = reserve_config::init();

        set_reserve_configuration_with_guard(
            aave_pool,
            underlying_u1_token_address,
            reserve_config_map
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 81, location = aave_pool::pool)]
    fun test_reset_isolation_mode_total_debt_when_debt_ceiling_not_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map = get_reserve_configuration(underlying_u1_token_address);
        reserve_config::set_debt_ceiling(&mut reserve_config_map, 100);
        set_reserve_configuration(underlying_u1_token_address, reserve_config_map);

        // reset isolation mode total debt
        reset_isolation_mode_total_debt(underlying_u1_token_address);
    }
}
