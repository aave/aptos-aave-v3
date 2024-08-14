module aave_pool::user_logic {

    use aave_pool::emode_logic;
    use aave_pool::generic_logic;
    use aave_pool::pool;

    #[view]
    /// @notice Returns the user account data across all the reserves
    /// @param user The address of the user
    /// @return total_collateral_base The total collateral of the user in the base currency used by the price feed
    /// @return total_debt_base The total debt of the user in the base currency used by the price feed
    /// @return available_borrows_base The borrowing power left of the user in the base currency used by the price feed
    /// @return current_liquidation_threshold The liquidation threshold of the user
    /// @return ltv The loan to value of The user
    /// @return health_factor The current health factor of the user
    public fun get_user_account_data(user: address): (u256, u256, u256, u256, u256, u256) {
        let user_config_map = pool::get_user_configuration(user);
        let reserves_count = pool::get_reserves_count();
        let user_emode_category = (emode_logic::get_user_emode(user) as u8);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            emode_logic::get_emode_configuration(user_emode_category);
        let (
            total_collateral_base,
            total_debt_base,
            ltv,
            current_liquidation_threshold,
            health_factor,
            _
        ) =
            generic_logic::calculate_user_account_data(
                reserves_count,
                &user_config_map,
                user,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price,
            );

        let available_borrows_base =
            generic_logic::calculate_available_borrows(
                total_collateral_base, total_debt_base, ltv
            );

        (
            total_collateral_base,
            total_debt_base,
            available_borrows_base,
            current_liquidation_threshold,
            ltv,
            health_factor
        )
    }
}
