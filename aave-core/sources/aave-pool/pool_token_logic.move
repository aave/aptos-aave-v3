/// @title Pool Token Logic Module
/// @author Aave
/// @notice Implements token-related logic for the Aave protocol pool
module aave_pool::pool_token_logic {
    // imports
    use std::option::Option;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_framework::event;

    use aave_config::error_config;
    use aave_config::reserve_config;
    use aave_config::user_config;
    use aave_math::wad_ray_math;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::token_base;
    use aave_pool::emode_logic;
    use aave_pool::validation_logic;

    use aave_pool::a_token_factory;
    use aave_pool::fungible_asset_manager;
    use aave_pool::pool::Self;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::events::Self;

    // friend modules
    friend aave_pool::pool_configurator;

    // Events
    #[event]
    /// @notice Emitted when a reserve is initialized
    /// @param asset The address of the underlying asset of the reserve
    /// @param a_token The address of the associated aToken contract
    /// @param variable_debt_token The address of the associated variable rate debt token
    struct ReserveInitialized has store, drop {
        /// Address of the underlying asset
        asset: address,
        /// Address of the corresponding aToken
        a_token: address,
        /// Address of the corresponding variable debt token
        variable_debt_token: address
    }

    #[event]
    /// @notice Emitted when the protocol treasury receives minted aTokens from the accrued interest
    /// @param reserve The address of the reserve
    /// @param amount_minted The amount minted to the treasury
    struct MintedToTreasury has store, drop {
        reserve: address,
        amount_minted: u256
    }

    // Public entry functions
    /// @notice Sets an incentives controller for the both aToken and variable debt token of a given underlying asset
    /// @param admin The address of the admin calling the method
    /// @param underlying_asset The address of the underlying asset
    /// @param incentives_controller The address of the incentives controller
    public entry fun set_incentives_controller(
        admin: &signer, underlying_asset: address, incentives_controller: Option<address>
    ) {
        // Check if underlying_asset exists
        fungible_asset_manager::assert_token_exists(underlying_asset);
        // check if the asset is listed
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        variable_debt_token_factory::set_incentives_controller(
            admin, variable_debt_token_address, incentives_controller
        );
        a_token_factory::set_incentives_controller(
            admin, a_token_address, incentives_controller
        );
    }

    /// @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
    /// @param assets The list of reserves for which the minting needs to be executed
    public entry fun mint_to_treasury(assets: vector<address>) {
        for (i in 0..vector::length(&assets)) {
            let asset_address = *vector::borrow(&assets, i);
            let reserve_data = pool::get_reserve_data(asset_address);
            let reserve_config_map =
                pool::get_reserve_configuration_by_reserve_data(reserve_data);

            if (!reserve_config::get_active(&reserve_config_map)) {
                continue
            };

            let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(reserve_data);
            if (accrued_to_treasury != 0) {
                pool::set_reserve_accrued_to_treasury(reserve_data, 0);

                let normalized_income =
                    pool::get_reserve_normalized_income(asset_address);
                let amount_to_mint =
                    wad_ray_math::ray_mul(accrued_to_treasury, normalized_income);

                a_token_factory::mint_to_treasury(
                    amount_to_mint,
                    normalized_income,
                    pool::get_reserve_a_token_address(reserve_data)
                );

                event::emit(
                    MintedToTreasury {
                        reserve: asset_address,
                        amount_minted: amount_to_mint
                    }
                );
            };
        }
    }

    /// @notice Transfers aTokens from the user to the recipient
    /// @param sender The account signer of the caller
    /// @param recipient The recipient of the aTokens
    /// @param amount The amount of aTokens to transfer
    /// @param a_token_address The address of the aToken
    public entry fun transfer(
        sender: &signer,
        recipient: address,
        amount: u256,
        a_token_address: address
    ) {
        assert!(amount > 0, error_config::get_einvalid_amount());
        let sender_address = signer::address_of(sender);
        let underlying_asset =
            a_token_factory::get_underlying_asset_address(a_token_address);
        let index = pool::get_reserve_normalized_income(underlying_asset);
        let from_balance_before =
            wad_ray_math::ray_mul(
                a_token_factory::scaled_balance_of(sender_address, a_token_address),
                index
            );
        let to_balance_before =
            wad_ray_math::ray_mul(
                a_token_factory::scaled_balance_of(recipient, a_token_address),
                index
            );
        token_base::transfer(
            sender_address,
            recipient,
            amount,
            index,
            a_token_address
        );

        finalize_transfer(
            underlying_asset,
            sender_address,
            recipient,
            amount,
            from_balance_before,
            to_balance_before
        );

        // send balance transfer event
        events::emit_balance_transfer(
            sender_address,
            recipient,
            wad_ray_math::ray_div(amount, index),
            index,
            a_token_address
        );
    }

    // Public friend functions
    /// @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
    /// interest rate strategy
    /// @dev Only callable by the pool_configurator module
    /// @param account The address of the caller
    /// @param underlying_asset The address of the underlying asset of the reserve
    /// @param treasury The address of the treasury
    /// @param incentives_controller The address of the incentives controller, if any
    /// @param a_token_name The name of the aToken
    /// @param a_token_symbol The symbol of the aToken
    /// @param variable_debt_token_name The name of the variable debt token
    /// @param variable_debt_token_symbol The symbol of the variable debt token
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    public(friend) fun init_reserve(
        account: &signer,
        underlying_asset: address,
        treasury: address,
        incentives_controller: Option<address>, // NOTE: shared by both AToken and DebtToken
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) {
        // Check if underlying_asset exists
        fungible_asset_manager::assert_token_exists(underlying_asset);

        // Assert that the asset is not already added
        assert!(
            !pool::asset_exists(underlying_asset),
            error_config::get_ereserve_already_added()
        );

        let underlying_asset_decimals =
            fungible_asset_manager::decimals(underlying_asset);

        // Assert that the asset decimals satisfy the min requirement
        assert!(
            (underlying_asset_decimals as u256)
                >= reserve_config::get_min_reserve_asset_decimals(),
            error_config::get_emin_asset_decimal_places()
        );

        // Create a token for the underlying asset
        let a_token_address =
            a_token_factory::create_token(
                account,
                a_token_name,
                a_token_symbol,
                underlying_asset_decimals,
                utf8(b""),
                utf8(b""),
                incentives_controller,
                underlying_asset,
                treasury
            );

        // Create variable debt token for the underlying asset
        let variable_debt_token_address =
            variable_debt_token_factory::create_token(
                account,
                variable_debt_token_name,
                variable_debt_token_symbol,
                underlying_asset_decimals,
                utf8(b""),
                utf8(b""),
                incentives_controller,
                underlying_asset
            );

        // Set the reserve configuration
        let reserve_configuration = reserve_config::init();
        reserve_config::set_decimals(
            &mut reserve_configuration, (underlying_asset_decimals as u256)
        );
        reserve_config::set_active(&mut reserve_configuration, true);
        reserve_config::set_paused(&mut reserve_configuration, false);
        reserve_config::set_frozen(&mut reserve_configuration, false);

        // Create the reserve
        let _reserve_data =
            pool::new_reserve_data(
                account,
                underlying_asset,
                a_token_address,
                variable_debt_token_address,
                reserve_configuration
            );

        default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
            underlying_asset,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // emit the ReserveInitialized event
        event::emit(
            ReserveInitialized {
                asset: underlying_asset,
                a_token: a_token_address,
                variable_debt_token: variable_debt_token_address
            }
        )
    }

    /// @notice Drop a reserve
    /// @dev Only callable by the pool_configurator module
    /// @param asset The address of the underlying asset of the reserve
    public(friend) fun drop_reserve(asset: address) {
        assert!(asset != @0x0, error_config::get_ezero_address_not_valid());

        // check if the asset is listed
        let reserve_data = pool::get_reserve_data(asset);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let variable_debt_token_total_supply =
            variable_debt_token_factory::total_supply(variable_debt_token_address);
        assert!(
            variable_debt_token_total_supply == 0,
            error_config::get_evariable_debt_supply_not_zero()
        );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let a_token_total_supply = a_token_factory::total_supply(a_token_address);
        assert!(
            a_token_total_supply == 0
                && pool::get_reserve_accrued_to_treasury(reserve_data) == 0,
            error_config::get_eunderlying_claimable_rights_not_zero()
        );

        // Check for remaining underlying assets in the resource account and transfer to treasury
        let remaining_underlying_balance =
            fungible_asset_manager::balance_of(
                a_token_factory::get_token_account_address(a_token_address),
                asset
            );

        if (remaining_underlying_balance > 0) {
            // Get treasury address from aToken
            let treasury_address =
                a_token_factory::get_reserve_treasury_address(a_token_address);

            // Transfer remaining underlying assets to treasury using a_token_factory
            a_token_factory::transfer_underlying_to(
                treasury_address,
                (remaining_underlying_balance as u256),
                a_token_address
            );
        };

        // Remove the ReserveList from the smart table
        let active_reserve_count = pool::number_of_active_reserves();
        pool::delete_reserve_data(asset);

        // assert assets count in storage
        assert!(
            pool::number_of_active_reserves() == active_reserve_count - 1,
            error_config::get_ereserves_storage_count_mismatch()
        );

        // drop a token and variable debt token associated data
        a_token_factory::drop_token(a_token_address);
        variable_debt_token_factory::drop_token(variable_debt_token_address);
    }

    // Private functions
    /// @notice Validates and finalizes an aToken transfer
    /// @param asset The address of the underlying asset of the aToken
    /// @param from The user from which the aTokens are transferred
    /// @param to The user receiving the aTokens
    /// @param amount The unscaled amount being transferred/withdrawn
    /// @param balance_from_before The aToken balance of the `from` user before the transfer
    /// @param balance_to_before The aToken balance of the `to` user before the transfer
    fun finalize_transfer(
        asset: address,
        from: address,
        to: address,
        amount: u256,
        balance_from_before: u256,
        balance_to_before: u256
    ) {
        let reserve_data = pool::get_reserve_data(asset);
        let liquidity_index = pool::get_normalized_income_by_reserve_data(reserve_data);
        let reserves_count = pool::number_of_active_and_dropped_reserves();
        let scaled_amount = wad_ray_math::ray_div(amount, liquidity_index);

        // validate transfer
        validation_logic::validate_transfer(reserve_data);

        let reserve_id = (pool::get_reserve_id(reserve_data) as u256);
        if (from != to && scaled_amount != 0) {
            let from_config = pool::get_user_configuration(from);
            if (user_config::is_using_as_collateral(&from_config, reserve_id)) {
                if (user_config::is_borrowing_any(&from_config)) {
                    let user_emode_category = emode_logic::get_user_emode(from);
                    let (emode_ltv, emode_liq_threshold) =
                        emode_logic::get_emode_configuration(user_emode_category);

                    validation_logic::validate_hf_and_ltv(
                        &from_config,
                        asset,
                        from,
                        reserves_count,
                        user_emode_category,
                        emode_ltv,
                        emode_liq_threshold
                    );
                };

                if (balance_from_before == amount) {
                    user_config::set_using_as_collateral(
                        &mut from_config, reserve_id, false
                    );
                    pool::set_user_configuration(from, from_config);
                    events::emit_reserve_used_as_collateral_disabled(asset, from);
                }
            };

            if (balance_to_before == 0) {
                let to_config = pool::get_user_configuration(to);
                let reserve_config_map =
                    pool::get_reserve_configuration_by_reserve_data(reserve_data);
                if (validation_logic::validate_automatic_use_as_collateral(
                    &to_config, &reserve_config_map
                )) {
                    user_config::set_using_as_collateral(&mut to_config, reserve_id, true);
                    pool::set_user_configuration(to, to_config);
                    events::emit_reserve_used_as_collateral_enabled(asset, to);
                }
            }
        }
    }

    // Test only functions
    #[test_only]
    /// @notice Initializes a reserve for testing
    /// @param account The address of the caller
    /// @param underlying_asset The address of the underlying asset of the reserve
    /// @param treasury The address of the treasury
    /// @param incentives_controller The address of the incentives controller, if any
    /// @param a_token_name The name of the aToken
    /// @param a_token_symbol The symbol of the aToken
    /// @param variable_debt_token_name The name of the variable debt token
    /// @param variable_debt_token_symbol The symbol of the variable debt token
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    public fun test_init_reserve(
        account: &signer,
        underlying_asset: address,
        treasury: address,
        incentives_controller: Option<address>, // NOTE: shared by both AToken and DebtToken
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) {
        init_reserve(
            account,
            underlying_asset,
            treasury,
            incentives_controller,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
    }

    #[test_only]
    /// @notice Drops a reserve for testing
    /// @param asset The address of the underlying asset of the reserve
    public fun test_drop_reserve(asset: address) {
        drop_reserve(asset);
    }
}
