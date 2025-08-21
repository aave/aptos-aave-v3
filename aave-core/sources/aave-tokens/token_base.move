/// @title Token Base Module
/// @author Aave
/// @notice Base module for token implementations in the Aave protocol
/// @dev Provides core functionality for aTokens and debt tokens with scaled balances
module aave_pool::token_base {
    // imports
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::String;
    use aptos_std::smart_table;
    use aptos_std::smart_table::{SmartTable};
    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::{BurnRef, Metadata, MintRef, TransferRef};
    use aptos_framework::object;
    use aptos_framework::object::{ConstructorRef, Object};
    use aptos_framework::primary_fungible_store;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::wad_ray_math;
    use aave_pool::rewards_controller;

    // friend modules
    friend aave_pool::a_token_factory;
    friend aave_pool::variable_debt_token_factory;
    friend aave_pool::pool_token_logic;

    #[test_only]
    friend aave_pool::token_base_tests;

    // Error constants

    // Global Constants

    // Structs and Events
    #[event]
    /// @notice Emitted when tokens are moved from one account to another
    /// @dev Note that value may be zero
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param value The amount of tokens transferred
    /// @param token The address of the token
    struct Transfer has store, drop {
        from: address,
        to: address,
        value: u256,
        token: address
    }

    #[event]
    /// @notice Emitted after a mint action
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted tokens
    /// @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
    /// @param balance_increase The increase in scaled-up balance since the last action of 'on_behalf_of'
    /// @param index The next liquidity index of the reserve
    /// @param token The a/v token address
    struct Mint has store, drop {
        caller: address,
        on_behalf_of: address,
        value: u256,
        balance_increase: u256,
        index: u256,
        token: address
    }

    #[event]
    /// @notice Emitted after a burn action
    /// @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
    /// @param from The address from which the tokens will be burned
    /// @param target The address that will receive the underlying, if any
    /// @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
    /// @param balance_increase The increase in scaled-up balance since the last action of 'from'
    /// @param index The next liquidity index of the reserve
    /// @param token The a/v token address
    struct Burn has store, drop {
        from: address,
        target: address,
        value: u256,
        balance_increase: u256,
        index: u256,
        token: address
    }

    /// @notice Stores user-specific token data
    /// @param balance The scaled balance of the user
    /// @param additional_data The liquidity index at the time of last balance update
    struct UserState has store, copy, drop {
        balance: u128,
        additional_data: u128
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice Hold refs to control the minting, transfer and burning of fungible assets
    /// @param mint_ref Reference for minting tokens
    /// @param transfer_ref Reference for transferring tokens
    /// @param burn_ref Reference for burning tokens
    struct ManagedFungibleAsset has key, drop {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice Hold stateful information about tokens based on `ScaledBalanceTokenBase`
    /// @param scaled_total_supply The total supply of the token in scaled units
    /// @param user_state Mapping of user addresses to their state
    /// @param incentives_controller Address of the incentives controller, if set
    struct TokenBaseState has key {
        scaled_total_supply: u256,
        user_state: SmartTable<address, UserState>,
        incentives_controller: Option<address>
    }

    // Public view functions
    #[view]
    /// @notice Returns the last index when interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the token
    /// @return The last index when interest was accrued to the user's balance, in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 acquires TokenBaseState {
        let user_state = get_user_state(user, metadata_address);
        (user_state.additional_data as u256)
    }

    #[view]
    /// @notice Returns the incentives controller address
    /// @param metadata_address The address of the token
    /// @return The address of the incentives controller, if set
    public fun get_incentives_controller(
        metadata_address: address
    ): Option<address> acquires TokenBaseState {
        let state = borrow_global<TokenBaseState>(metadata_address);
        state.incentives_controller
    }

    #[view]
    /// @notice Returns the scaled balance of a user
    /// @dev The scaled balance is the balance divided by the reserve's liquidity index at the time of the update
    /// @param owner The address of the user
    /// @param metadata_address The address of the token
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 acquires TokenBaseState {
        let user_state_map = get_user_state(owner, metadata_address);
        (user_state_map.balance as u256)
    }

    #[view]
    /// @notice Returns the total supply in scaled units
    /// @param metadata_address The address of the token
    /// @return The total supply in scaled units
    public fun scaled_total_supply(metadata_address: address): u256 acquires TokenBaseState {
        get_scaled_total_supply(metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of a user and the scaled total supply
    /// @param owner The address of the user
    /// @param metadata_address The address of the token
    /// @return The scaled balance of the user and the scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) acquires TokenBaseState {
        (
            scaled_balance_of(owner, metadata_address),
            scaled_total_supply(metadata_address)
        )
    }

    #[view]
    /// @notice Returns the name of the token
    /// @param metadata_address The address of the token
    /// @return The name of the token
    public fun name(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::name(asset)
    }

    #[view]
    /// @notice Returns the symbol of the token
    /// @param metadata_address The address of the token
    /// @return The symbol of the token
    public fun symbol(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::symbol(asset)
    }

    #[view]
    /// @notice Returns the number of decimals of the token
    /// @param metadata_address The address of the token
    /// @return The number of decimals
    public fun decimals(metadata_address: address): u8 {
        let asset = get_metadata(metadata_address);
        fungible_asset::decimals(asset)
    }

    // Public functions
    /// @notice Checks if the caller is a pool admin
    /// @param account The account to check
    /// @dev Aborts if the account is not a pool admin
    public fun only_pool_admin(account: &signer) {
        assert!(
            acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );
    }

    /// @notice Checks if the caller is a token admin
    /// @param account The account to check
    /// @dev Aborts if the account is not a token admin
    public fun only_token_admin(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_pool,
            error_config::get_enot_pool_owner()
        )
    }

    // Friend functions
    /// @notice Sets the incentives controller for the token
    /// @dev Only callable by friend modules
    /// @param admin The signer of the admin account
    /// @param metadata_address The address of the token
    /// @param incentives_controller The address of the incentives controller
    public(friend) fun set_incentives_controller(
        admin: &signer, metadata_address: address, incentives_controller: Option<address>
    ) acquires TokenBaseState {
        only_pool_admin(admin);
        let state = borrow_global_mut<TokenBaseState>(metadata_address);
        state.incentives_controller = incentives_controller;
    }

    /// @notice Creates a new token
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param constructor_ref The constructor reference of the token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param decimals The decimals of the token
    /// @param icon_uri The icon URI of the token
    /// @param project_uri The project URI of the token
    /// @param incentives_controller The incentive controller address, if any
    public(friend) fun create_token(
        constructor_ref: &ConstructorRef,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        incentives_controller: Option<address>
    ) {
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);

        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );

        // initialize the internal states of the token base
        move_to(
            &metadata_object_signer,
            TokenBaseState {
                scaled_total_supply: 0,
                user_state: smart_table::new(),
                incentives_controller
            }
        )
    }

    /// @notice Mints tokens to a recipient
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted tokens
    /// @param amount The amount of tokens to mint
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the token
    /// @return Whether this is the first time tokens are minted to the recipient
    public(friend) fun mint_scaled(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ): bool acquires ManagedFungibleAsset, TokenBaseState {
        // NOTE: in `ray_div`, while `amount` can be less precision than Ray
        //       precision, `index` must be expressed in Ray precision.
        let amount_scaled = wad_ray_math::ray_div(amount, index);
        assert!(amount_scaled != 0, error_config::get_einvalid_mint_amount());

        let user_state = get_user_state(on_behalf_of, metadata_address);
        let old_scaled_balance = (user_state.balance as u256);
        let balance_increase =
            wad_ray_math::ray_mul(old_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    old_scaled_balance, (user_state.additional_data as u256)
                );
        let new_scaled_balance = old_scaled_balance + amount_scaled;
        set_user_state(
            on_behalf_of,
            metadata_address,
            (new_scaled_balance as u128),
            (index as u128)
        );

        // update scale total supply
        let old_scaled_total_supply = get_scaled_total_supply(metadata_address);
        let new_scaled_total_supply = old_scaled_total_supply + amount_scaled;
        set_scaled_total_supply(metadata_address, new_scaled_total_supply);

        // fungible asset mint
        let asset = get_metadata(metadata_address);
        let managed_fungible_asset = obtain_managed_asset_refs(asset);
        let to_wallet =
            primary_fungible_store::ensure_primary_store_exists(on_behalf_of, asset);

        // freeze account
        if (!fungible_asset::is_frozen(to_wallet)) {
            fungible_asset::set_frozen_flag(
                &managed_fungible_asset.transfer_ref, to_wallet, true
            );
        };

        let fa =
            fungible_asset::mint(
                &managed_fungible_asset.mint_ref, (amount_scaled as u64)
            );
        fungible_asset::deposit_with_ref(
            &managed_fungible_asset.transfer_ref, to_wallet, fa
        );

        // apply incentives controller (if exists)
        let base_state = borrow_global<TokenBaseState>(metadata_address);
        if (option::is_some(&base_state.incentives_controller)) {
            rewards_controller::handle_action(
                metadata_address,
                on_behalf_of,
                old_scaled_total_supply,
                old_scaled_balance,
                *option::borrow(&base_state.incentives_controller)
            );
        };

        let amount_to_mint = amount + balance_increase;
        event::emit(
            Transfer {
                from: @0x0,
                to: on_behalf_of,
                value: amount_to_mint,
                token: metadata_address
            }
        );
        event::emit(
            Mint {
                caller,
                on_behalf_of,
                value: amount_to_mint,
                balance_increase,
                index,
                token: metadata_address
            }
        );

        // return whether this is the first time we see the user account
        old_scaled_balance == 0
    }

    /// @notice Burns tokens from a user
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @dev In some instances, the mint event could be emitted from a burn transaction
    /// if the amount to burn is less than the interest that the user accrued
    /// @param user The address from which the tokens will be burned
    /// @param target The address that will receive the underlying
    /// @param amount The amount being burned
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the token
    public(friend) fun burn_scaled(
        user: address,
        target: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires ManagedFungibleAsset, TokenBaseState {
        // NOTE: in `ray_div`, while `amount` can be less precision than Ray
        //       precision, `index` must be expressed in Ray precision.
        let amount_scaled = wad_ray_math::ray_div(amount, index);
        assert!(amount_scaled != 0, error_config::get_einvalid_mint_amount());

        // get scale balance
        let user_state = get_user_state(user, metadata_address);
        let old_scaled_balance = (user_state.balance as u256);
        let balance_increase =
            wad_ray_math::ray_mul(old_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    old_scaled_balance, (user_state.additional_data as u256)
                );
        let new_scaled_balance = old_scaled_balance - amount_scaled;
        set_user_state(
            user,
            metadata_address,
            (new_scaled_balance as u128),
            (index as u128)
        );

        // update scale total supply
        let old_scaled_total_supply = get_scaled_total_supply(metadata_address);
        let new_scaled_total_supply = old_scaled_total_supply - amount_scaled;
        set_scaled_total_supply(metadata_address, new_scaled_total_supply);

        // burn fungible asset
        let asset = get_metadata(metadata_address);
        let burn_ref = &obtain_managed_asset_refs(asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(user, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, (amount_scaled as u64));

        // apply incentives controller (if exists)
        let base_state = borrow_global<TokenBaseState>(metadata_address);
        if (option::is_some(&base_state.incentives_controller)) {
            rewards_controller::handle_action(
                metadata_address,
                user,
                old_scaled_total_supply,
                old_scaled_balance,
                *option::borrow(&base_state.incentives_controller)
            );
        };

        if (balance_increase > amount) {
            let amount_to_mint = balance_increase - amount;
            event::emit(
                Transfer {
                    from: @0x0,
                    to: user,
                    value: amount_to_mint,
                    token: metadata_address
                }
            );
            event::emit(
                Mint {
                    caller: user,
                    on_behalf_of: user,
                    value: amount_to_mint,
                    balance_increase,
                    index,
                    token: metadata_address
                }
            );
        } else {
            let amount_to_burn = amount - balance_increase;
            event::emit(
                Transfer {
                    from: user,
                    to: @0x0,
                    value: amount_to_burn,
                    token: metadata_address
                }
            );
            event::emit(
                Burn {
                    from: user,
                    target,
                    value: amount_to_burn,
                    balance_increase,
                    index,
                    token: metadata_address
                }
            );
        }
    }

    /// @notice Transfers tokens between accounts
    /// @dev Only callable by the a_token_factory and pool_token_logic module
    /// @param sender The address from which the tokens will be transferred
    /// @param recipient The address that will receive the tokens
    /// @param amount The amount being transferred
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the token
    public(friend) fun transfer(
        sender: address,
        recipient: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires ManagedFungibleAsset, TokenBaseState {
        if (amount == 0) {
            return;
        };
        // NOTE: in `ray_div`, while `amount` can be less precision than Ray
        //       precision, `index` must be expressed in Ray precision.
        let amount_scaled = wad_ray_math::ray_div(amount, index);

        // update sender balance
        let sender_user_state = get_user_state(sender, metadata_address);
        let sender_old_scaled_balance = (sender_user_state.balance as u256);
        let sender_balance_increase =
            wad_ray_math::ray_mul(sender_old_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    sender_old_scaled_balance,
                    (sender_user_state.additional_data as u256)
                );

        let sender_new_scaled_balance = sender_old_scaled_balance - amount_scaled;
        set_user_state(
            sender,
            metadata_address,
            (sender_new_scaled_balance as u128),
            (index as u128)
        );

        // update recipient balance
        // computation only make sense for the case recipient != sender
        let recipient_user_state = get_user_state(recipient, metadata_address);
        let recipient_old_scaled_balance = (recipient_user_state.balance as u256);
        // only for recipient != sender
        // if sender == recipient, the recipient_balance_increase will not be used for event emission
        let recipient_balance_increase =
            wad_ray_math::ray_mul(recipient_old_scaled_balance, index)
                - wad_ray_math::ray_mul(
                    recipient_old_scaled_balance,
                    (recipient_user_state.additional_data as u256)
                );

        let recipient_new_scaled_balance = recipient_old_scaled_balance + amount_scaled;
        set_user_state(
            recipient,
            metadata_address,
            (recipient_new_scaled_balance as u128),
            (index as u128)
        );

        // transfer fungible asset
        let asset = get_metadata(metadata_address);
        let transfer_ref = &obtain_managed_asset_refs(asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(sender, asset);
        let to_wallet =
            primary_fungible_store::ensure_primary_store_exists(recipient, asset);

        // freeze account
        if (!fungible_asset::is_frozen(to_wallet)) {
            fungible_asset::set_frozen_flag(transfer_ref, to_wallet, true);
        };

        fungible_asset::transfer_with_ref(
            transfer_ref,
            from_wallet,
            to_wallet,
            (amount_scaled as u64)
        );

        // apply incentives controller (if exists)
        let base_state = borrow_global<TokenBaseState>(metadata_address);
        if (option::is_some(&base_state.incentives_controller)) {
            let controller_address = *option::borrow(&base_state.incentives_controller);

            let scaled_total_supply = get_scaled_total_supply(metadata_address);
            rewards_controller::handle_action(
                metadata_address,
                sender,
                scaled_total_supply,
                sender_old_scaled_balance,
                controller_address
            );

            if (sender != recipient) {
                rewards_controller::handle_action(
                    metadata_address,
                    recipient,
                    scaled_total_supply,
                    recipient_old_scaled_balance,
                    controller_address
                );
            }
        };

        if (sender_balance_increase > 0) {
            event::emit(
                Transfer {
                    from: @0x0,
                    to: sender,
                    value: sender_balance_increase,
                    token: metadata_address
                }
            );
            event::emit(
                Mint {
                    caller: sender,
                    on_behalf_of: sender,
                    value: sender_balance_increase,
                    balance_increase: sender_balance_increase,
                    index,
                    token: metadata_address
                }
            );
        };

        // if sender == recipient, the following logic will not execute, the event will not be emitted
        if (sender != recipient && recipient_balance_increase > 0) {
            event::emit(
                Transfer {
                    from: @0x0,
                    to: recipient,
                    value: recipient_balance_increase,
                    token: metadata_address
                }
            );
            event::emit(
                Mint {
                    caller: sender,
                    on_behalf_of: recipient,
                    value: recipient_balance_increase,
                    balance_increase: recipient_balance_increase,
                    index,
                    token: metadata_address
                }
            );
        };

        event::emit(
            Transfer {
                from: sender,
                to: recipient,
                value: amount,
                token: metadata_address
            }
        );
    }

    /// @notice Drops the token data from the token map
    /// @dev Only callable by the a_token_factory and variable_debt_token_factory module
    /// @param metadata_address The address of the token
    public(friend) fun drop_token(
        metadata_address: address
    ) acquires ManagedFungibleAsset, TokenBaseState {
        assert_token_exists(metadata_address);
        assert_managed_fa_exists(metadata_address);

        let TokenBaseState { user_state, incentives_controller, scaled_total_supply: _ } =
            move_from<TokenBaseState>(metadata_address);

        smart_table::destroy(user_state);

        if (option::is_some(&incentives_controller)) {
            option::destroy_some(incentives_controller);
        };

        // detach the managed fungible asset from the metadata address
        move_from<ManagedFungibleAsset>(metadata_address);
    }

    // Private functions
    /// @notice Initializes the module
    /// @param signer The signer of the token admin account
    fun init_module(signer: &signer) {
        only_token_admin(signer);
    }

    /// @notice Verifies that a token exists
    /// @param metadata_address The address of the token to check
    /// @dev Aborts if the token does not exist
    fun assert_token_exists(metadata_address: address) {
        assert!(
            object::object_exists<TokenBaseState>(metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    /// @notice Verifies that a managed fungible asset exists
    /// @param metadata_address The address of the token to check
    /// @dev Aborts if the managed fungible asset does not exist
    fun assert_managed_fa_exists(metadata_address: address) {
        assert!(
            object::object_exists<ManagedFungibleAsset>(metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    /// @notice Gets the user state for a token
    /// @param user The address of the user
    /// @param metadata_address The address of the token
    /// @return The user state
    fun get_user_state(user: address, metadata_address: address): UserState acquires TokenBaseState {
        // NOTE: aborts if `metadata` is not a scaled balance token
        let token_state = borrow_global<TokenBaseState>(metadata_address);
        if (!smart_table::contains(&token_state.user_state, user)) {
            UserState { balance: 0, additional_data: 0 }
        } else {
            *smart_table::borrow(&token_state.user_state, user)
        }
    }

    /// @notice Sets the user state for a token
    /// @param user The address of the user
    /// @param metadata_address The address of the token
    /// @param balance The new balance in scaled units
    /// @param additional_data The new additional data (liquidity index)
    fun set_user_state(
        user: address,
        metadata_address: address,
        balance: u128,
        additional_data: u128
    ) acquires TokenBaseState {
        // NOTE: aborts if `metadata` is not a scaled balance token
        let token_state = borrow_global_mut<TokenBaseState>(metadata_address);
        smart_table::upsert(
            &mut token_state.user_state,
            user,
            UserState { balance, additional_data }
        );
    }

    #[view]
    /// @notice Gets the scaled total supply of a token
    /// @param metadata_address The address of the token
    /// @return The scaled total supply
    fun get_scaled_total_supply(metadata_address: address): u256 acquires TokenBaseState {
        // NOTE: aborts if `metadata` is not a scaled balance token
        let token_state = borrow_global<TokenBaseState>(metadata_address);
        token_state.scaled_total_supply
    }

    /// @notice Sets the scaled total supply of a token
    /// @param metadata_address The address of the token
    /// @param scaled_total_supply The new scaled total supply
    fun set_scaled_total_supply(
        metadata_address: address, scaled_total_supply: u256
    ) acquires TokenBaseState {
        // NOTE: aborts if `metadata` is not a scaled balance token
        let token_state = borrow_global_mut<TokenBaseState>(metadata_address);
        token_state.scaled_total_supply = scaled_total_supply;
    }

    #[view]
    /// @notice Gets the metadata object for a token
    /// @param metadata_address The address of the token
    /// @return The metadata object
    fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }

    /// @notice Gets the managed asset references for a token
    /// @param asset The metadata object of the token
    /// @return Reference to the managed fungible asset
    inline fun obtain_managed_asset_refs(
        asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    #[test_only]
    /// @notice Initialize the module for testing
    /// @param signer The signer of the token admin account
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }

    #[test_only]
    /// @notice Assert that a managed fungible asset exists for testing
    /// @param metadata_address The address of the token to check
    public fun assert_managed_fa_exists_for_testing(
        metadata_address: address
    ) {
        assert_managed_fa_exists(metadata_address)
    }
}
