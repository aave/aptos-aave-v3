module aave_pool::borrow_logic {
    use std::signer;
    use aptos_framework::event;

    use aave_config::error as error_config;
    use aave_config::reserve as reserve_config;
    use aave_config::user as user_config;
    use aave_math::math_utils;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::isolation_mode_logic;
    use aave_pool::pool;
    use aave_pool::underlying_token_factory;
    use aave_pool::validation_logic;
    use aave_pool::variable_token_factory;

    friend aave_pool::flashloan_logic;

    #[event]
    struct Borrow has store, copy, drop {
        reserve: address,
        user: address,
        on_behalf_of: address,
        amount: u256,
        interest_rate_mode: u8,
        borrow_rate: u256,
        referral_code: u16,
    }

    #[event]
    struct Repay has store, drop {
        reserve: address,
        user: address,
        repayer: address,
        amount: u256,
        use_a_tokens: bool,
    }

    #[event]
    struct IsolationModeTotalDebtUpdated has store, drop {
        asset: address,
        total_debt: u256,
    }

    // Function to execute borrowing of assets
    public entry fun borrow(
        account: &signer,
        asset: address,
        on_behalf_of: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
    ) {
        internal_borrow(account, asset, on_behalf_of, amount, interest_rate_mode, referral_code, true);
    }

    public(friend) fun internal_borrow(
        account: &signer,
        asset: address,
        on_behalf_of: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
        release_underlying: bool,
    ) {
        let user = signer::address_of(account);
        assert!(user == on_behalf_of, error_config::get_esigner_and_on_behalf_of_no_same());

        let (reserve_data, reserves_count) = pool::get_reserve_data_and_reserves_count(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);

        let user_config_map = pool::get_user_configuration(on_behalf_of);
        let (isolation_mode_active, isolation_mode_collateral_address,
            isolation_mode_debt_ceiling) = pool::get_isolation_mode_state(&user_config_map);

        // validate borrow
        validation_logic::validate_borrow(&reserve_data,
            &user_config_map,
            asset,
            on_behalf_of,
            amount,
            interest_rate_mode,
            reserves_count,
            (emode_logic::get_user_emode(on_behalf_of) as u8),
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling);

        let variable_token_address = pool::get_reserve_variable_debt_token_address(&reserve_data);
        let is_first_borrowing: bool =
            variable_token_factory::scale_balance_of(on_behalf_of, variable_token_address) ==
                0;

        variable_token_factory::mint(user,
            on_behalf_of,
            amount,
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            variable_token_address);

        if (is_first_borrowing) {
            let reserve_id = pool::get_reserve_id(&reserve_data);
            user_config::set_borrowing(&mut user_config_map, (reserve_id as u256), true);
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        if (isolation_mode_active) {
            let isolation_mode_collateral_reserve_data = pool::get_reserve_data(
                isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                pool::get_reserve_isolation_mode_total_debt(&isolation_mode_collateral_reserve_data);
            let reserve_configuration_map = pool::get_reserve_configuration_by_reserve_data(
                &reserve_data);
            let decimals =
                reserve_config::get_decimals(&reserve_configuration_map) - reserve_config::get_debt_ceiling_decimals();
            let next_isolation_mode_total_debt =
                (isolation_mode_total_debt as u256) + (amount / math_utils::pow(10, decimals));
            // update isolation_mode_total_debt
            pool::set_reserve_isolation_mode_total_debt(isolation_mode_collateral_address,
                (next_isolation_mode_total_debt as u128));

            event::emit(IsolationModeTotalDebtUpdated {
                asset: isolation_mode_collateral_address,
                total_debt: next_isolation_mode_total_debt
            });
        };

        // update pool interest rate
        let liquidity_taken = if (release_underlying) { amount }
        else { 0 };
        pool::update_interest_rates(&mut reserve_data, asset, 0, liquidity_taken);
        if (release_underlying) {
            a_token_factory::transfer_underlying_to(user, amount,
                pool::get_reserve_a_token_address(&reserve_data));
        };

        // Emit a borrow event
        event::emit(Borrow {
            reserve: asset,
            user,
            on_behalf_of,
            amount,
            interest_rate_mode,
            borrow_rate: (pool::get_reserve_current_variable_borrow_rate(&reserve_data) as u256),
            referral_code,
        });
    }

    // Function to execute repayment of borrowed assets
    public entry fun repay(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
    ) {
        internal_repay(account, asset, amount, interest_rate_mode, on_behalf_of, false)
    }

    fun internal_repay(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
        use_a_tokens: bool
    ) {
        let account_address = signer::address_of(account);
        assert!(account_address == on_behalf_of, error_config::get_esigner_and_on_behalf_of_no_same());

        let reserve_data = pool::get_reserve_data(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);

        let variable_debt_token_address = pool::get_reserve_variable_debt_token_address(&reserve_data);
        let variable_debt = pool::scale_variable_token_balance_of(on_behalf_of, variable_debt_token_address);

        // validate repay
        validation_logic::validate_repay(account,
            &reserve_data,
            amount,
            interest_rate_mode,
            on_behalf_of,
            variable_debt);

        let payback_amount = variable_debt;
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        if (use_a_tokens && amount == math_utils::u256_max()) {
            amount = pool::scale_a_token_balance_of(account_address, a_token_address)
        };

        if (amount < payback_amount) {
            payback_amount = amount;
        };
        variable_token_factory::burn(
            on_behalf_of,
            payback_amount,
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            pool::get_reserve_variable_debt_token_address(&reserve_data)
        );

        // update pool interest rate
        let liquidity_added = if (use_a_tokens) { 0 }
        else { payback_amount };
        pool::update_interest_rates(&mut reserve_data, asset, liquidity_added, 0);

        let user_config_map = pool::get_user_configuration(on_behalf_of);
        // set borrowing
        if (variable_debt - payback_amount == 0) {
            user_config::set_borrowing(&mut user_config_map, (pool::get_reserve_id(&reserve_data) as u256), true);
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        // update reserve_data.isolation_mode_total_debt field
        isolation_mode_logic::update_isolated_debt_if_isolated(&user_config_map, &reserve_data,
            payback_amount);

        // If you choose to repay with AToken, burn Atoken
        if (use_a_tokens) {
            a_token_factory::burn(account_address,
                a_token_factory::get_token_account_address(a_token_address),
                payback_amount,
                (pool::get_reserve_liquidity_index(&reserve_data) as u256),
                a_token_address);
        } else {
            underlying_token_factory::transfer_from(account_address,
                a_token_factory::get_token_account_address(a_token_address),
                (payback_amount as u64),
                asset);
            a_token_factory::handle_repayment(account_address,
                on_behalf_of,
                payback_amount,
                pool::get_reserve_a_token_address(&reserve_data));
        };

        // Emit a Repay event
        event::emit(Repay {
            reserve: asset,
            user: on_behalf_of,
            repayer: account_address,
            amount: payback_amount,
            use_a_tokens,
        });
    }

    public entry fun repay_with_a_tokens(
        account: &signer, asset: address, amount: u256, interest_rate_mode: u8
    ) {
        let account_address = signer::address_of(account);
        internal_repay(account, asset, amount, interest_rate_mode, account_address, true)
    }
}
