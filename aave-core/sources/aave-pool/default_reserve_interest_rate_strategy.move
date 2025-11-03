/// @title Default Reserve Interest Rate Strategy Module
/// @author Aave
/// @notice Default interest rate strategy used by the Aave protocol
module aave_pool::default_reserve_interest_rate_strategy {
    // imports
    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;

    use aave_config::error_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math::Self;

    // friend modules
    friend aave_pool::pool_configurator;
    friend aave_pool::pool_token_logic;

    // Constants
    /// @notice The maximum value achievable for variable borrow rate, in bps
    const MAX_BORROW_RATE: u256 = 1000_00;

    /// @notice The minimum optimal point, in bps
    const MIN_OPTIMAL_POINT: u256 = 1_00;

    /// @notice The maximum optimal point, in bps
    const MAX_OPTIMAL_POINT: u256 = 99_00;

    // Events
    #[event]
    /// @notice Emitted when new interest rate data is set in a reserve
    /// @param reserve Address of the reserve that has new interest rate data set
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    struct RateDataUpdate has store, drop {
        reserve: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    // Structs
    /// @notice Holds the interest rate data for a given reserve
    /// @dev Since values are in bps, they are multiplied by 1e23 in order to become rays with 27 decimals. This
    /// in turn means that the maximum supported interest rate is 4294967295 (2**32-1) bps or 42949672.95%.
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    struct InterestRateData has store, copy, drop {
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    /// @notice The interest rate data, where all values are in ray (fixed-point 27 decimal numbers) for a given reserve,
    /// used in in-memory calculations.
    /// @param optimal_usage_ratio The optimal usage ratio
    /// @param base_variable_borrow_rate The base variable borrow rate
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio
    struct InterestRateDataRay has drop {
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    /// @notice Map of reserves address and their interest rate data (reserve_address => InterestRateData)
    struct ReserveInterestRateStrategyMap has key {
        value: SmartTable<address, InterestRateData>
    }

    /// @notice Local variables for calculating interest rates
    struct CalcInterestRatesLocalVars has drop {
        available_liquidity: u256,
        current_variable_borrow_rate: u256,
        current_liquidity_rate: u256,
        borrow_usage_ratio: u256,
        supply_usage_ratio: u256,
        available_liquidity_plus_debt: u256
    }

    // Public view functions
    #[view]
    /// @notice Returns the full InterestRateData object for the given reserve, in ray
    /// @param reserve The reserve to get the data of
    /// @return The InterestRateDataRay object for the given reserve
    public fun get_reserve_interest_rate_strategy(
        reserve: address
    ): InterestRateDataRay acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = get_reserve_interest_rate_strategy_map_ref();
        if (!smart_table::contains(&rate_strategy_map.value, reserve)) {
            // If rate do not exist, return zero as default values, to be 1:1 with Solidity
            return rayify_rate_data(
                &InterestRateData {
                    optimal_usage_ratio: 0,
                    base_variable_borrow_rate: 0,
                    variable_rate_slope1: 0,
                    variable_rate_slope2: 0
                }
            )
        };

        rayify_rate_data(smart_table::borrow(&rate_strategy_map.value, reserve))
    }

    #[view]
    /// @notice Returns the full InterestRateDataRay object for the given reserve, in bps
    /// @param reserve The reserve to get the data of
    /// @return The InterestRateData object for the given reserve
    public fun get_reserve_interest_rate_strategy_bps(
        reserve: address
    ): InterestRateData acquires ReserveInterestRateStrategyMap {
        let rate_strategy_map = get_reserve_interest_rate_strategy_map_ref();
        if (!smart_table::contains(&rate_strategy_map.value, reserve)) {
            // If rate do not exist, return zero as default values, to be 1:1 with Solidity
            return InterestRateData {
                optimal_usage_ratio: 0,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 0,
                variable_rate_slope2: 0
            }
        };

        *smart_table::borrow(&rate_strategy_map.value, reserve)
    }

    #[view]
    /// @notice Returns the optimal usage rate for the given reserve in ray
    /// @param reserve The reserve to get the optimal usage rate of
    /// @return The optimal usage rate is the level of borrow / collateral at which the borrow rate
    public fun get_optimal_usage_ratio(
        reserve: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(reserve).optimal_usage_ratio
    }

    #[view]
    /// @notice Returns the variable rate slope below optimal usage ratio in ray
    /// @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
    /// @param reserve The reserve to get the variable rate slope 1 of
    /// @return The variable rate slope
    public fun get_variable_rate_slope1(
        reserve: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(reserve).variable_rate_slope1
    }

    #[view]
    /// @notice Returns the variable rate slope above optimal usage ratio in ray
    /// @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
    /// @param reserve The reserve to get the variable rate slope 2 of
    /// @return The variable rate slope
    public fun get_variable_rate_slope2(
        reserve: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(reserve).variable_rate_slope2
    }

    #[view]
    /// @notice Returns the base variable borrow rate, in ray
    /// @param reserve The reserve to get the base variable borrow rate of
    /// @return The base variable borrow rate
    public fun get_base_variable_borrow_rate(
        reserve: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        get_reserve_interest_rate_strategy(reserve).base_variable_borrow_rate
    }

    #[view]
    /// @notice Returns the maximum variable borrow rate, in ray
    /// @param reserve The reserve to get the maximum variable borrow rate of
    /// @return The maximum variable borrow rate
    public fun get_max_variable_borrow_rate(
        reserve: address
    ): u256 acquires ReserveInterestRateStrategyMap {
        let rate_data = get_reserve_interest_rate_strategy(reserve);

        rate_data.base_variable_borrow_rate + rate_data.variable_rate_slope1
            + rate_data.variable_rate_slope2
    }

    #[view]
    /// @notice Calculates the interest rates depending on the reserve's state and configurations
    /// @param unbacked The amount of unbacked liquidity
    /// @param liquidity_added The amount of liquidity added
    /// @param liquidity_taken The amount of liquidity taken
    /// @param total_debt The total debt of the reserve
    /// @param reserve_factor The reserve factor
    /// @param reserve The address of the reserve
    /// @param virtual_underlying_balance The virtual underlying balance of the reserve
    /// @return current_liquidity_rate The liquidity rate expressed in rays
    /// @return current_variable_borrow_rate The variable borrow rate expressed in rays
    public fun calculate_interest_rates(
        unbacked: u256,
        liquidity_added: u256,
        liquidity_taken: u256,
        total_debt: u256,
        reserve_factor: u256,
        reserve: address,
        virtual_underlying_balance: u256
    ): (u256, u256) acquires ReserveInterestRateStrategyMap {
        let rate_data = get_reserve_interest_rate_strategy(reserve);
        let vars = create_calc_interest_rates_local_vars();
        vars.current_liquidity_rate = 0;
        vars.current_variable_borrow_rate = rate_data.base_variable_borrow_rate;
        if (total_debt != 0) {
            vars.available_liquidity =
                virtual_underlying_balance + liquidity_added - liquidity_taken;
            vars.available_liquidity_plus_debt = vars.available_liquidity + total_debt;
            vars.borrow_usage_ratio = wad_ray_math::ray_div(
                total_debt, vars.available_liquidity_plus_debt
            );
            vars.supply_usage_ratio = wad_ray_math::ray_div(
                total_debt,
                (vars.available_liquidity_plus_debt + unbacked)
            );
        } else {
            return (0, vars.current_variable_borrow_rate)
        };

        if (vars.borrow_usage_ratio > rate_data.optimal_usage_ratio) {
            let excess_borrow_usage_ratio =
                wad_ray_math::ray_div(
                    (vars.borrow_usage_ratio - rate_data.optimal_usage_ratio),
                    wad_ray_math::ray() - rate_data.optimal_usage_ratio
                );

            vars.current_variable_borrow_rate =
                vars.current_variable_borrow_rate + rate_data.variable_rate_slope1
                    + wad_ray_math::ray_mul(
                        rate_data.variable_rate_slope2,
                        excess_borrow_usage_ratio
                    );
        } else {
            vars.current_variable_borrow_rate =
                vars.current_variable_borrow_rate
                    + wad_ray_math::ray_div(
                        wad_ray_math::ray_mul(
                            rate_data.variable_rate_slope1, vars.borrow_usage_ratio
                        ),
                        rate_data.optimal_usage_ratio
                    );
        };

        vars.current_liquidity_rate = math_utils::percent_mul(
            wad_ray_math::ray_mul(
                vars.current_variable_borrow_rate,
                vars.supply_usage_ratio
            ),
            (math_utils::get_percentage_factor() - reserve_factor)
        );

        return (vars.current_liquidity_rate, vars.current_variable_borrow_rate)
    }

    // Public friend functions
    /// @notice Initializes the interest rate strategy
    /// @dev Only callable by the pool_configurator module
    /// @param account The signer account of the caller
    public(friend) fun init_interest_rate_strategy(account: &signer) {
        assert!(
            (signer::address_of(account) == @aave_pool),
            error_config::get_enot_pool_owner()
        );

        move_to(
            account,
            ReserveInterestRateStrategyMap {
                value: smart_table::new<address, InterestRateData>()
            }
        );
    }

    /// @notice Sets interest rate data for an Aave rate strategy
    /// @dev Only callable by the pool_configurator and pool_token_logic module
    /// @param reserve The address of the underlying asset of the reserve
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    public(friend) fun set_reserve_interest_rate_strategy(
        reserve: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) acquires ReserveInterestRateStrategyMap {
        assert!(reserve != @0x0, error_config::get_ezero_address_not_valid());

        assert!(
            optimal_usage_ratio <= MAX_OPTIMAL_POINT
                && optimal_usage_ratio >= MIN_OPTIMAL_POINT,
            error_config::get_einvalid_optimal_usage_ratio()
        );

        assert!(
            variable_rate_slope1 <= variable_rate_slope2,
            error_config::get_eslope_2_must_be_gte_slope_1()
        );

        // The maximum rate should not be above certain threshold
        assert!(
            base_variable_borrow_rate + variable_rate_slope1 + variable_rate_slope2
                <= MAX_BORROW_RATE,
            error_config::get_einvalid_max_rate()
        );

        let interest_rate_data = InterestRateData {
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        };

        let rate_strategy = get_reserve_interest_rate_strategy_map_mut();
        smart_table::upsert(&mut rate_strategy.value, reserve, interest_rate_data);

        event::emit(
            RateDataUpdate {
                reserve,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            }
        )
    }

    // Private functions
    /// @notice Creates a CalcInterestRatesLocalVars struct with default values
    /// @return A new CalcInterestRatesLocalVars struct
    fun create_calc_interest_rates_local_vars(): CalcInterestRatesLocalVars {
        CalcInterestRatesLocalVars {
            available_liquidity: 0,
            current_variable_borrow_rate: 0,
            current_liquidity_rate: 0,
            borrow_usage_ratio: 0,
            supply_usage_ratio: 0,
            available_liquidity_plus_debt: 0
        }
    }

    /// @notice Transforms an InterestRateData struct to an InterestRateDataRay struct by multiplying all values
    /// by 1e23, turning them into ray values
    /// @param interest_rate_data The InterestRateData struct to transform
    /// @return The resulting InterestRateDataRay struct
    fun rayify_rate_data(interest_rate_data: &InterestRateData): InterestRateDataRay {
        InterestRateDataRay {
            optimal_usage_ratio: bps_to_ray(interest_rate_data.optimal_usage_ratio),
            base_variable_borrow_rate: bps_to_ray(
                interest_rate_data.base_variable_borrow_rate
            ),
            variable_rate_slope1: bps_to_ray(interest_rate_data.variable_rate_slope1),
            variable_rate_slope2: bps_to_ray(interest_rate_data.variable_rate_slope2)
        }
    }

    /// @notice Helper function to convert basis points to ray
    /// @dev Generally the protocol doesn't use bps, but this is a helper function
    /// @param n The number in basis points
    /// @return The number in ray
    fun bps_to_ray(n: u256): u256 {
        n * math_utils::pow(10, 23)
    }

    /// @notice Asserts that the ReserveInterestRateStrategyMap is initialized
    fun assert_reserve_interest_rate_strategy_map_initialized() {
        assert!(
            exists<ReserveInterestRateStrategyMap>(@aave_pool),
            error_config::get_edefault_interest_rate_strategy_not_initialized()
        )
    }

    /// @notice Gets a reference to the ReserveInterestRateStrategyMap
    /// @return A reference to the ReserveInterestRateStrategyMap
    inline fun get_reserve_interest_rate_strategy_map_ref()
        : &ReserveInterestRateStrategyMap {
        assert_reserve_interest_rate_strategy_map_initialized();
        borrow_global<ReserveInterestRateStrategyMap>(@aave_pool)
    }

    /// @notice Gets a mutable reference to the ReserveInterestRateStrategyMap
    /// @return A mutable reference to the ReserveInterestRateStrategyMap
    inline fun get_reserve_interest_rate_strategy_map_mut()
        : &mut ReserveInterestRateStrategyMap {
        assert_reserve_interest_rate_strategy_map_initialized();
        borrow_global_mut<ReserveInterestRateStrategyMap>(@aave_pool)
    }

    // Test only functions
    #[test_only]
    /// @notice Asserts that the ReserveInterestRateStrategyMap is initialized (for testing)
    public fun assert_reserve_interest_rate_strategy_map_initialized_for_testing() {
        assert_reserve_interest_rate_strategy_map_initialized();
    }

    #[test_only]
    /// @notice Converts basis points to ray (for testing)
    /// @param n The number in basis points
    /// @return The number in ray
    public fun bps_to_ray_test_for_testing(n: u256): u256 {
        bps_to_ray(n)
    }

    #[test_only]
    /// @notice Initializes the interest rate strategy (for testing)
    /// @param account The signer account of the caller
    public fun init_interest_rate_strategy_for_testing(account: &signer) {
        init_interest_rate_strategy(account);
    }

    #[test_only]
    /// @notice Gets the optimal usage ratio from InterestRateData (for testing)
    /// @param interest_rate_data The InterestRateData
    /// @return The optimal usage ratio
    public fun get_optimal_usage_ratio_for_testing(
        interest_rate_data: InterestRateData
    ): u256 {
        interest_rate_data.optimal_usage_ratio
    }

    #[test_only]
    /// @notice Gets the variable rate slope 1 from InterestRateData (for testing)
    /// @param interest_rate_data The InterestRateData
    /// @return The variable rate slope 1
    public fun get_variable_rate_slope1_for_testing(
        interest_rate_data: InterestRateData
    ): u256 {
        interest_rate_data.variable_rate_slope1
    }

    #[test_only]
    /// @notice Gets the variable rate slope 2 from InterestRateData (for testing)
    /// @param interest_rate_data The InterestRateData
    /// @return The variable rate slope 2
    public fun get_variable_rate_slope2_for_testing(
        interest_rate_data: InterestRateData
    ): u256 {
        interest_rate_data.variable_rate_slope2
    }

    #[test_only]
    /// @notice Gets the base variable borrow rate from InterestRateData (for testing)
    /// @param interest_rate_data The InterestRateData
    /// @return The base variable borrow rate
    public fun get_base_variable_borrow_rate_for_testing(
        interest_rate_data: InterestRateData
    ): u256 {
        interest_rate_data.base_variable_borrow_rate
    }

    #[test_only]
    /// @notice Sets the interest rate strategy for a reserve (for testing)
    /// @param reserve The address of the reserve
    /// @param optimal_usage_ratio The optimal usage ratio
    /// @param base_variable_borrow_rate The base variable borrow rate
    /// @param variable_rate_slope1 The variable rate slope 1
    /// @param variable_rate_slope2 The variable rate slope 2
    public fun set_reserve_interest_rate_strategy_for_testing(
        reserve: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) acquires ReserveInterestRateStrategyMap {
        set_reserve_interest_rate_strategy(
            reserve,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }
}
