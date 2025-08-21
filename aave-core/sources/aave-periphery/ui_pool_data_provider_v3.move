/// @title UI Pool Data Provider V3 Module
/// @author Aave
/// @notice Provides data for UI about Aave protocol pool and user reserve states
module aave_pool::ui_pool_data_provider_v3 {
    // imports
    use std::string::String;
    use std::vector;
    use aptos_framework::object;
    use aptos_framework::dispatchable_fungible_asset;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_coin;

    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_oracle::oracle::Self;
    use aave_pool::pool_data_provider;
    use aave_pool::default_reserve_interest_rate_strategy::{
        get_base_variable_borrow_rate,
        get_optimal_usage_ratio,
        get_variable_rate_slope1,
        get_variable_rate_slope2
    };
    use aave_pool::coin_migrator;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::pool::Self;

    // Constants
    /// @notice Currency unit for USD representation
    const USD_CURRENCY_UNIT: u256 = 1_000_000_000_000_000_000;

    // Structs
    /// @notice Aggregated reserve data structure
    /// @param underlying_asset The address of the underlying asset
    /// @param name The name of the reserve
    /// @param symbol The symbol of the reserve
    /// @param decimals The number of decimals of the reserve
    /// @param base_ltv_as_collateral The base LTV as collateral
    /// @param reserve_liquidation_threshold The reserve liquidation threshold
    /// @param reserve_liquidation_bonus The reserve liquidation bonus
    /// @param reserve_factor The reserve factor
    /// @param usage_as_collateral_enabled Whether the reserve can be used as collateral
    /// @param borrowing_enabled Whether borrowing is enabled
    /// @param is_active Whether the reserve is active
    /// @param is_frozen Whether the reserve is frozen
    /// @param liquidity_index The liquidity index
    /// @param variable_borrow_index The variable borrow index
    /// @param liquidity_rate The liquidity rate
    /// @param variable_borrow_rate The variable borrow rate
    /// @param last_update_timestamp The last update timestamp
    /// @param a_token_address The address of the aToken
    /// @param variable_debt_token_address The address of the variable debt token
    /// @param available_liquidity The available liquidity
    /// @param total_scaled_variable_debt The total scaled variable debt
    /// @param price_in_market_reference_currency The price in market reference currency
    /// @param variable_rate_slope1 The variable rate slope 1
    /// @param variable_rate_slope2 The variable rate slope 2
    /// @param base_variable_borrow_rate The base variable borrow rate
    /// @param optimal_usage_ratio The optimal usage ratio
    /// @param is_paused Whether the reserve is paused
    /// @param is_siloed_borrowing Whether siloed borrowing is enabled
    /// @param accrued_to_treasury The amount accrued to the treasury
    /// @param isolation_mode_total_debt The isolation mode total debt
    /// @param flash_loan_enabled Whether flash loans are enabled
    /// @param debt_ceiling The debt ceiling
    /// @param debt_ceiling_decimals The debt ceiling decimals
    /// @param e_mode_category_id The e-mode category ID
    /// @param borrow_cap The borrow cap
    /// @param supply_cap The supply cap
    /// @param e_mode_ltv The e-mode LTV
    /// @param e_mode_liquidation_threshold The e-mode liquidation threshold
    /// @param e_mode_liquidation_bonus The e-mode liquidation bonus
    /// @param e_mode_label The e-mode label
    /// @param borrowable_in_isolation Whether the reserve is borrowable in isolation
    /// @param deficit The deficit
    /// @param virtual_underlying_balance The virtual underlying balance
    /// @param is_virtual_acc_active Whether the virtual account is active
    struct AggregatedReserveData has key, store, drop {
        underlying_asset: address,
        name: String,
        symbol: String,
        decimals: u256,
        base_ltv_as_collateral: u256,
        reserve_liquidation_threshold: u256,
        reserve_liquidation_bonus: u256,
        reserve_factor: u256,
        usage_as_collateral_enabled: bool,
        borrowing_enabled: bool,
        is_active: bool,
        is_frozen: bool,
        // base data
        liquidity_index: u128,
        variable_borrow_index: u128,
        liquidity_rate: u128,
        variable_borrow_rate: u128,
        last_update_timestamp: u128,
        a_token_address: address,
        variable_debt_token_address: address,
        //
        available_liquidity: u256,
        total_scaled_variable_debt: u256,
        price_in_market_reference_currency: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256,
        base_variable_borrow_rate: u256,
        optimal_usage_ratio: u256,
        // v3 only
        is_paused: bool,
        is_siloed_borrowing: bool,
        accrued_to_treasury: u128,
        isolation_mode_total_debt: u128,
        flash_loan_enabled: bool,
        // debts
        debt_ceiling: u256,
        debt_ceiling_decimals: u256,
        e_mode_category_id: u8,
        borrow_cap: u256,
        supply_cap: u256,
        // e_mode
        e_mode_ltv: u16,
        e_mode_liquidation_threshold: u16,
        e_mode_liquidation_bonus: u16,
        e_mode_label: String,
        borrowable_in_isolation: bool,
        // v3.3
        deficit: u128,
        virtual_underlying_balance: u128,
        is_virtual_acc_active: bool
    }

    /// @notice User reserve data structure
    /// @param decimals The number of decimals of the reserve
    /// @param underlying_asset The address of the underlying asset
    /// @param scaled_a_token_balance The scaled aToken balance
    /// @param usage_as_collateral_enabled_on_user Whether usage as collateral is enabled for the user
    /// @param scaled_variable_debt The scaled variable debt
    struct UserReserveData has key, store, drop {
        decimals: u256,
        underlying_asset: address,
        scaled_a_token_balance: u256,
        usage_as_collateral_enabled_on_user: bool,
        scaled_variable_debt: u256
    }

    /// @notice Base currency information structure
    /// @param market_reference_currency_unit The market reference currency unit
    /// @param market_reference_currency_price_in_usd The market reference currency price in USD
    /// @param network_base_token_price_in_usd The network base token price in USD
    /// @param network_base_token_price_decimals The network base token price decimals
    struct BaseCurrencyInfo has key, store, drop {
        market_reference_currency_unit: u256,
        market_reference_currency_price_in_usd: u256,
        network_base_token_price_in_usd: u256,
        network_base_token_price_decimals: u8
    }

    // Public view functions
    #[view]
    /// @notice Gets the list of reserves in the pool
    /// @return Vector of reserve addresses
    public fun get_reserves_list(): vector<address> {
        pool::get_reserves_list()
    }

    #[view]
    /// @notice Gets data for all reserves in the pool
    /// @return Tuple containing vector of aggregated reserve data and base currency information
    public fun get_reserves_data(): (vector<AggregatedReserveData>, BaseCurrencyInfo) {
        let reserves = pool::get_reserves_list();

        let reserves_data = vector::empty<AggregatedReserveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let underlying_token = object::address_to_object<Metadata>(underlying_asset);

            let base_data = pool::get_reserve_data(underlying_asset);

            let liquidity_index = pool::get_reserve_liquidity_index(base_data);
            let variable_borrow_index =
                pool::get_reserve_variable_borrow_index(base_data);
            let liquidity_rate = pool::get_reserve_current_liquidity_rate(base_data);
            let variable_borrow_rate =
                pool::get_reserve_current_variable_borrow_rate(base_data);
            let last_update_timestamp =
                pool::get_reserve_last_update_timestamp(base_data);
            let a_token_address = pool::get_reserve_a_token_address(base_data);
            let variable_debt_token_address =
                pool::get_reserve_variable_debt_token_address(base_data);
            let price_in_market_reference_currency =
                oracle::get_asset_price(underlying_asset);

            let atoken_account_address =
                a_token_factory::get_token_account_address(a_token_address);

            let available_liquidity =
                if (primary_fungible_store::primary_store_exists(
                    atoken_account_address, underlying_token
                )) {
                    dispatchable_fungible_asset::derived_balance(
                        primary_fungible_store::primary_store(
                            atoken_account_address, underlying_token
                        )
                    )
                } else { 0 };

            let total_scaled_variable_debt =
                variable_debt_token_factory::scaled_total_supply(
                    variable_debt_token_address
                );

            let symbol = fungible_asset::symbol(underlying_token);
            let name = fungible_asset::name(underlying_token);
            let reserve_configuration_map =
                pool::get_reserve_configuration_by_reserve_data(base_data);

            let (
                base_ltv_as_collateral,
                reserve_liquidation_threshold,
                reserve_liquidation_bonus,
                decimals,
                reserve_factor,
                e_mode_category_id
            ) = reserve_config::get_params(&reserve_configuration_map);
            let usage_as_collateral_enabled = base_ltv_as_collateral != 0;

            let (is_active, is_frozen, borrowing_enabled, is_paused) =
                reserve_config::get_flags(&reserve_configuration_map);

            let variable_rate_slope1 = get_variable_rate_slope1(underlying_asset);
            let variable_rate_slope2 = get_variable_rate_slope2(underlying_asset);
            let base_variable_borrow_rate =
                get_base_variable_borrow_rate(underlying_asset);
            let optimal_usage_ratio = get_optimal_usage_ratio(underlying_asset);

            let debt_ceiling: u256 =
                reserve_config::get_debt_ceiling(&reserve_configuration_map);
            let debt_ceiling_decimals = reserve_config::get_debt_ceiling_decimals();
            let (borrow_cap, supply_cap) =
                reserve_config::get_caps(&reserve_configuration_map);

            let flash_loan_enabled =
                reserve_config::get_flash_loan_enabled(&reserve_configuration_map);

            let is_siloed_borrowing =
                reserve_config::get_siloed_borrowing(&reserve_configuration_map);
            let isolation_mode_total_debt =
                pool::get_reserve_isolation_mode_total_debt(base_data);
            let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(base_data);

            let e_mode_category_id_u8 = (e_mode_category_id as u8);

            let (e_mode_ltv, e_mode_liquidation_threshold) =
                emode_logic::get_emode_configuration(e_mode_category_id_u8);

            let e_mode_liquidation_bonus =
                emode_logic::get_emode_e_mode_liquidation_bonus(e_mode_category_id_u8);
            let e_mode_label = emode_logic::get_emode_e_mode_label(e_mode_category_id_u8);

            let borrowable_in_isolation =
                reserve_config::get_borrowable_in_isolation(&reserve_configuration_map);

            let aggregated_reserve_data = AggregatedReserveData {
                underlying_asset,
                name,
                symbol,
                decimals,
                base_ltv_as_collateral,
                reserve_liquidation_threshold,
                reserve_liquidation_bonus,
                reserve_factor,
                usage_as_collateral_enabled,
                borrowing_enabled,
                is_active,
                is_frozen,
                liquidity_index,
                variable_borrow_index,
                liquidity_rate,
                variable_borrow_rate,
                last_update_timestamp: (last_update_timestamp as u128),
                a_token_address,
                variable_debt_token_address,
                available_liquidity: (available_liquidity as u256),
                total_scaled_variable_debt,
                price_in_market_reference_currency,
                variable_rate_slope1,
                variable_rate_slope2,
                base_variable_borrow_rate,
                optimal_usage_ratio,
                is_paused,
                is_siloed_borrowing,
                accrued_to_treasury: (accrued_to_treasury as u128),
                isolation_mode_total_debt,
                flash_loan_enabled,
                debt_ceiling,
                debt_ceiling_decimals,
                e_mode_category_id: e_mode_category_id_u8,
                borrow_cap,
                supply_cap,
                e_mode_ltv: (e_mode_ltv as u16),
                e_mode_liquidation_threshold: (e_mode_liquidation_threshold as u16),
                e_mode_liquidation_bonus,
                e_mode_label,
                borrowable_in_isolation,
                deficit: pool_data_provider::get_reserve_deficit(underlying_asset),
                virtual_underlying_balance: pool::get_reserve_virtual_underlying_balance(
                    base_data
                ),
                is_virtual_acc_active: true
            };

            vector::push_back(&mut reserves_data, aggregated_reserve_data);
        };

        let apt_mapped_fa_asset = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        // NOTE(mpsc0x): the network base and the market reference currencies are on Aptos the same, but we
        // keep the interface for compatibility reasons
        let network_base_token_price_in_usd =
            oracle::get_asset_price(apt_mapped_fa_asset);
        let network_base_token_price_decimals = oracle::get_asset_price_decimals();
        let market_reference_currency_unit = USD_CURRENCY_UNIT;
        let market_reference_currency_price_in_usd = USD_CURRENCY_UNIT;

        let base_currency_info = BaseCurrencyInfo {
            market_reference_currency_unit,
            market_reference_currency_price_in_usd,
            network_base_token_price_in_usd,
            network_base_token_price_decimals
        };
        (reserves_data, base_currency_info)
    }

    #[view]
    /// @notice Gets data for all reserves for a specific user
    /// @param user The address of the user
    /// @return Tuple containing vector of user reserve data and the user's e-mode category ID
    public fun get_user_reserves_data(user: address): (vector<UserReserveData>, u8) {
        let reserves = pool::get_reserves_list();
        let user_config = pool::get_user_configuration(user);

        let user_emode_category_id = emode_logic::get_user_emode(user);

        let user_reserves_data = vector::empty<UserReserveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let underlying_token = object::address_to_object<Metadata>(underlying_asset);

            let base_data = pool::get_reserve_data(underlying_asset);
            let reserve_index = pool::get_reserve_id(base_data);

            let decimals = fungible_asset::decimals(underlying_token);
            let scaled_a_token_balance =
                a_token_factory::scaled_balance_of(
                    user, pool::get_reserve_a_token_address(base_data)
                );

            let usage_as_collateral_enabled_on_user =
                user_config::is_using_as_collateral(&user_config, (reserve_index as u256));

            let scaled_variable_debt = 0;
            if (user_config::is_borrowing(&user_config, (reserve_index as u256))) {
                scaled_variable_debt = variable_debt_token_factory::scaled_balance_of(
                    user, pool::get_reserve_variable_debt_token_address(base_data)
                );
            };

            vector::push_back(
                &mut user_reserves_data,
                UserReserveData {
                    decimals: (decimals as u256),
                    underlying_asset,
                    scaled_a_token_balance,
                    usage_as_collateral_enabled_on_user,
                    scaled_variable_debt
                }
            );
        };

        (user_reserves_data, user_emode_category_id)
    }
}
