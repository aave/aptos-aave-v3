/// @title Generic Logic module
/// @author Aave
/// @notice Implements protocol-level logic to calculate and validate the state of a user
module aave_pool::generic_logic {
    // imports
    use aptos_framework::object::Object;
    use aave_config::reserve_config;
    use aave_config::user_config::{Self, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;

    use aave_pool::a_token_factory;
    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::variable_debt_token_factory;

    /// @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
    /// @dev The variable debt balance is calculated by fetching `scaled_balance_of` normalized debt
    /// @param user The address of the user
    /// @param reserve_data The data of the reserve for which the total debt of the user is being calculated
    /// @param asset_price The price of the asset for which the total debt of the user is being calculated
    /// @param asset_unit The value representing one full unit of the asset (10^decimals)
    /// @return The total debt of the user normalized to the base currency
    fun get_user_debt_in_base_currency(
        user: address,
        reserve_data: Object<ReserveData>,
        asset_price: u256,
        asset_unit: u256
    ): u256 {
        let user_total_debt =
            variable_debt_token_factory::scaled_balance_of(
                user, pool::get_reserve_variable_debt_token_address(reserve_data)
            );

        if (user_total_debt != 0) {
            let normalized_debt = pool::get_normalized_debt_by_reserve_data(reserve_data);
            user_total_debt = wad_ray_math::ray_mul_up(user_total_debt, normalized_debt);
        };

        math_utils::ceil_div(asset_price * user_total_debt, asset_unit)
    }

    /// @notice Calculates total aToken balance of the user in the based currency used by the price oracle
    /// @dev The aToken balance is calculated by fetching `scaled_balance_of` normalized debt
    /// @param user The address of the user
    /// @param reserve_data The data of the reserve for which the total aToken balance of the user is being calculated
    /// @param asset_price The price of the asset for which the total aToken balance of the user is being calculated
    /// @param asset_unit The value representing one full unit of the asset (10^decimals)
    /// @return The total aToken balance of the user normalized to the base currency of the price oracle
    fun get_user_balance_in_base_currency(
        user: address,
        reserve_data: Object<ReserveData>,
        asset_price: u256,
        asset_unit: u256
    ): u256 {
        let normalized_income = pool::get_normalized_income_by_reserve_data(reserve_data);
        let balance =
            wad_ray_math::ray_mul_down(
                a_token_factory::scaled_balance_of(
                    user, pool::get_reserve_a_token_address(reserve_data)
                ),
                normalized_income
            ) * asset_price;
        balance / asset_unit
    }

    // Public functions
    /// @notice Calculates the user data across the reserves.
    /// @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
    /// the average Loan To Value, the average Liquidation Ratio, and the Health factor.
    /// @param user_config_map The user configuration map
    /// @param reserves_count The number of reserves
    /// @param user The address of the user
    /// @param user_emode_category The category of the user in the emode
    /// @param emode_ltv The ltv of the user in the emode
    /// @param emode_liq_threshold The liquidation threshold of the user in the emode
    /// @return The total collateral of the user in the base currency used by the price feed
    /// @return The total debt of the user in the base currency used by the price feed
    /// @return The average ltv of the user
    /// @return The average liquidation threshold of the user
    /// @return The health factor of the user
    /// @return True if the user has a zero-LTV asset enabled as collateral
    public fun calculate_user_account_data(
        user_config_map: &UserConfigurationMap,
        reserves_count: u256,
        user: address,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256
    ): (u256, u256, u256, u256, u256, bool) {
        if (user_config::is_empty(user_config_map)) {
            return (0, 0, 0, 0, math_utils::u256_max(), false)
        };

        let total_collateral_in_base_currency = 0;
        let total_debt_in_base_currency = 0;
        let average_ltv = 0;
        let average_liquidation_threshold = 0;
        let has_zero_ltv_collateral = false;

        let i = 0;
        while (i < reserves_count) {
            if (!user_config::is_using_as_collateral_or_borrowing(user_config_map, i)) {
                i = i + 1;
                continue
            };

            let current_reserve_address = pool::get_reserve_address_by_id(i);
            // `get_reserve_address_by_id` returns @0x0 if the id does not exist
            if (current_reserve_address == @0x0) {
                i = i + 1;
                continue
            };

            let current_reserve = pool::get_reserve_data(current_reserve_address);
            let current_reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(current_reserve);
            let (ltv, liquidation_threshold, _, decimals, _, emode_asset_category) =
                reserve_config::get_params(&current_reserve_config_map);

            let asset_unit = math_utils::pow(10, decimals);
            let asset_price = oracle::get_asset_price(current_reserve_address);

            if (liquidation_threshold != 0
                && user_config::is_using_as_collateral(user_config_map, i)) {
                let user_balance_in_base_currency =
                    get_user_balance_in_base_currency(
                        user, current_reserve, asset_price, asset_unit
                    );

                total_collateral_in_base_currency =
                    total_collateral_in_base_currency + user_balance_in_base_currency;

                let is_in_emode_category =
                    user_emode_category != 0
                        && emode_asset_category == (user_emode_category as u256);

                // NOTE: if the reserve's LTV is zero but its eMode category's LTV is non-zero,
                // the reserve's LTV supersedes eMode LTV, this is an intended behavior.
                if (ltv != 0) {
                    let actual_ltv = if (is_in_emode_category) {
                        emode_ltv
                    } else { ltv };
                    average_ltv = average_ltv
                        + user_balance_in_base_currency * actual_ltv;
                } else {
                    has_zero_ltv_collateral = true
                };

                let actual_liquidation_threshold =
                    if (is_in_emode_category) {
                        emode_liq_threshold
                    } else {
                        liquidation_threshold
                    };
                average_liquidation_threshold =
                    average_liquidation_threshold
                        + user_balance_in_base_currency * actual_liquidation_threshold;
            };

            if (user_config::is_borrowing(user_config_map, i)) {
                let user_debt_in_base_currency =
                    get_user_debt_in_base_currency(
                        user, current_reserve, asset_price, asset_unit
                    );
                total_debt_in_base_currency =
                    total_debt_in_base_currency + user_debt_in_base_currency;
            };

            i = i + 1;
        };

        if (total_collateral_in_base_currency != 0) {
            average_ltv = average_ltv / total_collateral_in_base_currency;
            average_liquidation_threshold =
                average_liquidation_threshold / total_collateral_in_base_currency;
        } else {
            average_ltv = 0;
            average_liquidation_threshold = 0;
        };

        let health_factor =
            if (total_debt_in_base_currency == 0) {
                math_utils::u256_max()
            } else {
                wad_ray_math::wad_div(
                    math_utils::percent_mul(
                        total_collateral_in_base_currency,
                        average_liquidation_threshold
                    ),
                    total_debt_in_base_currency
                )
            };

        return (
            total_collateral_in_base_currency,
            total_debt_in_base_currency,
            average_ltv,
            average_liquidation_threshold,
            health_factor,
            has_zero_ltv_collateral
        )
    }

    /// @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
    /// and the average Loan To Value
    /// @param total_collateral_in_base_currency The total collateral in the base currency used by the price feed
    /// @param total_debt_in_base_currency The total borrow balance in the base currency used by the price feed
    /// @param ltv The average loan to value
    /// @return The amount available to borrow in the base currency of the used by the price feed
    public fun calculate_available_borrows(
        total_collateral_in_base_currency: u256,
        total_debt_in_base_currency: u256,
        ltv: u256
    ): u256 {
        let available_borrows_in_base_currency =
            math_utils::percent_mul(total_collateral_in_base_currency, ltv);

        if (available_borrows_in_base_currency <= total_debt_in_base_currency) {
            return 0
        };

        available_borrows_in_base_currency - total_debt_in_base_currency
    }

    #[test_only]
    /// Test helper function that exposes get_user_debt_in_base_currency for testing
    public fun get_user_debt_in_base_currency_for_testing(
        user: address,
        reserve_data: Object<ReserveData>,
        asset_price: u256,
        asset_unit: u256
    ): u256 {
        get_user_debt_in_base_currency(user, reserve_data, asset_price, asset_unit)
    }

    #[test_only]
    /// Test helper function that exposes get_user_balance_in_base_currency for testing
    public fun get_user_balance_in_base_currency_for_testing(
        user: address,
        reserve_data: Object<ReserveData>,
        asset_price: u256,
        asset_unit: u256
    ): u256 {
        get_user_balance_in_base_currency(user, reserve_data, asset_price, asset_unit)
    }
}
