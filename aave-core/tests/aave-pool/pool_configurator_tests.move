#[test_only]
module aave_pool::pool_configurator_tests {
    use std::option::Option;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_math::wad_ray_math;
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::pool::number_of_active_and_dropped_reserves;
    use aave_pool::pool_token_logic::ReserveInitialized;
    use aave_pool::events::Self;
    use aave_pool::pool_configurator::{
        Self,
        set_reserve_freeze,
        set_reserve_pause,
        drop_reserve,
        ReserveBorrowing,
        CollateralConfigurationChanged,
        PendingLtvChanged,
        ReserveFlashLoaning,
        update_interest_rate_strategy,
        ReserveActive,
        BorrowableInIsolationChanged,
        ReserveFactorChanged,
        LiquidationGracePeriodDisabled,
        DebtCeilingChanged,
        SiloedBorrowingChanged,
        BorrowCapChanged,
        SupplyCapChanged,
        LiquidationProtocolFeeChanged,
        EModeCategoryAdded,
        EModeAssetCategoryChanged,
        ReservePaused,
        FlashloanPremiumTotalUpdated,
        FlashloanPremiumToProtocolUpdated,
        ReserveFrozen,
        init_reserves,
        LiquidationGracePeriodChanged,
        set_reserve_pause_no_grace_period,
        get_pending_ltv
    };
    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_pool::pool_fee_manager;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::emode_logic;
    use aave_pool::pool_data_provider;
    use aave_pool::token_helper;
    use aave_pool::pool;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    const TEST_ASSETS_COUNT: u8 = 3;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_init_reserves(
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
        // check emitted events
        let emitted_events = emitted_events<ReserveInitialized>();
        // make sure event of type was emitted
        assert!(
            vector::length(&emitted_events) == (TEST_ASSETS_COUNT as u64),
            TEST_SUCCESS
        );
        // test reserves count
        assert!(
            pool::number_of_active_and_dropped_reserves()
                == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    fun test_init_reserves_with_underlying_asset_is_empty(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {

        // init acl
        acl_manage::test_init_module(aave_role_super_admin);
        // add pool admin
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // init pool
        pool::test_init_pool(aave_pool);

        // init reserves
        let underlying_assets = vector[];
        let treasurys = vector[];
        let a_token_names = vector[];
        let a_token_symbols = vector[];
        let variable_debt_token_names = vector[];
        let variable_debt_token_symbols = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];

        init_reserves(
            aave_pool,
            underlying_assets,
            treasurys,
            a_token_names,
            a_token_symbols,
            variable_debt_token_names,
            variable_debt_token_symbols,
            incentives_controllers,
            vector[],
            vector[],
            vector[],
            vector[]
        );
        // check emitted events
        let emitted_events = emitted_events<ReserveInitialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 0, TEST_SUCCESS);
        // test reserves count
        assert!(pool::number_of_active_and_dropped_reserves() == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_drop_reserve_with_0_supply(
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

        // test reserves count
        assert!(
            number_of_active_and_dropped_reserves() == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // drop the first reserve
        drop_reserve(aave_pool, underlying_u1_token_address);

        // check emitted events
        let emitted_events = emitted_events<pool_configurator::ReserveDropped>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        assert!(
            number_of_active_and_dropped_reserves() == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );

        assert!(
            pool::number_of_active_reserves() == (TEST_ASSETS_COUNT as u256) - 1
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
    // Deactivates the reserve for borrowing via pool admin
    fun test_set_reserve_borrowing_by_pool_admin_deactivate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_token_address, false
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveBorrowing>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == false,
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
    // Activates the reserve for borrowing via pool admin
    fun test_set_reserve_borrowing_by_pool_admin_activate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_token_address, true
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveBorrowing>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == true,
            TEST_SUCCESS
        );

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let variable_borrow_index = pool::get_reserve_variable_borrow_index(reserve_data);
        assert!((variable_borrow_index as u256) == wad_ray_math::ray(), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Deactivates the reserve for borrowing via risk admin
    fun test_set_reserve_borrowing_by_risk_admin_deactivate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_token_address, false
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveBorrowing>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == false,
            TEST_SUCCESS
        );

        let (
            _, _, _, _, _, _, variable_borrow_index, _
        ) = pool_data_provider::get_reserve_data(underlying_token_address);
        assert!(variable_borrow_index == wad_ray_math::ray(), TEST_SUCCESS)
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Activates the reserve for borrowing via risk admin
    fun test_set_reserve_borrowing_by_risk_admin_activate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_borrowing(
            aave_pool, underlying_token_address, true
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveBorrowing>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(
            reserve_config::get_borrowing_enabled(&reserve_config_map) == true,
            TEST_SUCCESS
        );

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let variable_borrow_index = pool::get_reserve_variable_borrow_index(reserve_data);
        assert!((variable_borrow_index as u256) == wad_ray_math::ray(), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_update_interest_rate_strategy(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_acl,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let optimal_usage_ratio: u256 = 800;
        let base_variable_borrow_rate: u256 = 0;
        let variable_rate_slope1: u256 = 4000;
        let variable_rate_slope2: u256 = 7500;
        update_interest_rate_strategy(
            aave_pool,
            underlying_token_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // assertions on getters
        assert!(
            default_reserve_interest_rate_strategy::get_optimal_usage_ratio(
                underlying_token_address
            ) == default_reserve_interest_rate_strategy::bps_to_ray_test_for_testing(
                optimal_usage_ratio
            ),
            TEST_SUCCESS
        );
        assert!(
            default_reserve_interest_rate_strategy::get_variable_rate_slope1(
                underlying_token_address
            ) == default_reserve_interest_rate_strategy::bps_to_ray_test_for_testing(
                variable_rate_slope1
            ),
            TEST_SUCCESS
        );
        assert!(
            default_reserve_interest_rate_strategy::get_variable_rate_slope2(
                underlying_token_address
            ) == default_reserve_interest_rate_strategy::bps_to_ray_test_for_testing(
                variable_rate_slope2
            ),
            TEST_SUCCESS
        );
        assert!(
            default_reserve_interest_rate_strategy::get_base_variable_borrow_rate(
                underlying_token_address
            ) == default_reserve_interest_rate_strategy::bps_to_ray_test_for_testing(
                base_variable_borrow_rate
            ),
            TEST_SUCCESS
        );
        assert!(
            default_reserve_interest_rate_strategy::get_max_variable_borrow_rate(
                underlying_token_address
            ) == default_reserve_interest_rate_strategy::bps_to_ray_test_for_testing(
                base_variable_borrow_rate + variable_rate_slope1 + variable_rate_slope2
            ),
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
    // Deactivates the reserve as collateral via pool admin
    fun test_configure_reserve_as_collateral_by_pool_admin_deactivate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            0,
            0,
            0
        );

        // check emitted events
        let emitted_events = emitted_events<CollateralConfigurationChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let (
            ltv, liquidation_threshold, liquidation_bonus, _, _, _
        ) = reserve_config::get_params(&reserve_config_map);

        assert!(ltv == 0, TEST_SUCCESS);
        assert!(liquidation_threshold == 0, TEST_SUCCESS);
        assert!(liquidation_bonus == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Activates the reserve as collateral via pool admin
    fun test_configure_reserve_as_collateral_by_pool_admin_activate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            8000,
            8250,
            10500
        );

        // check emitted events
        let emitted_events = emitted_events<CollateralConfigurationChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let (
            ltv, liquidation_threshold, liquidation_bonus, _, _, _
        ) = reserve_config::get_params(&reserve_config_map);
        assert!(ltv == 8000, TEST_SUCCESS);
        assert!(liquidation_threshold == 8250, TEST_SUCCESS);
        assert!(liquidation_bonus == 10500, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Deactivates the reserve as collateral via risk admin
    fun test_configure_reserve_as_collateral_by_risk_admin_deactivate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            0,
            0,
            0
        );

        // check emitted events
        let emitted_events = emitted_events<CollateralConfigurationChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let (
            ltv, liquidation_threshold, liquidation_bonus, _, _, _
        ) = reserve_config::get_params(&reserve_config_map);
        assert!(ltv == 0, TEST_SUCCESS);
        assert!(liquidation_threshold == 0, TEST_SUCCESS);
        assert!(liquidation_bonus == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Activates the reserve as collateral via risk admin
    fun test_configure_reserve_as_collateral_by_risk_admin_activate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set underlying_token_address freeze
        pool_configurator::set_reserve_freeze(aave_pool, underlying_token_address, true);

        pool_configurator::configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            8000,
            8250,
            10500
        );

        // check emitted events
        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        // make sure event of type was emitted
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 2,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 2, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let (
            ltv, liquidation_threshold, liquidation_bonus, _, _, _
        ) = reserve_config::get_params(&reserve_config_map);
        assert!(ltv == 0, TEST_SUCCESS);
        assert!(liquidation_threshold == 8250, TEST_SUCCESS);
        assert!(liquidation_bonus == 10500, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // enable flash loan for reserve via pool admin
    fun test_set_reserve_flash_loaning_when_enabled_flash_loan(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_flash_loaning(
            aave_pool, underlying_u1_token_address, true
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveFlashLoaning>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let flashloan_enabled =
            pool_data_provider::get_flash_loan_enabled(underlying_u1_token_address);
        assert!(flashloan_enabled == true, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // disable flash loan for reserve via pool admin
    fun test_set_reserve_flash_loaning_when_disabled_flash_loan(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_flash_loaning(
            aave_pool, underlying_u1_token_address, false
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveFlashLoaning>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let flashloan_enabled =
            pool_data_provider::get_flash_loan_enabled(underlying_u1_token_address);
        assert!(flashloan_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Deactivates the reserve by pool admin
    fun test_set_reserve_active_by_pool_admin_deactivate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_active(aave_pool, underlying_token_address, false);

        // check emitted events
        let emitted_events = emitted_events<ReserveActive>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(reserve_config::get_active(&reserve_config_map) == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Reactivates the reserve by pool admin
    fun test_set_reserve_active_by_pool_admin_activate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::set_reserve_active(aave_pool, underlying_token_address, true);

        // check emitted events
        let emitted_events = emitted_events<ReserveActive>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        assert!(reserve_config::get_active(&reserve_config_map) == true, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_set_borrowable_in_isolation(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // case1: set borrowable in isolation to true for underlying_u1_token_address
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // check emitted events
        let emitted_events = emitted_events<BorrowableInIsolationChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let borrowable_in_isolation =
            reserve_config::get_borrowable_in_isolation(&reserve_config_map);
        assert!(borrowable_in_isolation == true, TEST_SUCCESS);

        // case2: set borrowable in isolation to false for underlying_u1_token_address
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, false
        );

        // check emitted events
        let emitted_events = emitted_events<BorrowableInIsolationChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let borrowable_in_isolation =
            reserve_config::get_borrowable_in_isolation(&reserve_config_map);
        assert!(borrowable_in_isolation == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_set_reserve_freeze_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // choose an asset to freeze
        let asset_to_freeze = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        set_reserve_freeze(aave_pool, asset_to_freeze, true);

        // check emitted events
        let reserve_frozen_emitted_events = emitted_events<ReserveFrozen>();
        assert!(vector::length(&reserve_frozen_emitted_events) == 1, TEST_SUCCESS);

        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 1,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 1, TEST_SUCCESS);

        // check if it is frozen
        let reserve_config_map =
            aave_pool::pool::get_reserve_configuration(asset_to_freeze);
        assert!(reserve_config::get_frozen(&reserve_config_map), TEST_SUCCESS);

        // unfreeze reserve
        set_reserve_freeze(aave_pool, asset_to_freeze, false);

        // check emitted events
        let reserve_frozen_emitted_events = emitted_events<ReserveFrozen>();
        assert!(vector::length(&reserve_frozen_emitted_events) == 2, TEST_SUCCESS);

        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 2,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 2, TEST_SUCCESS);

        // check if it is not frozen
        let reserve_config_map =
            aave_pool::pool::get_reserve_configuration(asset_to_freeze);
        assert!(!reserve_config::get_frozen(&reserve_config_map), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_set_reserve_freeze_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // remove pool admin and add risk admin
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // choose an asset to freeze
        let asset_to_freeze = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map = pool::get_reserve_configuration(asset_to_freeze);
        reserve_config::set_frozen(&mut reserve_config_map, true);
        pool::test_set_reserve_configuration(asset_to_freeze, reserve_config_map);

        // unfreeze reserve
        set_reserve_freeze(aave_pool, asset_to_freeze, false);

        // check emitted events
        let reserve_frozen_emitted_events = emitted_events<ReserveFrozen>();
        assert!(vector::length(&reserve_frozen_emitted_events) == 1, TEST_SUCCESS);

        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 1,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 1, TEST_SUCCESS);

        // check if it is not frozen
        let reserve_config_map =
            aave_pool::pool::get_reserve_configuration(asset_to_freeze);
        assert!(!reserve_config::get_frozen(&reserve_config_map), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_set_reserve_freeze_by_emergency_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // remove pool admin and add emergency admin
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_emergency_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // choose an asset to freeze
        let asset_to_freeze = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        set_reserve_freeze(aave_pool, asset_to_freeze, true);

        // check emitted events
        let reserve_frozen_emitted_events = emitted_events<ReserveFrozen>();
        assert!(vector::length(&reserve_frozen_emitted_events) == 1, TEST_SUCCESS);

        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 1,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 1, TEST_SUCCESS);

        // check if it is frozen
        let reserve_config_map =
            aave_pool::pool::get_reserve_configuration(asset_to_freeze);
        assert!(reserve_config::get_frozen(&reserve_config_map), TEST_SUCCESS);

        // unfreeze reserve
        set_reserve_freeze(aave_pool, asset_to_freeze, false);

        // check emitted events
        let reserve_frozen_emitted_events = emitted_events<ReserveFrozen>();
        assert!(vector::length(&reserve_frozen_emitted_events) == 2, TEST_SUCCESS);

        let collateral_configuration_changed_emitted_events =
            emitted_events<CollateralConfigurationChanged>();
        assert!(
            vector::length(&collateral_configuration_changed_emitted_events) == 2,
            TEST_SUCCESS
        );

        let pending_ltv_changed_emitted_events = emitted_events<PendingLtvChanged>();
        assert!(vector::length(&pending_ltv_changed_emitted_events) == 2, TEST_SUCCESS);

        // check if it is not frozen
        let reserve_config_map =
            aave_pool::pool::get_reserve_configuration(asset_to_freeze);
        assert!(!reserve_config::get_frozen(&reserve_config_map), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            underlying_tokens = @aave_mock_underlyings
        )
    ]
    // set reserve pause with grace period
    // case1: paused is true and grace period is 0
    // case2: paused is true and grace period is MAX_GRACE_PERIOD / 2
    // case3: paused is false and grace period is MAX_GRACE_PERIOD
    fun test_set_reserve_pause_with_grace_period(
        aave_pool: signer,
        aave_acl: &signer,
        aave_std: &signer,
        underlying_tokens: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            &aave_pool,
            aave_acl,
            aave_std,
            underlying_tokens
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // case1: pause is true and grace period is 0
        let new_paused = true;
        let new_grace_period = 0;
        set_reserve_pause(
            &aave_pool,
            underlying_token_address,
            new_paused,
            new_grace_period
        );

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(reserve_paused == new_paused, TEST_SUCCESS);
        assert!(
            pool::get_liquidation_grace_period(reserve_data) == new_grace_period,
            TEST_SUCCESS
        );

        // case2: pause is true and grace period is MAX_GRACE_PERIOD / 2
        let new_paused = true;
        let new_grace_period = reserve_config::get_max_valid_liquidation_grace_period()
            / 2;
        set_reserve_pause(
            &aave_pool,
            underlying_token_address,
            new_paused,
            (new_grace_period as u64)
        );

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(reserve_paused == new_paused, TEST_SUCCESS);
        assert!(pool::get_liquidation_grace_period(reserve_data) == 0, TEST_SUCCESS);

        timestamp::fast_forward_seconds(1000);
        // case3: pause is false and grace period is MAX_GRACE_PERIOD
        let new_paused = false;
        let new_grace_period =
            (reserve_config::get_max_valid_liquidation_grace_period() as u64);
        set_reserve_pause(
            &aave_pool,
            underlying_token_address,
            new_paused,
            new_grace_period
        );

        // check LiquidationGracePeriodChanged emitted events
        let liquidation_grace_period_changed_emitted_events =
            emitted_events<LiquidationGracePeriodChanged>();
        // make sure event of type was emitted
        assert!(
            vector::length(&liquidation_grace_period_changed_emitted_events) == 1,
            TEST_SUCCESS
        );

        let reserve_paused_emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&reserve_paused_emitted_events) == 3, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(reserve_paused == new_paused, TEST_SUCCESS);
        assert!(
            pool::get_liquidation_grace_period(reserve_data)
                == timestamp::now_seconds() + new_grace_period,
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
    // disable liquidation grace period by pool admin
    fun test_disable_liquidation_grace_period_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::disable_liquidation_grace_period(
            aave_pool, underlying_token_address
        );

        // check emitted events
        let emitted_events = emitted_events<LiquidationGracePeriodDisabled>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let liquidation_grace_period = pool::get_liquidation_grace_period(reserve_data);
        assert!(liquidation_grace_period == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // disable liquidation grace period by emergency admin
    fun test_disable_liquidation_grace_period_by_emergency_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // remove pool admin and add emergency admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::remove_pool_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_emergency_admin(aave_role_super_admin, aave_pool_address);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        pool_configurator::disable_liquidation_grace_period(
            aave_pool, underlying_token_address
        );

        // check emitted events
        let emitted_events = emitted_events<LiquidationGracePeriodDisabled>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let liquidation_grace_period = pool::get_liquidation_grace_period(reserve_data);
        assert!(liquidation_grace_period == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Changes the reserve factor via pool admin
    fun test_set_reserve_factor_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_reserve_factor = 1000;
        pool_configurator::set_reserve_factor(
            aave_pool, underlying_token_address, new_reserve_factor
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveFactorChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_config_map);
        assert!(reserve_factor == new_reserve_factor, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Changes the reserve factor via risk admin
    fun test_set_reserve_factor_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_reserve_factor = 2000;
        pool_configurator::set_reserve_factor(
            aave_pool, underlying_token_address, new_reserve_factor
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveFactorChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_config_map);
        assert!(reserve_factor == new_reserve_factor, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Updates the reserve factor equal to PERCENTAGE_FACTOR via pool admin
    fun test_set_reserve_factor_when_new_reserve_factor_equal_percentage_factor(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_reserve_factor = math_utils::get_percentage_factor();
        pool_configurator::set_reserve_factor(
            aave_pool, underlying_token_address, new_reserve_factor
        );

        // check emitted events
        let emitted_events = emitted_events<ReserveFactorChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_config_map);
        assert!(reserve_factor == new_reserve_factor, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets a debt ceiling through the pool admin
    fun test_set_debt_ceiling_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_token_address, new_debt_ceiling
        );

        // check emitted events
        let emitted_events = emitted_events<DebtCeilingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let debt_ceiling = reserve_config::get_debt_ceiling(&reserve_config_map);
        assert!(debt_ceiling == new_debt_ceiling, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets a debt ceiling is zero by pool admin
    fun test_set_debt_ceiling_is_zero_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_debt_ceiling = 0;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_token_address, new_debt_ceiling
        );

        // check DebtCeilingChanged emitted events
        let emitted_events = emitted_events<DebtCeilingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let debt_ceiling = reserve_config::get_debt_ceiling(&reserve_config_map);
        assert!(debt_ceiling == new_debt_ceiling, TEST_SUCCESS);

        // check IsolationModeTotalDebtUpdated emitted events
        let emitted_events = emitted_events<events::IsolationModeTotalDebtUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets a debt ceiling through the risk admin
    fun test_set_debt_ceiling_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // remove pool admin and add risk admin for aave_pool
        let aaave_pool_address = signer::address_of(aave_pool);
        acl_manage::remove_pool_admin(aave_role_super_admin, aaave_pool_address);
        acl_manage::add_risk_admin(aave_role_super_admin, aaave_pool_address);

        // case1: set debt ceiling to 1000 for underlying_token_address
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_debt_ceiling = 1000;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_token_address, new_debt_ceiling
        );

        // check emitted events
        let emitted_events = emitted_events<DebtCeilingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let debt_ceiling = reserve_config::get_debt_ceiling(&reserve_config_map);
        assert!(debt_ceiling == new_debt_ceiling, TEST_SUCCESS);

        // case2: set debt ceiling to 10000 for underlying_token_address
        // old debt ceiling is 1000 and liquidation_threshold != 0
        let new_debt_ceiling2 = 10000;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_token_address, new_debt_ceiling2
        );
        // check emitted events
        let emitted_events = emitted_events<DebtCeilingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let debt_ceiling = reserve_config::get_debt_ceiling(&reserve_config_map);
        assert!(debt_ceiling == new_debt_ceiling2, TEST_SUCCESS);

        // case3: set debt ceiling to 0 for underlying_token_address
        // old debt ceiling is 10000 and liquidation_threshold == 0
        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        reserve_config::set_liquidation_threshold(&mut reserve_config_map, 0);
        pool::test_set_reserve_configuration(
            underlying_token_address, reserve_config_map
        );

        // set new debt ceiling to 0
        let new_debt_ceiling3 = 0;
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_token_address, new_debt_ceiling3
        );
        // check DebtCeilingChanged emitted events
        let emitted_events = emitted_events<DebtCeilingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let debt_ceiling = reserve_config::get_debt_ceiling(&reserve_config_map);
        assert!(debt_ceiling == new_debt_ceiling3, TEST_SUCCESS);

        // check IsolationModeTotalDebtUpdated emitted events
        let emitted_events = emitted_events<events::IsolationModeTotalDebtUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets siloed borrowing through the pool admin
    fun test_set_siloed_borrowing_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_siloed_borrowing = true;
        pool_configurator::set_siloed_borrowing(
            aave_pool, underlying_token_address, new_siloed_borrowing
        );

        // check emitted events
        let emitted_events = emitted_events<SiloedBorrowingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let siloed_borrowing = reserve_config::get_siloed_borrowing(&reserve_config_map);
        assert!(siloed_borrowing == new_siloed_borrowing, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets siloed borrowing through the risk admin
    fun test_set_siloed_borrowing_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        // remove pool admin and add risk admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::remove_pool_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_risk_admin(aave_role_super_admin, aave_pool_address);

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_siloed_borrowing = false;
        pool_configurator::set_siloed_borrowing(
            aave_pool, underlying_token_address, new_siloed_borrowing
        );

        // check emitted events
        let emitted_events = emitted_events<SiloedBorrowingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let siloed_borrowing =
            pool_data_provider::get_siloed_borrowing(underlying_token_address);
        assert!(siloed_borrowing == new_siloed_borrowing, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Updates the borrow_cap via pool admin
    fun test_set_borrow_cap_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_borrow_cap = 3000000;
        pool_configurator::set_borrow_cap(
            aave_pool, underlying_token_address, new_borrow_cap
        );

        // check emitted events
        let emitted_events = emitted_events<BorrowCapChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let borrow_cap = reserve_config::get_borrow_cap(&reserve_config_map);
        assert!(borrow_cap == new_borrow_cap, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Updates the borrow_cap via risk admin
    fun test_set_borrow_cap_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        // remove pool admin and add risk admin for aave_pool
        let aaave_pool_address = signer::address_of(aave_pool);
        acl_manage::remove_pool_admin(aave_role_super_admin, aaave_pool_address);
        acl_manage::add_risk_admin(aave_role_super_admin, aaave_pool_address);
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_borrow_cap = 5000000;
        pool_configurator::set_borrow_cap(
            aave_pool, underlying_token_address, new_borrow_cap
        );

        // check emitted events
        let emitted_events = emitted_events<BorrowCapChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let borrow_cap = reserve_config::get_borrow_cap(&reserve_config_map);
        assert!(borrow_cap == new_borrow_cap, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Updates the supply_cap via pool admin
    fun test_set_supply_cap_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_supply_cap = 3000000;
        pool_configurator::set_supply_cap(
            aave_pool, underlying_token_address, new_supply_cap
        );

        // check emitted events
        let emitted_events = emitted_events<SupplyCapChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let supply_cap = reserve_config::get_supply_cap(&reserve_config_map);
        assert!(supply_cap == new_supply_cap, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Updates the supply_cap via risk admin
    fun test_set_supply_cap_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        acl_manage::remove_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_risk_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_supply_cap = reserve_config::get_max_valid_supply_cap();
        pool_configurator::set_supply_cap(
            aave_pool, underlying_token_address, new_supply_cap
        );

        // check emitted events
        let emitted_events = emitted_events<SupplyCapChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let supply_cap = reserve_config::get_supply_cap(&reserve_config_map);
        assert!(supply_cap == new_supply_cap, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets the protocol liquidation fee to 1000 (10.00%) by pool admin
    fun test_set_liquidation_protocol_fee_by_pool_admin(
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
        let new_fee = 1000;
        pool_configurator::set_liquidation_protocol_fee(
            aave_pool, underlying_u1_token_address, new_fee
        );

        // check emitted events
        let emitted_events = emitted_events<LiquidationProtocolFeeChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let liquidation_protocol_fee =
            pool_data_provider::get_liquidation_protocol_fee(underlying_u1_token_address);
        assert!(liquidation_protocol_fee == new_fee, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets the protocol liquidation fee to 10000 (100.00%) by risk admin
    fun test_set_liquidation_protocol_fee_by_risk_admin(
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
        let old_liquidation_protocol_fee =
            pool_data_provider::get_liquidation_protocol_fee(underlying_u1_token_address);
        assert!(old_liquidation_protocol_fee == 0, TEST_SUCCESS);

        let new_liquidation_protocol_fee = math_utils::get_percentage_factor();
        pool_configurator::set_liquidation_protocol_fee(
            aave_pool,
            underlying_u1_token_address,
            new_liquidation_protocol_fee
        );

        // check emitted events
        let emitted_events = emitted_events<LiquidationProtocolFeeChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let liquidation_protocol_fee =
            pool_data_provider::get_liquidation_protocol_fee(underlying_u1_token_address);
        assert!(liquidation_protocol_fee == new_liquidation_protocol_fee, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Adds a new eMode category by pool admin
    fun test_set_emode_category_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let category_id = 1;
        let ltv = 9800;
        let liquidation_threshold = 9800;
        let liquidation_bonus = 10100;
        let label = utf8(b"Stablecoin");
        pool_configurator::set_emode_category(
            aave_pool,
            category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // check emitted events
        let emitted_events = emitted_events<EModeCategoryAdded>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let emode_category = emode_logic::get_emode_category_data(category_id);
        assert!(
            emode_logic::get_emode_category_ltv(&emode_category) == ltv,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_liquidation_threshold(&emode_category)
                == liquidation_threshold,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_liquidation_bonus(&emode_category)
                == liquidation_bonus,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_label(&emode_category) == label,
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
    // Adds a new eMode category by risk admin
    fun test_set_emode_category_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let category_id = 10;
        let ltv = 8000;
        let liquidation_threshold = 8500;
        let liquidation_bonus = 10500;
        let label = utf8(b"Stablecoin");
        pool_configurator::set_emode_category(
            aave_pool,
            category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // check emitted events
        let emitted_events = emitted_events<EModeCategoryAdded>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let emode_category = emode_logic::get_emode_category_data(category_id);
        assert!(
            emode_logic::get_emode_category_ltv(&emode_category) == ltv,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_liquidation_threshold(&emode_category)
                == liquidation_threshold,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_liquidation_bonus(&emode_category)
                == liquidation_bonus,
            TEST_SUCCESS
        );
        assert!(
            emode_logic::get_emode_category_label(&emode_category) == label,
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
    // Set asset emode category by pool admin
    // eMode category is 1 for the reserve
    fun test_set_asset_emode_category_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let category_id = 1;
        let ltv = 9800;
        let liquidation_threshold = 9800;
        let liquidation_bonus = 10100;
        let label = utf8(b"Stablecoin");
        pool_configurator::set_emode_category(
            aave_pool,
            category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // set asset emode category for underlying_token_address
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_token_address, category_id
        );

        // check emitted events
        let emitted_events = emitted_events<EModeAssetCategoryChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let emode_asset_category =
            reserve_config::get_emode_category(&reserve_config_map);
        assert!(emode_asset_category == (category_id as u256), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Set asset emode category by risk admin
    // 1. eMode category is MAX_VALID_EMODE_CATEGORY for the reserve
    // 2. eMode category is 0 for the reserve
    fun test_set_asset_emode_category_by_risk_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let category_id = (reserve_config::get_max_valid_emode_category() as u8);
        let ltv = 9800;
        let liquidation_threshold = 9800;
        let liquidation_bonus = 10100;
        let label = utf8(b"Stablecoin");
        pool_configurator::set_emode_category(
            aave_pool,
            category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // case1: eMode category is MAX_VALID_EMODE_CATEGORY for the underlying_token_address
        // set asset emode category for underlying_token_address
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_token_address, category_id
        );

        // check emitted events
        let emitted_events = emitted_events<EModeAssetCategoryChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let emode_asset_category =
            reserve_config::get_emode_category(&reserve_config_map);
        assert!(emode_asset_category == (category_id as u256), TEST_SUCCESS);

        // case2: eMode category is 0 for the underlying_token_address
        // set asset emode category for underlying_token_address
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_token_address, 0
        );

        // check emitted events
        let emitted_events = emitted_events<EModeAssetCategoryChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let emode_asset_category =
            reserve_config::get_emode_category(&reserve_config_map);
        assert!(emode_asset_category == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Set pool pause by pool admin
    fun test_set_pool_pause_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        let new_pause = true;
        let new_grace_period = 0;
        pool_configurator::set_pool_pause(aave_pool, new_pause, new_grace_period);

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let u0_reserve_data = pool::get_reserve_data(underlying_u0_token_address);
        let u0_reserve_config_map =
            pool::get_reserve_configuration(underlying_u0_token_address);
        let u0_paused = reserve_config::get_paused(&u0_reserve_config_map);
        let u0_grace_period = pool::get_liquidation_grace_period(u0_reserve_data);
        assert!(u0_paused == new_pause, TEST_SUCCESS);
        assert!(u0_grace_period == new_grace_period, TEST_SUCCESS);

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        let u1_paused = reserve_config::get_paused(&u1_reserve_config_map);
        let u1_grace_period = pool::get_liquidation_grace_period(u1_reserve_data);
        assert!(u1_paused == new_pause, TEST_SUCCESS);
        assert!(u1_grace_period == new_grace_period, TEST_SUCCESS);

        let u2_reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let u2_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u2_reserve_data);
        let u2_paused = reserve_config::get_paused(&u2_reserve_config_map);
        let u2_grace_period = pool::get_liquidation_grace_period(u2_reserve_data);
        assert!(u2_paused == new_pause, TEST_SUCCESS);
        assert!(u2_grace_period == new_grace_period, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Set pool pause by emergency admin
    // pool pause is false and grace period is MAX_GRACE_PERIOD
    fun test_set_pool_pause_by_emergency_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );
        // remove pool admin and add emergency admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::remove_pool_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_emergency_admin(aave_role_super_admin, aave_pool_address);

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        let new_pause = false;
        let new_grace_period =
            (reserve_config::get_max_valid_liquidation_grace_period() as u64);
        pool_configurator::set_pool_pause(aave_pool, new_pause, new_grace_period);

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let u0_reserve_data = pool::get_reserve_data(underlying_u0_token_address);
        let u0_reserve_config_map =
            pool::get_reserve_configuration(underlying_u0_token_address);
        let u0_paused = reserve_config::get_paused(&u0_reserve_config_map);
        let u0_grace_period = pool::get_liquidation_grace_period(u0_reserve_data);
        assert!(u0_paused == new_pause, TEST_SUCCESS);
        assert!(u0_grace_period == new_grace_period, TEST_SUCCESS);

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        let u1_paused = reserve_config::get_paused(&u1_reserve_config_map);
        let u1_grace_period = pool::get_liquidation_grace_period(u1_reserve_data);
        assert!(u1_paused == new_pause, TEST_SUCCESS);
        assert!(u1_grace_period == new_grace_period, TEST_SUCCESS);

        let u2_reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let u2_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u2_reserve_data);
        let u2_paused = reserve_config::get_paused(&u2_reserve_config_map);
        let u2_grace_period = pool::get_liquidation_grace_period(u2_reserve_data);
        assert!(u2_paused == new_pause, TEST_SUCCESS);
        assert!(u2_grace_period == new_grace_period, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Update flashloan premium total by pool admin
    // case1: flashloan premium total is 0(0.00%)
    // case2: flashloan premium total is 1000(10.00%)
    // case3: flashloan premium total is max valid flashloan premium total 10000(100.00%)
    fun test_update_flashloan_premium_total_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // case1: flashloan premium total is 0(0.00%)
        let new_flashloan_premium_total = 0;
        pool_configurator::update_flashloan_premium_total(
            aave_pool, new_flashloan_premium_total
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumTotalUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let flashloan_premium_total = pool::get_flashloan_premium_total();
        assert!(flashloan_premium_total == new_flashloan_premium_total, TEST_SUCCESS);

        // case2: flashloan premium total is 1000(10.00%)
        let new_flashloan_premium_total = 1000;
        pool_configurator::update_flashloan_premium_total(
            aave_pool, new_flashloan_premium_total
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumTotalUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let flashloan_premium_total = pool::get_flashloan_premium_total();
        assert!(flashloan_premium_total == new_flashloan_premium_total, TEST_SUCCESS);

        // case3: flashloan premium total is max valid flashloan premium total 10000(100.00%)
        let new_flashloan_premium_total = 10000;
        pool_configurator::update_flashloan_premium_total(
            aave_pool, new_flashloan_premium_total
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumTotalUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let flashloan_premium_total = pool::get_flashloan_premium_total();
        assert!(flashloan_premium_total == new_flashloan_premium_total, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Update flashloan premium to protocol by pool admin
    // case1: flashloan premium to protocol is 0(0.00%)
    // case2: flashloan premium to protocol is 3000(30.00%)
    // case3: flashloan premium to protocol is max valid flashloan premium to protocol 10000(100.00%)
    fun test_update_flashloan_premium_to_protocol_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // case1: flashloan premium to protocol is 0(0.00%)
        let new_flashloan_premium_to_protocol = 0;
        pool_configurator::update_flashloan_premium_to_protocol(
            aave_pool, new_flashloan_premium_to_protocol
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumToProtocolUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let flashloan_premium_to_protocol = pool::get_flashloan_premium_to_protocol();
        assert!(
            flashloan_premium_to_protocol == new_flashloan_premium_to_protocol,
            TEST_SUCCESS
        );

        // case2: flashloan premium to protocol is 3000(30.00%)
        let new_flashloan_premium_to_protocol = 3000;
        pool_configurator::update_flashloan_premium_to_protocol(
            aave_pool, new_flashloan_premium_to_protocol
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumToProtocolUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        let flashloan_premium_to_protocol = pool::get_flashloan_premium_to_protocol();
        assert!(
            flashloan_premium_to_protocol == new_flashloan_premium_to_protocol,
            TEST_SUCCESS
        );

        // case3: flashloan premium to protocol is max valid flashloan premium to protocol 10000(100.00%)
        let new_flashloan_premium_to_protocol = 10000;
        pool_configurator::update_flashloan_premium_to_protocol(
            aave_pool, new_flashloan_premium_to_protocol
        );

        // check emitted events
        let emitted_events = emitted_events<FlashloanPremiumToProtocolUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let flashloan_premium_to_protocol = pool::get_flashloan_premium_to_protocol();
        assert!(
            flashloan_premium_to_protocol == new_flashloan_premium_to_protocol,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            underlying_tokens = @aave_mock_underlyings
        )
    ]
    // paused is true and grace period is 0
    fun test_set_reserve_pause_no_grace_period(
        aave_pool: signer,
        aave_acl: &signer,
        aave_std: &signer,
        underlying_tokens: &signer
    ) {
        token_helper::init_reserves(
            &aave_pool,
            aave_acl,
            aave_std,
            underlying_tokens
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // pause is true and grace period is 0
        let new_paused = true;
        let new_grace_period = 0;
        set_reserve_pause_no_grace_period(
            &aave_pool, underlying_token_address, new_paused
        );

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let reserve_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(reserve_paused == new_paused, TEST_SUCCESS);
        assert!(
            pool::get_liquidation_grace_period(reserve_data) == new_grace_period,
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
    // Set pool pause no grace period by pool admin
    fun test_set_pool_pause_no_grace_period_by_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        let new_pause = true;
        let new_grace_period = 0;
        pool_configurator::set_pool_pause_no_grace_period(aave_pool, new_pause);

        // check emitted events
        let emitted_events = emitted_events<ReservePaused>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 3, TEST_SUCCESS);

        let u0_reserve_data = pool::get_reserve_data(underlying_u0_token_address);
        let u0_reserve_config_map =
            pool::get_reserve_configuration(underlying_u0_token_address);
        let u0_paused = reserve_config::get_paused(&u0_reserve_config_map);
        let u0_grace_period = pool::get_liquidation_grace_period(u0_reserve_data);
        assert!(u0_paused == new_pause, TEST_SUCCESS);
        assert!(u0_grace_period == new_grace_period, TEST_SUCCESS);

        let u1_reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let u1_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u1_reserve_data);
        let u1_paused = reserve_config::get_paused(&u1_reserve_config_map);
        let u1_grace_period = pool::get_liquidation_grace_period(u1_reserve_data);
        assert!(u1_paused == new_pause, TEST_SUCCESS);
        assert!(u1_grace_period == new_grace_period, TEST_SUCCESS);

        let u2_reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let u2_reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(u2_reserve_data);
        let u2_paused = reserve_config::get_paused(&u2_reserve_config_map);
        let u2_grace_period = pool::get_liquidation_grace_period(u2_reserve_data);
        assert!(u2_paused == new_pause, TEST_SUCCESS);
        assert!(u2_grace_period == new_grace_period, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_pending_ltv(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let pending_ltv_before = get_pending_ltv(underlying_token_address);
        assert!(pending_ltv_before == 0, TEST_SUCCESS);

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        let ltv = reserve_config::get_ltv(&reserve_config_map);

        pool_configurator::set_reserve_freeze(aave_pool, underlying_token_address, true);

        let pending_ltv_after = get_pending_ltv(underlying_token_address);
        assert!(pending_ltv_after == ltv, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_set_apt_fee(
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

        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_apt_fee = 1000000; // 0.01 APT
        pool_configurator::set_apt_fee(aave_pool, underlying_token_address, new_apt_fee);

        assert!(
            pool_fee_manager::get_apt_fee(underlying_token_address) == new_apt_fee,
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
    fun test_drop_reserve_and_remove_pending_ltv(
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

        // test reserves count
        assert!(
            number_of_active_and_dropped_reserves() == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // freeze the reserve
        pool_configurator::set_reserve_freeze(
            aave_pool, underlying_u1_token_address, true
        );

        // drop the first reserve
        drop_reserve(aave_pool, underlying_u1_token_address);

        // check emitted events
        let emitted_events = emitted_events<pool_configurator::ReserveDropped>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        assert!(
            number_of_active_and_dropped_reserves() == (TEST_ASSETS_COUNT as u256),
            TEST_SUCCESS
        );

        assert!(
            pool::number_of_active_reserves() == (TEST_ASSETS_COUNT as u256) - 1
        )
    }
}
