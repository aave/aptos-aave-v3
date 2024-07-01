module aave_pool::liquidation_logic {
    use std::signer;
    use aptos_framework::event;

    use aave_config::reserve as reserve_config;
    use aave_config::user as user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::generic_logic;
    use aave_pool::isolation_mode_logic;
    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::pool_validation;
    use aave_pool::underlying_token_factory;
    use aave_pool::validation_logic;
    use aave_pool::variable_token_factory;

    #[event]
    struct ReserveUsedAsCollateralEnabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    struct ReserveUsedAsCollateralDisabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    struct LiquidationCall has store, drop {
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        liquidated_collateral_amount: u256,
        liquidator: address,
        receive_a_token: bool
    }

    /**
    * @dev Default percentage of borrower's debt to be repaid in a liquidation.
    * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
    * Expressed in bps, a value of 0.5e4 results in 50.00%
    */
    // 5 * 10 ** 3
    const DEFAULT_LIQUIDATION_CLOSE_FACTOR: u256 = 5000;
    /**
    * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
    * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
    * Expressed in bps, a value of 1e4 results in 100.00%
    */
    // 1 * 10 ** 4
    const MAX_LIQUIDATION_CLOSE_FACTOR: u256 = 10000;

    /**
    * @dev This constant represents below which health factor value it is possible to liquidate
    * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
    * A value of 0.95e18 results in 0.95
    */
    // 0.95 * 10 ** 18
    const CLOSE_FACTOR_HF_THRESHOLD: u256 = 950000000000000000;

    struct LiquidationCallLocalVars has drop {
        user_collateral_balance: u256,
        user_variable_debt: u256,
        user_total_debt: u256,
        actual_debt_to_liquidate: u256,
        actual_collateral_to_liquidate: u256,
        liquidation_bonus: u256,
        health_factor: u256,
        liquidation_protocol_fee_amount: u256,
        collateral_price_source: address,
        debt_price_source: address,
        collateral_a_token: address,
    }

    fun create_liquidation_call_local_vars(): LiquidationCallLocalVars {
        LiquidationCallLocalVars {
            user_collateral_balance: 0,
            user_variable_debt: 0,
            user_total_debt: 0,
            actual_debt_to_liquidate: 0,
            actual_collateral_to_liquidate: 0,
            liquidation_bonus: 0,
            health_factor: 0,
            liquidation_protocol_fee_amount: 0,
            collateral_price_source: @0x0,
            debt_price_source: @0x0,
            collateral_a_token: @0x0,
        }
    }

    struct ExecuteLiquidationCallParams has drop {
        reserves_count: u256,
        debt_to_cover: u256,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        receive_a_token: bool,
        user_emode_category: u8,
    }

    fun create_execute_liquidation_call_params(
        reserves_count: u256,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        receive_a_token: bool
    ): ExecuteLiquidationCallParams {
        ExecuteLiquidationCallParams {
            reserves_count,
            debt_to_cover,
            collateral_asset,
            debt_asset,
            user,
            receive_a_token,
            user_emode_category: (emode_logic::get_user_emode(user) as u8),
        }
    }

    public entry fun liquidation_call(
        account: &signer,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        receive_a_token: bool,
    ) {
        let reserves_count = pool::get_reserves_count();
        let account_address = signer::address_of(account);
        let vars = create_liquidation_call_local_vars();
        let params =
            create_execute_liquidation_call_params(reserves_count,
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover,
                receive_a_token);
        let collateral_reserve = pool::get_reserve_data(collateral_asset);
        let debt_reserve = pool::get_reserve_data(debt_asset);
        let user_config_map = pool::get_user_configuration(user);
        // update debt reserve state
        pool::update_state(debt_asset, &mut debt_reserve);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            emode_logic::get_emode_configuration(params.user_emode_category);
        let (_, _, _, _, health_factor, _) =
            generic_logic::calculate_user_account_data(reserves_count,
                &user_config_map,
                user,
                params.user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price);
        vars.health_factor = health_factor;

        let (user_variable_debt, user_total_debt, actual_debt_to_liquidate) =
            calculate_debt(&debt_reserve, &params, health_factor);
        vars.user_variable_debt = user_variable_debt;
        vars.user_total_debt = user_total_debt;
        vars.actual_debt_to_liquidate = actual_debt_to_liquidate;

        // validate liquidation call
        validation_logic::validate_liquidation_call(&user_config_map,
            &collateral_reserve,
            &debt_reserve,
            vars.user_total_debt,
            vars.health_factor);

        // get configuration data
        let (collateral_a_token, collateral_price_source, debt_price_source,
            liquidation_bonus) = get_configuration_data(&collateral_reserve, &params);

        vars.collateral_a_token = collateral_a_token;
        vars.collateral_price_source = collateral_price_source;
        vars.debt_price_source = debt_price_source;

        vars.user_collateral_balance = pool::scale_a_token_balance_of(params.user, collateral_a_token);

        let (actual_collateral_to_liquidate, actual_debt_to_liquidate,
            liquidation_protocol_fee_amount) =
            calculate_available_collateral_to_liquidate(
                &collateral_reserve,
                &debt_reserve,
                vars.collateral_price_source,
                vars.debt_price_source,
                vars.actual_debt_to_liquidate,
                vars.user_collateral_balance,
                liquidation_bonus);
        vars.actual_collateral_to_liquidate = actual_collateral_to_liquidate;
        vars.actual_debt_to_liquidate = actual_debt_to_liquidate;
        vars.liquidation_protocol_fee_amount = liquidation_protocol_fee_amount;

        if (vars.user_total_debt == vars.actual_debt_to_liquidate) {
            let debt_reserve_id = pool::get_reserve_id(&debt_reserve);
            user_config::set_borrowing(&mut user_config_map, (debt_reserve_id as u256),
                false);
            pool::set_user_configuration(params.user, user_config_map);
        };

        if (vars.actual_collateral_to_liquidate + vars.liquidation_protocol_fee_amount
            == vars.user_collateral_balance) {
            let collateral_reserve_id = pool::get_reserve_id(&collateral_reserve);
            user_config::set_using_as_collateral(&mut user_config_map, (
                    collateral_reserve_id as u256
                ), false);
            pool::set_user_configuration(params.user, user_config_map);
            event::emit(ReserveUsedAsCollateralDisabled {
                    reserve: params.collateral_asset,
                    user: params.user
                });
        };

        // burn debt tokens
        burn_debt_tokens(&debt_reserve, &params, &vars);

        // update pool interest rates
        pool::update_interest_rates(&mut debt_reserve, params.debt_asset, vars.actual_debt_to_liquidate,
            0);

        isolation_mode_logic::update_isolated_debt_if_isolated(&user_config_map, &debt_reserve, vars
            .actual_debt_to_liquidate);
        if (params.receive_a_token) {
            liquidate_a_tokens(account, &collateral_reserve, &params, &vars);
        } else {
            burn_collateral_a_tokens(account, collateral_reserve, &params, &vars)
        };

        if (vars.liquidation_protocol_fee_amount != 0) {
            let liquidity_index = pool::get_normalized_income_by_reserve_data(&collateral_reserve);
            let scaled_down_liquidation_protocol_fee =
                wad_ray_math::ray_div(vars.liquidation_protocol_fee_amount, liquidity_index);

            let scaled_down_user_balance = a_token_factory::scale_balance_of(params.user, vars.collateral_a_token);
            if (scaled_down_liquidation_protocol_fee > scaled_down_user_balance) {
                vars.liquidation_protocol_fee_amount = wad_ray_math::ray_mul(
                    scaled_down_user_balance, liquidity_index)
            };

            let underlying_asset_address =
                a_token_factory::get_underlying_asset_address(vars.collateral_a_token);
            let index = pool::get_reserve_normalized_income(underlying_asset_address);
            let a_token_treasury =
                a_token_factory::get_reserve_treasury_address(vars.collateral_a_token);
            a_token_factory::transfer_on_liquidation(
                params.user,
                a_token_treasury,
                vars.liquidation_protocol_fee_amount,
                index,
                vars.collateral_a_token
            );
        };

        // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
        let a_token_address = pool::get_reserve_a_token_address(&debt_reserve);
        underlying_token_factory::transfer_from(account_address,
            a_token_factory::get_token_account_address(a_token_address),
            (vars.actual_debt_to_liquidate as u64),
            debt_asset);

        a_token_factory::handle_repayment(account_address, params.user, vars.actual_debt_to_liquidate,
            a_token_address);

        event::emit(LiquidationCall {
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover: vars.actual_debt_to_liquidate,
                liquidated_collateral_amount: vars.actual_collateral_to_liquidate,
                liquidator: account_address,
                receive_a_token
            });
    }

    fun calculate_debt(
        reserve_data: &ReserveData, params: &ExecuteLiquidationCallParams, health_factor: u256
    ): (u256, u256, u256) {
        let user_variable_debt = pool::scale_variable_token_balance_of(
            params.user,
            pool::get_reserve_variable_debt_token_address(reserve_data)
        );
        let user_total_debt = user_variable_debt;

        let close_factor =
            if (health_factor > CLOSE_FACTOR_HF_THRESHOLD) { DEFAULT_LIQUIDATION_CLOSE_FACTOR }
            else { MAX_LIQUIDATION_CLOSE_FACTOR };
        let max_liquidatable_debt = math_utils::percent_mul(user_total_debt, close_factor);

        let actual_debt_to_liquidate =
            if (params.debt_to_cover > max_liquidatable_debt) { max_liquidatable_debt }
            else {
                params.debt_to_cover
            };
        (user_variable_debt, user_total_debt, actual_debt_to_liquidate)
    }

    fun get_configuration_data(
        reserve_data: &ReserveData, params: &ExecuteLiquidationCallParams
    ): (address, address, address, u256) {
        let collateral_a_token = pool::get_reserve_a_token_address(reserve_data);
        let collateral_config_map = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let liquidation_bonus =
            reserve_config::get_liquidation_bonus(&collateral_config_map);

        let collateral_price_source = params.collateral_asset;
        let debt_price_source = params.debt_asset;

        if (params.user_emode_category != 0) {
            let emode_category_data = emode_logic::get_emode_category_data(params.user_emode_category);
            let emode_price_source =
                emode_logic::get_emode_category_price_source(&emode_category_data);

            if (emode_logic::is_in_emode_category((params.user_emode_category as u256),
                    reserve_config::get_emode_category(&collateral_config_map))) {
                liquidation_bonus = (emode_logic::get_emode_category_liquidation_bonus(&emode_category_data) as u256);
                if (emode_price_source != @0x0) {
                    collateral_price_source = emode_price_source;
                };
            };

            // when in eMode, debt will always be in the same eMode category, can skip matching category check
            if (emode_price_source != @0x0) {
                debt_price_source = emode_price_source;
            };
        };
        (collateral_a_token, collateral_price_source, debt_price_source, liquidation_bonus)
    }

    fun liquidate_a_tokens(
        account: &signer,
        collateral_reserve: &ReserveData,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let account_address = signer::address_of(account);
        let liquidator_previous_a_token_balance = pool::scale_a_token_balance_of(account_address, vars.collateral_a_token);

        let underlying_asset_address =
            a_token_factory::get_underlying_asset_address(vars.collateral_a_token);
        let index = pool::get_reserve_normalized_income(underlying_asset_address);
        a_token_factory::transfer_on_liquidation(
            params.user,
            account_address,
            vars.actual_collateral_to_liquidate,
            index,
            vars.collateral_a_token
        );

        if (liquidator_previous_a_token_balance == 0) {
            let liquidator_config = pool::get_user_configuration(account_address);
            let reserve_config_map = pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
            if (pool_validation::validate_automatic_use_as_collateral(account_address, &liquidator_config, &reserve_config_map)) {
                user_config::set_using_as_collateral(&mut liquidator_config,
                    (pool::get_reserve_id(collateral_reserve) as u256), true);
                pool::set_user_configuration(account_address, liquidator_config);
                event::emit(ReserveUsedAsCollateralEnabled {
                        reserve: params.collateral_asset,
                        user: account_address
                    });
            };
        }
    }

    fun burn_debt_tokens(
        debt_reserve: &ReserveData,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        if (vars.user_variable_debt >= vars.actual_debt_to_liquidate) {
            variable_token_factory::burn(params.user,
                vars.actual_debt_to_liquidate,
                (pool::get_reserve_variable_borrow_index(debt_reserve) as u256),
                pool::get_reserve_variable_debt_token_address(debt_reserve))
        } else {
            if (vars.user_variable_debt != 0) {
                variable_token_factory::burn(params.user,
                    vars.user_variable_debt,
                    (pool::get_reserve_variable_borrow_index(debt_reserve) as u256),
                    pool::get_reserve_variable_debt_token_address(debt_reserve))
            }
        }
    }

    fun burn_collateral_a_tokens(
        account: &signer,
        collateral_reserve: ReserveData,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        // update pool state
        pool::update_state(params.collateral_asset, &mut collateral_reserve);

        // update pool interest rates
        pool::update_interest_rates(&mut collateral_reserve, params.collateral_asset, 0, vars
            .actual_collateral_to_liquidate);

        // Burn the equivalent amount of aToken, sending the underlying to the liquidator
        a_token_factory::burn(params.user,
            signer::address_of(account),
            vars.actual_collateral_to_liquidate,
            (pool::get_reserve_liquidity_index(&collateral_reserve) as u256),
            pool::get_reserve_a_token_address(&collateral_reserve),)
    }

    struct AvailableCollateralToLiquidateLocalVars has drop {
        collateral_price: u256,
        debt_asset_price: u256,
        max_collateral_to_liquidate: u256,
        base_collateral: u256,
        bonus_collateral: u256,
        debt_asset_decimals: u256,
        collateral_decimals: u256,
        collateral_asset_unit: u256,
        debt_asset_unit: u256,
        collateral_amount: u256,
        debt_amount_needed: u256,
        liquidation_protocol_fee_percentage: u256,
        liquidation_protocol_fee: u256,
    }

    fun create_available_collateral_to_liquidate_local_vars()
        : AvailableCollateralToLiquidateLocalVars {
        AvailableCollateralToLiquidateLocalVars {
            collateral_price: 0,
            debt_asset_price: 0,
            max_collateral_to_liquidate: 0,
            base_collateral: 0,
            bonus_collateral: 0,
            debt_asset_decimals: 0,
            collateral_decimals: 0,
            collateral_asset_unit: 0,
            debt_asset_unit: 0,
            collateral_amount: 0,
            debt_amount_needed: 0,
            liquidation_protocol_fee_percentage: 0,
            liquidation_protocol_fee: 0,
        }
    }

    fun calculate_available_collateral_to_liquidate(
        collateral_reserve: &ReserveData,
        debt_reserve: &ReserveData,
        collateral_asset: address,
        debt_asset: address,
        debt_to_cover: u256,
        user_collateral_balance: u256,
        liquidation_bonus: u256,
    ): (u256, u256, u256) {
        let vars = create_available_collateral_to_liquidate_local_vars();
        vars.collateral_price = oracle::get_asset_price(collateral_asset);
        vars.debt_asset_price = oracle::get_asset_price(debt_asset);

        let collateral_reserve_config =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        vars.collateral_decimals = reserve_config::get_decimals(&collateral_reserve_config);
        let debt_reserve_config = pool::get_reserve_configuration_by_reserve_data(
            debt_reserve);
        vars.debt_asset_decimals = reserve_config::get_decimals(&debt_reserve_config);

        vars.collateral_asset_unit = math_utils::pow(10, vars.collateral_decimals);
        vars.debt_asset_unit = math_utils::pow(10, vars.debt_asset_decimals);

        vars.liquidation_protocol_fee_percentage = reserve_config::get_liquidation_protocol_fee(
            &collateral_reserve_config);
        vars.base_collateral = (vars.debt_asset_price * debt_to_cover * vars.collateral_asset_unit)
            / (vars.collateral_price * vars.debt_asset_unit);

        vars.max_collateral_to_liquidate = math_utils::percent_mul(vars.base_collateral,
            liquidation_bonus);

        if (vars.max_collateral_to_liquidate > user_collateral_balance) {
            vars.collateral_amount = user_collateral_balance;
            vars.debt_amount_needed = math_utils::percent_div(
                ((vars.collateral_price * vars.collateral_amount * vars.debt_asset_unit) / (
                        vars.debt_asset_price * vars.collateral_asset_unit
                    )),
                liquidation_bonus);
        } else {
            vars.collateral_amount = vars.max_collateral_to_liquidate;
            vars.debt_amount_needed = debt_to_cover;
        };

        if (vars.liquidation_protocol_fee_percentage != 0) {
            vars.bonus_collateral = vars.collateral_amount - math_utils::percent_div(vars.collateral_amount,
                liquidation_bonus);
            vars.liquidation_protocol_fee = math_utils::percent_mul(vars.bonus_collateral, vars
                .liquidation_protocol_fee_percentage);
            (vars.collateral_amount - vars.liquidation_protocol_fee,
                vars.debt_amount_needed,
                vars.liquidation_protocol_fee)
        } else { (vars.collateral_amount, vars.debt_amount_needed, 0) }
    }
}
