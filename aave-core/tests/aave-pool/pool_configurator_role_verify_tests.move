#[test_only]
module aave_pool::pool_configurator_role_verify_tests {
    use std::option::Option;
    use std::string::{String, utf8};
    use aave_acl::acl_manage;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool_configurator;

    // --------------------------- only_asset_listing_or_pool_admins test ---------------------------
    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // Test the accessibility of only_asset_listing_or_pool_admins modified functions
    #[expected_failure(abort_code = 5, location = aave_pool::pool_configurator)]
    fun test_init_reserves_with_non_asset_listing_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        // create underlyings
        let underlying_assets: vector<address> = vector[@0x42];
        let treasurys: vector<address> = vector[@0x42];
        let atokens_names: vector<String> = vector[utf8(b"AN1")];
        let atokens_symbols: vector<String> = vector[utf8(b"AS1")];
        let var_tokens_names: vector<String> = vector[utf8(b"VN1")];
        let var_tokens_symbols: vector<String> = vector[utf8(b"VS1")];
        let incentives_controllers: vector<Option<address>> = vector[];

        pool_configurator::init_reserves(
            aave_pool,
            underlying_assets,
            treasurys,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols,
            incentives_controllers,
            vector[400],
            vector[100],
            vector[200],
            vector[300]
        );
    }

    // --------------------------- only_pool_admin test ---------------------------
    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // drop_reserve should only be accessible by pool admin
    #[expected_failure(abort_code = 1, location = aave_pool::pool_configurator)]
    fun test_drop_reserve_with_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::drop_reserve(aave_pool, underlying_token_address);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_reserve_active should only be accessible by pool admin
    #[expected_failure(abort_code = 1, location = aave_pool::pool_configurator)]
    fun test_set_reserve_active_with_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_active(aave_pool, underlying_token_address, true);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // update_flashloan_premium_total should only be accessible by pool admin
    #[expected_failure(abort_code = 1, location = aave_pool::pool_configurator)]
    fun test_update_flashloan_premium_total_with_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::update_flashloan_premium_total(aave_pool, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // update_flashloan_premium_to_protocol should only be accessible by pool admin
    #[expected_failure(abort_code = 1, location = aave_pool::pool_configurator)]
    fun test_update_flashloan_premium_to_protocol_with_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::update_flashloan_premium_to_protocol(aave_pool, 100);
    }

    // --------------------------- only_risk_or_pool_admins test ---------------------------
    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_reserve_borrowing enabled should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_reserve_borrowing_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_token_address, true
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // configure_reserve_as_collateral should only be accessible by risk admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            100,
            100,
            100
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_reserve_flash_loaning should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_reserve_flash_loaning_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_flash_loaning(
            aave_pool, underlying_token_address, true
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_borrowable_in_isolation should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_borrowable_in_isolation_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_token_address, true
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_reserve_factor should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_reserve_factor_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_factor(aave_pool, underlying_token_address, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_debt_ceiling should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_debt_ceiling_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_debt_ceiling(aave_pool, @0x31, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_siloed_borrowing should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_siloed_borrowing_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_siloed_borrowing(aave_pool, @0x31, true);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_borrow_cap should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_borrow_cap_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_borrow_cap(aave_pool, underlying_token_address, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_supply_cap should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_supply_cap_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_supply_cap(aave_pool, underlying_token_address, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_liquidation_protocol_fee should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_liquidation_protocol_fee_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_liquidation_protocol_fee(aave_pool, @0x31, 100);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_emode_category should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_emode_category(
            aave_pool,
            1,
            100,
            100,
            100,
            utf8(b"STABLECOIN")
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_asset_emode_category should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_asset_emode_category_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_asset_emode_category(aave_pool, @0x31, 1);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // update_interest_rate_strategy should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_update_interest_rate_strategy_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::update_interest_rate_strategy(
            aave_pool,
            underlying_token_address,
            10000,
            5,
            5,
            5
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_apt_fee should only be accessible by risk admin or pool admin
    #[expected_failure(abort_code = 4, location = aave_pool::pool_configurator)]
    fun test_set_apt_fee_with_non_risk_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::set_apt_fee(aave_pool, @0x31, 1000000);
    }

    // --------------------------- only_pool_or_emergency_admin test ---------------------------
    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // Tries to pause reserve with non-emergency-admin or non-pool-admin account (revert expected)
    #[expected_failure(abort_code = 3, location = aave_pool::pool_configurator)]
    fun test_pause_reserve_with_non_emergency_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // set reserve pause
        pool_configurator::set_reserve_pause(aave_pool, underlying_token_address, true, 0);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // Tries to pause pool with not-emergency-admin or non-pool-admin account (revert expected)
    #[expected_failure(abort_code = 3, location = aave_pool::pool_configurator)]
    fun test_set_pause_pool_with_non_emergency_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        acl_manage::test_init_module(aave_role_super_admin);

        // set pool pause
        pool_configurator::set_pool_pause(aave_pool, true, 0);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // Tries to disable liquidation grace period with not-emergency-admin or non-pool-admin account (revert expected)
    #[expected_failure(abort_code = 3, location = aave_pool::pool_configurator)]
    fun test_disable_liquidation_grace_period_with_non_emergency_admin_and_non_pool_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        acl_manage::test_init_module(aave_role_super_admin);

        pool_configurator::disable_liquidation_grace_period(aave_pool, @0x33);
    }

    // --------------------------- only_risk_or_pool_or_emergency_admins test ---------------------------
    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    // set_reserve_freeze should only be accessible by risk admin or pool admin or emergency admin
    #[expected_failure(abort_code = 96, location = aave_pool::pool_configurator)]
    fun test_set_reserve_freeze_with_non_risk_admin_and_non_pool_admin_and_non_emergency_admin(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        acl_manage::test_init_module(aave_role_super_admin);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_freeze(aave_pool, underlying_token_address, true);
    }
}
