/// @title Isolation Mode Logic Module
/// @author Aave
/// @notice Implements the logic for the isolation mode functionality
module aave_pool::isolation_mode_logic {
    // imports
    use aave_config::reserve_config;
    use aave_config::user_config::UserConfigurationMap;
    use aave_math::math_utils;
    use aave_pool::pool_logic::ReserveCache;
    use aave_pool::pool_logic;
    use aave_pool::events::Self;
    use aave_pool::pool::Self;

    // Module friends
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    // Public(friend) functions
    /// @notice Updates the isolated debt whenever a position collateralized by an isolated asset is repaid
    /// @dev Only callable by the borrow_logic module
    /// @param user_config_map The user configuration map
    /// @param reserve_cache The reserve cache
    /// @param repay_amount The amount being repaid
    public(friend) fun update_isolated_debt_if_isolated(
        user_config_map: &UserConfigurationMap,
        reserve_cache: &ReserveCache,
        repay_amount: u256
    ) {
        let (isolation_mode_active, isolation_mode_collateral_address, _) =
            pool::get_isolation_mode_state(user_config_map);

        if (isolation_mode_active) {
            update_isolated_debt(
                reserve_cache,
                repay_amount,
                isolation_mode_collateral_address
            );
        }
    }

    /// @notice Updates the isolated debt whenever a position collateralized by an isolated asset is liquidated
    /// @dev Only callable by the liquidation_logic module
    /// @param reserve_cache The reserve cache
    /// @param repay_amount The amount being repaid
    /// @param isolation_mode_collateral_address The address of the underlying asset of the reserve
    public(friend) fun update_isolated_debt(
        reserve_cache: &ReserveCache,
        repay_amount: u256,
        isolation_mode_collateral_address: address
    ) {
        let isolation_mode_debt_reserve_data =
            pool::get_reserve_data(isolation_mode_collateral_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(
                isolation_mode_debt_reserve_data
            );
        let reserve_config_map =
            pool_logic::get_reserve_cache_configuration(reserve_cache);
        let debt_decimals =
            reserve_config::get_decimals(&reserve_config_map)
                - reserve_config::get_debt_ceiling_decimals();

        let isolated_debt_repaid =
            (math_utils::ceil_div(repay_amount, math_utils::pow(10, debt_decimals)));

        // since the debt ceiling does not take into account the interest accrued, it might happen that amount
        // repaid > debt in isolation mode
        if (isolation_mode_total_debt <= (isolated_debt_repaid as u128)) {
            pool::set_reserve_isolation_mode_total_debt(
                isolation_mode_debt_reserve_data, 0
            );
            events::emit_isolated_mode_total_debt_updated(
                isolation_mode_collateral_address, 0
            );
        } else {
            let next_isolation_mode_total_debt =
                isolation_mode_total_debt - (isolated_debt_repaid as u128);
            pool::set_reserve_isolation_mode_total_debt(
                isolation_mode_debt_reserve_data,
                next_isolation_mode_total_debt
            );
            events::emit_isolated_mode_total_debt_updated(
                isolation_mode_collateral_address,
                (next_isolation_mode_total_debt as u256)
            );
        }
    }
}
