module aave_pool::generic_logic {

    use aave_config::reserve as reserve_config;
    use aave_config::user::{Self as user_config, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle;

    use aave_pool::a_token_factory;
    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::variable_token_factory;

    struct CalculateUserAccountDataVars has drop {
        asset_price: u256,
        asset_unit: u256,
        user_balance_in_base_currency: u256,
        decimals: u256,
        ltv: u256,
        liquidation_threshold: u256,
        i: u256,
        health_factor: u256,
        total_collateral_in_base_currency: u256,
        total_debt_in_base_currency: u256,
        avg_ltv: u256,
        avg_liquidation_threshold: u256,
        emode_asset_price: u256,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_category: u256,
        current_reserve_address: address,
        has_zero_ltv_collateral: bool,
        is_in_emode_category: bool,
    }

    fun create_calculate_user_account_data_vars(): CalculateUserAccountDataVars {
        CalculateUserAccountDataVars {
            asset_price: 0,
            asset_unit: 0,
            user_balance_in_base_currency: 0,
            decimals: 0,
            ltv: 0,
            liquidation_threshold: 0,
            i: 0,
            health_factor: 0,
            total_collateral_in_base_currency: 0,
            total_debt_in_base_currency: 0,
            avg_ltv: 0,
            avg_liquidation_threshold: 0,
            emode_asset_price: 0,
            emode_ltv: 0,
            emode_liq_threshold: 0,
            emode_asset_category: 0,
            current_reserve_address: @0x0,
            has_zero_ltv_collateral: false,
            is_in_emode_category: false,
        }
    }

    public fun calculate_user_account_data(
        reserves_count: u256,
        user_config_map: &UserConfigurationMap,
        user: address,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256,
    ): (u256, u256, u256, u256, u256, bool) {
        if (user_config::is_empty(user_config_map)) {
            return(0, 0, 0, 0, math_utils::u256_max(), false)
        };

        let vars = create_calculate_user_account_data_vars();
        if (user_emode_category != 0) {
            vars.emode_ltv = emode_ltv;
            vars.emode_liq_threshold = emode_liq_threshold;
            vars.emode_asset_price = emode_asset_price;
        };

        while (vars.i < reserves_count) {
            if (!user_config::is_using_as_collateral_or_borrowing(user_config_map, vars.i)) {
                vars.i = vars.i + 1;
                continue
            };

            vars.current_reserve_address = pool::get_reserve_address_by_id(vars.i);
            if (vars.current_reserve_address == @0x0) {
                vars.i = vars.i + 1;
                continue
            };

            let current_reserve = pool::get_reserve_data(vars.current_reserve_address);
            let current_reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(&current_reserve);
            let (ltv, liquidation_threshold, _, decimals, _, emode_asset_category) =
                reserve_config::get_params(&current_reserve_config_map);
            vars.ltv = ltv;
            vars.liquidation_threshold = liquidation_threshold;
            vars.decimals = decimals;
            vars.emode_asset_category = emode_asset_category;

            vars.asset_unit = math_utils::pow(10, vars.decimals);

            vars.asset_price = if (vars.emode_asset_price != 0 && user_emode_category == (vars.emode_asset_category as u8)) {
                vars.emode_asset_price
            } else {
                oracle::get_asset_price(vars.current_reserve_address)
            };

            if (vars.liquidation_threshold != 0 && user_config::is_using_as_collateral(user_config_map, vars
                        .i)) {
                vars.user_balance_in_base_currency = get_user_balance_in_base_currency(user, &current_reserve, vars
                    .asset_price, vars.asset_unit);

                vars.total_collateral_in_base_currency = vars.total_collateral_in_base_currency
                    + vars.user_balance_in_base_currency;

                vars.is_in_emode_category = user_emode_category != 0 && vars.emode_asset_category ==
                     (user_emode_category as u256);

                if (vars.ltv != 0) {
                    let ltv =
                        if (vars.is_in_emode_category) {
                            vars.emode_ltv
                        } else {
                            vars.ltv
                        };
                    vars.avg_ltv = vars.avg_ltv + vars.user_balance_in_base_currency * ltv;
                } else {
                    vars.has_zero_ltv_collateral = true
                };

                let liquidation_threshold =
                    if (vars.is_in_emode_category) {
                        vars.emode_liq_threshold
                    } else {
                        vars.liquidation_threshold
                    };
                vars.avg_liquidation_threshold = vars.avg_liquidation_threshold + vars.user_balance_in_base_currency
                    * liquidation_threshold;
            };

            if (user_config::is_borrowing(user_config_map, vars.i)) {
                let user_debt_in_base_currency =
                    get_user_debt_in_base_currency(user, &current_reserve, vars.asset_price, vars
                        .asset_unit);
                vars.total_debt_in_base_currency = vars.total_debt_in_base_currency + user_debt_in_base_currency;
            };

            vars.i = vars.i + 1;
        };

        vars.avg_ltv = if (vars.total_collateral_in_base_currency != 0) {
            vars.avg_ltv / vars.total_collateral_in_base_currency
        } else { 0 };

        vars.avg_liquidation_threshold = if (vars.total_collateral_in_base_currency != 0) {
            vars.avg_liquidation_threshold / vars.total_collateral_in_base_currency
        } else { 0 };

        vars.health_factor = if (vars.total_debt_in_base_currency == 0) {
            math_utils::u256_max()
        } else {
            wad_ray_math::wad_div(math_utils::percent_mul(vars.total_collateral_in_base_currency, vars
                        .avg_liquidation_threshold),
                vars.total_debt_in_base_currency)
        };

        return(vars.total_collateral_in_base_currency,
            vars.total_debt_in_base_currency,
            vars.avg_ltv,
            vars.avg_liquidation_threshold,
            vars.health_factor,
            vars.has_zero_ltv_collateral)
    }

    public fun calculate_available_borrows(
        total_collateral_in_base_currency: u256, total_debt_in_base_currency: u256, ltv: u256,
    ): u256 {
        let available_borrows_in_base_currency = math_utils::percent_mul(
            total_collateral_in_base_currency, ltv);

        if (available_borrows_in_base_currency < total_debt_in_base_currency) {
            return 0
        };

        available_borrows_in_base_currency - total_debt_in_base_currency
    }

    fun get_user_debt_in_base_currency(
        user: address, reserve_data: &ReserveData, asset_price: u256, asset_unit: u256
    ): u256 {
        let user_total_debt =
            variable_token_factory::scale_balance_of(user,
                pool::get_reserve_variable_debt_token_address(reserve_data));

        if (user_total_debt != 0) {
            let normalized_debt = pool::get_normalized_debt_by_reserve_data(reserve_data);
            user_total_debt = wad_ray_math::ray_mul(user_total_debt, normalized_debt);
        };

        user_total_debt = asset_price * user_total_debt;

        user_total_debt / asset_unit
    }

    fun get_user_balance_in_base_currency(
        user: address, reserve_data: &ReserveData, asset_price: u256, asset_unit: u256
    ): u256 {
        let normalized_income = pool::get_normalized_income_by_reserve_data(reserve_data);
        let balance =
            wad_ray_math::ray_mul(a_token_factory::scale_balance_of(user,
                    pool::get_reserve_a_token_address(reserve_data)),
                normalized_income) * asset_price;
        balance / asset_unit
    }
}