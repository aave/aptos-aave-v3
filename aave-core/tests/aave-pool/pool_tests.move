#[test_only]
module aave_pool::pool_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::option::Option;
    use std::signer::Self;
    use std::string::{utf8, String};
    use std::vector;
    use aptos_std::string_utils::format1;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::Self;
    use aave_config::reserve::{
        get_active,
        get_borrow_cap,
        get_borrowable_in_isolation,
        get_borrowing_enabled,
        get_debt_ceiling,
        get_decimals,
        get_emode_category,
        get_flash_loan_enabled,
        get_frozen,
        get_liquidation_bonus,
        get_liquidation_protocol_fee,
        get_liquidation_threshold,
        get_ltv,
        get_paused,
        get_reserve_factor,
        get_siloed_borrowing,
        get_supply_cap,
        get_unbacked_mint_cap,
        init,
        set_active,
        set_borrow_cap,
        set_borrowable_in_isolation,
        set_borrowing_enabled,
        set_debt_ceiling,
        set_decimals,
        set_emode_category,
        set_flash_loan_enabled,
        set_frozen,
        set_liquidation_bonus,
        set_liquidation_protocol_fee,
        set_liquidation_threshold,
        set_ltv,
        set_paused,
        set_reserve_factor,
        set_siloed_borrowing,
        set_supply_cap,
        set_unbacked_mint_cap,
    };
    use aave_config::user::{
        is_borrowing,
        is_borrowing_any,
        is_borrowing_one,
        is_empty,
        is_using_as_collateral,
        is_using_as_collateral_any,
        is_using_as_collateral_one,
        is_using_as_collateral_or_borrowing,
        set_borrowing,
        set_using_as_collateral,
    };
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory::Self;
    use aave_pool::pool::{
        get_bridge_protocol_fee,
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
        get_reserve_data_and_reserves_count,
        get_reserve_id,
        get_reserve_isolation_mode_total_debt,
        get_reserve_liquidity_index,
        get_reserve_unbacked,
        get_reserve_variable_borrow_index,
        get_reserve_variable_debt_token_address,
        get_reserves_count,
        get_reserves_list,
        get_user_configuration,
        ReserveInitialized,
        set_bridge_protocol_fee,
        set_flashloan_premiums,
        set_reserve_accrued_to_treasury,
        set_reserve_current_liquidity_rate_for_testing,
        set_reserve_current_variable_borrow_rate_for_testing,
        set_reserve_isolation_mode_total_debt,
        set_reserve_liquidity_index_for_testing,
        set_reserve_unbacked,
        set_reserve_variable_borrow_index_for_testing,
        set_user_configuration,
        test_drop_reserve,
        test_init_pool,
        test_init_reserve,
        test_set_reserve_configuration,
    };
    use aave_pool::token_base::Self;
    use aave_pool::underlying_token_factory::Self;
    use aave_pool::variable_token_factory::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;


    // #[test(pool = @aave_pool, aave_std = @std, aptos_framework = @0x1, a_token = @0x01, variable_debt_token = @0x03, underlying_asset = @0x05,)]
    // fun test_default_state(
    //     pool: &signer,
    //     aave_std: &signer,
    //     aptos_framework: &signer,
    //     a_token: &signer,
    //     variable_debt_token: &signer,
    //     underlying_asset: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     let underlying_asset_decimals = 2;
    //
    //     let a_token_tmpl = signer::address_of(a_token);
    //     let variable_debt_token_addr = signer::address_of(variable_debt_token);
    //     let underlying_asset_addr = signer::address_of(underlying_asset);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // init the reserve
    //     test_init_pool(pool);
    //
    //     // create a brand new reserve
    //     test_init_reserve(
    //         pool,
    //         underlying_asset_addr,
    //         underlying_asset_decimals,
    //         signer::address_of(pool),
    //         utf8(b"Fa"),
    //         utf8(b"FA") ,
    //         utf8(b"Fv") ,
    //         utf8(b"FV")
    //     );
    //
    //     // check emitted events
    //     let emitted_events = emitted_events<ReserveInitialized>();
    //     // make sure event of type was emitted
    //     assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
    //
    //     // test reserves cound
    //     assert!(get_reserves_count() == 1, TEST_SUCCESS);
    //
    //     // get the reserve config
    //     let reserve_config_map = get_reserve_configuration(underlying_asset_addr);
    //
    //     // test reserve config
    //     assert!(get_ltv(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_liquidation_threshold(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_liquidation_bonus(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_decimals(&reserve_config_map) == (underlying_asset_decimals as u256), TEST_SUCCESS);
    //     assert!(get_active(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_frozen(&reserve_config_map) == false, TEST_SUCCESS);
    //     assert!(get_paused(&reserve_config_map) == false, TEST_SUCCESS);
    //     assert!(get_borrowable_in_isolation(&reserve_config_map) == false, TEST_SUCCESS);
    //     assert!(get_siloed_borrowing(&reserve_config_map) == false, TEST_SUCCESS);
    //     assert!(get_borrowing_enabled(&reserve_config_map) == false, TEST_SUCCESS);
    //     assert!(get_reserve_factor(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_borrow_cap(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_supply_cap(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_debt_ceiling(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_liquidation_protocol_fee(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_unbacked_mint_cap(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_emode_category(&reserve_config_map) == 0, TEST_SUCCESS);
    //     assert!(get_flash_loan_enabled(&reserve_config_map) == false, TEST_SUCCESS);
    //
    //     // get the reserve data
    //     let reserve_data = get_reserve_data(underlying_asset_addr);
    //     let reserve_config = get_reserve_configuration_by_reserve_data(&reserve_data);
    //     assert!(reserve_config_map == reserve_config, TEST_SUCCESS);
    //     let (reserve_data1, count) = get_reserve_data_and_reserves_count(
    //         underlying_asset_addr);
    //     let reserve_data2 = get_reserve_address_by_id(count);
    //     // assert counts
    //     assert!(reserve_data == reserve_data1, TEST_SUCCESS);
    //     assert!(reserve_data2 == underlying_asset_addr, TEST_SUCCESS);
    //     assert!(count == get_reserves_count(), TEST_SUCCESS);
    //     // assert reserves list
    //     let reserves_list = get_reserves_list();
    //     assert!(vector::length(&reserves_list) == 1, TEST_SUCCESS);
    //     assert!(*vector::borrow(&reserves_list, 0) == underlying_asset_addr, TEST_SUCCESS);
    //
    //     // test reserve data
    //     assert!((get_reserve_id(&reserve_data) as u256) == count, TEST_SUCCESS);
    //     assert!(get_reserve_a_token_address(&reserve_data) == a_token_tmpl, TEST_SUCCESS);
    //     assert!(get_reserve_accrued_to_treasury(&reserve_data) == 0, TEST_SUCCESS);
    //     assert!(get_reserve_variable_borrow_index(&reserve_data)
    //         == (wad_ray_math::ray() as u128),
    //         TEST_SUCCESS);
    //     assert!(get_reserve_liquidity_index(&reserve_data)
    //         == (wad_ray_math::ray() as u128), TEST_SUCCESS);
    //     assert!(get_reserve_current_liquidity_rate(&reserve_data) == 0, TEST_SUCCESS);
    //     assert!(get_reserve_current_variable_borrow_rate(&reserve_data) == 0, TEST_SUCCESS);
    //     assert!(get_reserve_variable_debt_token_address(&reserve_data)
    //         == variable_debt_token_addr,
    //         TEST_SUCCESS);
    //     assert!(get_reserve_unbacked(&reserve_data) == 0, TEST_SUCCESS);
    //     assert!(get_reserve_isolation_mode_total_debt(&reserve_data) == 0, TEST_SUCCESS);
    //
    //     // test default extended config
    //     assert!(get_flashloan_premium_total() == 0, TEST_SUCCESS);
    //     assert!(get_bridge_protocol_fee() == 0, TEST_SUCCESS);
    //     assert!(get_flashloan_premium_to_protocol() == 0, TEST_SUCCESS);
    //
    //     // test default user config
    //     let random_user = @0x42;
    //     let user_config_map = get_user_configuration(random_user);
    //     assert!(is_empty(&user_config_map), TEST_SUCCESS);
    //     assert!(!is_borrowing_any(&user_config_map), TEST_SUCCESS);
    //     assert!(!is_using_as_collateral_any(&user_config_map), TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_std = @std, aptos_framework = @0x1, a_token = @0x01, variable_debt_token = @0x03, underlying_asset = @0x04,)]
    // fun test_modified_state(
    //     pool: &signer,
    //     aave_std: &signer,
    //     aptos_framework: &signer,
    //     a_token: &signer,
    //     variable_debt_token: &signer,
    //     underlying_asset: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // get addresses
    //     let underlying_asset_decimals = 2;
    //     let a_token_tmpl = signer::address_of(a_token);
    //     let variable_debt_token_addr = signer::address_of(variable_debt_token);
    //     let underlying_asset_addr = signer::address_of(underlying_asset);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // init the reserve
    //     test_init_pool(pool);
    //
    //     // create a brand new reserve
    //     test_init_reserve(
    //         pool,
    //         underlying_asset_addr,
    //         underlying_asset_decimals,
    //         signer::address_of(pool),
    //         utf8(b"Fa"),
    //         utf8(b"FA") ,
    //         utf8(b"Fv") ,
    //         utf8(b"FV")
    //     );
    //
    //     let reserve_index = get_reserves_count();
    //
    //     // test reserve config
    //     let reserve_config_new = init();
    //     set_ltv(&mut reserve_config_new, 100);
    //     set_liquidation_threshold(&mut reserve_config_new, 101);
    //     set_liquidation_bonus(&mut reserve_config_new, 102);
    //     set_decimals(&mut reserve_config_new, 103);
    //     set_active(&mut reserve_config_new, true);
    //     set_frozen(&mut reserve_config_new, true);
    //     set_paused(&mut reserve_config_new, true);
    //     set_borrowable_in_isolation(&mut reserve_config_new, true);
    //     set_siloed_borrowing(&mut reserve_config_new, true);
    //     set_borrowing_enabled(&mut reserve_config_new, true);
    //     set_reserve_factor(&mut reserve_config_new, 104);
    //     set_borrow_cap(&mut reserve_config_new, 105);
    //     set_supply_cap(&mut reserve_config_new, 106);
    //     set_debt_ceiling(&mut reserve_config_new, 107);
    //     set_liquidation_protocol_fee(&mut reserve_config_new, 108);
    //     set_unbacked_mint_cap(&mut reserve_config_new, 109);
    //     set_emode_category(&mut reserve_config_new, 110);
    //     set_flash_loan_enabled(&mut reserve_config_new, true);
    //
    //     // set the reserve configuration
    //     test_set_reserve_configuration(underlying_asset_addr, reserve_config_new);
    //
    //     let reserve_data = get_reserve_data(underlying_asset_addr);
    //     let reserve_config_map = get_reserve_configuration_by_reserve_data(&reserve_data);
    //
    //     assert!(get_ltv(&reserve_config_map) == 100, TEST_SUCCESS);
    //     assert!(get_liquidation_threshold(&reserve_config_map) == 101, TEST_SUCCESS);
    //     assert!(get_liquidation_bonus(&reserve_config_map) == 102, TEST_SUCCESS);
    //     assert!(get_decimals(&reserve_config_map) == 103, TEST_SUCCESS);
    //     assert!(get_active(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_frozen(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_paused(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_borrowable_in_isolation(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_siloed_borrowing(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_borrowing_enabled(&reserve_config_map) == true, TEST_SUCCESS);
    //     assert!(get_reserve_factor(&reserve_config_map) == 104, TEST_SUCCESS);
    //     assert!(get_borrow_cap(&reserve_config_map) == 105, TEST_SUCCESS);
    //     assert!(get_supply_cap(&reserve_config_map) == 106, TEST_SUCCESS);
    //     assert!(get_debt_ceiling(&reserve_config_map) == 107, TEST_SUCCESS);
    //     assert!(get_liquidation_protocol_fee(&reserve_config_map) == 108, TEST_SUCCESS);
    //     assert!(get_unbacked_mint_cap(&reserve_config_map) == 109, TEST_SUCCESS);
    //     assert!(get_emode_category(&reserve_config_map) == 110, TEST_SUCCESS);
    //     assert!(get_flash_loan_enabled(&reserve_config_map) == true, TEST_SUCCESS);
    //
    //     // test reserve data
    //     set_reserve_isolation_mode_total_debt(underlying_asset_addr, 200);
    //     set_reserve_unbacked(underlying_asset_addr, 201);
    //     set_reserve_current_variable_borrow_rate_for_testing(underlying_asset_addr, 202);
    //     set_reserve_current_liquidity_rate_for_testing(underlying_asset_addr, 204);
    //     set_reserve_liquidity_index_for_testing(underlying_asset_addr, 205);
    //     set_reserve_variable_borrow_index_for_testing(underlying_asset_addr, 206);
    //     set_reserve_accrued_to_treasury(underlying_asset_addr, 207);
    //     let reserve_data = get_reserve_data(underlying_asset_addr);
    //     assert!(get_reserve_isolation_mode_total_debt(&reserve_data) == 200, TEST_SUCCESS);
    //     assert!(get_reserve_unbacked(&reserve_data) == 201, TEST_SUCCESS);
    //     assert!(get_reserve_current_variable_borrow_rate(&reserve_data) == 202, TEST_SUCCESS);
    //     assert!(get_reserve_current_liquidity_rate(&reserve_data) == 204, TEST_SUCCESS);
    //     assert!(get_reserve_liquidity_index(&reserve_data) == 205, TEST_SUCCESS);
    //     assert!(get_reserve_variable_borrow_index(&reserve_data) == 206, TEST_SUCCESS);
    //     assert!(get_reserve_accrued_to_treasury(&reserve_data) == 207, TEST_SUCCESS);
    //     assert!((get_reserve_id(&reserve_data) as u256) == reserve_index, TEST_SUCCESS);
    //     assert!(get_reserve_a_token_address(&reserve_data) == a_token_tmpl, TEST_SUCCESS);
    //     assert!(get_reserve_variable_debt_token_address(&reserve_data)
    //         == variable_debt_token_addr,
    //         TEST_SUCCESS);
    //
    //     // test reserve extended config
    //     set_flashloan_premiums(1000, 2000);
    //     assert!(get_flashloan_premium_total() == 1000, TEST_SUCCESS);
    //     assert!(get_flashloan_premium_to_protocol() == 2000, TEST_SUCCESS);
    //     set_bridge_protocol_fee(4000);
    //     assert!(get_bridge_protocol_fee() == 4000, TEST_SUCCESS);
    //
    //     // test reserve user config
    //     let random_user = @0x42;
    //     let user_config_map = get_user_configuration(random_user);
    //     set_borrowing(&mut user_config_map, reserve_index, true);
    //     set_using_as_collateral(&mut user_config_map, reserve_index, true);
    //     set_user_configuration(random_user, user_config_map);
    //     assert!(is_borrowing(&user_config_map, reserve_index) == true, TEST_SUCCESS);
    //     assert!(is_borrowing_any(&user_config_map) == true, TEST_SUCCESS);
    //     assert!(is_borrowing_one(&user_config_map) == true, TEST_SUCCESS);
    //     assert!(is_using_as_collateral_or_borrowing(&user_config_map, reserve_index) == true,
    //         TEST_SUCCESS);
    //     assert!(is_using_as_collateral(&user_config_map, reserve_index) == true,
    //         TEST_SUCCESS);
    //     assert!(is_using_as_collateral_any(&user_config_map) == true, TEST_SUCCESS);
    //     assert!(is_using_as_collateral_one(&user_config_map) == true, TEST_SUCCESS);
    //     assert!(is_using_as_collateral_or_borrowing(&user_config_map, reserve_index) == true,
    //         TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_std = @std, aptos_framework = @0x1, aave_role_super_admin = @aave_acl, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aave_pool = @aave_pool,)]
    // fun test_add_drop_reserves(
    //     pool: &signer,
    //     aave_std: &signer,
    //     aptos_framework: &signer,
    //     aave_role_super_admin: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aave_pool: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     acl_manage::test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(aave_pool);
    //     // init token base for tokens
    //     token_base::test_init_module(aave_pool);
    //
    //     // init the reserve
    //     test_init_pool(pool);
    //
    //     // create all tokens
    //     let decimals = 2;
    //     let tokens_to_create = 4;
    //     let a_token_impl = vector<address>[];
    //     let variable_debt_token_addr = vector<address>[];
    //     let underlying_asset_addr = vector<address>[];
    //
    //     for (i in 0..tokens_to_create) {
    //         // create underlying tokens
    //         let underlying_token_name = format1(&b"TEST_TOKEN_{}", i);
    //         let underlying_token_symbol = format1(&b"TOKEN{}", i);
    //         let underlying_token_decimals = 3;
    //         let underlying_token_max_supply = 10000;
    //         underlying_token_factory::create_token(underlying_tokens_admin,
    //             underlying_token_max_supply,
    //             underlying_token_name,
    //             underlying_token_symbol,
    //             underlying_token_decimals,
    //             utf8(b""),
    //             utf8(b""),);
    //         let underlying_token_address = underlying_token_factory::token_address(
    //             underlying_token_symbol);
    //         vector::push_back(&mut underlying_asset_addr, underlying_token_address);
    //
    //         // create variable tokens
    //         let variable_token_name = format1(&b"TEST_VAR_TOKEN_{}", i);
    //         let variable_token_symbol = format1(&b"VAR{}", i);
    //         let variable_token_decimals = 3;
    //         variable_token_factory::create_token(variable_tokens_admin,
    //             variable_token_name,
    //             variable_token_symbol,
    //             variable_token_decimals,
    //             utf8(b""),
    //             utf8(b""),
    //             underlying_token_address, // take random
    //         );
    //         let underlying_token_address = variable_token_factory::token_address(
    //             variable_token_symbol);
    //         vector::push_back(&mut variable_debt_token_addr, underlying_token_address);
    //
    //         // create a tokens
    //         let a_token_name = format1(&b"A_TOKEN_{}", i);
    //         let a_token_symbol = format1(&b"ATOKEN{}", i);
    //         a_token_factory::create_token(a_tokens_admin,
    //             a_token_name,
    //             a_token_symbol,
    //             underlying_token_decimals,
    //             utf8(b""),
    //             utf8(b""),
    //             underlying_token_address, // underlying asset address
    //             @0x64, // treasury address
    //         );
    //         let a_token_address = a_token_factory::token_address(a_token_symbol);
    //         vector::push_back(&mut a_token_impl, a_token_address);
    //     };
    //
    //     // add reserves
    //     for (i in 0..tokens_to_create) {
    //         test_init_reserve(*vector::borrow(&a_token_impl, i),
    //             *vector::borrow(&variable_debt_token_addr, i),
    //             decimals,
    //             *vector::borrow(&underlying_asset_addr, i));
    //         let total_reserves = get_reserves_count();
    //         assert!(total_reserves == ((i + 1) as u256), TEST_SUCCESS);
    //     };
    //
    //     // drop some reserves
    //     test_drop_reserve(*vector::borrow(&underlying_asset_addr, 0));
    //     test_drop_reserve(*vector::borrow(&underlying_asset_addr, 1));
    //
    //     // add another reserve
    //     test_init_reserve(@0x015, @0x025, decimals, @0x035);
    //
    //     let total_reserves = get_reserves_count();
    //     assert!(total_reserves == ((tokens_to_create - 2 + 1) as u256), TEST_SUCCESS);
    // }

    public fun create_reserve_with_config(
        account: &signer,
        underlying_asset_addr: address,
        underlying_asset_decimals: u256,
        treasury: address,
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
        ltv: Option<u256>,
        liquidation_threshold: Option<u256>,
        liquidation_bonus: Option<u256>,
        decimals: Option<u256>,
        active: Option<bool>,
        frozen: Option<bool>,
        paused: Option<bool>,
        borrowable_in_isolation: Option<bool>,
        siloed_borrowing: Option<bool>,
        borrowing_enabled: Option<bool>,
        reserve_factor: Option<u256>,
        borrow_cap: Option<u256>,
        supply_cap: Option<u256>,
        debt_ceiling: Option<u256>,
        liquidation_protocol_fee: Option<u256>,
        unbacked_mint_cap: Option<u256>,
        e_mode_category: Option<u256>,
        flash_loan_enabled: Option<bool>,
    ): u256 {
        // create a brand new reserve
        test_init_reserve(
            account,
            underlying_asset_addr,
            (underlying_asset_decimals as u8),
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
        );

        let reserve_config_new = init();
        set_ltv(&mut reserve_config_new, option::get_with_default(&ltv, 100));
        set_liquidation_threshold(&mut reserve_config_new,
            option::get_with_default(&liquidation_threshold, 101));
        set_liquidation_bonus(&mut reserve_config_new,
            option::get_with_default(&liquidation_bonus, 102));
        set_decimals(&mut reserve_config_new, option::get_with_default(&decimals, 103));
        set_active(&mut reserve_config_new, option::get_with_default(&active, true));
        set_frozen(&mut reserve_config_new, option::get_with_default(&frozen, false));
        set_paused(&mut reserve_config_new, option::get_with_default(&paused, false));
        set_borrowable_in_isolation(&mut reserve_config_new,
            option::get_with_default(&borrowable_in_isolation, false));
        set_siloed_borrowing(&mut reserve_config_new,
            option::get_with_default(&siloed_borrowing, false));
        set_borrowing_enabled(&mut reserve_config_new,
            option::get_with_default(&borrowing_enabled, false));
        set_reserve_factor(&mut reserve_config_new,
            option::get_with_default(&reserve_factor, 104));
        set_borrow_cap(&mut reserve_config_new, option::get_with_default(&borrow_cap, 105));
        set_supply_cap(&mut reserve_config_new, option::get_with_default(&supply_cap, 106));
        set_debt_ceiling(&mut reserve_config_new,
            option::get_with_default(&debt_ceiling, 107));
        set_liquidation_protocol_fee(&mut reserve_config_new,
            option::get_with_default(&liquidation_protocol_fee, 108));
        set_unbacked_mint_cap(&mut reserve_config_new,
            option::get_with_default(&unbacked_mint_cap, 109));
        set_emode_category(&mut reserve_config_new,
            option::get_with_default(&e_mode_category, 0));
        set_flash_loan_enabled(&mut reserve_config_new,
            option::get_with_default(&flash_loan_enabled, true));

        // set the reserve configuration
        test_set_reserve_configuration(underlying_asset_addr, reserve_config_new);

        let reserve_index = get_reserves_count();
        reserve_index
    }

    public fun create_user_config_for_reserve(
        user: address,
        reserve_index: u256,
        is_borrowing: Option<bool>,
        is_using_as_collateral: Option<bool>,
    ) {
        let user_config_map = get_user_configuration(user);
        set_borrowing(&mut user_config_map, reserve_index,
            option::get_with_default(&is_borrowing, false));
        set_using_as_collateral(&mut user_config_map,
            reserve_index,
            option::get_with_default(&is_using_as_collateral, false));
        // set the user configuration
        set_user_configuration(user, user_config_map);
    }
}
