/// @title Pool Logic Module
/// @author Aave
/// @notice Implements core logic for Aave protocol pool operations including state updates and interest rate calculations
module aave_pool::pool_logic {
    // imports
    use aptos_framework::event;
    use aptos_framework::object::Object;
    use aptos_framework::timestamp;

    use aave_config::reserve_config;
    use aave_config::reserve_config::ReserveConfigurationMap;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::pool_logic;

    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::variable_debt_token_factory;

    // friend modules
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::pool_configurator;

    // Events
    #[event]
    /// @notice Emitted when the state of a reserve is updated
    /// @param reserve The address of the underlying asset of the reserve
    /// @param liquidity_rate The next liquidity rate
    /// @param variable_borrow_rate The next variable borrow rate
    /// @param liquidity_index The next liquidity index
    /// @param variable_borrow_index The next variable borrow index
    struct ReserveDataUpdated has store, drop {
        reserve: address,
        liquidity_rate: u256,
        variable_borrow_rate: u256,
        liquidity_index: u256,
        variable_borrow_index: u256
    }

    /// @notice Cache for pool reserve data to avoid repeated storage reads
    struct ReserveCache has drop {
        curr_scaled_variable_debt: u256,
        next_scaled_variable_debt: u256,
        curr_liquidity_index: u256,
        next_liquidity_index: u256,
        curr_variable_borrow_index: u256,
        next_variable_borrow_index: u256,
        curr_liquidity_rate: u256,
        curr_variable_borrow_rate: u256,
        reserve_factor: u256,
        reserve_configuration: ReserveConfigurationMap,
        a_token_address: address,
        variable_debt_token_address: address,
        reserve_last_update_timestamp: u64
    }

    // Public friend functions
    /// @notice Updates the liquidity cumulative index and the variable borrow index
    /// @dev Only callable by the supply_logic, borrow_logic, flashloan_logic and liquidation_logic module
    /// @param reserve_data The reserve data
    /// @param reserve_cache The mutable reference of the reserve cache
    public(friend) fun update_state(
        reserve_data: Object<ReserveData>, reserve_cache: &mut ReserveCache
    ) {
        let current_timestamp = timestamp::now_seconds();
        if (pool_logic::get_reserve_cache_last_update_timestamp(reserve_cache)
            == current_timestamp) { return };

        update_indexes(reserve_data, reserve_cache);
        accrue_to_treasury(reserve_data, reserve_cache);

        pool::set_reserve_last_update_timestamp(reserve_data, current_timestamp);
        pool_logic::set_reserve_cache_last_update_timestamp(
            reserve_cache, current_timestamp
        );
    }

    /// @notice Updates the reserve the current variable borrow rate and the current liquidity rate
    /// @dev Only callable by the supply_logic, borrow_logic, flashloan_logic, liquidation_logic and pool_configurator module
    /// @param reserve_data The reserve data
    /// @param reserve_cache The reserve cache
    /// @param reserve_address The address of the reserve to be updated
    /// @param liquidity_added The amount of liquidity added to the protocol (supply or repay) in the previous action
    /// @param liquidity_taken The amount of liquidity taken from the protocol (redeem or borrow)
    public(friend) fun update_interest_rates_and_virtual_balance(
        reserve_data: Object<ReserveData>,
        reserve_cache: &ReserveCache,
        reserve_address: address,
        liquidity_added: u256,
        liquidity_taken: u256
    ) {
        let total_variable_debt =
            wad_ray_math::ray_mul_up(
                reserve_cache.next_scaled_variable_debt,
                reserve_cache.next_variable_borrow_index
            );

        let underlying_balance =
            pool::get_reserve_virtual_underlying_balance(reserve_data) as u256;

        let (next_liquidity_rate, next_variable_rate) =
            default_reserve_interest_rate_strategy::calculate_interest_rates(
                pool::get_reserve_deficit(reserve_data) as u256,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_cache.reserve_factor,
                reserve_address,
                underlying_balance
            );

        pool::set_reserve_current_liquidity_rate(
            reserve_data, (next_liquidity_rate as u128)
        );
        pool::set_reserve_current_variable_borrow_rate(
            reserve_data, (next_variable_rate as u128)
        );

        let virtual_balance =
            (pool::get_reserve_virtual_underlying_balance(reserve_data) as u256);
        if (liquidity_added > 0) {
            virtual_balance = virtual_balance + liquidity_added;
        };
        if (liquidity_taken > 0) {
            virtual_balance = virtual_balance - liquidity_taken;
        };
        pool::set_reserve_virtual_underlying_balance(
            reserve_data, (virtual_balance as u128)
        );

        event::emit(
            ReserveDataUpdated {
                reserve: reserve_address,
                liquidity_rate: next_liquidity_rate,
                variable_borrow_rate: next_variable_rate,
                liquidity_index: reserve_cache.next_liquidity_index,
                variable_borrow_index: reserve_cache.next_variable_borrow_index
            }
        )
    }

    // Public functions
    /// @notice Creates a cache of the reserve data to avoid repeated storage reads
    /// @param reserve_data The reserve data
    /// @return A new ReserveCache containing the reserve data
    public fun cache(reserve_data: Object<ReserveData>): ReserveCache {
        let reserve_cache = init_cache();
        reserve_cache.reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data
        );
        reserve_cache.reserve_factor = reserve_config::get_reserve_factor(
            &reserve_cache.reserve_configuration
        );

        let liquidity_index = (pool::get_reserve_liquidity_index(reserve_data) as u256);
        reserve_cache.curr_liquidity_index = liquidity_index;
        reserve_cache.next_liquidity_index = liquidity_index;

        let variable_borrow_index =
            (pool::get_reserve_variable_borrow_index(reserve_data) as u256);
        reserve_cache.curr_variable_borrow_index = variable_borrow_index;
        reserve_cache.next_variable_borrow_index = variable_borrow_index;

        reserve_cache.curr_liquidity_rate =
            (pool::get_reserve_current_liquidity_rate(reserve_data) as u256);
        reserve_cache.curr_variable_borrow_rate =
            (pool::get_reserve_current_variable_borrow_rate(reserve_data) as u256);

        reserve_cache.a_token_address = pool::get_reserve_a_token_address(reserve_data);
        reserve_cache.variable_debt_token_address = pool::get_reserve_variable_debt_token_address(
            reserve_data
        );

        reserve_cache.reserve_last_update_timestamp = pool::get_reserve_last_update_timestamp(
            reserve_data
        );

        let scaled_total_debt =
            variable_debt_token_factory::scaled_total_supply(
                reserve_cache.variable_debt_token_address
            );
        reserve_cache.curr_scaled_variable_debt = scaled_total_debt;
        reserve_cache.next_scaled_variable_debt = scaled_total_debt;

        reserve_cache
    }

    /// @notice Gets the reserve configuration from cache
    /// @param reserve_cache The reserve cache
    /// @return The reserve configuration
    public fun get_reserve_cache_configuration(
        reserve_cache: &ReserveCache
    ): ReserveConfigurationMap {
        reserve_cache.reserve_configuration
    }

    /// @notice Gets the reserve factor from cache
    /// @param reserve_cache The reserve cache
    /// @return The reserve factor
    public fun get_reserve_factor(reserve_cache: &ReserveCache): u256 {
        reserve_cache.reserve_factor
    }

    /// @notice Gets the current liquidity index from cache
    /// @param reserve_cache The reserve cache
    /// @return The current liquidity index
    public fun get_curr_liquidity_index(reserve_cache: &ReserveCache): u256 {
        reserve_cache.curr_liquidity_index
    }

    /// @notice Sets the current liquidity index in cache
    /// @param reserve_cache The reserve cache
    /// @param index The index to set
    public fun set_curr_liquidity_index(
        reserve_cache: &mut ReserveCache, index: u256
    ) {
        reserve_cache.curr_liquidity_index = index;
    }

    /// @notice Gets the next liquidity index from cache
    /// @param reserve_cache The reserve cache
    /// @return The next liquidity index
    public fun get_next_liquidity_index(reserve_cache: &ReserveCache): u256 {
        reserve_cache.next_liquidity_index
    }

    /// @notice Sets the next liquidity index in cache
    /// @param reserve_cache The reserve cache
    /// @param index The index to set
    public fun set_next_liquidity_index(
        reserve_cache: &mut ReserveCache, index: u256
    ) {
        reserve_cache.next_liquidity_index = index;
    }

    /// @notice Gets the current variable borrow index from cache
    /// @param reserve_cache The reserve cache
    /// @return The current variable borrow index
    public fun get_curr_variable_borrow_index(
        reserve_cache: &ReserveCache
    ): u256 {
        reserve_cache.curr_variable_borrow_index
    }

    /// @notice Gets the last update timestamp from cache
    /// @param reserve_cache The reserve cache
    /// @return The last update timestamp
    public fun get_reserve_cache_last_update_timestamp(
        reserve_cache: &ReserveCache
    ): u64 {
        reserve_cache.reserve_last_update_timestamp
    }

    /// @notice Gets the next variable borrow index from cache
    /// @param reserve_cache The reserve cache
    /// @return The next variable borrow index
    public fun get_next_variable_borrow_index(
        reserve_cache: &ReserveCache
    ): u256 {
        reserve_cache.next_variable_borrow_index
    }

    /// @notice Sets the next variable borrow index in cache
    /// @param reserve_cache The reserve cache
    /// @param index The index to set
    public fun set_next_variable_borrow_index(
        reserve_cache: &mut ReserveCache, index: u256
    ) {
        reserve_cache.next_variable_borrow_index = index;
    }

    /// @notice Gets the current liquidity rate from cache
    /// @param reserve_cache The reserve cache
    /// @return The current liquidity rate
    public fun get_curr_liquidity_rate(reserve_cache: &ReserveCache): u256 {
        reserve_cache.curr_liquidity_rate
    }

    /// @notice Sets the current liquidity rate in cache
    /// @param reserve_cache The reserve cache
    /// @param rate The rate to set
    public fun set_curr_liquidity_rate(
        reserve_cache: &mut ReserveCache, rate: u256
    ) {
        reserve_cache.curr_liquidity_rate = rate;
    }

    /// @notice Gets the current variable borrow rate from cache
    /// @param reserve_cache The reserve cache
    /// @return The current variable borrow rate
    public fun get_curr_variable_borrow_rate(
        reserve_cache: &ReserveCache
    ): u256 {
        reserve_cache.curr_variable_borrow_rate
    }

    /// @notice Sets the current variable borrow rate in cache
    /// @param reserve_cache The reserve cache
    /// @param rate The rate to set
    public fun set_curr_variable_borrow_rate(
        reserve_cache: &mut ReserveCache, rate: u256
    ) {
        reserve_cache.curr_variable_borrow_rate = rate;
    }

    /// @notice Sets the last update timestamp in cache
    /// @param reserve_cache The reserve cache
    /// @param timestamp The timestamp to set
    public fun set_reserve_cache_last_update_timestamp(
        reserve_cache: &mut ReserveCache, timestamp: u64
    ) {
        reserve_cache.reserve_last_update_timestamp = timestamp;
    }

    /// @notice Gets the aToken address from cache
    /// @param reserve_cache The reserve cache
    /// @return The aToken address
    public fun get_a_token_address(reserve_cache: &ReserveCache): address {
        reserve_cache.a_token_address
    }

    /// @notice Gets the variable debt token address from cache
    /// @param reserve_cache The reserve cache
    /// @return The variable debt token address
    public fun get_variable_debt_token_address(
        reserve_cache: &ReserveCache
    ): address {
        reserve_cache.variable_debt_token_address
    }

    /// @notice Gets the current scaled variable debt from cache
    /// @param reserve_cache The reserve cache
    /// @return The current scaled variable debt
    public fun get_curr_scaled_variable_debt(
        reserve_cache: &ReserveCache
    ): u256 {
        reserve_cache.curr_scaled_variable_debt
    }

    /// @notice Gets the next scaled variable debt from cache
    /// @param reserve_cache The reserve cache
    /// @return The next scaled variable debt
    public fun get_next_scaled_variable_debt(
        reserve_cache: &ReserveCache
    ): u256 {
        reserve_cache.next_scaled_variable_debt
    }

    /// @notice Sets the next scaled variable debt in cache
    /// @param reserve_cache The reserve cache
    /// @param scaled_debt The scaled debt to set
    public fun set_next_scaled_variable_debt(
        reserve_cache: &mut ReserveCache, scaled_debt: u256
    ) {
        reserve_cache.next_scaled_variable_debt = scaled_debt;
    }

    // Private functions
    /// @notice Updates the reserve indexes and the timestamp of the update
    /// @param reserve_data The reserve data
    /// @param reserve_cache The reserve cache
    fun update_indexes(
        reserve_data: Object<ReserveData>, reserve_cache: &mut ReserveCache
    ) {
        // Only cumulating on the supply side if there is any income being produced
        // The case of Reserve Factor 100% is not a problem (currentLiquidityRate == 0),
        // as liquidity index should not be updated
        if (reserve_cache.curr_liquidity_rate != 0) {
            let cumulated_liquidity_interest =
                math_utils::calculate_linear_interest(
                    reserve_cache.curr_liquidity_rate,
                    reserve_cache.reserve_last_update_timestamp
                );
            let next_liquidity_index =
                wad_ray_math::ray_mul(
                    cumulated_liquidity_interest,
                    reserve_cache.curr_liquidity_index
                );
            reserve_cache.next_liquidity_index = next_liquidity_index;

            pool::set_reserve_liquidity_index(
                reserve_data, (next_liquidity_index as u128)
            )
        };

        // Variable borrow index only gets updated if there is any variable debt.
        // reserve_cache.curr_variable_borrow_rate != 0 is not a correct validation,
        // because a positive base variable rate can be stored on
        // reserve_cache.curr_variable_borrow_rate, but the index should not increase
        if (reserve_cache.curr_scaled_variable_debt != 0) {
            let cumulated_variable_borrow_interest =
                math_utils::calculate_compounded_interest_now(
                    reserve_cache.curr_variable_borrow_rate,
                    reserve_cache.reserve_last_update_timestamp
                );

            reserve_cache.next_variable_borrow_index = wad_ray_math::ray_mul(
                cumulated_variable_borrow_interest,
                reserve_cache.curr_variable_borrow_index
            );
            // update reserve data
            pool::set_reserve_variable_borrow_index(
                reserve_data,
                (reserve_cache.next_variable_borrow_index as u128)
            )
        }
    }

    /// @notice Update part of the repaid interest to the reserve treasury as a function of the reserve factor for the
    /// specific asset
    /// @param reserve_data The reserve data
    /// @param reserve_cache The reserve cache
    fun accrue_to_treasury(
        reserve_data: Object<ReserveData>, reserve_cache: &mut ReserveCache
    ) {
        if (reserve_cache.reserve_factor == 0) { return };

        //calculate the total variable debt at moment of the last interaction
        let prev_total_variable_debt =
            wad_ray_math::ray_mul(
                reserve_cache.curr_scaled_variable_debt,
                reserve_cache.curr_variable_borrow_index
            );

        //calculate the new total variable debt after accumulation of the interest on the index
        let curr_total_variable_debt =
            wad_ray_math::ray_mul(
                reserve_cache.curr_scaled_variable_debt,
                reserve_cache.next_variable_borrow_index
            );

        let total_debt_accrued = curr_total_variable_debt - prev_total_variable_debt;
        let amount_to_mint =
            math_utils::percent_mul(total_debt_accrued, reserve_cache.reserve_factor);

        if (amount_to_mint != 0) {
            let new_accrued_to_treasury =
                pool::get_reserve_accrued_to_treasury(reserve_data)
                    + wad_ray_math::ray_div_down(
                        amount_to_mint,
                        reserve_cache.next_liquidity_index
                    );

            pool::set_reserve_accrued_to_treasury(reserve_data, new_accrued_to_treasury)
        }
    }

    /// @notice Initializes a new ReserveCache with default values
    /// @return A new ReserveCache
    fun init_cache(): ReserveCache {
        ReserveCache {
            curr_scaled_variable_debt: 0,
            next_scaled_variable_debt: 0,
            curr_liquidity_index: 0,
            next_liquidity_index: 0,
            curr_variable_borrow_index: 0,
            next_variable_borrow_index: 0,
            curr_liquidity_rate: 0,
            curr_variable_borrow_rate: 0,
            reserve_factor: 0,
            reserve_configuration: reserve_config::init(),
            a_token_address: @0x0,
            variable_debt_token_address: @0x0,
            reserve_last_update_timestamp: 0
        }
    }

    #[test_only]
    /// Test helper function that exposes update_interest_rates_and_virtual_balance for testing
    public fun update_interest_rates_and_virtual_balance_for_testing(
        reserve_data: Object<ReserveData>,
        reserve_cache: &ReserveCache,
        reserve_address: address,
        liquidity_added: u256,
        liquidity_taken: u256
    ) {
        update_interest_rates_and_virtual_balance(
            reserve_data,
            reserve_cache,
            reserve_address,
            liquidity_added,
            liquidity_taken
        )
    }
}
