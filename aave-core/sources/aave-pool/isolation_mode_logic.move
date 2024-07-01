module aave_pool::isolation_mode_logic {
    use aptos_framework::event;

    use aave_config::reserve as reserve_config;
    use aave_config::user::UserConfigurationMap;
    use aave_math::math_utils;

    use aave_pool::pool::{Self, ReserveData};

    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    #[event]
    struct IsolationModeTotalDebtUpdated has store, drop {
        asset: address,
        total_debt: u256,
    }

    public(friend) fun update_isolated_debt_if_isolated(
        user_config_map: &UserConfigurationMap, reserve_data: &ReserveData, repay_amount: u256
    ) {
        let (isolation_mode_active, isolation_mode_collateral_address, _) = pool::get_isolation_mode_state(user_config_map);
        if (isolation_mode_active) {
            let isolation_mode_debt_reserve_data = pool::get_reserve_data(
                isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                pool::get_reserve_isolation_mode_total_debt(&isolation_mode_debt_reserve_data);
            let reserve_config_map = pool::get_reserve_configuration_by_reserve_data(
                reserve_data);
            let debt_decimals =
                reserve_config::get_decimals(&reserve_config_map) - reserve_config::get_debt_ceiling_decimals();
            let isolated_debt_repaid = (repay_amount / math_utils::pow(10, debt_decimals));

            if (isolation_mode_total_debt <= (isolated_debt_repaid as u128)) {
                pool::set_reserve_isolation_mode_total_debt(isolation_mode_collateral_address, 0);
                event::emit(IsolationModeTotalDebtUpdated {
                        asset: isolation_mode_collateral_address,
                        total_debt: 0
                    })
            } else {
                let next_isolation_mode_total_debt = isolation_mode_total_debt - (
                    isolated_debt_repaid as u128
                );
                pool::set_reserve_isolation_mode_total_debt(isolation_mode_collateral_address,
                    next_isolation_mode_total_debt);
                event::emit(IsolationModeTotalDebtUpdated {
                        asset: isolation_mode_collateral_address,
                        total_debt: (next_isolation_mode_total_debt as u256)
                    })
            }
        }
    }
}
