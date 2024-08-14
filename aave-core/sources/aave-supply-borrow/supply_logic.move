module aave_pool::supply_logic {
    use std::signer;
    use aptos_framework::event;

    use aave_config::error as error_config;
    use aave_config::user as user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::emode_logic;
    use aave_pool::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_pool::pool_validation;
    use aave_pool::validation_logic;

    #[event]
    /// @dev Emitted on supply()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address initiating the supply
    /// @param on_behalf_of The beneficiary of the supply, receiving the aTokens
    /// @param amount The amount supplied
    /// @param referral_code The referral code used
    struct Supply has drop, copy, store {
        reserve: address,
        user: address,
        on_behalf_of: address,
        amount: u256,
        referral_code: u16,
    }

    #[event]
    /// @dev Emitted on withdraw()
    /// @param reserve The address of the underlying asset being withdrawn
    /// @param user The address initiating the withdrawal, owner of aTokens
    /// @param to The address that will receive the underlying
    /// @param amount The amount to be withdrawn
    struct Withdraw has drop, store {
        reserve: address,
        user: address,
        to: address,
        amount: u256,
    }

    #[event]
    /// @dev Emitted on setUserUseReserveAsCollateral()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user enabling the usage as collateral
    struct ReserveUsedAsCollateralEnabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    /// @dev Emitted on setUserUseReserveAsCollateral()
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address of the user enabling the usage as collateral
    struct ReserveUsedAsCollateralDisabled has store, drop {
        reserve: address,
        user: address
    }

    /// @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    /// - E.g. User supplies 100 USDC and gets in return 100 aUSDC
    /// @param account The account that will supply the asset
    /// @param asset The address of the underlying asset to supply
    /// @param amount The amount to be supplied
    /// @param on_behalf_of The address that will receive the aTokens, same as msg.sender if the user
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
        assert!(
            account_address == on_behalf_of,
            error_config::get_esigner_and_on_behalf_of_no_same(),
        );
        let reserve_data = pool::get_reserve_data(asset);
        pool::update_state(asset, &mut reserve_data);
        validation_logic::validate_supply(&reserve_data, amount);
        pool::update_interest_rates(&mut reserve_data, asset, amount, 0);

        let token_a_address = pool::get_reserve_a_token_address(&reserve_data);
        let a_token_account = a_token_factory::get_token_account_address(token_a_address);
        // transfer the asset to the a_token address
        mock_underlying_token_factory::transfer_from(
            account_address, a_token_account, (amount as u64), asset
        );
        let is_first_supply: bool =
            a_token_factory::scaled_balance_of(on_behalf_of, token_a_address) == 0;
        a_token_factory::mint(
            account_address,
            on_behalf_of,
            amount,
            (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            token_a_address,
        );
        if (is_first_supply) {
            let user_config_map = pool::get_user_configuration(on_behalf_of);
            let reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(&reserve_data);
            if (pool_validation::validate_automatic_use_as_collateral(
                    account_address, &user_config_map, &reserve_config_map
                )) {
                user_config::set_using_as_collateral(
                    &mut user_config_map,
                    (pool::get_reserve_id(&reserve_data) as u256),
                    true,
                );
                pool::set_user_configuration(on_behalf_of, user_config_map);
                event::emit(
                    ReserveUsedAsCollateralEnabled { reserve: asset, user: on_behalf_of }
                );
            }
        };
        // Emit a supply event
        event::emit(
            Supply {
                reserve: asset,
                user: account_address,
                on_behalf_of,
                amount,
                referral_code,
            },
        );
    }

    /// @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    ///   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    /// @param to The address that will receive the underlying, same as msg.sender if the user
    ///   wants to receive it on his own wallet, or a different address if the beneficiary is a
    ///   different wallet
    public entry fun withdraw(
        account: &signer,
        asset: address,
        amount: u256,
        to: address,
    ) {
        let account_address = signer::address_of(account);
        assert!(
            account_address == to, error_config::get_esigner_and_on_behalf_of_no_same()
        );
        let (reserve_data, reserves_count) =
            pool::get_reserve_data_and_reserves_count(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);
        let user_balance =
            wad_ray_math::ray_mul(
                a_token_factory::scaled_balance_of(
                    account_address, pool::get_reserve_a_token_address(&reserve_data)
                ),
                (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            );
        let amount_to_withdraw = amount;
        if (amount == math_utils::u256_max()) {
            amount_to_withdraw = user_balance;
        };

        // validate withdraw
        validation_logic::validate_withdraw(
            &reserve_data, amount_to_withdraw, user_balance
        );

        // update interest rates
        pool::update_interest_rates(&mut reserve_data, asset, 0, amount_to_withdraw);

        let user_config_map = pool::get_user_configuration(account_address);
        let reserve_id = pool::get_reserve_id(&reserve_data);
        let is_collateral =
            user_config::is_using_as_collateral(&user_config_map, (reserve_id as u256));

        if (is_collateral && amount_to_withdraw == user_balance) {
            user_config::set_using_as_collateral(
                &mut user_config_map, (reserve_id as u256), false
            );
            pool::set_user_configuration(account_address, user_config_map);
            event::emit(
                ReserveUsedAsCollateralDisabled { reserve: asset, user: account_address }
            );
        };

        // burn a token
        a_token_factory::burn(
            account_address,
            to,
            amount_to_withdraw,
            (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            pool::get_reserve_a_token_address(&reserve_data),
        );

        if (is_collateral && user_config::is_borrowing_any(&user_config_map)) {
            let user_emode_category = (emode_logic::get_user_emode(account_address) as u8);
            let (emode_ltv, emode_liq_threshold, emode_asset_price) =
                emode_logic::get_emode_configuration(user_emode_category);
            pool_validation::validate_hf_and_ltv(
                &mut reserve_data,
                reserves_count,
                &user_config_map,
                account_address,
                user_emode_category,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price,
            );
        };
        // Emit a withdraw event
        event::emit(
            Withdraw {
                reserve: asset,
                user: account_address,
                to,
                amount: amount_to_withdraw
            },
        );
    }

    /// @notice Validates and finalizes an aToken transfer
    /// @dev Only callable by the overlying aToken of the `asset`
    /// @param asset The address of the underlying asset of the aToken
    /// @param from The user from which the aTokens are transferred
    /// @param to The user receiving the aTokens
    /// @param amount The amount being transferred/withdrawn
    /// @param balance_from_before The aToken balance of the `from` user before the transfer
    /// @param balance_to_before The aToken balance of the `to` user before the transfer
    public entry fun finalize_transfer(
        account: &signer,
        asset: address,
        from: address,
        to: address,
        amount: u256,
        balance_from_before: u256,
        balance_to_before: u256,
    ) {
        let account_address = signer::address_of(account);
        let (reserve_data, reserves_count) =
            pool::get_reserve_data_and_reserves_count(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        assert!(
            account_address == a_token_factory::get_token_account_address(
                a_token_address
            ),
            error_config::get_ecaller_not_atoken(),
        );
        // validate transfer
        validation_logic::validate_transfer(&reserve_data);

        let reserve_id = (pool::get_reserve_id(&reserve_data) as u256);
        if (from != to && amount != 0) {
            let from_config = pool::get_user_configuration(from);
            if (user_config::is_using_as_collateral(&from_config, reserve_id)) {
                if (user_config::is_borrowing_any(&from_config)) {
                    let user_emode_category = (emode_logic::get_user_emode(from) as u8);
                    let (emode_ltv, emode_liq_threshold, emode_asset_price) =
                        emode_logic::get_emode_configuration(user_emode_category);
                    pool_validation::validate_hf_and_ltv(
                        &mut reserve_data,
                        reserves_count,
                        &from_config,
                        from,
                        user_emode_category,
                        emode_ltv,
                        emode_liq_threshold,
                        emode_asset_price,
                    );
                };

                if (balance_from_before == amount) {
                    user_config::set_using_as_collateral(
                        &mut from_config, reserve_id, false
                    );
                    pool::set_user_configuration(from, from_config);
                    event::emit(
                        ReserveUsedAsCollateralDisabled { reserve: asset, user: from }
                    );
                }
            };

            if (balance_to_before == 0) {
                let to_config = pool::get_user_configuration(to);
                let reserve_config_map =
                    pool::get_reserve_configuration_by_reserve_data(&reserve_data);
                if (pool_validation::validate_automatic_use_as_collateral(
                        account_address, &to_config, &reserve_config_map
                    )) {
                    user_config::set_using_as_collateral(&mut to_config, reserve_id, true);
                    pool::set_user_configuration(to, to_config);
                    event::emit(
                        ReserveUsedAsCollateralEnabled { reserve: asset, user: to }
                    );
                }
            }
        }
    }

    /// @notice Allows suppliers to enable/disable a specific supplied asset as collateral
    /// @param asset The address of the underlying asset supplied
    /// @param use_as_collateral True if the user wants to use the supply as collateral, false otherwise
    public entry fun set_user_use_reserve_as_collateral(
        account: &signer, asset: address, use_as_collateral: bool
    ) {
        let account_address = signer::address_of(account);
        let (reserve_data, reserves_count) =
            pool::get_reserve_data_and_reserves_count(asset);
        let user_balance =
            pool::scaled_a_token_balance_of(
                account_address, pool::get_reserve_a_token_address(&reserve_data)
            );
        // validate set use reserve as collateral
        validation_logic::validate_set_use_reserve_as_collateral(
            &reserve_data, user_balance
        );

        let user_config_map = pool::get_user_configuration(account_address);

        let reserve_id = (pool::get_reserve_id(&reserve_data) as u256);
        if (use_as_collateral
                != user_config::is_using_as_collateral(&user_config_map, reserve_id)) {
            if (use_as_collateral) {
                let reserve_config_map =
                    pool::get_reserve_configuration_by_reserve_data(&reserve_data);
                assert!(
                    pool_validation::validate_use_as_collateral(
                        &user_config_map, &reserve_config_map
                    ),
                    error_config::get_euser_in_isolation_mode_or_ltv_zero(),
                );
                user_config::set_using_as_collateral(
                    &mut user_config_map, reserve_id, true
                );
                pool::set_user_configuration(account_address, user_config_map);
                event::emit(
                    ReserveUsedAsCollateralEnabled { reserve: asset, user: account_address }
                );
            } else {
                user_config::set_using_as_collateral(
                    &mut user_config_map, reserve_id, false
                );
                pool::set_user_configuration(account_address, user_config_map);
                let user_emode_category =
                    (emode_logic::get_user_emode(account_address) as u8);
                let (emode_ltv, emode_liq_threshold, emode_asset_price) =
                    emode_logic::get_emode_configuration(user_emode_category);
                pool_validation::validate_hf_and_ltv(
                    &mut reserve_data,
                    reserves_count,
                    &user_config_map,
                    account_address,
                    user_emode_category,
                    emode_ltv,
                    emode_liq_threshold,
                    emode_asset_price,
                );

                event::emit(
                    ReserveUsedAsCollateralDisabled {
                        reserve: asset,
                        user: account_address
                    },
                );
            }
        }
    }
}
