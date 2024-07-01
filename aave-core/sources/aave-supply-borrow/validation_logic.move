module aave_pool::validation_logic {
    use std::signer;
    use std::vector;

    use aave_config::error as error_config;
    use aave_config::reserve as reserve_config;
    use aave_config::user::{Self as user_config, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle;
    use aave_mock_oracle::oracle_sentinel;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::generic_logic;
    use aave_pool::pool::{Self, ReserveData};
    use aave_pool::variable_token_factory;

    // Flashloan Validate
    public fun validate_flashloan_complex(
        reserve_data: &vector<ReserveData>, assets: &vector<address>, amounts: &vector<u256>,
    ) {
        assert!(vector::length(assets) == vector::length(amounts),
            error_config::get_einconsistent_flashloan_params());
        for (i in 0..vector::length(assets)) {
            validate_flashloan_simple(vector::borrow(reserve_data, i));
        }
    }

    // Simple Flashloan Validation
    public fun validate_flashloan_simple(reserve_data: &ReserveData) {
        let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(is_active, error_config::get_ereserve_inactive());
        let is_flashloan_enabled = reserve_config::get_flash_loan_enabled(&reserve_configuration);
        assert!(is_flashloan_enabled, error_config::get_eflashloan_disabled());
    }

    // Supply Validate
    public fun validate_supply(reserve_data: &ReserveData, amount: u256) {
        assert!(amount != 0, error_config::get_einvalid_amount());
        let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, is_frozen, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(!is_frozen, error_config::get_ereserve_frozen());

        let supply_cap = reserve_config::get_supply_cap(&reserve_configuration);
        let a_token_supply = a_token_factory::scale_total_supply(
            pool::get_reserve_a_token_address(reserve_data)
        );

        let accrued_to_treasury_liquidity =
            wad_ray_math::ray_mul((a_token_supply + pool::get_reserve_accrued_to_treasury(reserve_data)),
                (pool::get_reserve_liquidity_index(reserve_data) as u256));
        let total_supply = accrued_to_treasury_liquidity + amount;
        let max_supply =
            supply_cap * (math_utils::pow(10,
                    reserve_config::get_decimals(&reserve_configuration)));

        assert!(supply_cap == 0 || total_supply <= max_supply,
            error_config::get_esupply_cap_exceeded());
    }

    public fun validate_withdraw(
        reserve_data: &ReserveData, amount: u256, user_balance: u256
    ) {
        assert!(amount != 0, error_config::get_einvalid_amount());
        assert!(amount <= user_balance,
            error_config::get_enot_enough_available_user_balance());
        let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
    }

    public fun validate_transfer(reserve_data: &ReserveData) {
        let reserve_config_map = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        assert!(!reserve_config::get_paused(&reserve_config_map),
            error_config::get_ereserve_paused())
    }

    public fun validate_set_use_reserve_as_collateral(
        reserve_data: &ReserveData, user_balance: u256
    ) {
        assert!(user_balance != 0, error_config::get_eunderlying_balance_zero());
        let reserve_configuration_map = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration_map);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
    }

    /**
    * ----------------------------
    * Borrow Validate
    * ----------------------------
    */

    struct ValidateBorrowLocalVars has drop {
        current_ltv: u256,
        collateral_needed_in_base_currency: u256,
        user_collateral_in_base_currency: u256,
        user_debt_in_base_currency: u256,
        available_liquidity: u256,
        health_factor: u256,
        total_debt: u256,
        total_supply_variable_debt: u256,
        reserve_decimals: u256,
        borrow_cap: u256,
        amount_in_base_currency: u256,
        asset_unit: u256,
        emode_price_source: address,
        siloed_borrowing_address: address,
        is_active: bool,
        is_frozen: bool,
        is_paused: bool,
        borrowing_enabled: bool,
        siloed_borrowing_enabled: bool,
    }

    fun create_validate_borrow_local_vars(): ValidateBorrowLocalVars {
        ValidateBorrowLocalVars {
            current_ltv: 0,
            collateral_needed_in_base_currency: 0,
            user_collateral_in_base_currency: 0,
            user_debt_in_base_currency: 0,
            available_liquidity: 0,
            health_factor: 0,
            total_debt: 0,
            total_supply_variable_debt: 0,
            reserve_decimals: 0,
            borrow_cap: 0,
            amount_in_base_currency: 0,
            asset_unit: 0,
            emode_price_source: @0x0,
            siloed_borrowing_address: @0x0,
            is_active: false,
            is_frozen: false,
            is_paused: false,
            borrowing_enabled: false,
            siloed_borrowing_enabled: false,
        }
    }

    public fun validate_borrow(
        reserve_data: &ReserveData,
        user_config_map: &UserConfigurationMap,
        asset: address,
        user_address: address,
        amount: u256,
        interest_rate_mode: u8,
        reserves_count: u256,
        user_emode_category: u8,
        isolation_mode_active: bool,
        isolation_mode_collateral_address: address,
        isolation_mode_debt_ceiling: u256,
    ) {
        assert!(amount != 0, error_config::get_einvalid_amount());
        let vars = create_validate_borrow_local_vars();

        let reserve_configuration_map = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, is_frozen, borrowing_enabled, is_paused) =
            reserve_config::get_flags(&reserve_configuration_map);

        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());
        assert!(!is_frozen, error_config::get_ereserve_frozen());
        assert!(borrowing_enabled, error_config::get_eborrowing_not_enabled());

        assert!(oracle_sentinel::is_borrow_allowed(),
            error_config::get_eprice_oracle_sentinel_check_failed());

        assert!(interest_rate_mode
            == user_config::get_interest_rate_mode_variable(),
            error_config::get_einvalid_interest_rate_mode_selected());

        vars.reserve_decimals = reserve_config::get_decimals(&reserve_configuration_map);
        vars.borrow_cap = reserve_config::get_borrow_cap(&reserve_configuration_map);

        vars.asset_unit = math_utils::pow(10, vars.reserve_decimals);

        if (vars.borrow_cap != 0) {
            let total_supply_variable_debt = variable_token_factory::scale_total_supply(
                    pool::get_reserve_variable_debt_token_address(reserve_data)
            );
            vars.total_supply_variable_debt = wad_ray_math::ray_mul(
                total_supply_variable_debt, (pool::get_reserve_variable_borrow_index(
                        reserve_data) as u256));
            vars.total_debt = vars.total_supply_variable_debt + amount;

            assert!(vars.total_debt <= vars.borrow_cap * vars.asset_unit,
                error_config::get_eborrow_cap_exceeded())
        };

        if (isolation_mode_active) {
            assert!(reserve_config::get_borrowable_in_isolation(&reserve_configuration_map),
                error_config::get_easset_not_borrowable_in_isolation());

            let mode_collateral_reserve_data = pool::get_reserve_data(
                isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                (pool::get_reserve_isolation_mode_total_debt(&mode_collateral_reserve_data) as u256);

            let total_debt =
                isolation_mode_total_debt + (amount / math_utils::pow(10,
                        (vars.reserve_decimals - reserve_config::get_debt_ceiling_decimals())));
            assert!(total_debt <= isolation_mode_debt_ceiling,
                error_config::get_edebt_ceiling_exceeded());
        };

        if (user_emode_category != 0) {
            assert!(reserve_config::get_emode_category(&reserve_configuration_map)
                == (user_emode_category as u256),
                error_config::get_einconsistent_emode_category());
            let emode_category_data = emode_logic::get_emode_category_data(user_emode_category);
            vars.emode_price_source = emode_logic::get_emode_category_price_source(&emode_category_data)
        };
        let (emode_ltv, emode_liq_threshold, emode_asset_price) =
            emode_logic::get_emode_configuration(user_emode_category);

        let (user_collateral_in_base_currency, user_debt_in_base_currency, current_ltv, _,
            health_factor, _) =
            generic_logic::calculate_user_account_data(reserves_count,
                user_config_map,
                user_address,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price);

        vars.user_collateral_in_base_currency = user_collateral_in_base_currency;
        vars.user_debt_in_base_currency = user_debt_in_base_currency;
        vars.current_ltv = current_ltv;
        vars.health_factor = health_factor;
        assert!(vars.user_collateral_in_base_currency != 0,
            error_config::get_ecollateral_balance_is_zero());
        assert!(vars.current_ltv != 0, error_config::get_eltv_validation_failed());
        assert!(
            vars.health_factor > user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_lower_than_liquidation_threshold());

        let asset_address =
            if (vars.emode_price_source != @0x0) {
                vars.emode_price_source
            } else { asset };
        vars.amount_in_base_currency = oracle::get_asset_price(asset_address) * amount;

        vars.amount_in_base_currency = vars.amount_in_base_currency / vars.asset_unit;

        vars.collateral_needed_in_base_currency = math_utils::percent_div(
            (vars.user_debt_in_base_currency + vars.amount_in_base_currency), vars.current_ltv);
        assert!(vars.collateral_needed_in_base_currency <= vars.user_collateral_in_base_currency,
            error_config::get_ecollateral_cannot_cover_new_borrow());

        if (user_config::is_borrowing_any(user_config_map)) {
            let (siloed_borrowing_enabled, siloed_borrowing_address) = pool::get_siloed_borrowing_state(
                user_address);
            vars.siloed_borrowing_enabled = siloed_borrowing_enabled;
            vars.siloed_borrowing_address = siloed_borrowing_address;
            if (vars.siloed_borrowing_enabled) {
                assert!(vars.siloed_borrowing_address == asset,
                    error_config::get_esiloed_borrowing_violation())
            } else {
                assert!(!reserve_config::get_siloed_borrowing(&reserve_configuration_map),
                    error_config::get_esiloed_borrowing_violation())
            }
        }
    }

    // Repay Validate
    public fun validate_repay(
        account: &signer,
        reserve_data: &ReserveData,
        amount_sent: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
        variable_debt: u256
    ) {
        let account_address = signer::address_of(account);
        assert!(amount_sent != 0, error_config::get_einvalid_amount());
        assert!(amount_sent != math_utils::u256_max() || account_address == on_behalf_of,
            error_config::get_eno_explicit_amount_to_repay_on_behalf());

        let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        let (is_active, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
        assert!(is_active, error_config::get_ereserve_inactive());
        assert!(!is_paused, error_config::get_ereserve_paused());

        // check debt selected type
        assert!(variable_debt != 0 && interest_rate_mode
            == user_config::get_interest_rate_mode_variable(),
            error_config::get_eno_debt_of_selected_type());
    }

    public fun validate_liquidation_call(
        user_config_map: &UserConfigurationMap,
        collateral_reserve: &ReserveData,
        debt_reserve: &ReserveData,
        total_debt: u256,
        health_factor: u256
    ) {
        let collateral_reserve_config =
            pool::get_reserve_configuration_by_reserve_data(collateral_reserve);
        let (collateral_reserve_active, _, _, collateral_reserve_paused) =
            reserve_config::get_flags(&collateral_reserve_config);

        let debt_reserve_config = pool::get_reserve_configuration_by_reserve_data(
            debt_reserve);
        let (principal_reserve_active, _, _, principal_reserve_paused) = reserve_config::get_flags(
            &debt_reserve_config);
        assert!(collateral_reserve_active && principal_reserve_active,
            error_config::get_ereserve_inactive());
        assert!(!collateral_reserve_paused && !principal_reserve_paused,
            error_config::get_ereserve_paused());

        assert!(health_factor < user_config::get_minimum_health_factor_liquidation_threshold() || oracle_sentinel::is_liquidation_allowed(),
            error_config::get_eprice_oracle_sentinel_check_failed());

        assert!(health_factor < user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_not_below_threshold());

        let collateral_reserve_id = pool::get_reserve_id(collateral_reserve);
        let is_collateral_enabled =
            reserve_config::get_liquidation_threshold(&collateral_reserve_config) != 0 && user_config::is_using_as_collateral(
                user_config_map, (collateral_reserve_id as u256));
        assert!(is_collateral_enabled, error_config::get_ecollateral_cannot_be_liquidated());
        assert!(total_debt != 0,
            error_config::get_especified_currency_not_borrowed_by_user());
    }
}
