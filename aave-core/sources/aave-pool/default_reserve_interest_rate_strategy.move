module aave_pool::default_reserve_interest_rate_strategy {

    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;

    use aave_acl::acl_manage;
    use aave_config::error;
    use aave_math::math_utils;
    use aave_math::wad_ray_math::{Self, wad_to_ray};

    use aave_pool::a_token_factory;
    use aave_pool::underlying_token_factory;

    friend aave_pool::pool_configurator;
    #[test_only]
    friend aave_pool::default_reserve_interest_rate_strategy_tests;

    struct DefaultReserveInterestRateStrategy has key, store, copy, drop {
        optimal_usage_ratio: u256,
        max_excess_usage_ratio: u256,
        // Base variable borrow rate when usage rate = 0. Expressed in ray
        base_variable_borrow_rate: u256,
        // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope1: u256,
        // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
        variable_rate_slope2: u256,
    }

    // List of reserves as a map (underlying_asset => DefaultReserveInterestRateStrategy)
    struct ReserveInterestRateStrategyMap has key {
        vaule: SmartTable<address, DefaultReserveInterestRateStrategy>
    }

    struct CalcInterestRatesLocalVars has drop {
        available_liquidity: u256,
        total_debt: u256,
        current_variable_borrow_rate: u256,
        current_liquidity_rate: u256,
        borrow_usage_ratio: u256,
        supply_usage_ratio: u256,
        available_liquidity_plus_debt: u256,
    }

    public(friend) fun init_interest_rate_strategy(account: &signer) {
        assert!((signer::address_of(account) == @aave_pool),
            error::get_ecaller_not_pool_admin());
        move_to(account,
            ReserveInterestRateStrategyMap {
                vaule: smart_table::new<address, DefaultReserveInterestRateStrategy>()
            })
    }

    public entry fun set_reserve_interest_rate_strategy(
        account: &signer,
        asset: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256,
    ) acquires ReserveInterestRateStrategyMap {
        let account_address = signer::address_of(account);
        assert!(only_risk_or_pool_admins(account_address),
            error::get_ecaller_not_risk_or_pool_admin());
        assert!(wad_ray_math::ray() >= optimal_usage_ratio,
            error::get_einvalid_optimal_usage_ratio());
        let rate_strategy = borrow_global_mut<ReserveInterestRateStrategyMap>(@aave_pool);
        let reserve_interest_rate_strategy =
            DefaultReserveInterestRateStrategy {
                optimal_usage_ratio,
                max_excess_usage_ratio: wad_ray_math::ray() - optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2,
            };

        smart_table::upsert(&mut rate_strategy.vaule, asset, reserve_interest_rate_strategy);
    }

    #[view]
    public fun get_reserve_interest_rate_strategy(asset: address)
    : DefaultReserveInterestRateStrategy acquires ReserveInterestRateStrategyMap {
        let rate_strategy = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy.vaule, asset)) {
            return DefaultReserveInterestRateStrategy {
                optimal_usage_ratio: 0,
                max_excess_usage_ratio: 0,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 0,
                variable_rate_slope2: 0
            }
        } else {
            *smart_table::borrow(&rate_strategy.vaule, asset)
        }
    }

    #[view]
    public fun get_optimal_usage_ratio(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        smart_table::borrow(&rate_strategy_map.vaule, asset).optimal_usage_ratio
    }

    #[view]
    public fun get_max_excess_usage_ratio(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        smart_table::borrow(&rate_strategy_map.vaule, asset).max_excess_usage_ratio
    }

    #[view]
    public fun get_variable_rate_slope1(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        smart_table::borrow(&rate_strategy_map.vaule, asset).variable_rate_slope1
    }

    #[view]
    public fun get_variable_rate_slope2(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        smart_table::borrow(&rate_strategy_map.vaule, asset).variable_rate_slope2
    }

    #[view]
    public fun get_base_variable_borrow_rate(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        smart_table::borrow(&rate_strategy_map.vaule, asset).base_variable_borrow_rate
    }

    #[view]
    public fun get_max_variable_borrow_rate(asset: address): u256 acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = borrow_global<ReserveInterestRateStrategyMap>(@aave_pool);
        if (!smart_table::contains(&rate_strategy_map.vaule, asset))
            return 0;

        let strategy = smart_table::borrow(&rate_strategy_map.vaule, asset);
        strategy.base_variable_borrow_rate + strategy.variable_rate_slope1 + strategy.variable_rate_slope2
    }

    #[view]
    public fun calculate_interest_rates(
        unbacked: u256,
        liquidity_added: u256,
        liquidity_taken: u256,
        total_variable_debt: u256,
        reserve_factor: u256,
        reserve: address,
        a_token_address: address
    ): (u256, u256) acquires ReserveInterestRateStrategyMap {
        let vars = create_calc_interest_rates_local_vars();
        vars.total_debt = total_variable_debt;
        vars.current_liquidity_rate = 0;
        vars.current_variable_borrow_rate = get_base_variable_borrow_rate(reserve);

        if (vars.total_debt != 0) {
            let balance =
                (underlying_token_factory::balance_of(a_token_factory::get_token_account_address(
                    a_token_address), reserve) as u256);
            vars.available_liquidity = balance + liquidity_added - liquidity_taken;
            vars.available_liquidity_plus_debt = vars.available_liquidity + vars.total_debt;
            vars.borrow_usage_ratio = wad_ray_math::ray_div(vars.total_debt, vars.available_liquidity_plus_debt);
            vars.supply_usage_ratio = wad_ray_math::ray_div(vars.total_debt,
                (vars.available_liquidity_plus_debt + unbacked));
        };

        let rate_strategy = get_reserve_interest_rate_strategy(reserve);
        if (vars.borrow_usage_ratio > rate_strategy.optimal_usage_ratio) {
            let excess_borrow_usage_ratio =
                wad_ray_math::ray_div(
                    (vars.borrow_usage_ratio - rate_strategy.optimal_usage_ratio),
                    rate_strategy.max_excess_usage_ratio);

            vars.current_variable_borrow_rate = vars.current_variable_borrow_rate + rate_strategy
                .variable_rate_slope1 + wad_ray_math::ray_mul(rate_strategy.variable_rate_slope2,
                excess_borrow_usage_ratio);
        } else {
            vars.current_variable_borrow_rate = vars.current_variable_borrow_rate + wad_ray_math::ray_div(
                wad_ray_math::ray_mul(rate_strategy.variable_rate_slope1, vars.borrow_usage_ratio),
                rate_strategy.optimal_usage_ratio);
        };

        vars.current_liquidity_rate = math_utils::percent_mul(wad_ray_math::ray_mul(
            get_overall_borrow_rate(total_variable_debt, vars.current_variable_borrow_rate, ),
            vars.supply_usage_ratio),
            (math_utils::get_percentage_factor() - reserve_factor));

        return (vars.current_liquidity_rate, vars.current_variable_borrow_rate)
    }

    fun create_calc_interest_rates_local_vars(): CalcInterestRatesLocalVars {
        CalcInterestRatesLocalVars {
            available_liquidity: 0,
            total_debt: 0,
            current_variable_borrow_rate: 0,
            current_liquidity_rate: 0,
            borrow_usage_ratio: 0,
            supply_usage_ratio: 0,
            available_liquidity_plus_debt: 0,
        }
    }

    fun get_overall_borrow_rate(
        total_variable_debt: u256, current_variable_borrow_rate: u256,
    ): u256 {
        let totalDebt = total_variable_debt;
        if (totalDebt == 0) return 0;

        let weighted_variable_rate =
            wad_ray_math::ray_mul(wad_to_ray(total_variable_debt),
                current_variable_borrow_rate);

        let overall_borrow_rate =
            wad_ray_math::ray_div((weighted_variable_rate), wad_to_ray(totalDebt));

        overall_borrow_rate
    }

    fun only_risk_or_pool_admins(account: address): bool {
        acl_manage::is_risk_admin(account) || acl_manage::is_pool_admin(account)
    }
}
