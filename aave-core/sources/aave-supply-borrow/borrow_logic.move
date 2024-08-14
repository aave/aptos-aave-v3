/// @title borrow_logic module
/// @author Aave
/// @notice Implements the base logic for all the actions related to borrowing
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
    use aave_pool::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_pool::validation_logic;
    use aave_pool::variable_debt_token_factory;

    friend aave_pool::flashloan_logic;

    #[event]
    /// @dev Emitted on borrow() and flashLoan() when debt needs to be opened
    /// @param reserve The address of the underlying asset being borrowed
    /// @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
    ///  initiator of the transaction on flashLoan()
    /// @param on_behalf_of The address that will be getting the debt
    /// @param amount The amount borrowed out
    /// @param interest_rate_mode The rate mode: 2 for Variable
    /// @param borrow_rate The numeric rate at which the user has borrowed, expressed in ray
    /// @param referral_code The referral code used
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
    /// @dev Emitted on repay()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The beneficiary of the repayment, getting his debt reduced
    /// @param repayer The address of the user initiating the repay(), providing the funds
    /// @param amount The amount repaid
    /// @param use_a_tokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
    struct Repay has store, drop {
        reserve: address,
        user: address,
        repayer: address,
        amount: u256,
        use_a_tokens: bool,
    }

    #[event]
    /// @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
    /// @param asset The address of the underlying asset of the reserve
    /// @param totalDebt The total isolation mode debt for the reserve
    struct IsolationModeTotalDebtUpdated has store, drop {
        asset: address,
        total_debt: u256,
    }

    /// @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    /// already supplied enough collateral, or he was given enough allowance by a credit delegator on the
    /// corresponding debt token VariableDebtToken
    /// - E.g. User borrows 100 USDC passing as `on_behalf_of` his own address, receiving the 100 USDC in his wallet
    /// and 100 stable/variable debt tokens, depending on the `interest_rate_mode`
    /// @param asset The address of the underlying asset to borrow
    /// @param amount The amount to be borrowed
    /// @param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
    /// @param referral_code The code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    /// @param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
    /// calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    /// if he has been given credit delegation allowance
    public entry fun borrow(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
        on_behalf_of: address,
    ) {
        internal_borrow(
            account,
            asset,
            amount,
            interest_rate_mode,
            referral_code,
            on_behalf_of,
            true,
        );
    }

    /// @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
    /// Aave protocol proportionally to their collateralization power. For isolated positions, it also increases the
    /// isolated debt.
    /// @dev  Emits the `Borrow()` event
    /// @param account The signer account
    /// @param asset The address of the underlying asset to borrow
    /// @param amount The amount to be borrowed
    /// @param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
    /// @param referral_code The code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle
    /// @param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
    /// calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    /// if he has been given credit delegation allowance
    /// @param release_underlying If true, the underlying asset will be transferred to the user, otherwise it will stay
    public(friend) fun internal_borrow(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
        on_behalf_of: address,
        release_underlying: bool,
    ) {
        let user = signer::address_of(account);
        assert!(
            user == on_behalf_of, error_config::get_esigner_and_on_behalf_of_no_same()
        );

        let (reserve_data, reserves_count) =
            pool::get_reserve_data_and_reserves_count(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);

        let user_config_map = pool::get_user_configuration(on_behalf_of);
        let (
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        ) = pool::get_isolation_mode_state(&user_config_map);

        // validate borrow
        validation_logic::validate_borrow(
            &reserve_data,
            &user_config_map,
            asset,
            on_behalf_of,
            amount,
            interest_rate_mode,
            reserves_count,
            (emode_logic::get_user_emode(on_behalf_of) as u8),
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling,
        );

        let variable_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);
        let is_first_borrowing: bool =
            variable_debt_token_factory::scaled_balance_of(
                on_behalf_of, variable_token_address
            ) == 0;

        variable_debt_token_factory::mint(
            user,
            on_behalf_of,
            amount,
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            variable_token_address,
        );

        if (is_first_borrowing) {
            let reserve_id = pool::get_reserve_id(&reserve_data);
            user_config::set_borrowing(&mut user_config_map, (reserve_id as u256), true);
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        if (isolation_mode_active) {
            let isolation_mode_collateral_reserve_data =
                pool::get_reserve_data(isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                pool::get_reserve_isolation_mode_total_debt(
                    &isolation_mode_collateral_reserve_data
                );
            let reserve_configuration_map =
                pool::get_reserve_configuration_by_reserve_data(&reserve_data);
            let decimals =
                reserve_config::get_decimals(&reserve_configuration_map)
                    - reserve_config::get_debt_ceiling_decimals();
            let next_isolation_mode_total_debt =
                (isolation_mode_total_debt as u256) + (
                    amount / math_utils::pow(10, decimals)
                );
            // update isolation_mode_total_debt
            pool::set_reserve_isolation_mode_total_debt(
                isolation_mode_collateral_address,
                (next_isolation_mode_total_debt as u128),
            );

            event::emit(
                IsolationModeTotalDebtUpdated {
                    asset: isolation_mode_collateral_address,
                    total_debt: next_isolation_mode_total_debt
                },
            );
        };

        // update pool interest rate
        let liquidity_taken = if (release_underlying) { amount }
        else { 0 };
        pool::update_interest_rates(&mut reserve_data, asset, 0, liquidity_taken);
        if (release_underlying) {
            a_token_factory::transfer_underlying_to(
                user, amount, pool::get_reserve_a_token_address(&reserve_data)
            );
        };

        // Emit a borrow event
        event::emit(
            Borrow {
                reserve: asset,
                user,
                on_behalf_of,
                amount,
                interest_rate_mode,
                borrow_rate: (
                    pool::get_reserve_current_variable_borrow_rate(&reserve_data) as u256
                ),
                referral_code,
            },
        );
    }

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    /// - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `on_behalf_of` address
    /// @param asset The address of the borrowed underlying asset previously borrowed
    /// @param amount The amount to repay
    /// - Send the value math_utils::u256_max() in order to repay the whole debt for `asset` on the specific `debtMode`
    /// @param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    /// @param on_behalf_of The address of the user who will get his debt reduced/removed. Should be the address of the
    /// user calling the function if he wants to reduce/remove his own debt, or the address of any other
    /// other borrower whose debt should be removed
    public entry fun repay(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
    ) {
        internal_repay(account, asset, amount, interest_rate_mode, on_behalf_of, false)
    }

    /// @notice Implements the repay feature. Repaying transfers the underlying back to the aToken and clears the
    /// equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
    /// reduces the isolated debt.
    /// @dev  Emits the `Repay()` event
    /// @param account The signer account
    /// @param asset The address of the underlying asset to repay
    /// @param amount The amount to be repaid. Can be `math_utils::u256_max()` to repay the whole debt
    /// @param interest_rate_mode The interest rate mode at which the user wants to repay: 2 for Variable
    /// @param on_behalf_of The address of the user who will repay the debt. Should be the address of the borrower itself
    /// calling the function if he wants to repay his own debt, or the address of the credit delegator
    /// if he wants to repay the debt of a borrower to whom he has given credit delegation allowance
    /// @param use_a_tokens If true, the user wants to repay using aTokens, otherwise he wants to repay using the underlying
    fun internal_repay(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        on_behalf_of: address,
        use_a_tokens: bool
    ) {
        let account_address = signer::address_of(account);
        assert!(
            account_address == on_behalf_of,
            error_config::get_esigner_and_on_behalf_of_no_same(),
        );

        let reserve_data = pool::get_reserve_data(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);

        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(&reserve_data);
        let variable_debt =
            pool::scaled_variable_token_balance_of(
                on_behalf_of, variable_debt_token_address
            );

        // validate repay
        validation_logic::validate_repay(
            account,
            &reserve_data,
            amount,
            interest_rate_mode,
            on_behalf_of,
            variable_debt,
        );

        let payback_amount = variable_debt;
        // Allows a user to repay with aTokens without leaving dust from interest.
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        if (use_a_tokens && amount == math_utils::u256_max()) {
            amount = pool::scaled_a_token_balance_of(account_address, a_token_address)
        };

        if (amount < payback_amount) {
            payback_amount = amount;
        };
        variable_debt_token_factory::burn(
            on_behalf_of,
            payback_amount,
            (pool::get_reserve_variable_borrow_index(&reserve_data) as u256),
            pool::get_reserve_variable_debt_token_address(&reserve_data),
        );

        // update pool interest rate
        let liquidity_added = if (use_a_tokens) { 0 }
        else {
            payback_amount
        };
        pool::update_interest_rates(&mut reserve_data, asset, liquidity_added, 0);

        let user_config_map = pool::get_user_configuration(on_behalf_of);
        // set borrowing
        if (variable_debt - payback_amount == 0) {
            user_config::set_borrowing(
                &mut user_config_map, (pool::get_reserve_id(&reserve_data) as u256), true
            );
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        // update reserve_data.isolation_mode_total_debt field
        isolation_mode_logic::update_isolated_debt_if_isolated(
            &user_config_map, &reserve_data, payback_amount
        );

        // If you choose to repay with AToken, burn Atoken
        if (use_a_tokens) {
            a_token_factory::burn(
                account_address,
                a_token_factory::get_token_account_address(a_token_address),
                payback_amount,
                (pool::get_reserve_liquidity_index(&reserve_data) as u256),
                a_token_address,
            );
        } else {
            mock_underlying_token_factory::transfer_from(
                account_address,
                a_token_factory::get_token_account_address(a_token_address),
                (payback_amount as u64),
                asset,
            );
            a_token_factory::handle_repayment(
                account_address,
                on_behalf_of,
                payback_amount,
                pool::get_reserve_a_token_address(&reserve_data),
            );
        };

        // Emit a Repay event
        event::emit(
            Repay {
                reserve: asset,
                user: on_behalf_of,
                repayer: account_address,
                amount: payback_amount,
                use_a_tokens,
            },
        );
    }

    /// @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
    /// equivalent debt tokens
    /// - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable debt tokens
    /// @dev  Passing math_utils::u256_max() as amount will clean up any residual aToken dust balance, if the user aToken
    /// balance is not enough to cover the whole debt
    /// @param account The signer account
    /// @param asset The address of the borrowed underlying asset previously borrowed
    /// @param amount The amount to repay
    /// @param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    public entry fun repay_with_a_tokens(
        account: &signer, asset: address, amount: u256, interest_rate_mode: u8
    ) {
        let account_address = signer::address_of(account);
        internal_repay(account, asset, amount, interest_rate_mode, account_address, true)
    }
}
