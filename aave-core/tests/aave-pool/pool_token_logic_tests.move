#[test_only]
module aave_pool::pool_token_logic_tests {
    use std::option;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_config::reserve_config;
    use aave_math::wad_ray_math;
    use aave_pool::events::{
        ReserveUsedAsCollateralEnabled,
        BalanceTransfer,
        ReserveUsedAsCollateralDisabled
    };
    use aave_pool::pool_configurator;
    use aave_pool::token_helper;
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::a_token_factory;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_pool::pool_token_logic::{Self, mint_to_treasury, MintedToTreasury};
    use aave_pool::token_helper::{
        init_reserves,
        init_reserves_with_assets_count_params,
        convert_to_currency_decimals,
        init_reserves_with_oracle
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    #[expected_failure(abort_code = 1503, location = aave_pool::fungible_asset_manager)]
    fun test_init_reserve_when_underlying_asset_not_exist(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_asset: address = @0x22;
        let treasury: address = @0x33;
        let a_token_name: String = utf8(b"aDAI");
        let a_token_symbol: String = utf8(b"ADAI");
        let variable_debt_token_name: String = utf8(b"vDAI");
        let variable_debt_token_symbol: String = utf8(b"VDAI");

        pool_token_logic::test_init_reserve(
            aave_pool,
            underlying_asset,
            treasury,
            option::none(),
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            400,
            100,
            200,
            300
        )
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 14, location = aave_pool::pool_token_logic)]
    fun test_init_reserve_when_reserve_already_added(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_asset: address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let treasury: address = @0x33;
        let a_token_name: String = utf8(b"aDAI");
        let a_token_symbol: String = utf8(b"ADAI");
        let variable_debt_token_name: String = utf8(b"vDAI");
        let variable_debt_token_symbol: String = utf8(b"VDAI");

        pool_token_logic::test_init_reserve(
            aave_pool,
            underlying_asset,
            treasury,
            option::none(),
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            400,
            100,
            200,
            300
        )
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
    #[expected_failure(abort_code = 15, location = aave_pool::pool)]
    fun test_init_reserve_when_no_more_reserves_allowed(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        init_reserves_with_assets_count_params(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            reserve_config::get_max_reserves_count() + 1
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
    fun test_init_reserve_when_drop_an_asset_and_then_adding_it_again(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init 3 reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let asset_count = 3;

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(reserve_list_count == asset_count, TEST_SUCCESS);

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(reserve_addresses_list_count == asset_count, TEST_SUCCESS);

        let id = 1;
        let underlying_asset: address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_asset);
        assert!(pool::get_reserve_id(reserve_data) == id, TEST_SUCCESS);

        let reserve_address = pool::get_reserve_address_by_id((id as u256));
        assert!(reserve_address == underlying_asset, TEST_SUCCESS);

        // drop U_1
        pool_token_logic::test_drop_reserve(underlying_asset);

        let reserve_address = pool::get_reserve_address_by_id((id as u256));
        assert!(reserve_address == @0x0, TEST_SUCCESS);

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_list_count == asset_count - 1,
            TEST_SUCCESS
        );

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_addresses_list_count == asset_count - 1,
            TEST_SUCCESS
        );

        // add U_1 again
        let treasury: address = @0x33;
        let a_token_name: String = utf8(b"aDAI");
        let a_token_symbol: String = utf8(b"ADAI");
        let variable_debt_token_name: String = utf8(b"vDAI");
        let variable_debt_token_symbol: String = utf8(b"VDAI");

        pool_token_logic::test_init_reserve(
            aave_pool,
            underlying_asset,
            treasury,
            option::none(),
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            400,
            100,
            200,
            300
        );

        let reserve_data = pool::get_reserve_data(underlying_asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let a_token_name_new = a_token_factory::name(a_token_address);
        assert!(a_token_name == a_token_name_new, TEST_SUCCESS);

        let a_token_symbol_new = a_token_factory::symbol(a_token_address);
        assert!(a_token_symbol == a_token_symbol_new, TEST_SUCCESS);

        let treasury_new = a_token_factory::get_reserve_treasury_address(a_token_address);
        assert!(treasury == treasury_new, TEST_SUCCESS);

        let variable_debt_token_name_new =
            variable_debt_token_factory::name(variable_debt_token_address);
        assert!(variable_debt_token_name == variable_debt_token_name_new, TEST_SUCCESS);

        let variable_debt_token_symbol_new =
            variable_debt_token_factory::symbol(variable_debt_token_address);
        assert!(
            variable_debt_token_symbol == variable_debt_token_symbol_new, TEST_SUCCESS
        );

        let reserve_address = pool::get_reserve_address_by_id((id as u256));
        assert!(reserve_address == underlying_asset, TEST_SUCCESS);

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(reserve_list_count == asset_count, TEST_SUCCESS);

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(reserve_addresses_list_count == asset_count, TEST_SUCCESS);
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
    fun test_init_reserve_when_drop_multiple_asset_and_then_adding_them_again(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let asset_count = 20;
        // init 20 reserves
        init_reserves_with_assets_count_params(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            asset_count
        );

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(reserve_list_count == asset_count, TEST_SUCCESS);

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(reserve_addresses_list_count == asset_count, TEST_SUCCESS);

        let drop_asset_count = 3;
        let u1_id = 1;
        let u1_underlying_asset: address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let u4_id = 4;
        let u4_underlying_asset: address =
            mock_underlying_token_factory::token_address(utf8(b"U_4"));
        let u16_id = 16;
        let u16_underlying_asset: address =
            mock_underlying_token_factory::token_address(utf8(b"U_16"));

        let u1_reserve_data = pool::get_reserve_data(u1_underlying_asset);
        assert!(pool::get_reserve_id(u1_reserve_data) == u1_id, TEST_SUCCESS);

        let u4_reserve_data = pool::get_reserve_data(u4_underlying_asset);
        assert!(pool::get_reserve_id(u4_reserve_data) == u4_id, TEST_SUCCESS);

        let u16_reserve_data = pool::get_reserve_data(u16_underlying_asset);
        assert!(pool::get_reserve_id(u16_reserve_data) == u16_id, TEST_SUCCESS);

        let u1_reserve_address = pool::get_reserve_address_by_id((u1_id as u256));
        assert!(u1_reserve_address == u1_underlying_asset, TEST_SUCCESS);

        let u4_reserve_address = pool::get_reserve_address_by_id((u4_id as u256));
        assert!(u4_reserve_address == u4_underlying_asset, TEST_SUCCESS);

        let u16_reserve_address = pool::get_reserve_address_by_id((u16_id as u256));
        assert!(u16_reserve_address == u16_underlying_asset, TEST_SUCCESS);

        // drop U_1, U_4 and U_16
        pool_token_logic::test_drop_reserve(u1_underlying_asset);
        pool_token_logic::test_drop_reserve(u4_underlying_asset);
        pool_token_logic::test_drop_reserve(u16_underlying_asset);

        let u1_reserve_address = pool::get_reserve_address_by_id((u1_id as u256));
        assert!(u1_reserve_address == @0x0, TEST_SUCCESS);

        let u4_reserve_address = pool::get_reserve_address_by_id((u4_id as u256));
        assert!(u4_reserve_address == @0x0, TEST_SUCCESS);

        let u16_reserve_address = pool::get_reserve_address_by_id((u16_id as u256));
        assert!(u16_reserve_address == @0x0, TEST_SUCCESS);

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_list_count == asset_count - drop_asset_count,
            TEST_SUCCESS
        );

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_addresses_list_count == asset_count - drop_asset_count,
            TEST_SUCCESS
        );

        // add U_1 again
        let treasury: address = @0x33;
        let a_token_name: String = utf8(b"aDAI");
        let a_token_symbol: String = utf8(b"ADAI");
        let variable_debt_token_name: String = utf8(b"vDAI");
        let variable_debt_token_symbol: String = utf8(b"VDAI");

        pool_token_logic::test_init_reserve(
            aave_pool,
            u1_underlying_asset,
            treasury,
            option::none(),
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            400,
            100,
            200,
            300
        );

        let reserve_data = pool::get_reserve_data(u1_underlying_asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let a_token_name_new = a_token_factory::name(a_token_address);
        assert!(a_token_name == a_token_name_new, TEST_SUCCESS);

        let a_token_symbol_new = a_token_factory::symbol(a_token_address);
        assert!(a_token_symbol == a_token_symbol_new, TEST_SUCCESS);

        let treasury_new = a_token_factory::get_reserve_treasury_address(a_token_address);
        assert!(treasury == treasury_new, TEST_SUCCESS);

        let variable_debt_token_name_new =
            variable_debt_token_factory::name(variable_debt_token_address);
        assert!(variable_debt_token_name == variable_debt_token_name_new, TEST_SUCCESS);

        let variable_debt_token_symbol_new =
            variable_debt_token_factory::symbol(variable_debt_token_address);
        assert!(
            variable_debt_token_symbol == variable_debt_token_symbol_new, TEST_SUCCESS
        );

        let reserve_address = pool::get_reserve_address_by_id((u1_id as u256));
        assert!(reserve_address == u1_underlying_asset, TEST_SUCCESS);

        let reserve_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_list_count == asset_count - drop_asset_count + 1,
            TEST_SUCCESS
        );

        let reserve_addresses_list_count = pool::number_of_active_reserves();
        assert!(
            reserve_addresses_list_count == asset_count - drop_asset_count + 1,
            TEST_SUCCESS
        );
    }

    #[test]
    #[expected_failure(abort_code = 77, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_when_asset_address_is_zero_address() {
        let asset = @0x0;
        pool_token_logic::test_drop_reserve(asset);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    #[expected_failure(abort_code = 54, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_when_underlying_claimable_rights_not_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        create_account_for_test(user1_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // mint 10 APT to the user1_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // Deleting assets when liquidity already exists, with expected revert
        pool_token_logic::test_drop_reserve(underlying_u1_token_address);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // user1 mint 1000 U_1,
    // user1 deposit 1000 U_1
    // user1 borrow 100 U_1
    #[expected_failure(abort_code = 56, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_when_variable_debt_supply_not_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        create_account_for_test(user1_address);

        init_reserves_with_oracle(
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
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // mint 10 APT to the user1_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );

        // set asset price for U_1 token
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user1 borrow 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user1,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user1_address
        );

        // drop reserve with expected revert
        pool_token_logic::test_drop_reserve(underlying_u1_token_address);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41
        )
    ]
    fun test_mint_to_treasury_when_accrued_to_treasury_is_zreo(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        create_account_for_test(depositor_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(reserve_data);

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let treasury_address =
            a_token_factory::get_reserve_treasury_address(a_token_address);

        mint_to_treasury(vector[underlying_u1_token_address]);

        let normalized_income =
            pool::get_reserve_normalized_income(underlying_u1_token_address);
        let treasury_balance =
            a_token_factory::balance_of(treasury_address, a_token_address);
        let expected_treasury_balance =
            wad_ray_math::ray_mul(accrued_to_treasury, normalized_income);

        assert!(treasury_balance == expected_treasury_balance, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41
        )
    ]
    // Depositor deposits 1000 U_1.
    // Depositor borrows 100 U_1.
    // Clock moved forward one year. Calculates and verifies the amount accrued to the treasury
    fun test_mint_to_treasury_when_accrued_to_treasury_gt_0(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        create_account_for_test(depositor_address);

        init_reserves_with_oracle(
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
        let amount_u1_to_deposit =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);

        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (amount_u1_to_deposit as u64),
            underlying_u1_token_address
        );

        // deposit 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            amount_u1_to_deposit,
            depositor_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            depositor, underlying_u1_token_address, true
        );

        // set asset price for U_1 token
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrow 100 U_1
        let amount_u1_to_borrow =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            depositor,
            underlying_u1_token_address,
            amount_u1_to_borrow,
            2,
            0,
            signer::address_of(depositor)
        );

        timestamp::fast_forward_seconds(31536000); // 1 year

        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (amount_u1_to_deposit as u64),
            underlying_u1_token_address
        );

        // deposit 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            amount_u1_to_deposit,
            depositor_address,
            0
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(reserve_data);
        assert!(accrued_to_treasury > 0, TEST_SUCCESS);

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // set U_2 inactive
        pool_configurator::set_reserve_active(
            aave_pool, underlying_u2_token_address, false
        );

        mint_to_treasury(
            vector[underlying_u1_token_address, underlying_u2_token_address]
        );

        // check emitted events
        let emitted_events = emitted_events<MintedToTreasury>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(reserve_data);
        assert!(accrued_to_treasury == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // user1 mint 1000 U_1,
    // user1 deposit 1000 U_1
    // user1 transfer 100 a_token to user2
    fun test_transfer(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        // user1 transfer 100 a_token to user2
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        let transfer_amount = convert_to_currency_decimals(a_token_address, 100);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        // check ReserveUsedAsCollateralEnabled emitted events
        let collateral_enabled_emitted_events =
            emitted_events<ReserveUsedAsCollateralEnabled>();
        // make sure event of type was emitted
        assert!(vector::length(&collateral_enabled_emitted_events) == 0, TEST_SUCCESS);

        // check BalanceTransfer emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        // make sure event of type was emitted
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);

        let user1_balance_after =
            a_token_factory::balance_of(user1_address, a_token_address);
        assert!(
            user1_balance_after == user1_balance - transfer_amount,
            TEST_SUCCESS
        );

        let user2_balance_after =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance_after == transfer_amount, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_transfer_when_reserve_is_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        // user1 transfer 0 a_token to user2
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // pause the reserve
        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u1_token_address,
            true,
            0
        );

        pool_token_logic::transfer(
            user1,
            user2_address,
            convert_to_currency_decimals(a_token_address, 10),
            a_token_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 1 deposits 1000 U_1, disable as collateral, transfers 1000 to user 2
    fun test_transfer_when_disable_as_collateral(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // disable the reserve as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );

        // user1 transfer 1000 a_token to user2
        let transfer_amount = convert_to_currency_decimals(a_token_address, 1000);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        // check ReserveUsedAsCollateralEnabled emitted events
        let collateral_enabled_emitted_events =
            emitted_events<ReserveUsedAsCollateralEnabled>();
        // make sure event of type was emitted
        assert!(vector::length(&collateral_enabled_emitted_events) == 0, TEST_SUCCESS);

        // check BalanceTransfer emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        // make sure event of type was emitted
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);

        let user1_balance = a_token_factory::balance_of(user1_address, a_token_address);
        assert!(user1_balance == 0, TEST_SUCCESS);

        let user2_balance = a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance == transfer_amount, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 1 deposits 1000 U_1
    // User 2 deposits 1000 U_2
    // User 1 borrows 100 U_2
    // User 1 transfers 100 u1_a_token to user 2
    fun test_transfer_when_user_is_borrowing_any(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves_with_oracle(
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
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user2 mint 1000 U_2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        // user2 deposit 1000 U_2 to the pool
        let supply_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_u2_amount,
            user2_address,
            0
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let u2_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user2_balance = a_token_factory::balance_of(
            user2_address, u2_a_token_address
        );
        assert!(user2_balance == supply_u2_amount, TEST_SUCCESS);

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user1 borrow 100 U_2
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 100);
        borrow_logic::borrow(
            user1,
            underlying_u2_token_address,
            borrow_u2_amount,
            2,
            0,
            user1_address
        );

        // user1 transfer 100 u1_a_token to user2
        let transfer_amount = convert_to_currency_decimals(u1_a_token_address, 100);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            u1_a_token_address
        );

        // check BalanceTransfer emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        // make sure event of type was emitted
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);

        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(
            user1_balance == supply_u1_amount - transfer_amount,
            TEST_SUCCESS
        );

        let user2_balance = a_token_factory::balance_of(
            user2_address, u1_a_token_address
        );
        assert!(user2_balance == transfer_amount, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 1 deposits 1000 U_1
    // User 2 deposits 1000 U_2
    // User 1 borrows 100 U_2
    // User 1 transfers 1000 to user 2 (revert expected)
    #[expected_failure(abort_code = 35, location = aave_pool::validation_logic)]
    fun test_transfer_when_health_factor_lower_than_liquidation_threshold(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves_with_oracle(
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
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user2 mint 1000 U_2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        // user2 deposit 1000 U_2 to the pool
        let supply_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_u2_amount,
            user2_address,
            0
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let u2_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user2_balance = a_token_factory::balance_of(
            user2_address, u2_a_token_address
        );
        assert!(user2_balance == supply_u2_amount, TEST_SUCCESS);

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user1 borrow 100 U_2
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 100);
        borrow_logic::borrow(
            user1,
            underlying_u2_token_address,
            borrow_u2_amount,
            2,
            0,
            user1_address
        );

        // user1 transfer 1000 u1_a_token to user2 (revert expected)
        let transfer_amount = convert_to_currency_decimals(u1_a_token_address, 1000);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            u1_a_token_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 1 deposits 1000 U_1
    // User 1 transfers 1000 to user 2 (revert expected)
    fun test_transfer_when_balance_from_before_equal_amount(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // user1 transfer 1000 u1_a_token to user2
        let transfer_amount = convert_to_currency_decimals(u1_a_token_address, 1000);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            u1_a_token_address
        );

        // check ReserveUsedAsCollateralDisabled emitted events
        let collateral_disabled_emitted_events =
            emitted_events<ReserveUsedAsCollateralDisabled>();
        // make sure event of type was emitted
        assert!(vector::length(&collateral_disabled_emitted_events) == 1, TEST_SUCCESS);

        // check ReserveUsedAsCollateralEnabled emitted events
        let collateral_enabled_emitted_events =
            emitted_events<ReserveUsedAsCollateralEnabled>();
        // make sure event of type was emitted
        assert!(vector::length(&collateral_enabled_emitted_events) == 1, TEST_SUCCESS);

        // check BalanceTransfer emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        // make sure event of type was emitted
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);

        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(
            user1_balance == supply_u1_amount - transfer_amount,
            TEST_SUCCESS
        );
        let user2_balance = a_token_factory::balance_of(
            user2_address, u1_a_token_address
        );
        assert!(user2_balance == transfer_amount, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 1 deposits 1000 U_1
    // User 1 transfers 10 u1_a_token to user 1 (amount != 0 and sender == recipient)
    fun test_transfer_when_amount_non_zero_and_sender_equal_recipient(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        create_account_for_test(user1_address);
        create_account_for_test(user2_address);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // user1 transfer 10 u1_a_token to user1
        let transfer_amount = convert_to_currency_decimals(u1_a_token_address, 10);
        pool_token_logic::transfer(
            user1,
            user1_address,
            transfer_amount,
            u1_a_token_address
        );

        // check BalanceTransfer emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        // make sure event of type was emitted
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);

        let user1_balance = a_token_factory::balance_of(
            user1_address, u1_a_token_address
        );
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        let user2_balance = a_token_factory::balance_of(
            user2_address, u1_a_token_address
        );
        assert!(user2_balance == 0, TEST_SUCCESS);
    }
}
