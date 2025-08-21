#[test_only]
module aave_pool::liquidation_validation_tests {
    use std::signer;
    use std::string::{utf8, bytes};
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_oracle::oracle;
    use aave_pool::user_logic;
    use aave_pool::pool;
    use aave_pool::supply_logic;
    use aave_pool::borrow_logic;
    use aave_pool::liquidation_logic::liquidation_call;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool_fee_manager;
    use aave_pool::pool_configurator;
    use aave_pool::token_helper::{
        init_reserves,
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
            borrower = @0x41,
            liquidator = @0x42
        )
    ]
    // It's not possible to liquidate on a non-active collateral asset
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_liquidation_when_collateral_asset_is_not_active(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        pool_configurator::set_reserve_active(
            aave_pool, underlying_u1_token_address, false
        );

        liquidation_call(
            liquidator,
            underlying_u1_token_address,
            underlying_u2_token_address,
            borrower_address,
            1000 * math_utils::pow(10, 8),
            false
        )
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            borrower = @0x41,
            liquidator = @0x42
        )
    ]
    // It's not possible to liquidate on a non-active debt asset
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_liquidation_when_debt_asset_is_not_active(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        pool_configurator::set_reserve_active(
            aave_pool, underlying_u2_token_address, false
        );

        liquidation_call(
            liquidator,
            underlying_u1_token_address,
            underlying_u2_token_address,
            borrower_address,
            1000 * math_utils::pow(10, 8),
            false
        )
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            borrower = @0x41,
            liquidator = @0x42
        )
    ]
    // It's not possible to liquidate when collateral asset is paused
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_liquidation_when_collateral_asset_is_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u1_token_address,
            true,
            0
        );

        liquidation_call(
            liquidator,
            underlying_u1_token_address,
            underlying_u2_token_address,
            borrower_address,
            1000 * math_utils::pow(10, 8),
            false
        )
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            borrower = @0x41,
            liquidator = @0x42
        )
    ]
    // It's not possible to liquidate when debt asset is paused
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_liquidation_when_debt_asset_is_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        borrower: &signer,
        liquidator: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let borrower_address = signer::address_of(borrower);
        let liquidator_address = signer::address_of(liquidator);
        create_account_for_test(borrower_address);
        create_account_for_test(liquidator_address);

        // init reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u2_token_address,
            true,
            0
        );

        liquidation_call(
            liquidator,
            underlying_u1_token_address,
            underlying_u2_token_address,
            borrower_address,
            1000 * math_utils::pow(10, 8),
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42
        )
    ]
    // test liquidation when health_factor > threshold (revert expected)
    #[expected_failure(abort_code = 45, location = aave_pool::validation_logic)]
    fun test_liquidation_when_health_factor_is_greater_than_threshold(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        depositor: &signer,
        borrower: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // create users
        let depositor_address = signer::address_of(depositor);
        let borrower_address = signer::address_of(borrower);
        create_account_for_test(depositor_address);
        create_account_for_test(borrower_address);

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
        // mint 500 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 500) as u64),
            underlying_u1_token_address
        );

        // Set prices to trigger liquidation
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 100, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 500 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 500),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 500 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 500) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 500 U_2 tokens to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower
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

        // borrower borrow 250 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 250),
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

        // depositor Try to liquidate the borrower
        liquidation_call(
            depositor,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            0,
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // if collateral isn't enabled as collateral by user, it cannot be liquidated
    #[expected_failure(abort_code = 46, location = aave_pool::validation_logic)]
    fun test_liquidation_when_collateral_is_not_enabled_as_collateral(
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
        set_time_has_started_for_testing(aave_std);

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
        // mint 500 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 500) as u64),
            underlying_u1_token_address
        );

        // set asset price
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 500 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 500),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 500 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 500) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 500 U_2 tokens to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
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

        // borrower borrow 2 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
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

        // Change asset price and Drop the health factor below 1
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_chainlink_mock_price(
            aave_pool,
            math_utils::percent_mul(10, 118000),
            underlying_u1_token_feed_id
        );

        // disabled collateral asset
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let reserve_id = pool::get_reserve_id(reserve_data);
        let user_config_map = pool::get_user_configuration(borrower_address);
        user_config::set_using_as_collateral(
            &mut user_config_map,
            (reserve_id as u256),
            false
        );

        pool::set_user_configuration_for_testing(borrower_address, user_config_map);

        // mint 1000 U_1 tokens to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // liquidator Try to liquidate the borrower
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            convert_to_currency_decimals(underlying_u2_token_address, 20),
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // if collateral liquidation threshold is 0, it cannot be liquidated
    #[expected_failure(abort_code = 46, location = aave_pool::validation_logic)]
    fun test_liquidation_when_collateral_liquidation_threshold_is_zero(
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
        set_time_has_started_for_testing(aave_std);

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
        // mint 500 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 500) as u64),
            underlying_u1_token_address
        );

        // set asset price
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 500 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 500),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 500 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 500) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 500 U_2 tokens to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
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

        // borrower borrow 2 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
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

        // Change asset price and Drop the health factor below 1
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_chainlink_mock_price(
            aave_pool,
            math_utils::percent_mul(10, 118000),
            underlying_u1_token_feed_id
        );
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // set collateral liquidation threshold to 0
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        reserve_config::set_liquidation_threshold(&mut reserve_config_map, 0);
        pool::test_set_reserve_configuration(
            underlying_u2_token_address,
            reserve_config_map
        );

        // mint 1000 U_1 tokens to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // liquidator Try to liquidate the borrower
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            convert_to_currency_decimals(underlying_u2_token_address, 20),
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // test liquidation when total debt == 0 and health_factor > threshold (revert expected)
    // health_factor == u256_max
    #[expected_failure(abort_code = 45, location = aave_pool::validation_logic)]
    fun test_liquidation_when_total_debt_is_zero_and_health_factor_is_greater_than_threshold(
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
        set_time_has_started_for_testing(aave_std);

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
        // mint 500 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 500) as u64),
            underlying_u1_token_address
        );

        // set asset price
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 500 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 500),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 500 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 500) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 500 U_2 tokens to the pool
        supply_logic::supply(
            borrower,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
            borrower_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            borrower, underlying_u2_token_address, true
        );

        // mint 1 APT to the borrower
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

        // borrower borrow 300 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
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

        // Change asset price and Drop the health factor below 1
        oracle::set_chainlink_mock_price(
            aave_pool,
            math_utils::percent_mul(10, 118000),
            underlying_u1_token_feed_id
        );

        // disabled collateral asset
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let reserve_id = pool::get_reserve_id(reserve_data);
        let user_config_map = pool::get_user_configuration(borrower_address);
        user_config::set_using_as_collateral(
            &mut user_config_map,
            (reserve_id as u256),
            false
        );

        pool::set_user_configuration_for_testing(borrower_address, user_config_map);

        // mint 1 APT to the borrower
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            borrower_address, 100000000
        );

        // borrower repay 300 U_1 tokens to the pool
        borrow_logic::repay(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
            2,
            borrower_address
        );

        // mint 1000 U_1 tokens to the liquidator
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // liquidator Try to liquidate the borrower
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            convert_to_currency_decimals(underlying_u2_token_address, 20),
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // Pool Liquidation: Liquidator receiving aToken
    // depositor Deposits U_1,
    // borrower Deposits U_2, borrows U_1
    // Drop the health factor below 1
    // test liquidation when total debt == 0 and health_factor < threshold (revert expected)
    #[expected_failure(abort_code = 47, location = aave_pool::validation_logic)]
    fun test_liquidation_when_total_debt_is_zero_and_health_is_less_than_factor_threshold(
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
        set_time_has_started_for_testing(aave_std);

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
        // mint 1000 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 500 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 1000 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 1000 U_2 tokens to the pool
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

        // mint 1 APT to the borrower
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

        // borrower borrow 300 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
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

        // Change asset price and Drop the health factor below 1
        oracle::set_chainlink_mock_price(
            aave_pool,
            math_utils::percent_mul(10, 118000),
            underlying_u1_token_feed_id
        );

        // liquidator Try to liquidate the borrower
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u2_token_address,
            borrower_address,
            math_utils::pow(10, 18),
            true
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    #[expected_failure(abort_code = 97, location = aave_pool::validation_logic)]
    fun test_liquidation_when_liquidation_grace_sentinel_check_failed(
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
        set_time_has_started_for_testing(aave_std);

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
        // mint 1000 U_1 tokens to the depositor
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price
        let underlying_u1_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u1_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u1_token_address, underlying_u1_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u1_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u1_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // deposit 1000 U_1 tokens to the pool
        supply_logic::supply(
            depositor,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            depositor_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 1000 U_2 tokens to the borrower
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            borrower_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_pool, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_pool, 10, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_pool,
            underlying_u2_token_address,
            oracle::get_test_max_price_age_secs()
        );

        // supply 1000 U_2 tokens to the pool
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

        // mint 1 APT to the borrower
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

        // borrower borrow 300 U_1 tokens from the pool
        borrow_logic::borrow(
            borrower,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 300),
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

        // Change asset price and Drop the health factor below 1
        oracle::set_chainlink_mock_price(
            aave_pool,
            math_utils::percent_mul(10, 118000),
            underlying_u1_token_feed_id
        );

        // set liquidation grace period to 1001 > timestamp::now_seconds() = 1000
        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u2_token_address,
            false,
            1001
        );

        // liquidator Try to liquidate the borrower
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            convert_to_currency_decimals(underlying_u2_token_address, 20),
            false
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
            underlying_tokens_admin = @aave_mock_underlyings,
            depositor = @0x41,
            borrower = @0x42,
            liquidator = @0x43
        )
    ]
    // depositor deposits 1000 U_1
    // borrower deposits 1000 U_1, borrows 10 U_1
    // Drop the health factor below 1
    // Liquidates the borrow while leaving dust (revert expected)
    #[expected_failure(abort_code = 103, location = aave_pool::liquidation_logic)]
    fun test_liquidation_when_leave_dust(
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

        // mint 1 APT to the borrower
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

        // set global time
        timestamp::update_global_time_for_test_secs(1100);

        let amount_to_liquidate = 500;
        liquidation_call(
            liquidator,
            underlying_u2_token_address,
            underlying_u1_token_address,
            borrower_address,
            amount_to_liquidate,
            false
        );
    }
}
