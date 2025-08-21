/// @title Borrow Logic Module
/// @author Aave
/// @notice Implements the base logic for all the actions related to borrowing
module aave_pool::borrow_logic {
    // imports
    use std::signer;
    use aptos_framework::event;

    use aave_config::error_config;
    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_pool::pool_fee_manager;
    use aave_pool::pool_logic;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::isolation_mode_logic;
    use aave_pool::pool;
    use aave_pool::validation_logic;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::events::Self;

    // Module friends
    friend aave_pool::flashloan_logic;

    // Event definitions
    #[event]
    /// @notice Emitted when a borrow occurs
    /// @dev Emitted on borrow() and flash_loan() when debt needs to be opened
    /// @param reserve The address of the underlying asset being borrowed
    /// @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
    ///  initiator of the transaction on flash_loan()
    /// @param on_behalf_of The address that will be getting the debt
    /// @param amount The amount borrowed out
    /// @param interest_rate_mode The rate mode: 2 for Variable
    /// @param borrow_rate The numeric rate at which the user has borrowed, expressed in ray
    /// @param referral_code The referral code used
    struct Borrow has store, drop {
        /// @dev The address of the borrowed underlying asset
        reserve: address,
        /// @dev The address of the user initiating the borrow
        user: address,
        /// @dev The address receiving the debt
        on_behalf_of: address,
        /// @dev The amount borrowed
        amount: u256,
        /// @dev The interest rate mode (2 for Variable)
        interest_rate_mode: u8,
        /// @dev The borrow rate in ray
        borrow_rate: u256,
        /// @dev The referral code
        referral_code: u16
    }

    #[event]
    /// @notice Emitted when a repayment occurs
    /// @dev Emitted on repay()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The beneficiary of the repayment, getting his debt reduced
    /// @param repayer The address of the user initiating the repay(), providing the funds
    /// @param amount The amount repaid
    /// @param use_a_tokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
    struct Repay has store, drop {
        /// @dev The address of the underlying asset
        reserve: address,
        /// @dev The address of the user whose debt is being repaid
        user: address,
        /// @dev The address of the repayer
        repayer: address,
        /// @dev The amount repaid
        amount: u256,
        /// @dev Whether aTokens were used for repayment
        use_a_tokens: bool
    }

    // Public entry functions
    /// @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    /// already supplied enough collateral
    /// - E.g. User borrows 100 USDC passing as `on_behalf_of` his own address, receiving the 100 USDC in his wallet
    /// and 100 variable debt tokens, depending on the `interest_rate_mode`
    /// @dev Emits the `Borrow()` event
    /// @param account The signer account of the caller
    /// @param asset The address of the underlying asset to borrow
    /// @param amount The amount to be borrowed
    /// @param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
    /// @param referral_code The code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    /// @param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
    public entry fun borrow(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
        on_behalf_of: address
    ) {
        // Collect an extra gas fee if applicable
        pool_fee_manager::collect_apt_fee(account, asset);

        internal_borrow(
            signer::address_of(account),
            asset,
            amount,
            interest_rate_mode,
            referral_code,
            on_behalf_of,
            true
        );
    }

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    /// - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `on_behalf_of` address
    /// @param account The signer account of the caller
    /// @param asset The address of the borrowed underlying asset previously borrowed
    /// @param amount The amount to repay
    /// - Send the value math_utils::u256_max() in order to repay the whole debt for `asset` on the specific `interest_rate_mode`
    /// @param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 2 for Variable
    /// @param on_behalf_of The address of the user who will get his debt reduced/removed. Should be the address of the
    /// user calling the function if he wants to reduce/remove his own debt, or the address of any other
    /// other borrower whose debt should be removed
    public entry fun repay(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        on_behalf_of: address
    ) {
        internal_repay(
            account,
            asset,
            amount,
            interest_rate_mode,
            on_behalf_of,
            false
        )
    }

    /// @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
    /// equivalent debt tokens
    /// - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable debt tokens
    /// @dev Passing math_utils::u256_max() as amount will clean up any residual aToken dust balance, if the user aToken
    /// balance is not enough to cover the whole debt
    /// @param account The signer account of the caller
    /// @param asset The address of the borrowed underlying asset previously borrowed
    /// @param amount The amount to repay
    /// @param interest_rate_mode The interest rate mode at of the debt the user wants to repay: 2 for Variable
    public entry fun repay_with_a_tokens(
        account: &signer,
        asset: address,
        amount: u256,
        interest_rate_mode: u8
    ) {
        let account_address = signer::address_of(account);
        internal_repay(
            account,
            asset,
            amount,
            interest_rate_mode,
            account_address,
            true
        )
    }

    // Friend functions
    /// @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
    /// Aave protocol proportionally to their collateralization power. For isolated positions, it also increases the
    /// isolated debt.
    /// @dev Only callable by the borrow_logic and flashloan_logic module
    /// @dev Emits the `Borrow()` event
    /// @param user The address of the caller
    /// @param asset The address of the underlying asset to borrow
    /// @param amount The amount to be borrowed
    /// @param interest_rate_mode The interest rate mode at which the user wants to borrow: 2 for Variable
    /// @param referral_code The code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle
    /// @param on_behalf_of The address of the user who will receive the debt. Should be the address of the borrower itself
    /// @param release_underlying If true, the underlying asset will be transferred to the user, otherwise it will stay
    public(friend) fun internal_borrow(
        user: address,
        asset: address,
        amount: u256,
        interest_rate_mode: u8,
        referral_code: u16,
        on_behalf_of: address,
        release_underlying: bool
    ) {
        // Verify that the user and on_behalf_of addresses match
        assert!(
            user == on_behalf_of, error_config::get_esigner_and_on_behalf_of_not_same()
        );

        // Get reserve data and cache
        let reserve_data = pool::get_reserve_data(asset);
        let reserves_count = pool::number_of_active_and_dropped_reserves();
        let reserve_cache = pool_logic::cache(reserve_data);

        // Update pool state
        pool_logic::update_state(reserve_data, &mut reserve_cache);

        // Get user configuration and isolation mode state
        let user_config_map = pool::get_user_configuration(on_behalf_of);
        let (
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        ) = pool::get_isolation_mode_state(&user_config_map);

        // Get eMode configuration
        let user_emode_category = emode_logic::get_user_emode(on_behalf_of);
        let (emode_ltv, emode_liq_threshold) =
            emode_logic::get_emode_configuration(user_emode_category);

        // Validate borrow parameters
        validation_logic::validate_borrow(
            &reserve_cache,
            &user_config_map,
            asset,
            on_behalf_of,
            amount,
            interest_rate_mode,
            reserves_count,
            user_emode_category,
            emode_ltv,
            emode_liq_threshold,
            isolation_mode_active,
            isolation_mode_collateral_address,
            isolation_mode_debt_ceiling
        );

        // Mint variable debt tokens to the borrower
        let variable_debt_token_address =
            pool_logic::get_variable_debt_token_address(&reserve_cache);
        let is_first_borrowing =
            variable_debt_token_factory::mint(
                user,
                on_behalf_of,
                amount,
                pool_logic::get_next_variable_borrow_index(&reserve_cache),
                variable_debt_token_address
            );

        // Update reserve cache with new debt
        let next_scaled_variable_debt =
            variable_debt_token_factory::scaled_total_supply(variable_debt_token_address);
        pool_logic::set_next_scaled_variable_debt(
            &mut reserve_cache, next_scaled_variable_debt
        );

        // Update user configuration if first time borrowing
        if (is_first_borrowing) {
            let reserve_id = pool::get_reserve_id(reserve_data);
            user_config::set_borrowing(&mut user_config_map, (reserve_id as u256), true);
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        // Update isolation mode debt if applicable
        if (isolation_mode_active) {
            let isolation_mode_collateral_reserve_data =
                pool::get_reserve_data(isolation_mode_collateral_address);
            let isolation_mode_total_debt =
                pool::get_reserve_isolation_mode_total_debt(
                    isolation_mode_collateral_reserve_data
                );
            let reserve_configuration_map =
                pool_logic::get_reserve_cache_configuration(&reserve_cache);
            let decimals =
                reserve_config::get_decimals(&reserve_configuration_map)
                    - reserve_config::get_debt_ceiling_decimals();

            let next_isolation_mode_total_debt =
                (isolation_mode_total_debt as u256)
                    + (math_utils::ceil_div(amount, math_utils::pow(10, decimals)));
            // Update isolation_mode_total_debt
            pool::set_reserve_isolation_mode_total_debt(
                isolation_mode_collateral_reserve_data,
                (next_isolation_mode_total_debt as u128)
            );

            // Emit event for isolation mode debt update
            events::emit_isolated_mode_total_debt_updated(
                isolation_mode_collateral_address, next_isolation_mode_total_debt
            );
        };

        // Update pool interest rates
        let liquidity_taken = if (release_underlying) { amount }
        else { 0 };
        pool_logic::update_interest_rates_and_virtual_balance(
            reserve_data,
            &reserve_cache,
            asset,
            0,
            liquidity_taken
        );

        // Transfer underlying asset to borrower if requested
        if (release_underlying) {
            a_token_factory::transfer_underlying_to(
                user,
                amount,
                pool_logic::get_a_token_address(&reserve_cache)
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
                    pool::get_reserve_current_variable_borrow_rate(reserve_data) as u256
                ),
                referral_code
            }
        );
    }

    // Private functions
    /// @notice Implements the repay feature. Repaying transfers the underlying back to the aToken and clears the
    /// equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
    /// reduces the isolated debt.
    /// @dev Emits the `Repay()` event
    /// @param account The signer account of the caller
    /// @param asset The address of the underlying asset to repay
    /// @param amount The amount to be repaid. Can be `math_utils::u256_max()` to repay the whole debt
    /// @param interest_rate_mode The interest rate mode at which the user wants to repay: 2 for Variable
    /// @param on_behalf_of The address of the user who had the borrow position opened.
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

        // Get reserve data and cache
        let reserve_data = pool::get_reserve_data(asset);
        let reserve_cache = pool_logic::cache(reserve_data);

        // Update pool state
        pool_logic::update_state(reserve_data, &mut reserve_cache);

        // Get variable debt information
        let variable_debt_token_address =
            pool_logic::get_variable_debt_token_address(&reserve_cache);
        let variable_debt =
            variable_debt_token_factory::balance_of(
                on_behalf_of, variable_debt_token_address
            );

        // Validate repay parameters
        validation_logic::validate_repay(
            account_address,
            &reserve_cache,
            amount,
            interest_rate_mode,
            on_behalf_of,
            variable_debt
        );

        // Collect an extra gas fee if applicable
        pool_fee_manager::collect_apt_fee(account, asset);

        // Calculate actual repayment amount
        let payback_amount = variable_debt;
        let a_token_address = pool_logic::get_a_token_address(&reserve_cache);

        // Allows a user to repay with aTokens without leaving dust from interest
        if (use_a_tokens && amount == math_utils::u256_max()) {
            amount = a_token_factory::balance_of(account_address, a_token_address)
        };

        if (amount < payback_amount) {
            payback_amount = amount;
        };

        // Burn variable debt tokens
        variable_debt_token_factory::burn(
            on_behalf_of,
            payback_amount,
            pool_logic::get_next_variable_borrow_index(&reserve_cache),
            variable_debt_token_address
        );

        // Update reserve cache with new debt
        let next_scaled_variable_debt =
            variable_debt_token_factory::scaled_total_supply(variable_debt_token_address);
        pool_logic::set_next_scaled_variable_debt(
            &mut reserve_cache, next_scaled_variable_debt
        );

        // Update pool interest rates
        let liquidity_added = if (use_a_tokens) { 0 }
        else {
            payback_amount
        };
        pool_logic::update_interest_rates_and_virtual_balance(
            reserve_data,
            &reserve_cache,
            asset,
            liquidity_added,
            0
        );

        // Update user configuration if debt is fully repaid
        let user_config_map = pool::get_user_configuration(on_behalf_of);
        if (variable_debt - payback_amount == 0) {
            user_config::set_borrowing(
                &mut user_config_map,
                (pool::get_reserve_id(reserve_data) as u256),
                false
            );
            pool::set_user_configuration(on_behalf_of, user_config_map);
        };

        // Update isolation mode debt if applicable
        isolation_mode_logic::update_isolated_debt_if_isolated(
            &user_config_map,
            &reserve_cache,
            payback_amount
        );

        // Process repayment using aTokens or underlying asset
        if (use_a_tokens) {
            // If repaying with aTokens, burn them
            a_token_factory::burn(
                account_address,
                a_token_factory::get_token_account_address(a_token_address),
                payback_amount,
                pool_logic::get_next_liquidity_index(&reserve_cache),
                a_token_address
            );

            // Check if collateral state needs to be updated
            let reserve_id = (pool::get_reserve_id(reserve_data) as u256);
            let is_collateral =
                user_config::is_using_as_collateral(&user_config_map, reserve_id);
            if (is_collateral
                && a_token_factory::scaled_balance_of(account_address, a_token_address)
                    == 0) {
                user_config::set_using_as_collateral(
                    &mut user_config_map, reserve_id, false
                );
                // If repay with aTokens, on_behalf_of must be the same as account_address
                // should update user_config_map for the caller, which is account_address
                // however on_behalf_of is passed in as a parameter
                // to be consistent with code context of line #344, let user_config_map = pool::get_user_configuration(on_behalf_of);
                pool::set_user_configuration(on_behalf_of, user_config_map);
                events::emit_reserve_used_as_collateral_disabled(asset, account_address);
            };
        } else {
            // If repaying with underlying asset, transfer it to the aToken
            fungible_asset_manager::transfer(
                account,
                a_token_factory::get_token_account_address(a_token_address),
                (payback_amount as u64),
                asset
            );
            a_token_factory::handle_repayment(
                account_address,
                on_behalf_of,
                payback_amount,
                a_token_address
            );
        };

        // Emit a Repay event
        event::emit(
            Repay {
                reserve: asset,
                user: on_behalf_of,
                repayer: account_address,
                amount: payback_amount,
                use_a_tokens
            }
        );
    }
}
