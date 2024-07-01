module aave_pool::pool_validation {
    use std::string::Self;

    use aave_acl::acl_manage;
    use aave_config::error as error_config;
    use aave_config::reserve as reserve_config;
    use aave_config::reserve::ReserveConfigurationMap;
    use aave_config::user::{Self as user_config, UserConfigurationMap};

    use aave_pool::generic_logic;
    use aave_pool::pool::{Self, ReserveData};

    public fun validate_hf_and_ltv(
        reserve_data: &mut ReserveData,
        reserves_count: u256,
        user_config_map: &UserConfigurationMap,
        from: address,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256,
    ) {
        let (_, has_zero_ltv_collateral) =
            validate_health_factor(reserves_count,
                user_config_map,
                from,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price);
        let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(
            reserve_data);
        assert!(!has_zero_ltv_collateral || reserve_config::get_ltv(&reserve_configuration) ==
             0,
            error_config::get_eltv_validation_failed());
    }

    public fun validate_automatic_use_as_collateral(
        account: address,
        user_config_map: &UserConfigurationMap,
        reserve_config_map: &ReserveConfigurationMap
    ): bool {
        if (reserve_config::get_debt_ceiling(reserve_config_map) != 0) {
            if (!acl_manage::has_role(string::utf8(user_config::get_isolated_collateral_supplier_role()),
                    account)) {
                return false
            };
        };
        return validate_use_as_collateral(user_config_map, reserve_config_map)
    }

    public fun validate_use_as_collateral(
        user_config_map: &UserConfigurationMap,
        reserve_config_map: &ReserveConfigurationMap
    ): bool {
        if (reserve_config::get_ltv(reserve_config_map) == 0) {
            return false
        };
        if (!user_config::is_using_as_collateral_any(user_config_map)) {
            return true
        };
        let (isolation_mode_active, _, _) = pool::get_isolation_mode_state(user_config_map);
        (!isolation_mode_active && reserve_config::get_debt_ceiling(reserve_config_map) ==
             0)
    }

    public fun validate_health_factor(
        reserves_count: u256,
        user_config_map: &UserConfigurationMap,
        user: address,
        user_emode_category: u8,
        emode_ltv: u256,
        emode_liq_threshold: u256,
        emode_asset_price: u256,
    ): (u256, bool) {
        let (_, _, _, _, health_factor, has_zero_ltv_collateral) =
            generic_logic::calculate_user_account_data(reserves_count,
                user_config_map,
                user,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price);
        assert!(health_factor >= user_config::get_health_factor_liquidation_threshold(),
            error_config::get_ehealth_factor_lower_than_liquidation_threshold());

        (health_factor, has_zero_ltv_collateral)
    }

    public fun validate_set_user_emode(
        user_config_map: &UserConfigurationMap,
        reserves_count: u256,
        category_id: u8,
        liquidation_threshold: u16
    ) {
        assert!(category_id != 0 || liquidation_threshold != 0,
            error_config::get_einvalid_emode_category_assignment());
        if (!user_config::is_empty(user_config_map)) {
            if (category_id != 0) {
                for (i in 0..reserves_count) {
                    if (user_config::is_borrowing(user_config_map, i)) {
                        let reserve_address = pool::get_reserve_address_by_id(i);
                        let reserve_configuration = pool::get_reserve_configuration(
                            reserve_address);
                        assert!(reserve_config::get_emode_category(&reserve_configuration)
                            == (category_id as u256),
                            error_config::get_einconsistent_emode_category());
                    };
                }
            }
        }
    }
}
