module aave_pool::pool_data_provider {
    use std::string::String;
    use std::vector;

    use aave_config::reserve as reserve_config;
    use aave_config::user as user_config;

    use aave_pool::a_token_factory;
    use aave_pool::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_pool::variable_debt_token_factory;

    struct TokenData has drop {
        symbol: String,
        token_address: address
    }

    #[test_only]
    public fun get_reserve_token_symbol(token_data: &TokenData): String {
        token_data.symbol
    }

    #[test_only]
    public fun get_reserve_token_address(token_data: &TokenData): address {
        token_data.token_address
    }

    #[view]
    public fun get_all_reserves_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let reserves_tokens = vector::empty<TokenData>();
        for (i in 0..vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);
            vector::push_back<TokenData>(
                &mut reserves_tokens,
                TokenData {
                    symbol: mock_underlying_token_factory::symbol(reserve_address),
                    token_address: reserve_address
                },
            );
        };
        reserves_tokens
    }

    #[view]
    public fun get_all_a_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let a_tokens = vector::empty<TokenData>();
        for (i in 0..vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);
            let reserve_data = pool::get_reserve_data(reserve_address);
            let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
            vector::push_back<TokenData>(
                &mut a_tokens,
                TokenData {
                    symbol: a_token_factory::symbol(a_token_address),
                    token_address: a_token_address
                },
            );
        };
        a_tokens
    }

    #[view]
    public fun get_all_var_tokens(): vector<TokenData> {
        let reserves = pool::get_reserves_list();
        let var_tokens = vector::empty<TokenData>();
        let i = 0;
        while (i < vector::length(&reserves)) {
            let reserve_address = *vector::borrow(&reserves, i);
            let reserve_data = pool::get_reserve_data(reserve_address);
            let var_token_address =
                pool::get_reserve_variable_debt_token_address(&reserve_data);
            vector::push_back<TokenData>(
                &mut var_tokens,
                TokenData {
                    symbol: variable_debt_token_factory::symbol(var_token_address),
                    token_address: var_token_address
                },
            );

            i = i + 1
        };
        var_tokens
    }

    #[view]
    public fun get_reserve_configuration_data(asset: address)
        : (
        u256, u256, u256, u256, u256, bool, bool, bool, bool
    ) {
        let reserve_configuration = pool::get_reserve_configuration(asset);

        let (ltv, liquidation_threshold, liquidation_bonus, decimals, reserve_factor, _) =
            reserve_config::get_params(&reserve_configuration);
        let (is_active, is_frozen, borrowing_enabled, _) =
            reserve_config::get_flags(&reserve_configuration);
        let usage_as_collateral_enabled = liquidation_threshold != 0;

        (
            decimals,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            reserve_factor,
            usage_as_collateral_enabled,
            borrowing_enabled,
            is_active,
            is_frozen
        )
    }

    #[view]
    public fun get_reserve_emode_category(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_emode_category(&reserve_configuration)
    }

    #[view]
    public fun get_reserve_caps(asset: address): (u256, u256) {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_caps(&reserve_configuration)
    }

    #[view]
    public fun get_paused(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_paused(&reserve_configuration)
    }

    #[view]
    public fun get_siloed_borrowing(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_siloed_borrowing(&reserve_configuration)
    }

    #[view]
    public fun get_liquidation_protocol_fee(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_liquidation_protocol_fee(&reserve_configuration)
    }

    #[view]
    public fun get_unbacked_mint_cap(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_unbacked_mint_cap(&reserve_configuration)
    }

    #[view]
    public fun get_debt_ceiling(asset: address): u256 {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_debt_ceiling(&reserve_configuration)
    }

    #[view]
    public fun get_debt_ceiling_decimals(): u256 {
        reserve_config::get_debt_ceiling_decimals()
    }

    #[view]
    public fun get_reserve_data(asset: address)
        : (
        u256, u256, u256, u256, u256, u256, u256, u256, u64
    ) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);
        (
            (pool::get_reserve_unbacked(&reserve_data) as u256),
            pool::get_reserve_accrued_to_treasury(&reserve_data),
            pool::scaled_a_token_total_supply(a_token_address),
            pool::scaled_variable_token_total_supply(variable_token_address),
            (pool::get_reserve_current_liquidity_rate(&reserve_data) as u256),
            (pool::get_reserve_current_variable_borrow_rate(&reserve_data) as u256),
            (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            pool::get_reserve_last_update_timestamp(&reserve_data),
        )
    }

    #[view]
    public fun get_a_token_total_supply(asset: address): u256 {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);

        pool::scaled_a_token_total_supply(a_token_address)
    }

    #[view]
    public fun get_total_debt(asset: address): u256 {
        let reserve_data = pool::get_reserve_data(asset);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);

        pool::scaled_variable_token_total_supply(variable_token_address)
    }

    #[view]
    public fun get_user_reserve_data(asset: address, user: address)
        : (u256, u256, u256, u256, bool) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);

        let current_a_token_balance =
            pool::scaled_a_token_balance_of(user, a_token_address);
        let current_variable_debt =
            pool::scaled_variable_token_balance_of(user, variable_token_address);
        let scaled_variable_debt =
            variable_debt_token_factory::scaled_balance_of(user, variable_token_address);
        let liquidity_rate =
            (pool::get_reserve_current_liquidity_rate(&reserve_data) as u256);

        let user_configuration = pool::get_user_configuration(user);
        let usage_as_collateral_enabled =
            user_config::is_using_as_collateral(
                &user_configuration, (pool::get_reserve_id(&reserve_data) as u256)
            );

        (
            current_a_token_balance,
            current_variable_debt,
            scaled_variable_debt,
            liquidity_rate,
            usage_as_collateral_enabled
        )
    }

    #[view]
    public fun get_reserve_tokens_addresses(asset: address): (address, address) {
        let reserve_data = pool::get_reserve_data(asset);
        (
            pool::get_reserve_a_token_address(&reserve_data),
            pool::get_reserve_variable_debt_token_address(&reserve_data),
        )
    }

    #[view]
    public fun get_flash_loan_enabled(asset: address): bool {
        let reserve_configuration = pool::get_reserve_configuration(asset);
        reserve_config::get_flash_loan_enabled(&reserve_configuration)
    }
}
