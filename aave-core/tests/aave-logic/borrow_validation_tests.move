#[test_only]
module aave_pool::borrow_validation_tests {
    use std::signer;
    use std::string::utf8;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_pool::variable_debt_token_factory;

    use aave_pool::borrow_logic;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_oracle::oracle;
    use aave_pool::emode_logic;
    use aave_pool::token_helper;
    use aave_pool::pool;
    use aave_pool::pool_configurator;
    use aave_pool::pool_data_provider;
    use aave_pool::supply_logic;
    use aave_pool::token_helper::{
        convert_to_currency_decimals,
        init_reserves,
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
    #[expected_failure(abort_code = 1404, location = aave_pool::borrow_logic)]
    fun test_borrow_when_signer_and_on_behalf_of_no_same(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        let user2_address = signer::address_of(user2);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // User 1 borrows 100 U_2, on behalf of is user 2
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 100);
        borrow_logic::borrow(
            user1,
            underlying_u2_token_address,
            borrow_u2_amount,
            2,
            0,
            user2_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_borrow() when amount is zero (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_borrow_when_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // user1 repay 0 u_1 token from the pool
        borrow_logic::borrow(
            usre1,
            underlying_u1_token_address,
            0,
            2,
            0,
            user1_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_borrow() when reserve is active (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_borrow_when_reserve_is_not_active(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        reserve_config::set_active(&mut reserve_config_map, false);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // user1 repay 1000 u_1 token to the pool
        borrow_logic::borrow(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            2,
            0,
            signer::address_of(usre1)
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
    // validate_borrow() when reserve is paused (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_borrow_when_reserve_is_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == false, TEST_SUCCESS);

        // set reserve as not active
        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u1_token_address,
            true,
            0
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == true, TEST_SUCCESS);

        // borrow 1000  u_1 token from the pool
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            1000,
            2,
            0,
            signer::address_of(aave_pool)
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
    // validate_borrow() when reserve is frozen (revert expected)
    #[expected_failure(abort_code = 28, location = aave_pool::validation_logic)]
    fun test_validate_borrow_when_reserve_is_frozen(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_frozen = reserve_config::get_frozen(&reserve_config_map);
        assert!(is_frozen == false, TEST_SUCCESS);

        // set reserve as not active
        pool_configurator::set_reserve_freeze(
            aave_pool, underlying_u1_token_address, true
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // borrow 1000 u_1 token from the pool
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            1000,
            2,
            0,
            signer::address_of(aave_pool)
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
    // validate_borrow() when borrowing is not enabled (revert expected)
    #[expected_failure(abort_code = 30, location = aave_pool::validation_logic)]
    fun test_validate_borrow_when_borrowing_is_not_enabled(
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
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_borrowing_enabled =
            reserve_config::get_borrowing_enabled(&reserve_config_map);
        assert!(is_borrowing_enabled == true, TEST_SUCCESS);

        // set reserve not enabled for borrowing
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_u1_token_address, false
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_borrowing_enabled =
            reserve_config::get_borrowing_enabled(&reserve_config_map);
        assert!(is_borrowing_enabled == false, TEST_SUCCESS);

        // borrow 1000  u_1 token from the pool
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            1000,
            2,
            0,
            signer::address_of(aave_pool)
        );
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
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_borrow_with_asset_total_supply_lt_amount(
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

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // test isolation mode
        // mint 100 underlying tokens
        let aave_pool_address = signer::address_of(aave_pool);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 100) as u64),
            underlying_u1_token_address
        );
        // supply 100 underlying tokens to aave_pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            aave_pool_address,
            0
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // borrow 10000 underlying tokens
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10000),
            2,
            0,
            aave_pool_address
        );
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
    #[expected_failure(abort_code = 33, location = aave_pool::validation_logic)]
    fun test_borrow_when_invalid_interest_rate_mode_selected(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // User 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 1 borrows 100 U_2, on behalf of is user 1
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user1,
            underlying_u1_token_address,
            borrow_u2_amount,
            1,
            0,
            user1_address
        );
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
    // Borrows 10 variable U_1
    // Sets the borrow cap for U_1 to 10 Units
    // Tries to borrow any U_1 (> BORROW_CAP) (revert expected)
    #[expected_failure(abort_code = 50, location = aave_pool::validation_logic)]
    fun test_borrow_exceed_borrow_cap(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        // user1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supplied_amount,
            user1_address,
            0
        );

        // user2 supplies 1000 U_1
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000000000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supplied_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrow 10 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            user2_address
        );

        // set borrow cap for U_1 to 10
        pool_configurator::set_borrow_cap(aave_pool, underlying_u1_token_address, 10);

        // user2 tries to borrow 1 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1),
            2,
            0,
            user2_address
        );
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
    #[expected_failure(abort_code = 60, location = aave_pool::validation_logic)]
    fun test_borrow_with_asset_not_borrowable_in_isolation(
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

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // test isolation mode
        // mint 100 underlying tokens
        let aave_pool_address = signer::address_of(aave_pool);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 100) as u64),
            underlying_u1_token_address
        );
        // supply 100 underlying tokens to aave_pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            aave_pool_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            aave_pool, underlying_u1_token_address, true
        );

        // set debt ceiling
        let user_config_map = pool::get_user_configuration(aave_pool_address);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let debt_ceiling = 10000;
        reserve_config::set_debt_ceiling(&mut reserve_config_map, debt_ceiling);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let (
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        ) = pool::get_isolation_mode_state(&user_config_map);

        assert!(isolation_mode_active == true, TEST_SUCCESS);
        assert!(
            isolation_mode_collateral_address == underlying_u1_token_address,
            TEST_SUCCESS
        );
        assert!(isolation_mode_debt_ceiling == debt_ceiling, TEST_SUCCESS);

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // borrow 10 underlying tokens
        borrow_logic::borrow(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 10),
            2,
            0,
            aave_pool_address
        );
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
    // User 1 supplies 1000 U_1
    // Set borrowable in isolation for U_1
    // Set U_2 debt ceiling is 100
    // User 2 supplies 500 U_2
    // User 2 borrow 100 U_1 (revert expected)
    #[expected_failure(abort_code = 53, location = aave_pool::validation_logic)]
    fun test_borrow_with_debt_ceiling_exceeded(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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
        // set borrowable in isolation for U_1
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // set debt ceiling for U_2
        // let reserve_config_map = pool::get_reserve_configuration(underlying_u2_token_address);
        let debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_u2_token_address, debt_ceiling
        );

        // mint 1000 U_1 to user 1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 1000 U_1 to user 1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // mint 500 U_2 to user 2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 500) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 500 U_2 to user 2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 2 borrow 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );
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
            usre1 = @0x41,
            user2 = @0x42
        )
    ]
    // validate_borrow() with eMode > 0, borrowing asset not in emode category (revert expected)
    #[expected_failure(abort_code = 58, location = aave_pool::validation_logic)]
    fun test_validate_borrow_with_inconsistent_emode_category(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer,
        user2: &signer
    ) {
        let user1_address = signer::address_of(usre1);
        let user2_address = signer::address_of(user2);

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
        let u1_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);
        let u1_supply_amount = 2000 * math_utils::pow(10, (u1_decimals as u256));

        // mint 2000 u_1 token to the user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (u1_supply_amount as u64),
            underlying_u1_token_address
        );

        // set u_1 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 2000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            u1_supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let u2_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);
        let u2_supply_amount = 2000 * math_utils::pow(10, (u2_decimals as u256));

        // mint 2000 u_2 token to the user2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (u2_supply_amount as u64),
            underlying_u2_token_address
        );

        // set u_2 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 2000 u_2 token to the pool
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            u2_supply_amount,
            user2_address,
            0
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set emode category
        pool_configurator::set_emode_category(
            aave_pool,
            101,
            9800,
            9900,
            10100,
            utf8(b"NO-ASSETS")
        );

        emode_logic::set_user_emode(user2, 101);

        // user2 borrow 200 u_1 token from the pool
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            200 * math_utils::pow(10, 8),
            2,
            0,
            user2_address
        );
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
    // User 1 supplies 1000 U_1
    // User 2 has not deposited any tokens, tries to borrow 100 U_1 (revert expected)
    #[expected_failure(abort_code = 34, location = aave_pool::validation_logic)]
    fun test_borrow_when_collateral_balance_is_zero(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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
        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // User 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // User 2 mint 1000 U_2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 2 borrows 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );
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
    #[expected_failure(abort_code = 57, location = aave_pool::validation_logic)]
    fun test_borrow_when_ltv_is_zeor_validation_failed(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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
        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // User 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // User 1 set U_1 as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        // User 2 mint 1000 U_2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // User 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // Set U_1 LTV = 0
        let new_ltv = 0;
        let new_liquidation_threshold = 8000;
        let new_liquidation_bonus = 10500;
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_u1_token_address,
            new_ltv,
            new_liquidation_threshold,
            new_liquidation_bonus
        );

        let (_, ltv, liquidation_threshold, liquidation_bonus, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u1_token_address
            );

        assert!(ltv == new_ltv, TEST_SUCCESS);
        assert!(liquidation_threshold == new_liquidation_threshold, TEST_SUCCESS);
        assert!(liquidation_bonus == new_liquidation_bonus, TEST_SUCCESS);

        // User 1 borrows 100 U_2
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
            usre1 = @0x41,
            user2 = @0x42
        )
    ]
    // validate_borrow() borrowing when user has already a HF < threshold (revert expected)
    #[expected_failure(abort_code = 35, location = aave_pool::validation_logic)]
    fun test_validate_borrow_when_health_factor_lower_than_liquidation_threshold(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer,
        user2: &signer
    ) {
        let user1_address = signer::address_of(usre1);
        let user2_address = signer::address_of(user2);

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
        let u1_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);
        let u1_supply_amount = 2000 * math_utils::pow(10, (u1_decimals as u256));

        // mint 2000 u_1 token to the user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (u1_supply_amount as u64),
            underlying_u1_token_address
        );

        // set u_1 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 2000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            u1_supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let u2_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);
        let u2_supply_amount = 2000 * math_utils::pow(10, (u2_decimals as u256));
        // mint 2000 u_2 token to the user2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (u2_supply_amount as u64),
            underlying_u2_token_address
        );

        // set u_2 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 2000 u_2 token to the pool
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            u2_supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrow 2000 u_1 token from the pool
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            1000 * math_utils::pow(10, 8),
            2,
            0,
            user2_address
        );

        let u1_oracle_price = oracle::get_asset_price(underlying_u1_token_address);
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            u1_oracle_price * 2
        );

        // user2 borrow 200 u_1 token from the pool
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            200 * math_utils::pow(10, 8),
            2,
            0,
            user2_address
        );
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
    // User 1 supply 1000 U_1
    // User 2 supply 2 U_2
    // User 2 borrows 10 U_1. collateral cannot cover the new borrow (revert expected)
    #[expected_failure(abort_code = 36, location = aave_pool::validation_logic)]
    fun test_borrow_with_collateral_cannot_cover_new_borrow(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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

        // mint 10000000 U_1 to user 1
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 1000 U_1 to user 1
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        aave_pool::supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        // mint 10000000 U_2 to user 2
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 2 U_2 to user 2
        let supply_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 2);
        aave_pool::supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_u2_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // borrow 10 U_1 to user 2
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );
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
    // Configure U_1 as siloed borrowing asset
    // User 1 supplies U_1, User 2 supplies U_2, borrows U_1
    // User 1 supplies U_2, User 2 tries to borrow U_2 (revert expected)
    #[expected_failure(abort_code = 89, location = aave_pool::validation_logic)]
    fun test_borrow_when_u1_as_siloed_borrowing_asset_failed(
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

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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
        // Configure U_1 as siloed borrowing asset
        pool_configurator::set_siloed_borrowing(
            aave_pool, underlying_u1_token_address, true
        );

        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // User 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // User 2 mint 1000 U_2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // User 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 2 borrows 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let debt_balance =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(debt_balance == borrow_u1_amount, TEST_SUCCESS);

        // mint 1000 U_2 to user 1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // User 1 supplies 1000 U_2
        supply_logic::supply(
            user1,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user1_address,
            0
        );

        // User 2 borrows 100 U_2 (revert expected)
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u2_token_address,
            borrow_u2_amount,
            2,
            0,
            user2_address
        );
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
    // Configure U_2 as siloed borrowing asset
    // User 1 supplies U_1, User 2 supplies U_2, borrows U_1
    // User 1 supplies U_2, User 2 tries to borrow U_2 (revert expected)
    #[expected_failure(abort_code = 89, location = aave_pool::validation_logic)]
    fun test_borrow_when_u2_as_siloed_borrowing_asset_failed(
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
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

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

        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // User 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // User 2 mint 1000 U_2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // Configure U_1 as siloed borrowing asset
        pool_configurator::set_siloed_borrowing(
            aave_pool, underlying_u2_token_address, true
        );
        // User 2 mint 1000 U_2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // User 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 2 borrows 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let debt_balance =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(debt_balance == borrow_u1_amount, TEST_SUCCESS);

        // mint 1000 U_2 to user 1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // User 1 supplies 1000 U_2
        supply_logic::supply(
            user1,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user1_address,
            0
        );

        // User 2 borrows 100 U_2 (revert expected)
        let borrow_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 100);
        borrow_logic::borrow(
            user2,
            underlying_u2_token_address,
            borrow_u2_amount,
            2,
            0,
            user2_address
        );
    }

    // =========================== Test Repay ===========================
    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_reapy() when amount is zero (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_repay_when_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // user1 repay 0 u_1 token from the pool
        borrow_logic::repay(
            usre1,
            underlying_u1_token_address,
            0,
            2,
            user1_address
        );
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
            usre1 = @0x41
        )
    ]
    // validate_reapy() when no explicit amount to repay on behalf (revert expected)
    #[expected_failure(abort_code = 40, location = aave_pool::validation_logic)]
    fun test_repay_when_no_explicit_amount_to_repay_on_behalf(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
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
        // user1 repay 0 u_1 token from the pool
        let on_behalf_of = @0x33;
        borrow_logic::repay(
            usre1,
            underlying_u1_token_address,
            math_utils::u256_max(),
            2,
            on_behalf_of
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_repay() when reserve is active (revert expected)
    // Users do not borrow money to repay directly
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_repay_with_a_tokens_when_reserve_is_not_active(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        reserve_config::set_active(&mut reserve_config_map, false);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // user1 repay 1000 u_1 token to the pool
        borrow_logic::repay_with_a_tokens(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            2
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_repay() when reserve is paused (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_repay_with_a_tokens_when_reserve_is_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == false, TEST_SUCCESS);

        // set reserve as paused
        reserve_config::set_paused(&mut reserve_config_map, true);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == true, TEST_SUCCESS);

        // user1 repay 1000 u_1 token to the pool
        borrow_logic::repay_with_a_tokens(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            2
        );
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
    // User 1 tries to repay using aTokens without actually holding aToken
    #[expected_failure(abort_code = 39, location = aave_pool::validation_logic)]
    fun test_repay_with_a_tokens_when_user_not_actually_holding_atoken(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let repay_amount = 100000;

        borrow_logic::repay_with_a_tokens(
            user1,
            underlying_u1_token_address,
            repay_amount,
            2
        );
    }
}
