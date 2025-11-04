/// @title liquidation_logic module
/// @author Aave
/// @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
module aave_pool::liquidation_logic {
    // imports
    use std::signer;
    use aptos_framework::event;
    use aptos_framework::object::Object;
    use aave_config::error_config;

    use aave_config::reserve_config;
    use aave_config::reserve_config::ReserveConfigurationMap;
    use aave_config::user_config;
    use aave_config::user_config::UserConfigurationMap;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_oracle::oracle;
    use aave_pool::pool_logic::ReserveCache;
    use aave_pool::pool_logic;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::generic_logic;
    use aave_pool::isolation_mode_logic;
    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::validation_logic;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::events::Self;

    // Constants
    /// @dev Default percentage of borrower's debt to be repaid in a liquidation.
    /// @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
    /// Expressed in bps, a value of 0.5e4 results in 50.00%
    /// 5 * 10 ** 3
    const DEFAULT_LIQUIDATION_CLOSE_FACTOR: u256 = 5000;

    /// @dev This constant represents below which health factor value it is possible to liquidate
    /// an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
    /// A value of 0.95e18 results in 0.95
    /// 0.95 * 10 ** 18
    const CLOSE_FACTOR_HF_THRESHOLD: u256 = 950000000000000000;

    /// @dev This constant represents a base value threshold.
    /// If the total collateral or debt on a position is below this threshold, the close factor is raised to 100%.
    /// @notice The default value assumes that the basePrice is usd denominated by 18 decimals and needs to be adjusted in a non USD-denominated pool.
    /// 2000 * 10 ** 18, since CL's price is always 18 decimals on Aptos.
    // @notice changed from 2000 to 500 * 10 ** 18, since gas fee is low on Aptos, liquidating lower threshold become profitable.
    const MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD: u256 = 500_000_000_000_000_000_000;

    /// @dev This constant represents the minimum amount of assets in base currency that need to be leftover after a liquidation, if not clearing a position completely.
    /// This parameter is inferred from MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD as the logic is dependent.
    /// Assuming a MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD of `n` a liquidation of `n+1` might result in `n/2` leftover which is assumed to be still economically liquidatable.
    /// This mechanic was introduced to ensure liquidators don't optimize gas by leaving some wei on the liquidation.
    const MIN_LEFTOVER_BASE: u256 = MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD / 2;

    // Events
    #[event]
    /// @notice Emitted when a deficit is created in the protocol
    /// @param user The address of the user whose debt created the deficit
    /// @param debt_asset The address of the debt asset
    /// @param amount_created The amount of deficit created
    struct DeficitCreated has store, drop {
        user: address,
        debt_asset: address,
        amount_created: u256
    }

    #[event]
    /// @dev Emitted when a borrower is liquidated.
    /// @param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
    /// @param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
    /// @param user The address of the borrower getting liquidated
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param liquidated_collateral_amount The amount of collateral received by the liquidator
    /// @param liquidator The address of the liquidator
    /// @param receive_a_token True if the liquidators wants to receive the collateral aTokens, `false` if he wants
    /// to receive the underlying collateral asset directly
    struct LiquidationCall has store, drop {
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        liquidated_collateral_amount: u256,
        liquidator: address,
        receive_a_token: bool
    }

    // Structs
    /// @notice Local variables for liquidation call function
    /// @dev Used to avoid stack too deep errors
    struct LiquidationCallLocalVars has drop {
        user_collateral_balance: u256,
        user_reserve_debt: u256,
        actual_debt_to_liquidate: u256,
        actual_collateral_to_liquidate: u256,
        liquidation_bonus: u256,
        health_factor: u256,
        liquidation_protocol_fee_amount: u256,
        total_collateral_in_base_currency: u256,
        total_debt_in_base_currency: u256,
        collateral_to_liquidate_in_base_currency: u256,
        user_reserve_debt_in_base_currency: u256,
        user_reserve_collateral_in_base_currency: u256,
        collateral_asset_price: u256,
        debt_asset_price: u256,
        collateral_asset_unit: u256,
        debt_asset_unit: u256,
        collateral_a_token: address
    }

    /// @notice Parameters for execute liquidation call function
    /// @dev Used to pass parameters to helper functions
    struct ExecuteLiquidationCallParams has drop {
        reserves_count: u256,
        debt_to_cover: u256,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        receive_a_token: bool,
        user_emode_category: u8
    }

    /// @notice Local variables for calculate available collateral to liquidate function
    /// @dev Used to avoid stack too deep errors
    struct AvailableCollateralToLiquidateLocalVars has drop {
        max_collateral_to_liquidate: u256,
        base_collateral: u256,
        bonus_collateral: u256,
        collateral_amount: u256,
        debt_amount_needed: u256,
        liquidation_protocol_fee_percentage: u256,
        liquidation_protocol_fee: u256,
        collateral_to_liquidate_in_base_currency: u256,
        collateral_asset_price: u256
    }

    // Private functions
    /// @notice Creates and initializes a new LiquidationCallLocalVars struct
    /// @dev Sets all numeric values to 0 and address to @0x0
    /// @return A new initialized LiquidationCallLocalVars struct
    fun create_liquidation_call_local_vars(): LiquidationCallLocalVars {
        LiquidationCallLocalVars {
            user_collateral_balance: 0,
            user_reserve_debt: 0,
            actual_debt_to_liquidate: 0,
            actual_collateral_to_liquidate: 0,
            liquidation_bonus: 0,
            health_factor: 0,
            liquidation_protocol_fee_amount: 0,
            total_collateral_in_base_currency: 0,
            total_debt_in_base_currency: 0,
            collateral_to_liquidate_in_base_currency: 0,
            user_reserve_debt_in_base_currency: 0,
            user_reserve_collateral_in_base_currency: 0,
            collateral_asset_price: 0,
            debt_asset_price: 0,
            collateral_asset_unit: 0,
            debt_asset_unit: 0,
            collateral_a_token: @0x0
        }
    }

    /// @notice Creates and initializes a new ExecuteLiquidationCallParams struct
    /// @dev Packages parameters needed for liquidation execution
    /// @param reserves_count The number of reserves in the protocol
    /// @param collateral_asset The address of the collateral asset
    /// @param debt_asset The address of the debt asset
    /// @param user The address of the user being liquidated
    /// @param debt_to_cover The amount of debt to cover
    /// @param receive_a_token Whether to receive aTokens instead of underlying
    /// @return A new initialized ExecuteLiquidationCallParams struct
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
            user_emode_category: emode_logic::get_user_emode(user)
        }
    }

    /// @notice Creates and initializes a new AvailableCollateralToLiquidateLocalVars struct
    /// @dev Sets all numeric values to 0
    /// @return A new initialized AvailableCollateralToLiquidateLocalVars struct
    fun create_available_collateral_to_liquidate_local_vars()
        : AvailableCollateralToLiquidateLocalVars {
        AvailableCollateralToLiquidateLocalVars {
            max_collateral_to_liquidate: 0,
            base_collateral: 0,
            bonus_collateral: 0,
            collateral_amount: 0,
            debt_amount_needed: 0,
            liquidation_protocol_fee_percentage: 0,
            liquidation_protocol_fee: 0,
            collateral_to_liquidate_in_base_currency: 0,
            collateral_asset_price: 0
        }
    }

    /// @notice Burns the collateral aTokens and transfers the underlying to the liquidator.
    /// @dev   The function also updates the state and the interest rate of the collateral reserve.
    /// @param account_address The liquidator account address
    /// @param collateral_reserve_data The data of the collateral reserve
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param vars The liquidation_call() function local vars
    fun burn_collateral_a_tokens(
        account_address: address,
        collateral_reserve_data: Object<ReserveData>,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let collateral_reserve_cache = pool_logic::cache(collateral_reserve_data);
        // update pool state
        pool_logic::update_state(collateral_reserve_data, &mut collateral_reserve_cache);

        // update pool interest rates
        pool_logic::update_interest_rates_and_virtual_balance(
            collateral_reserve_data,
            &collateral_reserve_cache,
            params.collateral_asset,
            0,
            vars.actual_collateral_to_liquidate
        );

        // Burn the equivalent amount of aToken, sending the underlying to the liquidator
        a_token_factory::burn(
            params.user,
            account_address,
            vars.actual_collateral_to_liquidate,
            pool_logic::get_next_liquidity_index(&collateral_reserve_cache),
            pool_logic::get_a_token_address(&collateral_reserve_cache)
        )
    }

    /// @notice Liquidates the user aTokens by transferring them to the liquidator.
    /// @dev The function also checks the state of the liquidator and activates the aToken as collateral
    /// as in standard transfers if the isolation mode constraints are respected.
    /// @param account_address The liquidator account address
    /// @param collateral_reserve_data The data of the collateral reserve
    /// @param params The additional parameters needed to execute the liquidation function
    /// @param vars The liquidation_call() function local vars
    fun liquidate_a_tokens(
        account_address: address,
        collateral_reserve_data: Object<ReserveData>,
        params: &ExecuteLiquidationCallParams,
        vars: &LiquidationCallLocalVars
    ) {
        let liquidator_previous_a_token_balance =
            a_token_factory::balance_of(account_address, vars.collateral_a_token);

        let underlying_asset =
            a_token_factory::get_underlying_asset_address(vars.collateral_a_token);
        let index = pool::get_reserve_normalized_income(underlying_asset);

        a_token_factory::transfer_on_liquidation(
            params.user,
            account_address,
            vars.actual_collateral_to_liquidate,
            index,
            vars.collateral_a_token,
            true
        );

        // For the special case of account_address == params.user (self-liquidation) the liquidator_previous_a_token_balance
        // will not yet be 0, but the liquidation will result in collateral being fully liquidated and then resupplied.
        if (liquidator_previous_a_token_balance == 0
            || (
                account_address == params.user
                    && vars.actual_collateral_to_liquidate
                        + vars.liquidation_protocol_fee_amount
                        == vars.user_collateral_balance
            )) {
            let liquidator_config = pool::get_user_configuration(account_address);
            let reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(collateral_reserve_data);
            if (validation_logic::validate_automatic_use_as_collateral(
                &liquidator_config, &reserve_config_map
            )) {
                user_config::set_using_as_collateral(
                    &mut liquidator_config,
                    (pool::get_reserve_id(collateral_reserve_data) as u256),
                    true
                );
                pool::set_user_configuration(account_address, liquidator_config);
                events::emit_reserve_used_as_collateral_enabled(
                    params.collateral_asset, account_address
                );
            };
        }
    }

    /// @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator
    /// or the entire debt if the user is in a bad debt scenario.
    /// @param debt_reserve_cache The cached debt reserve parameters
    /// @param debt_reserve_data The storage pointer of the debt reserve parameters
    /// @param user_config The pointer of the user configuration
    /// @param user The user address
    /// @param debt_asset The debt asset address
    /// @param user_reserve_debt The user reserver debt amount
    /// @param actual_debt_to_liquidate The actual debt to liquidate
    /// @param has_no_collateral_left The flag representing, whether the user will have no collateral left after liquidation
    fun burn_debt_tokens(
        debt_reserve_cache: &mut ReserveCache,
        debt_reserve_data: Object<ReserveData>,
        user_config: &mut UserConfigurationMap,
        user: address,
        debt_asset: address,
        user_reserve_debt: u256,
        actual_debt_to_liquidate: u256,
        has_no_collateral_left: bool
    ) {
        let variable_debt_token_address =
            pool_logic::get_variable_debt_token_address(debt_reserve_cache);
        // Prior v3.1, there were cases where, after liquidation, the `is_borrowing` flag was left on
        // even after the user debt was fully repaid, so to avoid this function reverting in the `burn_scaled`
        // (see token_base contract), we check for any debt remaining.
        if (user_reserve_debt != 0) {
            let next_variable_borrow_index =
                pool_logic::get_next_variable_borrow_index(debt_reserve_cache);
            variable_debt_token_factory::burn(
                user,
                if (has_no_collateral_left) {
                    user_reserve_debt
                } else {
                    actual_debt_to_liquidate
                },
                next_variable_borrow_index,
                variable_debt_token_address
            );
            let next_scaled_variable_debt =
                variable_debt_token_factory::scaled_total_supply(
                    variable_debt_token_address
                );
            pool_logic::set_next_scaled_variable_debt(
                debt_reserve_cache, next_scaled_variable_debt
            );
        };

        let outstanding_debt = user_reserve_debt - actual_debt_to_liquidate;
        if (has_no_collateral_left && outstanding_debt != 0) {
            // Special handling of GHO. Implicitly assuming that virtual acc !active == GHO, which is true.
            // Scenario 1: The amount of GHO debt being liquidated is greater or equal to the GHO accrued interest.
            //             In this case, the outer handleRepayment will clear the storage and all additional operations can be skipped.
            // Scenario 2: The amount of debt being liquidated is lower than the GHO accrued interest.
            //             In this case handleRepayment will be called with the difference required to clear the storage.
            //             If we assume a liquidation of n debt, and m accrued interest, the difference is k = m-n.
            //             Therefore we call handleRepayment(k).
            //             Additionally, as the dao (GHO issuer) accepts the loss on interest on the bad debt,
            //             we need to discount k from the deficit (via reducing outstandingDebt).
            // Note: If a non GHO asset is liquidated and GHO bad debt is created in the process, Scenario 2 applies with n = 0.

            // update debt_reserve deficit
            let deficit =
                pool::get_reserve_deficit(debt_reserve_data)
                    + (outstanding_debt as u128);
            pool::set_reserve_deficit(debt_reserve_data, deficit);
            event::emit(
                DeficitCreated { user, debt_asset, amount_created: outstanding_debt }
            );

            outstanding_debt = 0;
        };

        if (outstanding_debt == 0) {
            let debt_reserve_id = pool::get_reserve_id(debt_reserve_data);
            user_config::set_borrowing(user_config, (debt_reserve_id as u256), false);
            pool::set_user_configuration(user, *user_config);
        };

        pool_logic::update_interest_rates_and_virtual_balance(
            debt_reserve_data,
            debt_reserve_cache,
            debt_asset,
            actual_debt_to_liquidate,
            0
        );
    }

    /// @notice Calculates how much of a specific collateral can be liquidated, given
    /// a certain amount of debt asset.
    /// @dev This function needs to be called after all the checks to validate the liquidation have been performed,
    ///   otherwise it might fail.
    /// @param collateral_reserve_config The data of the collateral reserve
    /// @param collateral_asset_price The price of the underlying asset used as collateral
    /// @param collateral_asset_unit The asset units of the collateral
    /// @param debt_asset_price The price of the underlying borrowed asset to be repaid with the liquidation
    /// @param debt_asset_unit The asset units of the debt
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param user_collateral_balance The collateral balance for the specific `collateralAsset` of the user being liquidated
    /// @param liquidation_bonus The collateral bonus percentage to receive as result of the liquidation
    /// @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
    /// @return The amount to repay with the liquidation
    /// @return The fee taken from the liquidation bonus amount to be paid to the protocol
    /// @return The collateral amount to liquidate in the base currency used by the price feed
    fun calculate_available_collateral_to_liquidate(
        collateral_reserve_config: &ReserveConfigurationMap,
        collateral_asset_price: u256,
        collateral_asset_unit: u256,
        debt_asset_price: u256,
        debt_asset_unit: u256,
        debt_to_cover: u256,
        user_collateral_balance: u256,
        liquidation_bonus: u256
    ): (u256, u256, u256, u256) {
        let vars = create_available_collateral_to_liquidate_local_vars();
        vars.collateral_asset_price = collateral_asset_price;
        vars.liquidation_protocol_fee_percentage = reserve_config::get_liquidation_protocol_fee(
            collateral_reserve_config
        );

        // This is the base collateral to liquidate based on the given debt to cover
        vars.base_collateral =
            ((debt_asset_price * debt_to_cover * collateral_asset_unit))
                / (vars.collateral_asset_price * debt_asset_unit);

        vars.max_collateral_to_liquidate = math_utils::percent_mul(
            vars.base_collateral, liquidation_bonus
        );

        if (vars.max_collateral_to_liquidate > user_collateral_balance) {
            vars.collateral_amount = user_collateral_balance;
            vars.debt_amount_needed = math_utils::percent_div(
                ((vars.collateral_asset_price * vars.collateral_amount
                    * debt_asset_unit)
                    / (debt_asset_price * collateral_asset_unit)),
                liquidation_bonus
            );
        } else {
            vars.collateral_amount = vars.max_collateral_to_liquidate;
            vars.debt_amount_needed = debt_to_cover;
        };

        vars.collateral_to_liquidate_in_base_currency =
            (vars.collateral_amount * collateral_asset_price) / collateral_asset_unit;

        if (vars.liquidation_protocol_fee_percentage != 0) {
            vars.bonus_collateral =
                vars.collateral_amount
                    - math_utils::percent_div(vars.collateral_amount, liquidation_bonus);

            vars.liquidation_protocol_fee = math_utils::percent_mul(
                vars.bonus_collateral, vars.liquidation_protocol_fee_percentage
            );
            vars.collateral_amount = vars.collateral_amount
                - vars.liquidation_protocol_fee;
        };

        (
            vars.collateral_amount,
            vars.debt_amount_needed,
            vars.liquidation_protocol_fee,
            vars.collateral_to_liquidate_in_base_currency
        )
    }

    /// @notice Remove a user's bad debt by burning debt tokens.
    /// @dev This function iterates through all active reserves where the user has a debt position,
    /// updates their state, and performs the necessary burn.
    /// @param user_config_map The user configuration
    /// @param reserves_count The total number of valid reserves
    /// @param user The user from which the debt will be burned.
    fun burn_bad_debt(
        user_config_map: &mut UserConfigurationMap, reserves_count: u256, user: address
    ) {
        for (i in 0..reserves_count) {
            if (!user_config::is_borrowing(user_config_map, i)) {
                continue
            };

            let reserve_address = pool::get_reserve_address_by_id(i);
            if (reserve_address == @0x0) {
                continue
            };

            let current_reserve = pool::get_reserve_data(reserve_address);
            let current_reserve_cache = pool_logic::cache(current_reserve);
            let current_reserve_config =
                pool::get_reserve_configuration_by_reserve_data(current_reserve);
            if (!reserve_config::get_active(&current_reserve_config)) {
                continue
            };

            pool_logic::update_state(current_reserve, &mut current_reserve_cache);

            let user_reserve_debt =
                variable_debt_token_factory::balance_of(
                    user,
                    pool_logic::get_variable_debt_token_address(&current_reserve_cache)
                );

            burn_debt_tokens(
                &mut current_reserve_cache,
                current_reserve,
                user_config_map,
                user,
                reserve_address,
                user_reserve_debt,
                0,
                true
            );
        }
    }

    // Public entry functions
    /// @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
    //  covers `debt_to_cover` amount of debt of the user getting liquidated, and receives
    //  a proportional amount of the `collateral_asset` plus a bonus to cover market risk
    /// @dev Emits the `LiquidationCall()` event, and the `DeficitCreated()` event if the liquidation results in bad debt
    /// @param account The account signer of the caller
    /// @param collateral_asset The address of the underlying asset used as collateral, to receive as result of the liquidation
    /// @param debt_asset The address of the underlying borrowed asset to be repaid with the liquidation
    /// @param user The address of the borrower getting liquidated
    /// @param debt_to_cover The debt amount of borrowed `asset` the liquidator wants to cover
    /// @param receive_a_token True if the liquidators wants to receive the collateral aTokens, `false` if he wants
    /// to receive the underlying collateral asset directly
    public entry fun liquidation_call(
        account: &signer,
        collateral_asset: address,
        debt_asset: address,
        user: address,
        debt_to_cover: u256,
        receive_a_token: bool
    ) {
        let reserves_count = pool::number_of_active_and_dropped_reserves();
        let account_address = signer::address_of(account);
        let vars = create_liquidation_call_local_vars();
        let params =
            create_execute_liquidation_call_params(
                reserves_count,
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover,
                receive_a_token
            );
        let collateral_reserve = pool::get_reserve_data(params.collateral_asset);
        let debt_reserve = pool::get_reserve_data(params.debt_asset);
        let debt_reserve_cache = pool_logic::cache(debt_reserve);
        // update debt reserve state
        pool_logic::update_state(debt_reserve, &mut debt_reserve_cache);

        let user_config_map = pool::get_user_configuration(params.user);
        let (emode_ltv, emode_liq_threshold) =
            emode_logic::get_emode_configuration(params.user_emode_category);

        let (
            total_collateral_in_base_currency,
            total_debt_in_base_currency,
            _,
            _,
            health_factor,
            _
        ) =
            generic_logic::calculate_user_account_data(
                &user_config_map,
                params.reserves_count,
                params.user,
                params.user_emode_category,
                emode_ltv,
                emode_liq_threshold
            );
        vars.total_collateral_in_base_currency = total_collateral_in_base_currency;
        vars.total_debt_in_base_currency = total_debt_in_base_currency;
        vars.health_factor = health_factor;

        vars.collateral_a_token = pool::get_reserve_a_token_address(collateral_reserve);
        vars.user_collateral_balance = a_token_factory::balance_of(
            params.user, vars.collateral_a_token
        );
        let debt_reserve_variable_debt_token_address =
            pool_logic::get_variable_debt_token_address(&debt_reserve_cache);
        vars.user_reserve_debt = variable_debt_token_factory::balance_of(
            params.user,
            debt_reserve_variable_debt_token_address
        );

        // validate liquidation call
        validation_logic::validate_liquidation_call(
            &user_config_map,
            collateral_reserve,
            debt_reserve,
            &debt_reserve_cache,
            vars.user_reserve_debt,
            vars.health_factor
        );

        let collateral_reserve_config =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        if (params.user_emode_category != 0
            && emode_logic::is_in_emode_category(
                params.user_emode_category,
                (reserve_config::get_emode_category(&collateral_reserve_config) as u8)
            )) {
            vars.liquidation_bonus =
                (
                    emode_logic::get_emode_e_mode_liquidation_bonus(
                        params.user_emode_category
                    ) as u256
                );
        } else {
            vars.liquidation_bonus = reserve_config::get_liquidation_bonus(
                &collateral_reserve_config
            )
        };

        vars.collateral_asset_price = oracle::get_asset_price(params.collateral_asset);
        vars.debt_asset_price = oracle::get_asset_price(params.debt_asset);

        let debt_reserve_cache_config =
            pool_logic::get_reserve_cache_configuration(&debt_reserve_cache);
        vars.collateral_asset_unit = math_utils::pow(
            10, reserve_config::get_decimals(&collateral_reserve_config)
        );
        vars.debt_asset_unit = math_utils::pow(
            10, reserve_config::get_decimals(&debt_reserve_cache_config)
        );

        vars.user_reserve_debt_in_base_currency = math_utils::ceil_div(
            vars.user_reserve_debt * vars.debt_asset_price,
            vars.debt_asset_unit
        );

        vars.user_reserve_collateral_in_base_currency =
            (vars.user_collateral_balance * vars.collateral_asset_price)
                / vars.collateral_asset_unit;

        // by default whole debt in the reserve could be liquidated
        let max_liquidatable_debt = vars.user_reserve_debt;
        // but if debt and collateral is above or equal MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
        // and health factor is above CLOSE_FACTOR_HF_THRESHOLD this amount may be adjusted
        if (vars.user_reserve_collateral_in_base_currency
            >= MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
            && vars.user_reserve_debt_in_base_currency
                >= MIN_BASE_MAX_CLOSE_FACTOR_THRESHOLD
            && vars.health_factor > CLOSE_FACTOR_HF_THRESHOLD) {
            let total_default_liquidatable_debt_in_base_currency =
                math_utils::percent_mul(
                    vars.total_debt_in_base_currency,
                    DEFAULT_LIQUIDATION_CLOSE_FACTOR
                );
            // if the debt is more then DEFAULT_LIQUIDATION_CLOSE_FACTOR % of the whole,
            // then we CAN liquidate only up to DEFAULT_LIQUIDATION_CLOSE_FACTOR %
            if (vars.user_reserve_debt_in_base_currency
                > total_default_liquidatable_debt_in_base_currency) {
                max_liquidatable_debt =
                    (
                        total_default_liquidatable_debt_in_base_currency
                            * vars.debt_asset_unit
                    ) / vars.debt_asset_price;
            }
        };

        vars.actual_debt_to_liquidate =
            if (params.debt_to_cover > max_liquidatable_debt) {
                max_liquidatable_debt
            } else {
                params.debt_to_cover
            };

        let (
            actual_collateral_to_liquidate,
            actual_debt_to_liquidate,
            liquidation_protocol_fee_amount,
            collateral_to_liquidate_in_base_currency
        ) =
            calculate_available_collateral_to_liquidate(
                &collateral_reserve_config,
                vars.collateral_asset_price,
                vars.collateral_asset_unit,
                vars.debt_asset_price,
                vars.debt_asset_unit,
                vars.actual_debt_to_liquidate,
                vars.user_collateral_balance,
                vars.liquidation_bonus
            );
        vars.actual_collateral_to_liquidate = actual_collateral_to_liquidate;
        vars.actual_debt_to_liquidate = actual_debt_to_liquidate;
        vars.liquidation_protocol_fee_amount = liquidation_protocol_fee_amount;
        vars.collateral_to_liquidate_in_base_currency =
            collateral_to_liquidate_in_base_currency;

        // to prevent accumulation of dust on the protocol, it is enforced that you either
        // 1. liquidate all debt
        // 2. liquidate all collateral
        // 3. leave more than MIN_LEFTOVER_BASE of collateral & debt
        if (vars.actual_debt_to_liquidate < vars.user_reserve_debt
            && vars.actual_collateral_to_liquidate
                + vars.liquidation_protocol_fee_amount < vars.user_collateral_balance) {
            let is_debt_more_than_leftover_threshold =
                ((vars.user_reserve_debt - vars.actual_debt_to_liquidate)
                    * vars.debt_asset_price) / vars.debt_asset_unit
                    >= MIN_LEFTOVER_BASE;
            let is_collateral_more_than_leftover_threshold =
                (
                    (
                        vars.user_collateral_balance
                            - vars.actual_collateral_to_liquidate
                            - vars.liquidation_protocol_fee_amount
                    ) * vars.collateral_asset_price
                ) / vars.collateral_asset_unit >= MIN_LEFTOVER_BASE;

            assert!(
                is_debt_more_than_leftover_threshold
                    && is_collateral_more_than_leftover_threshold,
                error_config::get_emust_not_leave_dust()
            )
        };

        // If the collateral being liquidated is equal to the user balance,
        // we set the asset as not being used as collateral anymore
        if (vars.actual_collateral_to_liquidate + vars.liquidation_protocol_fee_amount
            == vars.user_collateral_balance) {
            user_config::set_using_as_collateral(
                &mut user_config_map,
                (pool::get_reserve_id(collateral_reserve) as u256),
                false
            );
            pool::set_user_configuration(params.user, user_config_map);
            events::emit_reserve_used_as_collateral_disabled(
                params.collateral_asset, params.user
            );
        };

        let has_no_collateral_left =
            vars.total_collateral_in_base_currency
                == vars.collateral_to_liquidate_in_base_currency;
        // burn debt tokens
        burn_debt_tokens(
            &mut debt_reserve_cache,
            debt_reserve,
            &mut user_config_map,
            params.user,
            params.debt_asset,
            vars.user_reserve_debt,
            vars.actual_debt_to_liquidate,
            has_no_collateral_left
        );

        // An asset can only be ceiled if it has no supply or if it was not a collateral previously.
        // Therefore we can be sure that no inconsistent state can be reached in which a user has multiple collaterals, with one being ceiled.
        // This allows for the implicit assumption that: if the asset was a collateral & the asset was ceiled, the user must have been in isolation.
        if (reserve_config::get_debt_ceiling(&collateral_reserve_config) != 0) {
            // isolation_mode_total_debt only discounts `actual_debt_to_liquidate`, not the fully burned amount in case of deficit creation.
            // This is by design as otherwise the debt ceiling would render ineffective if a collateral asset faces bad debt events.
            // The governance can decide the raise the ceiling to discount manifested deficit.
            isolation_mode_logic::update_isolated_debt(
                &debt_reserve_cache,
                vars.actual_debt_to_liquidate,
                params.collateral_asset
            )
        };

        let collateral_reserve = pool::get_reserve_data(params.collateral_asset);
        if (params.receive_a_token) {
            liquidate_a_tokens(
                account_address,
                collateral_reserve,
                &params,
                &vars
            );
        } else {
            burn_collateral_a_tokens(
                account_address,
                collateral_reserve,
                &params,
                &vars
            )
        };

        let user_config_map = pool::get_user_configuration(params.user);

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidation_protocol_fee_amount != 0) {
            let liquidity_index =
                pool::get_normalized_income_by_reserve_data(collateral_reserve);
            let scaled_down_liquidation_protocol_fee =
                wad_ray_math::ray_div(
                    vars.liquidation_protocol_fee_amount,
                    liquidity_index
                );

            let scaled_down_user_balance =
                a_token_factory::scaled_balance_of(params.user, vars.collateral_a_token);
            // To avoid trying to send more aTokens than available on balance, due to 1 wei imprecision
            if (scaled_down_liquidation_protocol_fee > scaled_down_user_balance) {
                vars.liquidation_protocol_fee_amount = wad_ray_math::ray_mul(
                    scaled_down_user_balance, liquidity_index
                )
            };

            let a_token_treasury =
                a_token_factory::get_reserve_treasury_address(vars.collateral_a_token);
            a_token_factory::transfer_on_liquidation(
                params.user,
                a_token_treasury,
                vars.liquidation_protocol_fee_amount,
                liquidity_index,
                vars.collateral_a_token,
                false
            );
        };

        // burn bad debt if necessary
        // Each additional debt asset already adds around ~75k gas to the liquidation.
        // To keep the liquidation gas under control, 0 usd collateral positions are not touched, as there is no immediate benefit in burning or transferring to treasury.
        if (has_no_collateral_left && user_config::is_borrowing_any(&user_config_map)) {
            burn_bad_debt(&mut user_config_map, params.reserves_count, params.user);
        };

        // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
        let debt_reserve_a_token_address =
            pool_logic::get_a_token_address(&debt_reserve_cache);
        fungible_asset_manager::transfer(
            account,
            a_token_factory::get_token_account_address(debt_reserve_a_token_address),
            (vars.actual_debt_to_liquidate as u64),
            debt_asset
        );

        a_token_factory::handle_repayment(
            account_address,
            params.user,
            vars.actual_debt_to_liquidate,
            debt_reserve_a_token_address
        );

        event::emit(
            LiquidationCall {
                collateral_asset,
                debt_asset,
                user,
                debt_to_cover: vars.actual_debt_to_liquidate,
                liquidated_collateral_amount: vars.actual_collateral_to_liquidate,
                liquidator: account_address,
                receive_a_token
            }
        );
    }
}
