/// @title Supply Logic Module
/// @author Aave
/// @notice Implements the logic for supply and withdraw operations
module aave_pool::supply_logic {
    // imports
    use std::signer;
    use aptos_framework::event;
    use aptos_framework::object;

    use aave_config::error_config;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_pool::pool_fee_manager;
    use aave_pool::pool_logic;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::pool;
    use aave_pool::validation_logic;
    use aave_pool::events::Self;
    use aave_pool::coin_migrator::Self;

    // Events
    #[event]
    /// @dev Emitted on supply()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address initiating the supply
    /// @param on_behalf_of The beneficiary of the supply, receiving the aTokens
    /// @param amount The amount supplied
    /// @param referral_code The referral code used
    struct Supply has store, drop {
        reserve: address,
        user: address,
        on_behalf_of: address,
        amount: u256,
        referral_code: u16
    }

    #[event]
    /// @dev Emitted on withdraw()
    /// @param reserve The address of the underlying asset being withdrawn
    /// @param user The address initiating the withdrawal, owner of aTokens
    /// @param to The address that will receive the underlying
    /// @param amount The amount to be withdrawn
    struct Withdraw has store, drop {
        reserve: address,
        user: address,
        to: address,
        amount: u256
    }

    // Public entry functions
    /// @notice Supplies an `amount` of underlying fungible asset into the reserve, receiving in return overlying aTokens.
    /// - E.g. User supplies 100 USDC and gets in return 100 aUSDC
    /// @param account The account signer that will supply the asset
    /// @param asset The address of the underlying fungible asset to supply
    /// @param amount The amount to be supplied
    /// @param on_behalf_of The address that will receive the aTokens, same as account address if the user
    /// wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    /// is a different wallet
    /// @param referral_code Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    public entry fun supply(
        account: &signer,
        asset: address,
        amount: u256,
        on_behalf_of: address,
        referral_code: u16
    ) {
        let account_address = signer::address_of(account);
        let reserve_data = pool::get_reserve_data(asset);
        let reserve_cache = pool_logic::cache(reserve_data);
        // update pool state
        pool_logic::update_state(reserve_data, &mut reserve_cache);

        // validate supply
        validation_logic::validate_supply(
            &reserve_cache,
            reserve_data,
            amount,
            on_behalf_of
        );

        // collect an extra fee if applicable
        pool_fee_manager::collect_apt_fee(account, asset);

        // update interest rates
        pool_logic::update_interest_rates_and_virtual_balance(
            reserve_data, &reserve_cache, asset, amount, 0
        );

        let token_a_address = pool_logic::get_a_token_address(&reserve_cache);
        let a_token_resource_account =
            a_token_factory::get_token_account_address(token_a_address);
        // transfer the asset to the a_token address
        fungible_asset_manager::transfer(
            account,
            a_token_resource_account,
            (amount as u64),
            asset
        );

        let is_first_supply =
            a_token_factory::mint(
                account_address,
                on_behalf_of,
                amount,
                pool_logic::get_next_liquidity_index(&reserve_cache),
                token_a_address
            );

        if (is_first_supply) {
            let user_config_map = pool::get_user_configuration(on_behalf_of);
            let reserve_config_map =
                pool_logic::get_reserve_cache_configuration(&reserve_cache);
            if (validation_logic::validate_automatic_use_as_collateral(
                &user_config_map, &reserve_config_map
            )) {
                user_config::set_using_as_collateral(
                    &mut user_config_map,
                    (pool::get_reserve_id(reserve_data) as u256),
                    true
                );
                pool::set_user_configuration(on_behalf_of, user_config_map);
                events::emit_reserve_used_as_collateral_enabled(asset, on_behalf_of);
            }
        };
        // Emit a supply event
        event::emit(
            Supply {
                reserve: asset,
                user: account_address,
                on_behalf_of,
                amount,
                referral_code
            }
        );
    }

    /// @notice Supplies an `amount` of underlying asset of type Coin into the reserve, receiving in return overlying aTokens.
    /// - E.g. User supplies 100 APT and gets in return 100 aAPT
    /// @param account The account signer that will supply the asset
    /// @param asset The address of the underlying asset of type coin to supply
    /// @param amount The amount to be supplied
    /// @param on_behalf_of The address that will receive the aTokens, same as account address if the user
    /// wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    /// is a different wallet
    /// @param referral_code Code used to register the integrator originating the operation, for potential rewards.
    /// 0 if the action is executed directly by the user, without any middle-man
    public entry fun supply_coin<CoinType>(
        account: &signer,
        amount: u256,
        on_behalf_of: address,
        referral_code: u16
    ) {
        let wrapped_fa_meta = coin_migrator::coin_to_fa<CoinType>(
            account, (amount as u64)
        );
        let wrapped_fa_address = object::object_address(&wrapped_fa_meta);
        supply(
            account,
            wrapped_fa_address,
            amount,
            on_behalf_of,
            referral_code
        );
    }

    /// @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    /// @param account The account signer that will withdraw the asset
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    ///   - Send the value math_utils::u256_max() in order to withdraw the whole aToken balance
    /// @param to The address that will receive the underlying, same as account address if the user
    ///   wants to receive it on his own wallet, or a different address if the beneficiary is a
    ///   different wallet
    public entry fun withdraw(
        account: &signer,
        asset: address,
        amount: u256,
        to: address
    ) {
        let account_address = signer::address_of(account);
        let reserve_data = pool::get_reserve_data(asset);
        let reserves_count = pool::number_of_active_and_dropped_reserves();
        let reserve_cache = pool_logic::cache(reserve_data);

        let a_token_address = pool_logic::get_a_token_address(&reserve_cache);
        let a_token_resource_account =
            a_token_factory::get_token_account_address(a_token_address);
        assert!(to != a_token_resource_account, error_config::get_ewithdraw_to_atoken());

        // update pool state
        pool_logic::update_state(reserve_data, &mut reserve_cache);

        let user_balance =
            wad_ray_math::ray_mul_down(
                a_token_factory::scaled_balance_of(account_address, a_token_address),
                pool_logic::get_next_liquidity_index(&reserve_cache)
            );
        let amount_to_withdraw = amount;
        if (amount == math_utils::u256_max()) {
            amount_to_withdraw = user_balance;
        };

        // validate withdraw
        validation_logic::validate_withdraw(
            &reserve_cache, amount_to_withdraw, user_balance
        );

        // collect an extra fee if applicable
        pool_fee_manager::collect_apt_fee(account, asset);

        // update interest rates
        pool_logic::update_interest_rates_and_virtual_balance(
            reserve_data,
            &reserve_cache,
            asset,
            0,
            amount_to_withdraw
        );

        let user_config_map = pool::get_user_configuration(account_address);
        let reserve_id = pool::get_reserve_id(reserve_data);
        let is_collateral =
            user_config::is_using_as_collateral(&user_config_map, (reserve_id as u256));

        if (is_collateral && amount_to_withdraw == user_balance) {
            user_config::set_using_as_collateral(
                &mut user_config_map,
                (reserve_id as u256),
                false
            );
            pool::set_user_configuration(account_address, user_config_map);
            events::emit_reserve_used_as_collateral_disabled(asset, account_address);
        };

        // burn a token
        a_token_factory::burn(
            account_address,
            to,
            amount_to_withdraw,
            pool_logic::get_next_liquidity_index(&reserve_cache),
            a_token_address
        );

        if (is_collateral && user_config::is_borrowing_any(&user_config_map)) {
            let user_emode_category = emode_logic::get_user_emode(account_address);
            let (emode_ltv, emode_liq_threshold) =
                emode_logic::get_emode_configuration(user_emode_category);
            // validate health factor and ltv
            validation_logic::validate_hf_and_ltv(
                &user_config_map,
                asset,
                account_address,
                reserves_count,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold
            );
        };
        // Emit a withdraw event
        event::emit(
            Withdraw {
                reserve: asset,
                user: account_address,
                to,
                amount: amount_to_withdraw
            }
        );
    }

    /// @notice Allows suppliers to enable/disable a specific supplied asset as collateral
    /// @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
    /// @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
    /// @param account The account signer that will enable/disable the usage of the asset as collateral
    /// @param asset The address of the underlying asset supplied
    /// @param use_as_collateral True if the user wants to use the supply as collateral, false otherwise
    public entry fun set_user_use_reserve_as_collateral(
        account: &signer, asset: address, use_as_collateral: bool
    ) {
        let account_address = signer::address_of(account);
        let reserve_data = pool::get_reserve_data(asset);
        let reserves_count = pool::number_of_active_and_dropped_reserves();
        let reserve_cache = pool_logic::cache(reserve_data);

        let user_balance =
            a_token_factory::balance_of(
                account_address,
                pool_logic::get_a_token_address(&reserve_cache)
            );

        let user_config_map = pool::get_user_configuration(account_address);
        let reserve_id = (pool::get_reserve_id(reserve_data) as u256);
        let is_collateral =
            user_config::is_using_as_collateral(&user_config_map, reserve_id);
        // validate set use reserve as collateral
        validation_logic::validate_set_use_reserve_as_collateral(
            &reserve_cache,
            user_balance,
            is_collateral,
            use_as_collateral
        );

        if (use_as_collateral == is_collateral) { return };

        if (use_as_collateral) {
            let reserve_config_map =
                pool_logic::get_reserve_cache_configuration(&reserve_cache);
            assert!(
                validation_logic::validate_use_as_collateral(
                    &user_config_map, &reserve_config_map
                ),
                error_config::get_euser_in_isolation_mode_or_ltv_zero()
            );
            user_config::set_using_as_collateral(&mut user_config_map, reserve_id, true);
            pool::set_user_configuration(account_address, user_config_map);
            events::emit_reserve_used_as_collateral_enabled(asset, account_address);
        } else {
            user_config::set_using_as_collateral(&mut user_config_map, reserve_id, false);
            pool::set_user_configuration(account_address, user_config_map);
            let user_emode_category = emode_logic::get_user_emode(account_address);
            let (emode_ltv, emode_liq_threshold) =
                emode_logic::get_emode_configuration(user_emode_category);

            validation_logic::validate_hf_and_ltv(
                &user_config_map,
                asset,
                account_address,
                reserves_count,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold
            );
            events::emit_reserve_used_as_collateral_disabled(asset, account_address);
        }
    }
}
