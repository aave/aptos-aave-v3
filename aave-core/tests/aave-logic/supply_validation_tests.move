#[test_only]
module aave_pool::supply_validation_tests {
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_oracle::oracle;
    use aave_pool::borrow_logic;
    use aave_pool::user_logic;
    use aave_pool::token_helper;
    use aave_pool::a_token_factory;

    use aave_pool::pool;

    use aave_pool::pool_configurator;
    use aave_pool::pool_data_provider;
    use aave_pool::supply_logic::Self;
    use aave_pool::token_helper::{
        init_reserves,
        convert_to_currency_decimals,
        init_reserves_with_oracle
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // ========================= validate_supply =========================

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // User 1 deposit U_0 and U_1
    // Set emode category for U_1
    // User 1 tries to use U_1 as collateral (revert expected)
    #[expected_failure(abort_code = 62, location = aave_pool::supply_logic)]
    fun test_set_user_use_reserve_as_collateral_when_user_not_in_isolation_mode_and_ltv_gt_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // User 1 mint 100000000 U_0.
        let mint_u0_amount =
            convert_to_currency_decimals(underlying_u0_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u0_amount as u64),
            underlying_u0_token_address
        );

        // User 1 supply 1 U_0. Checks that U_0 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1),
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u0_token_address, true
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u0_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // User 1 mint 100000000 U_1.
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // set debt ceiling for U_1
        let ceilingAmount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000);
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u1_token_address,
            ceilingAmount
        );

        // User 1 supply 1 U_1. Checks that U_1 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // User 1 tries to use U_1 as collateral (revert expected)
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
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
    // User 1 deposit U_0 and U_1
    // Set emode category for U_1
    // User 1 tries to use U_1 as collateral (revert expected)
    #[expected_failure(abort_code = 62, location = aave_pool::supply_logic)]
    fun test_set_user_use_reserve_as_collateral_when_user_in_isolation_mode_or_ltv_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // User 1 mint 100000000 U_0.
        let mint_u0_amount =
            convert_to_currency_decimals(underlying_u0_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u0_amount as u64),
            underlying_u0_token_address
        );

        // User 1 supply 1 U_0. Checks that U_0 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1),
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u0_token_address, true
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u0_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // User 1 mint 100000000 U_1.
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // set debt ceiling for U_1
        let ceilingAmount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000);
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u1_token_address,
            ceilingAmount
        );

        // User 1 supply 1 U_1. Checks that U_1 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // set debt ceiling for U_0
        let ceilingAmount =
            convert_to_currency_decimals(underlying_u0_token_address, 10000);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u0_token_address);
        reserve_config::set_debt_ceiling(&mut reserve_config_map, ceilingAmount);
        pool::test_set_reserve_configuration(
            underlying_u0_token_address,
            reserve_config_map
        );

        // User 1 tries to use U_1 as collateral (revert expected)
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
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
    // validate_supply() when amount is zero
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_validate_supply_when_amount_is_zero(
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

        // mint 1000 u_1 token to the aave_pool
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            1000,
            underlying_u1_token_address
        );

        // supply 0 u_1 token to the pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            0,
            signer::address_of(aave_pool),
            0
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
    // validate_supply() when reserve is not active (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_validate_supply_when_reserve_is_not_active(
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
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        pool_configurator::set_reserve_active(
            aave_pool, underlying_u1_token_address, false
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == false, TEST_SUCCESS);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            1000,
            underlying_u1_token_address
        );

        // supply 1000  u_1 token to the pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            1000,
            signer::address_of(aave_pool),
            0
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
    // validate_supply() when reserve is pasued (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_supply_when_reserve_is_paused(
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

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            1000,
            underlying_u1_token_address
        );

        // supply 1000  u_1 token to the pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            1000,
            signer::address_of(aave_pool),
            0
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
    // validate_supply() when reserve is frozen (revert expected)
    #[expected_failure(abort_code = 28, location = aave_pool::validation_logic)]
    fun test_validate_supply_when_reserve_is_frozen(
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

        // mint 1000 u_1 token to the aave_pool
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

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
        let is_frozen = reserve_config::get_frozen(&reserve_config_map);
        assert!(is_frozen == true, TEST_SUCCESS);

        // supply 1000  u_1 token to the pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            signer::address_of(aave_pool),
            0
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
    // validate_supply() when on_behalf_of is equal to a_token_resource_account (revert expected)
    #[expected_failure(abort_code = 94, location = aave_pool::validation_logic)]
    fun test_validate_supply_when_on_behalf_of_equal_a_token_resource_account(
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

        // mint 1000 u_1 token to the aave_pool
        let mint_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            mint_amount,
            underlying_u1_token_address
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let a_token_resource_account =
            a_token_factory::get_token_account_address(a_token_address);

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            a_token_resource_account,
            0
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
    // validate_supply() Sets the supply cap for U_1 to 1000 Unit, leaving 0 Units to reach the limit
    // Tries to supply any U_1 (> SUPPLY_CAP) (revert expected)
    #[expected_failure(abort_code = 51, location = aave_pool::validation_logic)]
    fun test_validate_supply_with_exceed_supply_cap(
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

        let aave_pool_address = signer::address_of(aave_pool);
        let new_supply_cap = 1000;
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let u1_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);

        let mint_amount = 100000000000;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            mint_amount,
            underlying_u1_token_address
        );

        // set supply cap to 1000
        pool_configurator::set_supply_cap(
            aave_pool,
            underlying_u1_token_address,
            new_supply_cap
        );

        // check emitted events
        let emitted_events = emitted_events<pool_configurator::SupplyCapChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let (_, u1_supply_cap) =
            pool_data_provider::get_reserve_caps(underlying_u1_token_address);
        assert!(u1_supply_cap == new_supply_cap, TEST_SUCCESS);

        // first supply 1000
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            1000 * math_utils::pow(10, (u1_decimals as u256)),
            aave_pool_address,
            0
        );

        // then try to supply 10 u_1
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            10 * math_utils::pow(10, (u1_decimals as u256)),
            aave_pool_address,
            0
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
    // validate_supply() Sets the supply cap for U_1 to 1110 Units
    // Supply 1000 U_1, leaving 100 Units to reach the limit
    // Supply 10 U_1, leaving 100 Units to reach the limit
    // Tries to supply 101 U_1  (> SUPPLY_CAP) 1 unit above the limit (revert expected)
    #[expected_failure(abort_code = 51, location = aave_pool::validation_logic)]
    fun test_validate_supply_with_exceed_supply_cap_by_1_unit(
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

        let aave_pool_address = signer::address_of(aave_pool);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let mint_amount = 1000000000000000;
        let u1_decimals =
            mock_underlying_token_factory::decimals(underlying_u1_token_address);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            mint_amount,
            underlying_u1_token_address
        );

        let new_supply_cap = 1100;
        // set supply cap to 1110
        pool_configurator::set_supply_cap(
            aave_pool,
            underlying_u1_token_address,
            new_supply_cap
        );

        let (_, supply_cap) =
            pool_data_provider::get_reserve_caps(underlying_u1_token_address);
        assert!(supply_cap == new_supply_cap, TEST_SUCCESS);

        // Supply 1000 U_1, leaving 100 Units to reach the limit
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            1000 * math_utils::pow(10, (u1_decimals as u256)),
            aave_pool_address,
            0
        );

        // Supply 10 U_1, leaving 100 Units to reach the limit
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            10 * math_utils::pow(10, (u1_decimals as u256)),
            aave_pool_address,
            0
        );

        // then try to supply 101 U_1  (> SUPPLY_CAP) 1 unit above the limit
        supply_logic::supply(
            aave_pool,
            underlying_u1_token_address,
            101 * math_utils::pow(10, (u1_decimals as u256)),
            aave_pool_address,
            0
        );
    }

    // ========================= validate_withdraw =========================

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    #[expected_failure(abort_code = 93, location = aave_pool::supply_logic)]
    fun test_withdraw_when_receiver_equal_a_token_resource_account(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1 APT to the user1_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, mint_apt_amount
        );

        // user 1 deposits
        let supply_amount = 100;
        // user 1 supplies U_1 tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            supply_amount,
            underlying_u1_token_address
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            (supply_amount as u256),
            user1_address,
            0
        );

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let a_token_resource_account_addr =
            a_token_factory::get_token_account_address(a_token_address);
        // user 1 withdraws
        supply_logic::withdraw(
            user1,
            underlying_u1_token_address,
            math_utils::get_u256_max_for_testing(),
            a_token_resource_account_addr
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
    // validate_withdraw() when amount == 0 (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_validate_withdraw_when_amount_is_zero(
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
        let u1_supply_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 2000);

        // mint 2000 u_1 token to the user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (u1_supply_amount as u64),
            underlying_u1_token_address
        );

        // supply 2000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            u1_supply_amount,
            user1_address,
            0
        );

        // user1 withdraw 0 u_1 token from the pool
        supply_logic::withdraw(
            usre1,
            underlying_u1_token_address,
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
    // validate_withdraw() when not enough available user balance (revert expected)
    // Users do not have deposits to withdraw money directly
    #[expected_failure(abort_code = 32, location = aave_pool::validation_logic)]
    fun test_validate_withdraw_when_not_enough_available_user_balance(
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
        // user1 withdraw 1000 u_1 token from the pool
        supply_logic::withdraw(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
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
    // validate_withdraw() when reserve is not active (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_validate_withdraw_when_reserve_is_not_active(
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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        reserve_config::set_active(&mut reserve_config_map, false);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // user1 withdraw 1000 u_1 token from the pool
        supply_logic::withdraw(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
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
    // validate_withdraw() when reserve is paused (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_withdraw_when_reserve_is_paused(
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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

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

        // user1 withdraw 1000 u_1 token from the pool
        supply_logic::withdraw(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
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
    // validate_hf_and_ltv() with HF < 1 (revert expected)
    #[expected_failure(abort_code = 35, location = aave_pool::validation_logic)]
    fun test_withdraw_with_hf_less_than_one(
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

        let user1_address = signer::address_of(usre1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // set u_1 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 1000000000 u_2 token to user2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000000000) as u64),
            underlying_u2_token_address
        );

        // set u_2 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 1000 u_2 token to the pool
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user2_address,
            0
        );

        // Manually enable collateral since auto-collateralization is disabled
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        let (_, _, available_borrows_base, _, _, _) =
            user_logic::get_user_account_data(user2_address);
        let u1_price = oracle::get_asset_price(underlying_u1_token_address);

        let amount_u1_to_borrow =
            convert_to_currency_decimals(
                underlying_u1_token_address,
                available_borrows_base / u1_price
            );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrows 800 u_1 token
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            amount_u1_to_borrow,
            2,
            0,
            user2_address
        );

        // user2 withdraw 500 u_2 token from the pool
        supply_logic::withdraw(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
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
    // validate_h_f_and_ltv() with HF < 1 for 0 LTV asset (revert expected)
    #[expected_failure(abort_code = 35, location = aave_pool::validation_logic)]
    fun test_withdraw_with_hf_less_than_one_for_zero_ltv_asset(
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

        let user1_address = signer::address_of(usre1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // set u_1 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 1000000000 u_2 token to user2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000000000) as u64),
            underlying_u2_token_address
        );

        // set u_2 price to 10
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // supply 1000 u_2 token to the pool
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user2_address,
            0
        );

        // Manually enable collateral since auto-collateralization is disabled
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        let amount_u1_to_borrow =
            convert_to_currency_decimals(underlying_u1_token_address, 500);

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrows 500 u_1 token
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            amount_u1_to_borrow,
            2,
            0,
            user2_address
        );

        // drop ltv
        let (_, _, liquidation_threshold, liquidation_bonus, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(
                underlying_u2_token_address
            );

        // configure reserve as collateral ltv = 0
        let ltv = 0;
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_u2_token_address,
            ltv,
            liquidation_threshold,
            liquidation_bonus
        );

        // user2 withdraw 500 u_2 token from the pool
        supply_logic::withdraw(
            user2,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 500),
            user2_address
        );
    }

    // ========================= validate_set_use_reserve_as_collateral =========================
    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate set_user_use_reserve_as_collateral() when reserve is not active (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_validate_set_user_use_reserve_as_collateral_when_reserve_is_not_active(
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
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // set reserve as not active
        reserve_config::set_active(&mut reserve_config_map, false);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == false, TEST_SUCCESS);

        // user1 set u_1 token as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            usre1, underlying_u1_token_address, true
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
    // validate set_user_use_reserve_as_collateral() when reserve is paused (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_set_user_use_reserve_as_collateral_when_reserve_is_paused(
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
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == false, TEST_SUCCESS);

        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // set reserve as paused
        reserve_config::set_paused(&mut reserve_config_map, true);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == true, TEST_SUCCESS);

        // user1 set u_1 token as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            usre1, underlying_u1_token_address, true
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
    // validate set_user_use_reserve_as_collateral() when underlying balance zero (revert expected)
    #[expected_failure(abort_code = 43, location = aave_pool::validation_logic)]
    fun test_validate_set_user_use_reserve_as_collateral_when_underlying_balance_is_zero(
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

        // user1 set u_1 token as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            usre1, underlying_u1_token_address, true
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
            user1 = @0x41
        )
    ]
    #[expected_failure(abort_code = 57, location = aave_pool::validation_logic)]
    fun test_validate_set_user_use_reserve_as_collateral_when_ltv_is_zeor_validation_failed(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

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

        // User 1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // User 1 mint 1000 U_2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
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

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        // User 1 supplies 1000 U_2
        supply_logic::supply(
            user1,
            underlying_u2_token_address,
            convert_to_currency_decimals(underlying_u2_token_address, 1000),
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u2_token_address, true
        );

        // set U_2 ltv to 0
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u2_token_address);
        reserve_config::set_ltv(&mut reserve_config_map, 0);
        pool::test_set_reserve_configuration(
            underlying_u2_token_address, reserve_config_map
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        )
    }
}
