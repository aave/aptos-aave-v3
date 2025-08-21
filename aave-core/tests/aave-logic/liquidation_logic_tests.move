#[test_only]
module aave_pool::liquidation_logic_tests {
    use std::signer;
    use std::string::{utf8, bytes};
    use std::vector;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_acl::acl_manage;
    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_oracle::oracle;
    use aave_pool::pool_fee_manager;
    use aave_pool::emode_logic;
    use aave_pool::pool_configurator;
    use aave_pool::liquidation_logic::{liquidation_call, LiquidationCall};
    use aave_pool::pool_data_provider;
    use aave_pool::user_logic;
    use aave_pool::token_helper::{init_reserves_with_oracle, convert_to_currency_decimals};
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;
    use aave_pool::pool;
    use aave_mock_underlyings::mock_underlying_token_factory;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow
    fun test_liquidation_when_use_underlying_liquidation(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1300 U_2, borrows 10 U_1
    // Drop the health factor below 1 and greater than 0.95
    // Liquidates 50% of the borrower's debt
    fun test_liquidation_when_use_underlying_liquidation_in_emode(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(
            aave_oracle,
            100000000 * math_utils::pow(10, 18),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 600000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 600000) as u64),
            underlying_u2_token_address
        );
        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(
            aave_oracle,
            1000000000 * math_utils::pow(10, 18),
            underlying_u2_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1300 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1300),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // set emode
        pool_configurator::set_emode_category(
            aave_pool, 1, 8500, 9000, 10500, utf8(b"EMODE")
        );
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_u1_token_address, 1
        );
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_u2_token_address, 1
        );
        emode_logic::set_user_emode(borrower, 1);

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // borrower borrows 10 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 10
        );
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            borrow_amount,
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 9000, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, u2_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after == borrow_amount / 2,
            TEST_SUCCESS
        );
        assert!(u2_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == borrow_amount, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_1, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow
    fun test_liquidation_when_liquidation_protocol_fee_greater_than_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // set liquidation protocol fee for U_2
        pool_configurator::set_liquidation_protocol_fee(
            aave_pool, underlying_u2_token_address, 1000
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow
    fun test_liquidation_when_receive_a_token(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            true
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_0, 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow
    fun test_liquidation_when_has_no_collateral_left_and_user_has_borrowing_any(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // mint 1000 U_0 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u0_token_address, 1000) as u64),
            underlying_u0_token_address
        );

        // supply 1000 U_0 to the pool
        supply_logic::supply(
            depositor,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u0_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u0_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u0_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u0_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_0 and 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 10),
            2,
            0,
            borrower_address
        );

        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address) * 2,
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        // set virtual acc active is false
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );

        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_0, 10 U_1
    // Drop the health factor below 1
    // Set U_0 reserve as inactive
    // Liquidates the borrow
    fun test_liquidation_burn_bad_debt_when_reserve_is_not_active(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // mint 1000 U_0 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u0_token_address, 1000) as u64),
            underlying_u0_token_address
        );

        // supply 1000 U_0 to the pool
        supply_logic::supply(
            depositor,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u0_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u0_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u0_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u0_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_0 and 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 10),
            2,
            0,
            borrower_address
        );

        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address) * 2,
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        // set virtual acc active is false
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // set u0 reserve as not active
        let u0_reserve_config =
            pool::get_reserve_configuration(underlying_u0_token_address);
        reserve_config::set_active(&mut u0_reserve_config, false);
        pool::test_set_reserve_configuration(
            underlying_u0_token_address,
            u0_reserve_config
        );

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );

        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_0, 10 U_1
    // Drop the health factor below 1
    // Set U2 reserve debt ceiling to 1000
    // Liquidates the borrow
    fun test_liquidation_when_collateral_reserve_debt_ceiling_is_not_equal_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );

        // Config U_0
        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // mint 1000 U_0 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u0_token_address, 1000) as u64),
            underlying_u0_token_address
        );

        // supply 1000 U_0 to the pool
        supply_logic::supply(
            depositor,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1000),
            depositor_address,
            0
        );

        // set U0 price
        let underlying_u0_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u0_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u0_token_address, underlying_u0_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u0_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u0_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // Config U1
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set U1 price
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        // Config U2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set U2 price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_0 and 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 10),
            2,
            0,
            borrower_address
        );

        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address) * 2,
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        // set virtual acc active is false
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // set U_2 reserve debt ceiling to 1000
        let u2_reserve_config =
            pool::get_reserve_configuration(underlying_u2_token_address);
        reserve_config::set_debt_ceiling(&mut u2_reserve_config, 1000);
        pool::test_set_reserve_configuration(
            underlying_u2_token_address,
            u2_reserve_config
        );

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );

        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1300 U_2, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow when has collateral left and outstanding debt > 0
    fun test_liquidation_when_has_collateral_left_and_outstanding_debt_gt_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(
            aave_oracle,
            100000000 * math_utils::pow(10, 18),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 600000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 600000) as u64),
            underlying_u2_token_address
        );
        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(
            aave_oracle,
            1000000000 * math_utils::pow(10, 18),
            underlying_u2_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1300 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1300),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // set emode
        pool_configurator::set_emode_category(
            aave_pool, 1, 8500, 9000, 10500, utf8(b"EMODE")
        );
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_u1_token_address, 1
        );
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_u2_token_address, 1
        );
        emode_logic::set_user_emode(borrower, 1);

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 9000, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        // mints 1000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 5);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, u2_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                <= u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == amount_to_liquidate, TEST_SUCCESS);
        assert!(u2_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before > amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow when the liquidator is the borrower
    fun test_liquidation_receive_a_token_when_liquidator_is_borrower(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        // mint 100000 U_1 to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 100000) as u64),
            underlying_u1_token_address
        );

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            borrower,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            true
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
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
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_2, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow with collateral a token
    fun test_liquidation_receive_a_token_when_liquidator_has_collateral_a_token(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
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
        // mint 1000 U_1 to depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );
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

        // depositor deposits 1000 U_1 to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );

        // mint 1000 U_2 to borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // borrower deposits 1000 U_2 to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(borrower_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // borrower borrows 10 U_1
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            borrower_address
        );

        assert!(
            coin::balance<AptosCoin>(borrower_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        let (_, _, _, current_liquidation_threshold, _, _) =
            user_logic::get_user_account_data(borrower_address);
        assert!(current_liquidation_threshold == 8500, TEST_SUCCESS);

        // Drop the health factor below 1
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);
        oracle::set_chainlink_mock_price(
            aave_oracle,
            math_utils::percent_mul(u1_price, 11800000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_oracle,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        let (_, _, _, _, _, health_factor) =
            user_logic::get_user_account_data(borrower_address);
        assert!(
            health_factor < user_config::get_health_factor_liquidation_threshold(),
            TEST_SUCCESS
        );

        let (_, u1_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_before, u2_current_variable_debt_before, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_before =
            pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_before =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        // mint 10000000000 U_1 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (
                convert_to_currency_decimals(underlying_u1_token_address, 10000000000) as u64
            ),
            underlying_u1_token_address
        );

        // mint 1000 U_2 to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // supply 1000 U_2 to the pool
        let supply_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            liquidator,
            underlying_u2_token_address,
            supply_amount,
            liquidator_address,
            0
        );

        let amount_to_liquidate =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            true
        );

        // check LiquidationCall emitted events
        let emitted_events = emitted_events<LiquidationCall>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_current_variable_debt_after, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, borrower_address
            );

        let (u2_current_a_token_balance_after, _, _, _, _) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, borrower_address
            );

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_liquidity_index_after = pool::get_reserve_liquidity_index(u1_reserve_data);
        let u1_liquidity_rate_after =
            pool::get_reserve_current_liquidity_rate(u1_reserve_data);

        let collateral_price = oracle::get_asset_price(underlying_u2_token_address);
        let principal_price = oracle::get_asset_price(underlying_u1_token_address);
        let (collateral_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );
        let (principal_decimals, _, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        let base_collateral =
            (
                principal_price * amount_to_liquidate
                    * math_utils::pow(10, collateral_decimals)
            ) / (collateral_price * math_utils::pow(10, principal_decimals));
        let expected_collateral_liquidated =
            math_utils::percent_mul(base_collateral, 10500);

        assert!(
            expected_collateral_liquidated
                > u2_current_a_token_balance_before - u2_current_a_token_balance_after,
            TEST_SUCCESS
        );
        assert!(
            u1_current_variable_debt_after
                == u1_current_variable_debt_before - amount_to_liquidate,
            TEST_SUCCESS
        );
        assert!(u1_current_variable_debt_after == 0, TEST_SUCCESS);
        assert!(u2_current_variable_debt_before == 0, TEST_SUCCESS);
        assert!(u1_current_variable_debt_before == amount_to_liquidate, TEST_SUCCESS);
        assert!(u1_liquidity_index_after >= u1_liquidity_index_before, TEST_SUCCESS);
        assert!(u1_liquidity_rate_after < u1_liquidity_rate_before, TEST_SUCCESS);
    }
}
