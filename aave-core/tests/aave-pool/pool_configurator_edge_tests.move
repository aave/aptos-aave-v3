#[test_only]
module aave_pool::pool_configurator_edge_tests {
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::{utf8, bytes};
    use std::vector;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;

    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;
    use aave_pool::pool_fee_manager;
    use aave_pool::borrow_logic;
    use aave_pool::a_token_factory;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::pool_configurator::{
        init_reserves,
        configure_reserve_as_collateral,
        set_reserve_factor,
        update_flashloan_premium_total,
        update_flashloan_premium_to_protocol,
        set_borrow_cap,
        set_supply_cap,
        set_emode_category,
        set_asset_emode_category,
        set_reserve_active,
        drop_reserve,
        set_reserve_pause,
        test_init_module,
        set_debt_ceiling,
        SiloedBorrowingChanged,
        set_siloed_borrowing,
        set_liquidation_protocol_fee,
        set_reserve_freeze,
        set_apt_fee
    };
    use aave_pool::token_helper;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool_configurator;
    use aave_pool::pool;
    use aave_pool::pool_data_provider;
    use aave_pool::supply_logic;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(account = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::pool_configurator)]
    fun test_init_module_with_non_pool_owner(account: &signer) {
        test_init_module(account);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    #[expected_failure(abort_code = 76, location = aave_pool::pool_configurator)]
    fun test_init_reserves_with_inconsistent_params_length(
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
        let underlying_asset = vector[@0x12];
        let treasury = vector[];
        let a_token_name = vector[];
        let a_token_symbol = vector[];
        let variable_debt_token_name = vector[];
        let variable_debt_token_symbol = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];

        init_reserves(
            aave_pool,
            underlying_asset,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            incentives_controllers,
            vector[400],
            vector[100],
            vector[200],
            vector[300]
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
    #[expected_failure(abort_code = 1503, location = aave_pool::fungible_asset_manager)]
    fun test_init_reserves_when_underlying_asset_not_exist(
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

        // new underlying asset
        let underlying_asset = vector[@0x22];
        let treasury = vector[@0x33];
        let a_token_name = vector[utf8(b"aDAI")];
        let a_token_symbol = vector[utf8(b"ADAI")];
        let variable_debt_token_name = vector[utf8(b"vDAI")];
        let variable_debt_token_symbol = vector[utf8(b"VDAI")];
        let incentives_controllers: vector<Option<address>> = vector[option::none()];

        init_reserves(
            aave_pool,
            underlying_asset,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            incentives_controllers,
            vector[400],
            vector[100],
            vector[200],
            vector[300]
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
    fun test_init_reserves_when_reserve_already_added(
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

        let underlying_asset = vector[mock_underlying_token_factory::token_address(
            utf8(b"U_1")
        )];
        let treasury = vector[@0x33];
        let a_token_name = vector[utf8(b"aDAI")];
        let a_token_symbol = vector[utf8(b"ADAI")];
        let variable_debt_token_name = vector[utf8(b"vDAI")];
        let variable_debt_token_symbol = vector[utf8(b"VDAI")];
        let incentives_controllers: vector<Option<address>> = vector[option::none()];

        init_reserves(
            aave_pool,
            underlying_asset,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            incentives_controllers,
            vector[400],
            vector[100],
            vector[200],
            vector[300]
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
    #[expected_failure(abort_code = 1506, location = aave_pool::pool_token_logic)]
    fun test_init_reserves_when_underlying_asset_decimals_lt_6(
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

        // create underlying tokens
        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 5;
        let max_supply = 10000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );

        let underlying_asset = mock_underlying_token_factory::token_address(symbol);
        let underlying_assets = vector[underlying_asset];
        let treasurys = vector[@0x33];
        let a_token_names = vector[utf8(b"aDAI")];
        let a_token_symbols = vector[utf8(b"ADAI")];
        let variable_debt_token_names = vector[utf8(b"vDAI")];
        let variable_debt_token_symbols = vector[utf8(b"VDAI")];
        let incentives_controllers: vector<Option<address>> = vector[option::none()];

        // set asset rate strategy
        let optimal_usage_ratio: u256 = 800;
        let base_variable_borrow_rate: u256 = 0;
        let variable_rate_slope1: u256 = 4000;
        let variable_rate_slope2: u256 = 7500;
        default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy_for_testing(
            underlying_asset,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        init_reserves(
            aave_pool,
            underlying_assets,
            treasurys,
            a_token_names,
            a_token_symbols,
            variable_debt_token_names,
            variable_debt_token_symbols,
            incentives_controllers,
            vector[400],
            vector[100],
            vector[200],
            vector[300]
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
    #[expected_failure(abort_code = 77, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_when_underlying_asset_is_zero_address(
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

        // drop reserve with zero address
        drop_reserve(aave_pool, @0x0);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            caller = @0x42
        )
    ]
    #[expected_failure(abort_code = 54, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_with_nonzero_supply_atokens_failure(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_acl,
            aave_std,
            underlying_tokens_admin
        );

        // ============= MINT ATOKENS ============== //
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        a_token_factory::mint_for_testing(
            signer::address_of(caller),
            signer::address_of(caller),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // drop the first reserve
        drop_reserve(aave_pool, underlying_u1_token_address);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            caller = @0x42
        )
    ]
    #[expected_failure(abort_code = 56, location = aave_pool::pool_token_logic)]
    fun test_drop_reserve_with_nonzero_supply_variable_tokens_failure(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // ============= MINT VARIABLE TOKENS ============== //
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let var_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        variable_debt_token_factory::test_mint_for_testing(
            signer::address_of(caller),
            signer::address_of(caller),
            amount_to_mint,
            reserve_index,
            var_token_address
        );

        // assert var token supply
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // drop the first reserve
        drop_reserve(aave_pool, underlying_u1_token_address);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // configure_reserve_as_collateral() ltv > liquidation_threshold
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_ltv_exceeds_liquidation_threshold(
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
        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            10,
            5,
            10000
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
    // configure_reserve_as_collateral()  liquidation_threshold !=0 and liquidation_bonus < 10000
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_liquidation_bonus_below_10000(
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
        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            10,
            11,
            9999
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
    // configure_reserve_as_collateral() math_utils::percent_mul(liquidation_threshold, liquidation_bonus) > PERCENTAGE_FACTOR
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_liquidation_threshold_times_liquidation_bonus_exceeds_percentage_factor(
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
        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            10001,
            10001,
            10001
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
    // configure_reserve_as_collateral() liquidation_threshold == 0 && liquidation_bonus > 0
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_liquidation_threshold_zero_and_liquidation_bonus_greater_than_zero(
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
        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            0,
            0,
            10500
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
    // Tries to configure reserve as collateral with liquidity on it (revert expected)
    #[expected_failure(abort_code = 18, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_when_reserve_liquidity_not_zero(
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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            10000,
            underlying_token_address
        );

        // deposit some liquidity
        supply_logic::supply(
            aave_pool,
            underlying_token_address,
            10000,
            signer::address_of(aave_pool),
            0
        );
        let ltv = 0;
        let liquidation_threshold = 0;
        let liquidation_bonus = 0;

        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            ltv,
            liquidation_threshold,
            liquidation_bonus
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
    // set_liquidation_bonus() liquidation_bonus > MAX_VALID_LIQUIDATION_BONUS
    #[expected_failure(abort_code = 65, location = aave_config::reserve_config)]
    fun test_configure_reserve_as_collateral_liquidation_bonus_exceeds_max_valid_liquidation_bonus(
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
        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            5,
            10,
            65535 + 1
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
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_with_emode_ltv_less_than_reserve_ltv(
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
        // set emode category
        set_emode_category(
            aave_pool,
            1,
            8500,
            9000,
            10500,
            utf8(b"EMODE_1")
        );

        // set asset emode category
        set_asset_emode_category(aave_pool, underlying_token_address, 1);

        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            9000,
            9500,
            10500
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
    #[expected_failure(abort_code = 20, location = aave_pool::pool_configurator)]
    fun test_configure_reserve_as_collateral_with_emode_lt_less_than_reserve_lt(
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
        // set emode category
        set_emode_category(
            aave_pool,
            1,
            8500,
            9000,
            10500,
            utf8(b"EMODE_1")
        );

        // set asset emode category
        set_asset_emode_category(aave_pool, underlying_token_address, 1);

        configure_reserve_as_collateral(
            aave_pool,
            underlying_token_address,
            8000,
            9500,
            10500
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
    #[expected_failure(abort_code = 98, location = aave_pool::pool_configurator)]
    fun test_set_reserve_pause_extreme_grace_period(
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

        // choose an asset to pause
        let asset_to_pause = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // pause the asset
        set_reserve_pause(&aave_pool, asset_to_pause, true, 0);

        // now unpause the asset setting a new extreme grace period
        set_reserve_pause(
            &aave_pool,
            asset_to_pause,
            false,
            (reserve_config::get_max_valid_liquidation_grace_period() + 1 as u64)
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
    // set_reserve_factor() reserve_factor > PERCENTAGE_FACTOR (revert expected)
    #[expected_failure(abort_code = 67, location = aave_pool::pool_configurator)]
    fun test_set_reserve_factor_exceeds_percentage_factor(
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
        set_reserve_factor(aave_pool, underlying_token_address, 20000);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // reserve_configuration set_reserve_factor() reserve_factor > MAX_VALID_RESERVE_FACTOR
    #[expected_failure(abort_code = 67, location = aave_pool::pool_configurator)]
    fun test_set_reserve_factor_exceeds_max_valid_reserve_factor(
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
        set_reserve_factor(aave_pool, underlying_token_address, 65536);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to Set debt ceiling the reserve with liquidity on it (revert expected)
    #[expected_failure(abort_code = 18, location = aave_pool::pool_configurator)]
    fun test_set_debt_ceiling_when_reserve_with_liquidity(
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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            10000,
            underlying_token_address
        );

        // deposit some liquidity
        supply_logic::supply(
            aave_pool,
            underlying_token_address,
            10000,
            signer::address_of(aave_pool),
            0
        );

        // set reserve accrued to treasury is 1000
        let reserve_data = pool::get_reserve_data(underlying_token_address);
        pool::set_reserve_accrued_to_treasury_for_testing(reserve_data, 1000);

        set_debt_ceiling(aave_pool, underlying_token_address, 5000)
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
    // Resets the siloed borrowing mode. Tries to set siloed borrowing after the asset has been borrowed (revert expected)
    #[expected_failure(abort_code = 90, location = aave_pool::pool_configurator)]
    fun test_set_siloed_borrowing_with_reserve_after_borrowing(
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
            aave_oracle, underlying_u1_token_address, 10000000
        );

        // set siloed borrowing for U_1 token
        set_siloed_borrowing(aave_pool, underlying_u1_token_address, false);

        // check emitted events
        let emitted_events = emitted_events<SiloedBorrowingChanged>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let supply_amount =
            token_helper::convert_to_currency_decimals(
                underlying_u1_token_address, 1000
            );
        // user 1 supplies 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (supply_amount as u64),
            underlying_u1_token_address
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // set asset price for U_2 token
        let underlying_u2_token_feed_id =
            *bytes(&mock_underlying_token_factory::symbol(underlying_u2_token_address));
        oracle::set_asset_feed_id(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_feed(
            aave_oracle, underlying_u2_token_address, underlying_u2_token_feed_id
        );
        oracle::set_chainlink_mock_price(aave_oracle, 100, underlying_u2_token_feed_id);
        oracle::set_max_asset_price_age(
            aave_oracle, underlying_u2_token_address, 10000000
        );

        // user 2 supplies 1000 U_2
        let supply_amount =
            token_helper::convert_to_currency_decimals(
                underlying_u2_token_address, 1000
            );
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (supply_amount as u64),
            underlying_u2_token_address
        );
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // mint 1 APT to the user2
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(user2_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);
        // user2 borrow U_1 tokens
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            100,
            2,
            0,
            user2_address
        );

        assert!(
            coin::balance<AptosCoin>(user2_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_u1_token_address),
            TEST_SUCCESS
        );

        // try to set siloed borrowing
        set_siloed_borrowing(aave_pool, underlying_u1_token_address, true);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Sets the protocol liquidation fee to 10001 (100.01%) greater than PERCENTAGE_FACTOR (revert expected)
    #[expected_failure(abort_code = 70, location = aave_pool::pool_configurator)]
    fun test_set_liquidation_protocol_fee_greater_than_percentage_factor(
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

        let new_fee = math_utils::get_percentage_factor() + 1;
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        set_liquidation_protocol_fee(aave_pool, underlying_u1_token_address, new_fee);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to update flashloan premium total > PERCENTAGE_FACTOR (revert expected)
    #[expected_failure(abort_code = 19, location = aave_pool::pool_configurator)]
    fun test_update_flashloan_premium_total_exceeds_percentage_factor(
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

        update_flashloan_premium_total(aave_pool, 10001);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to update flashloan premium to protocol > PERCENTAGE_FACTOR (revert expected)
    #[expected_failure(abort_code = 19, location = aave_pool::pool_configurator)]
    fun test_update_flashloan_premium_to_protocol_exceeds_percentage_factor(
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

        update_flashloan_premium_to_protocol(aave_pool, 10001);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to update borrow_cap > MAX_BORROW_CAP (revert expected)
    #[expected_failure(abort_code = 68, location = aave_config::reserve_config)]
    fun test_set_borrow_cap_exceeds_max_borrow_cap(
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
        set_borrow_cap(
            aave_pool,
            underlying_token_address,
            reserve_config::get_max_valid_borrow_cap() + 1
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
    // Tries to update supply_cap > MAX_SUPPLY_CAP (revert expected)
    #[expected_failure(abort_code = 69, location = aave_config::reserve_config)]
    fun test_set_supply_cap_exceeds_max_supply_cap(
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
        set_supply_cap(
            aave_pool,
            underlying_token_address,
            reserve_config::get_max_valid_supply_cap() + 1
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
    // Tries to add a category with id 0 (revert expected)
    #[expected_failure(abort_code = 16, location = aave_pool::emode_logic)]
    fun test_set_emode_category_add_category_id_zero(
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

        set_emode_category(
            aave_pool,
            0,
            9800,
            9800,
            10100,
            utf8(b"INVALID_ID_CATEGORY")
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
    // Tries to add an eMode category with ltv > liquidation threshold (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_ltv_greater_than_liquidation_threshold(
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

        set_emode_category(
            aave_pool,
            16,
            9900,
            9800,
            10100,
            utf8(b"STABLECOINS")
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
    // Tries to add an eMode category with no liquidation bonus (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_no_liquidation_bonus(
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

        set_emode_category(
            aave_pool,
            16,
            9800,
            9800,
            10000,
            utf8(b"STABLECOINS")
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
    // Tries to add an eMode category with too large liquidation bonus (revert expected)
    // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
    // a loan is taken there is enough collateral available to cover the liquidation bonus
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_liquidation_bonus_too_large(
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

        set_emode_category(
            aave_pool,
            16,
            9800,
            9800,
            11000,
            utf8(b"STABLECOINS")
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
    // Tries to add an eMode category with liquidation threshold > 1 (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_liquidation_threshold_greater_than_one(
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

        set_emode_category(
            aave_pool,
            16,
            9800,
            10100,
            10100,
            utf8(b"STABLECOINS")
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
    // Tries to add an eMode category with ltv == 0 (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_when_ltv_is_zero(
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

        set_emode_category(
            aave_pool,
            16,
            0,
            10100,
            10100,
            utf8(b"STABLECOINS")
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
    // Tries to add an eMode category with liquidation_bonus == 0 (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_when_liquidation_bonus_is_zero(
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

        set_emode_category(
            aave_pool,
            16,
            9800,
            10100,
            0,
            utf8(b"STABLECOINS")
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
    // Tries to set asset eMode category to undefined category (revert expected)
    #[expected_failure(abort_code = 17, location = aave_pool::pool_configurator)]
    fun test_set_asset_emode_category_undefined_category(
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
        set_asset_emode_category(aave_pool, underlying_token_address, 100)
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 17, location = aave_pool::pool_configurator)]
    fun test_set_asset_emode_category_with_emode_lt_less_than_reserve_lt(
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
        // set emode category
        set_emode_category(
            aave_pool,
            100,
            8500,
            9000,
            10500,
            utf8(b"EMODE_1")
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        reserve_config::set_liquidation_threshold(&mut reserve_config_map, 9500);
        pool::test_set_reserve_configuration(
            underlying_token_address, reserve_config_map
        );

        set_asset_emode_category(aave_pool, underlying_token_address, 100)
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to set eMode category to category with too low ltv (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_when_ltv_too_low(
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
        let (_, ltv, liquidation_threshold, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(underlying_token_address);

        set_emode_category(
            aave_pool,
            100,
            (ltv + 500 as u16),
            (liquidation_threshold + 1 as u16),
            10100,
            utf8(b"LTV_TOO_LOW")
        );

        set_asset_emode_category(aave_pool, underlying_token_address, 100);

        set_emode_category(
            aave_pool,
            100,
            (ltv - 1 as u16),
            (liquidation_threshold + 1 as u16),
            10100,
            utf8(b"LTV_TOO_LOW")
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
    // Tries to set eMode category to category with too low LT (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_when_liquidation_threshold_too_low(
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
        let (_, ltv, liquidation_threshold, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(underlying_token_address);
        set_emode_category(
            aave_pool,
            100,
            (ltv + 500 as u16),
            (liquidation_threshold + 1 as u16),
            10100,
            utf8(b"LT_TOO_LOW")
        );

        set_asset_emode_category(aave_pool, underlying_token_address, 100);

        set_emode_category(
            aave_pool,
            100,
            (ltv + 1 as u16),
            (liquidation_threshold - 1 as u16),
            10100,
            utf8(b"LT_TOO_LOW")
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
    // Tries to disable the reserve with liquidity on it (revert expected)
    #[expected_failure(abort_code = 18, location = aave_pool::pool_configurator)]
    fun test_set_reserve_active_when_disable_reserve_with_liquidity(
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
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(aave_pool),
            10000,
            underlying_token_address
        );

        // deposit some liquidity
        supply_logic::supply(
            aave_pool,
            underlying_token_address,
            10000,
            signer::address_of(aave_pool),
            0
        );

        set_reserve_active(aave_pool, underlying_token_address, false)
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 99, location = aave_pool::pool_configurator)]
    fun test_set_reserve_freeze_with_invalid_freeze_flag(
        aave_pool: signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            &aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // choose an asset to freeze
        let asset_to_freeze = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // freeze the asset with an invalid freeze flag
        set_reserve_freeze(&aave_pool, asset_to_freeze, false);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Tries to set eMode category to category with liquidation_threshold = 0 (revert expected)
    #[expected_failure(abort_code = 21, location = aave_pool::pool_configurator)]
    fun test_set_emode_category_when_liquidation_threshold_is_zero(
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
        let (_, ltv, _, _, _, _, _, _, _) =
            pool_data_provider::get_reserve_configuration_data(underlying_token_address);

        set_emode_category(
            aave_pool,
            100,
            (ltv as u16),
            0,
            10100,
            utf8(b"LT_TOO_LOW")
        );
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    #[expected_failure(abort_code = 82, location = aave_pool::pool_configurator)]
    fun test_set_apt_fee_when_asset_not_exist(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(aave_role_super_admin);

        // init pool configurator module
        pool_configurator::test_init_module(aave_pool);

        // add pool admin
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        set_apt_fee(aave_pool, @0x31, 1000000);
    }
}
