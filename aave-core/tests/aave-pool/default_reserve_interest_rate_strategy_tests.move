#[test_only]
module aave_pool::default_reserve_interest_rate_strategy_tests {
    use std::features::change_feature_flags_for_testing;
    use std::signer;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::Self;
    use aave_math::math_utils;
    use aave_math::wad_ray_math::Self;

    use aave_pool::default_reserve_interest_rate_strategy::{
        get_base_variable_borrow_rate,
        get_max_variable_borrow_rate,
        get_optimal_usage_ratio,
        get_variable_rate_slope1,
        get_variable_rate_slope2,
        RateDataUpdate,
        calculate_interest_rates,
        assert_reserve_interest_rate_strategy_map_initialized_for_testing,
        bps_to_ray_test_for_testing,
        init_interest_rate_strategy_for_testing,
        get_reserve_interest_rate_strategy_bps,
        get_optimal_usage_ratio_for_testing,
        get_variable_rate_slope1_for_testing,
        get_variable_rate_slope2_for_testing,
        get_base_variable_borrow_rate_for_testing,
        set_reserve_interest_rate_strategy_for_testing
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(aave_role_super_admin = @aave_acl, aave_std = @std, aptos_framework = @0x1)]
    #[
        expected_failure(
            abort_code = 1401, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_init_interest_rate_strategy_with_not_pool_owner(
        aave_role_super_admin: &signer, aave_std: &signer, aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        init_interest_rate_strategy_for_testing(aave_role_super_admin);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    #[
        expected_failure(
            abort_code = 83, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_set_reserve_interest_rate_strategy_with_invalid_optimal_usage_ratio(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init the interest rate strategy module
        init_interest_rate_strategy_for_testing(aave_pool);

        // init the strategy
        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = wad_ray_math::ray() + 1;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        set_reserve_interest_rate_strategy_for_testing(
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }

    #[test(
        pool = @aave_pool,
        aave_role_super_admin = @aave_acl,
        aave_std = @std,
        aptos_framework = @0x1
    )]
    fun test_get_reserve_interest_rate_strategy(
        pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init the interest rate strategy module
        init_interest_rate_strategy_for_testing(pool);

        // init the strategy
        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = 300;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        set_reserve_interest_rate_strategy_for_testing(
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // check emitted events
        let emitted_events = emitted_events<RateDataUpdate>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // assertions on getters
        assert!(
            get_optimal_usage_ratio(asset_address)
                == bps_to_ray_test_for_testing(optimal_usage_ratio),
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope1(asset_address)
                == bps_to_ray_test_for_testing(variable_rate_slope1),
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope2(asset_address)
                == bps_to_ray_test_for_testing(variable_rate_slope2),
            TEST_SUCCESS
        );
        assert!(
            get_base_variable_borrow_rate(asset_address)
                == bps_to_ray_test_for_testing(base_variable_borrow_rate),
            TEST_SUCCESS
        );
        assert!(
            get_max_variable_borrow_rate(asset_address)
                == bps_to_ray_test_for_testing(
                    base_variable_borrow_rate + variable_rate_slope1
                        + variable_rate_slope2
                ),
            TEST_SUCCESS
        );
    }

    #[test(
        pool = @aave_pool,
        aave_role_super_admin = @aave_acl,
        aave_std = @std,
        aptos_framework = @0x1
    )]
    fun test_get_reserve_interest_rate_strategy_bps(
        pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init the interest rate strategy module
        init_interest_rate_strategy_for_testing(pool);

        // init the strategy
        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = 300;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        let base_variable_borrow_rate: u256 = 100;

        let interest_rate_data = get_reserve_interest_rate_strategy_bps(asset_address);
        assert!(
            get_optimal_usage_ratio_for_testing(interest_rate_data) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope1_for_testing(interest_rate_data) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope2_for_testing(interest_rate_data) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_base_variable_borrow_rate_for_testing(interest_rate_data) == 0,
            TEST_SUCCESS
        );

        set_reserve_interest_rate_strategy_for_testing(
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // check emitted events
        let emitted_events = emitted_events<RateDataUpdate>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // assertions on getters
        let interest_rate_data = get_reserve_interest_rate_strategy_bps(asset_address);
        assert!(
            get_optimal_usage_ratio_for_testing(interest_rate_data)
                == optimal_usage_ratio,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope1_for_testing(interest_rate_data)
                == variable_rate_slope1,
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope2_for_testing(interest_rate_data)
                == variable_rate_slope2,
            TEST_SUCCESS
        );
        assert!(
            get_base_variable_borrow_rate_for_testing(interest_rate_data)
                == base_variable_borrow_rate,
            TEST_SUCCESS
        );
    }

    #[test(
        pool = @aave_pool,
        aave_role_super_admin = @aave_acl,
        aave_std = @std,
        aptos_framework = @0x1
    )]
    fun test_get_reserve_interest_rate_strategy_for_unset_asset(
        pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init the interest rate strategy module
        init_interest_rate_strategy_for_testing(pool);

        // get strategy elements without having initialized the strategy
        let asset_address = @0x42;
        assert!(get_optimal_usage_ratio(asset_address) == 0, TEST_SUCCESS);
        assert!(get_variable_rate_slope1(asset_address) == 0, TEST_SUCCESS);
        assert!(get_variable_rate_slope2(asset_address) == 0, TEST_SUCCESS);
        assert!(get_base_variable_borrow_rate(asset_address) == 0, TEST_SUCCESS);
        assert!(get_max_variable_borrow_rate(asset_address) == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_calculate_interest_rates_default_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        init_interest_rate_strategy_for_testing(aave_pool);
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = 200;
        let base_variable_borrow_rate: u256 = 0;
        let variable_rate_slope1: u256 = 0;
        let variable_rate_slope2: u256 = 0;
        set_reserve_interest_rate_strategy_for_testing(
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // check emitted events
        let emitted_events = emitted_events<RateDataUpdate>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let unbacked: u256 = 1;
        let liquidity_added: u256 = 2;
        let liquidity_taken: u256 = 3;
        let total_variable_debt: u256 = 100;
        let reserve_factor: u256 = 10;
        let reserve: address = asset_address;
        let a_token_underlying_balance: u256 = 10;
        let (next_liquidity_rate, next_variable_rate) =
            calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            );

        assert!(next_liquidity_rate == 0, TEST_SUCCESS);
        assert!(next_variable_rate == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_calculate_interest_rates(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        init_interest_rate_strategy_for_testing(aave_pool);
        acl_manage::test_init_module(aave_role_super_admin);

        acl_manage::add_risk_admin(aave_role_super_admin, @aave_pool);
        acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);

        // init the strategy
        let asset_address = @0x42;
        let optimal_usage_ratio: u256 = 500;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        set_reserve_interest_rate_strategy_for_testing(
            asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // check emitted events
        let emitted_events = emitted_events<RateDataUpdate>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // assertions on getters
        assert!(
            get_optimal_usage_ratio(asset_address)
                == bps_to_ray_test_for_testing(optimal_usage_ratio),
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope1(asset_address)
                == bps_to_ray_test_for_testing(variable_rate_slope1),
            TEST_SUCCESS
        );
        assert!(
            get_variable_rate_slope2(asset_address)
                == bps_to_ray_test_for_testing(variable_rate_slope2),
            TEST_SUCCESS
        );
        assert!(
            get_base_variable_borrow_rate(asset_address)
                == bps_to_ray_test_for_testing(base_variable_borrow_rate),
            TEST_SUCCESS
        );
        assert!(
            get_max_variable_borrow_rate(asset_address)
                == bps_to_ray_test_for_testing(
                    base_variable_borrow_rate + variable_rate_slope1
                        + variable_rate_slope2
                ),
            TEST_SUCCESS
        );

        // case 1 total_variable_debt = 0, vars.borrow_usage_ratio > rate_data.optimal_usage_ratio
        let unbacked: u256 = 10;
        let liquidity_added: u256 = 10;
        let liquidity_taken: u256 = 20;
        let total_variable_debt: u256 = 0;
        let reserve_factor: u256 = 1000;
        let reserve: address = asset_address;
        let a_token_underlying_balance: u256 = 80;
        let (next_liquidity_rate, next_variable_rate) =
            calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            );
        let current_variable_borrow_rate =
            get_base_variable_borrow_rate(asset_address)
                + wad_ray_math::ray_div(
                    wad_ray_math::ray_mul(get_variable_rate_slope1(asset_address), 0),
                    get_optimal_usage_ratio(asset_address)
                );
        assert!(next_liquidity_rate == 0, TEST_SUCCESS);
        assert!(next_variable_rate == current_variable_borrow_rate, TEST_SUCCESS);

        // case 2 total_variable_debt != 0, vars.borrow_usage_ratio <= rate_data.optimal_usage_ratio
        let unbacked: u256 = 10;
        let liquidity_added: u256 = 10;
        let liquidity_taken: u256 = 20;
        let total_variable_debt: u256 = wad_ray_math::ray();
        let reserve_factor: u256 = 1000;
        let reserve = asset_address;
        let a_token_underlying_balance: u256 = 80;
        let (next_liquidity_rate, next_variable_rate) =
            calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            );

        let available_liquidity =
            a_token_underlying_balance + liquidity_added - liquidity_taken;
        let available_liquidity_plus_debt = available_liquidity + total_variable_debt;
        let borrow_usage_ratio =
            wad_ray_math::ray_div(total_variable_debt, available_liquidity_plus_debt);
        let supply_usage_ratio =
            wad_ray_math::ray_div(
                total_variable_debt, (available_liquidity_plus_debt + unbacked)
            );
        let optimal_usage_ratio = get_optimal_usage_ratio(asset_address);
        let excess_borrow_usage_ratio =
            wad_ray_math::ray_div(
                (borrow_usage_ratio - optimal_usage_ratio),
                wad_ray_math::ray() - optimal_usage_ratio
            );

        let current_variable_borrow_rate =
            get_base_variable_borrow_rate(asset_address)
                + get_variable_rate_slope1(asset_address)
                + wad_ray_math::ray_mul(
                    get_variable_rate_slope2(asset_address),
                    excess_borrow_usage_ratio
                );

        let current_liquidity_rate =
            math_utils::percent_mul(
                wad_ray_math::ray_mul(current_variable_borrow_rate, supply_usage_ratio),
                (math_utils::get_percentage_factor() - reserve_factor)
            );

        assert!(next_liquidity_rate == current_liquidity_rate, TEST_SUCCESS);
        assert!(next_variable_rate == current_variable_borrow_rate, TEST_SUCCESS);
    }

    #[test(aave_std = @std, aptos_framework = @0x1)]
    #[
        expected_failure(
            abort_code = 1302, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_reserve_interest_rate_strategy_map_not_initialized_expected_failure(
        aave_std: &signer, aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        assert_reserve_interest_rate_strategy_map_initialized_for_testing();
    }

    #[test(aave_pool = @aave_pool, aave_std = @std, aptos_framework = @0x1)]
    fun test_reserve_interest_rate_strategy_map_initialized(
        aave_pool: &signer, aave_std: &signer, aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        init_interest_rate_strategy_for_testing(aave_pool);
        assert_reserve_interest_rate_strategy_map_initialized_for_testing();
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    #[
        expected_failure(
            abort_code = 77, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_set_reserve_interest_rate_strategy_with_reserve_is_zero_address(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        init_interest_rate_strategy_for_testing(aave_pool);

        let reserve_address = @0x0;
        let optimal_usage_ratio: u256 = 200;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 200;
        let variable_rate_slope2: u256 = 300;
        set_reserve_interest_rate_strategy_for_testing(
            reserve_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    #[
        expected_failure(
            abort_code = 95, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_set_reserve_interest_rate_strategy_with_variable_rate_slope1_gt_variable_rate_slope2(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        init_interest_rate_strategy_for_testing(aave_pool);

        let reserve_address = @0x42;
        let optimal_usage_ratio: u256 = 200;
        let base_variable_borrow_rate: u256 = 100;
        let variable_rate_slope1: u256 = 500;
        let variable_rate_slope2: u256 = 300;
        set_reserve_interest_rate_strategy_for_testing(
            reserve_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    #[
        expected_failure(
            abort_code = 92, location = aave_pool::default_reserve_interest_rate_strategy
        )
    ]
    fun test_set_reserve_interest_rate_strategy_with_invalid_max_rate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        acl_manage::test_init_module(aave_role_super_admin);

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        init_interest_rate_strategy_for_testing(aave_pool);

        let reserve_address = @0x42;
        let optimal_usage_ratio: u256 = 200;
        let base_variable_borrow_rate: u256 = 1000;
        let variable_rate_slope1: u256 = 60000;
        let variable_rate_slope2: u256 = 80000;
        set_reserve_interest_rate_strategy_for_testing(
            reserve_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }
}
