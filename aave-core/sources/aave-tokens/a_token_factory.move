/// @title a_token_factory Module
/// @author Aave
/// @notice Factory module for creating and managing aTokens in the Aave protocol
/// @dev This module manages the creation, minting, burning, and various operations of aTokens
module aave_pool::a_token_factory {
    // imports
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::String;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::Object;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::wad_ray_math;
    use aave_pool::pool;
    use aave_pool::fungible_asset_manager;
    use aave_pool::token_base;
    use aave_pool::events::Self;

    // friend modules
    friend aave_pool::pool_token_logic;
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::a_token_factory_tests;
    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::ui_incentive_data_provider_v3_tests;
    #[test_only]
    friend aave_pool::ui_pool_data_provider_v3_tests;
    #[test_only]
    friend aave_pool::emission_manager_tests;
    #[test_only]
    friend aave_pool::rewards_controller_tests;
    #[test_only]
    friend aave_pool::collector_tests;

    // Error constants

    // Global Constants

    // Structs and Events
    #[event]
    /// @notice Emitted when an aToken is initialized
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @param incentives_controller The address of the incentives controller
    /// @param a_token_decimals The decimals of the underlying
    /// @param a_token_name The name of the aToken
    /// @param a_token_symbol The symbol of the aToken
    struct Initialized has store, drop {
        underlying_asset: address,
        treasury: address,
        incentives_controller: Option<address>,
        a_token_decimals: u8,
        a_token_name: String,
        a_token_symbol: String
    }

    #[event]
    /// @notice Emitted when a token is being rescued
    /// @dev Emitted during the the rescue tokens method
    /// @param from The account from which the token is being transferred/rescued
    /// @param to The receiver of the rescued tokens
    /// @param amount The amount being transferred during rescue
    /// @param a_token_address The address of the aToken
    struct TokenRescued has store, drop {
        /// @dev The rescuer address
        rescuer: address,
        /// @dev The source address
        from: address,
        /// @dev The destination address
        to: address,
        /// @dev The amount being transferred/rescued (scaled)
        amount: u256,
        /// @dev The address of the corresponding aToken
        a_token_address: address
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice Data structure that stores aToken-specific information
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @param signer_cap The signer capability for the resource account
    struct TokenData has key, drop {
        underlying_asset: address,
        treasury: address,
        signer_cap: SignerCapability
    }

    /// @notice Bi-directional mapping between underlying tokens and aTokens
    /// @dev This serves two purposes:
    /// 1. Ensures the same underlying token has only one aToken (underlying_to_token)
    /// 2. Provides quick lookup to check if an address is an aToken (token_to_underlying)
    /// @param underlying_to_token Maps underlying token address to aToken address
    /// @param token_to_underlying Maps aToken address to underlying token address
    struct TokenMap has key {
        underlying_to_token: SmartTable<address, address>,
        token_to_underlying: SmartTable<address, address>
    }

    // Public view functions
    #[view]
    /// @notice Checks if the given address represents an aToken
    /// @param metadata_address The address to check
    /// @return True if the address is an aToken, false otherwise
    public fun is_atoken(metadata_address: address): bool acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        smart_table::contains(&token_map.token_to_underlying, metadata_address)
            && object::object_exists<TokenData>(metadata_address)
    }

    #[view]
    /// @notice Retrieves the account address of the managed fungible asset for a specific aToken
    /// @dev Creates a signer capability for the resource account managing the fungible asset
    /// @param metadata_address The address of the aToken
    /// @return The address of the managed fungible asset account
    public fun get_token_account_address(
        metadata_address: address
    ): address acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);
        let token_data = get_token_data(metadata_address);
        let account_signer = get_token_account_with_signer(token_data);
        signer::address_of(&account_signer)
    }

    #[view]
    /// @notice Returns the address of the Aave treasury that receives fees on this aToken
    /// @param metadata_address The address of the aToken
    /// @return Address of the Aave treasury
    public fun get_reserve_treasury_address(
        metadata_address: address
    ): address acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);
        let token_data = get_token_data(metadata_address);
        token_data.treasury
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this aToken
    /// @param metadata_address The address of the aToken
    /// @return The address of the underlying asset
    public fun get_underlying_asset_address(
        metadata_address: address
    ): address acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);
        let token_data = get_token_data(metadata_address);
        token_data.underlying_asset
    }

    #[view]
    /// @notice Returns last index interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply
    /// @param owner The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the amount of tokens owned by the owner
    /// @param owner The address of the token owner
    /// @param metadata_address The address of the aToken
    /// @return The balance of tokens for the owner
    public fun balance_of(owner: address, metadata_address: address): u256 acquires TokenData, TokenMap {
        let current_scaled_balance = scaled_balance_of(owner, metadata_address);
        if (current_scaled_balance == 0) {
            return 0
        };
        let underlying_token_address = get_underlying_asset_address(metadata_address);

        wad_ray_math::ray_mul_down(
            current_scaled_balance,
            pool::get_reserve_normalized_income(underlying_token_address)
        )
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token
    /// @dev Represents sum(debt/index)
    /// @param metadata_address The address of the aToken
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::scaled_total_supply(metadata_address)
    }

    #[view]
    /// @notice Returns the amount of tokens in existence
    /// @param metadata_address The address of the aToken
    /// @return The total supply of tokens
    public fun total_supply(metadata_address: address): u256 acquires TokenData, TokenMap {
        let current_supply_scaled = scaled_total_supply(metadata_address);
        if (current_supply_scaled == 0) {
            return 0
        };

        let underlying_token_address = get_underlying_asset_address(metadata_address);

        wad_ray_math::ray_mul_down(
            current_supply_scaled,
            pool::get_reserve_normalized_income(underlying_token_address)
        )
    }

    #[view]
    /// @notice Returns the name of the token
    /// @param metadata_address The address of the aToken
    /// @return The name of the token
    public fun name(metadata_address: address): String acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::name(metadata_address)
    }

    #[view]
    /// @notice Returns the symbol of the token
    /// @param metadata_address The address of the aToken
    /// @return The symbol of the token
    public fun symbol(metadata_address: address): String acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::symbol(metadata_address)
    }

    #[view]
    /// @notice Returns the number of decimals of the token
    /// @param metadata_address The address of the aToken
    /// @return The number of decimals
    public fun decimals(metadata_address: address): u8 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::decimals(metadata_address)
    }

    #[view]
    /// @notice Returns the address of an aToken by its symbol
    /// @param symbol The symbol of the aToken to find
    /// @return The address of the aToken
    public fun token_address(symbol: String): address acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);

        let address_found = option::none();
        smart_table::for_each_ref(
            &token_map.token_to_underlying,
            |metadata_address, _underlying_asset| {
                let token_metadata =
                    object::address_to_object<Metadata>(*metadata_address);
                let token_symbol = fungible_asset::symbol(token_metadata);
                if (token_symbol == symbol) {
                    assert!(
                        std::option::is_none(&address_found),
                        error_config::get_etoken_already_exists()
                    );
                    std::option::fill(&mut address_found, *metadata_address);
                };
            }
        );

        assert!(
            std::option::is_some(&address_found),
            error_config::get_etoken_not_exist()
        );
        std::option::destroy_some(address_found)
    }

    #[view]
    /// @notice Returns the metadata object of an aToken by its symbol
    /// @param symbol The symbol of the aToken to find
    /// @return The metadata object of the aToken
    public fun asset_metadata(symbol: String): Object<Metadata> acquires TokenMap {
        object::address_to_object<Metadata>(token_address(symbol))
    }

    // Public Entrypoint functions
    /// @notice Transfers out any token that is not the underlying token from an aToken's resource account
    /// @param account The account signer of the caller
    /// @param token The address of the token to transfer
    /// @param to The address of the recipient
    /// @param amount The amount of token to transfer
    /// @param metadata_address The address of the aToken
    public entry fun rescue_tokens(
        account: &signer,
        token: address,
        to: address,
        amount: u256,
        metadata_address: address
    ) acquires TokenData, TokenMap {
        token_base::only_pool_admin(account);
        assert_token_exists(metadata_address);
        let token_data = get_token_data(metadata_address);

        assert!(
            token != token_data.underlying_asset,
            error_config::get_eunderlying_cannot_be_rescued()
        );

        let a_token_resource_account = get_token_account_with_signer(token_data);
        fungible_asset_manager::transfer(
            &a_token_resource_account,
            to,
            (amount as u64),
            token
        );
        event::emit(
            TokenRescued {
                rescuer: signer::address_of(account),
                from: signer::address_of(&a_token_resource_account),
                to,
                amount,
                a_token_address: metadata_address
            }
        );
    }

    // Public functions
    /// @notice Handles repayment by potentially performing actions with the underlying asset
    /// @dev The default implementation is empty, but subclasses may override to stake or use the asset
    /// @param _user The user executing the repayment
    /// @param _on_behalf_of The address of the user who will get his debt reduced/removed
    /// @param _amount The amount getting repaid
    /// @param _metadata_address The address of the aToken
    public fun handle_repayment(
        _user: address,
        _on_behalf_of: address,
        _amount: u256,
        _metadata_address: address
    ) {
        // Intentionally left blank
    }

    // Friend functions
    /// @notice Creates a new aToken
    /// @dev Only callable by the pool_token_logic module
    /// @param signer The signer of the caller
    /// @param name The name of the aToken
    /// @param symbol The symbol of the aToken
    /// @param decimals The decimals of the aToken
    /// @param icon_uri The icon URI of the aToken
    /// @param project_uri The project URI of the aToken
    /// @param incentives_controller The incentive controller address, if any, of the Token
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @return The address of the aToken
    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        incentives_controller: Option<address>,
        underlying_asset: address,
        treasury: address
    ): address acquires TokenMap {
        only_asset_listing_or_pool_admins(signer);
        let signer_addr = signer::address_of(signer);

        // create the object that represents this AToken first
        //
        // NOTE: an alternative is to use the
        // `object::create_named_object(creator: &signer, seed: vector<u8>)`
        // method, using `signer` as the `creator` and `symbol` as the seed.
        //
        // This alternative enables simple object look-up (via creator address
        // and seed), but whether this is really a benefit or not is debatable,
        // as there could be caveats.
        //
        // Caveat 1: multiple accounts can be the creator as long as the account
        // is an AssetListingAdmin or a PoolAdmin. To look up the AToken address
        // of, say, `aUSDC`, you also need to know who created `aUSDC`, which
        // might not be obvious.
        //
        // Cavear 2: there might be a case in the future where we want to move
        // the `aUSDC` object to a different object (e.g., upgrade `aUSDC` to
        // `aUSDC_V2`). In this case, the easy look up will resolve to `aUSDC`
        // which is something we want to avoid.
        //
        // Hence, we use this `object::create_sticky_object` to force the AToken
        // lookup logic to go through functions we control.
        let constructor_ref = object::create_sticky_object(signer_addr);
        token_base::create_token(
            &constructor_ref,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
            incentives_controller
        );

        // create the resource account associated with this object
        let object_signer = object::generate_signer(&constructor_ref);
        let (_resource_signer, signer_cap) =
            account::create_resource_account(&object_signer, b"");

        // mark this object as an AToken by storing a `TokenData` at the object address
        move_to(
            &object_signer,
            TokenData { underlying_asset, treasury, signer_cap }
        );

        // save to mapping
        let metadata_address = object::address_from_constructor_ref(&constructor_ref);
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        smart_table::add(
            &mut token_map.underlying_to_token,
            underlying_asset,
            metadata_address
        );
        smart_table::add(
            &mut token_map.token_to_underlying,
            metadata_address,
            underlying_asset
        );

        // emit event
        event::emit(
            Initialized {
                underlying_asset,
                treasury,
                incentives_controller,
                a_token_decimals: decimals,
                a_token_name: name,
                a_token_symbol: symbol
            }
        );

        // return the token address
        metadata_address
    }

    /// @notice Mints `amount` aTokens to `on_behalf_of`
    /// @dev Only callable by the supply_logic module
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted aTokens
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    /// @return whether this is the first time we mint aTokens to `on_behalf_of`
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ): bool acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::mint_scaled(
            caller,
            on_behalf_of,
            amount,
            index,
            metadata_address,
            false
        )
    }

    /// @notice Burns aTokens from `from` and sends the equivalent amount of underlying to `receiver_of_underlying`
    /// @dev Only callable by the supply_logic, borrow_logic and liquidation_logic module
    /// @dev In some instances, the mint event could be emitted from a burn transaction
    /// if the amount to burn is less than the interest that the user accrued
    /// @param from The address from which the aTokens will be burned
    /// @param receiver_of_underlying The address that will receive the underlying
    /// @param amount The amount being burned
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun burn(
        from: address,
        receiver_of_underlying: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);
        token_base::burn_scaled(
            from,
            receiver_of_underlying,
            amount,
            index,
            metadata_address,
            true
        );

        let token_data = get_token_data(metadata_address);
        let a_token_resource_account_signer = get_token_account_with_signer(token_data);
        let a_token_resource_account_address =
            signer::address_of(&a_token_resource_account_signer);

        if (receiver_of_underlying != a_token_resource_account_address) {
            fungible_asset_manager::transfer(
                &a_token_resource_account_signer,
                receiver_of_underlying,
                (amount as u64),
                token_data.underlying_asset
            )
        }
    }

    /// @notice Mints aTokens to the reserve treasury
    /// @dev Only callable by the pool_token_logic module
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun mint_to_treasury(
        amount: u256, index: u256, metadata_address: address
    ) acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);

        // Early return if amount is 0 to avoid unnecessary computation
        if (amount == 0) { return };

        let amount_scaled = wad_ray_math::ray_div_down(amount, index);

        if (amount_scaled != 0) {
            let token_data = get_token_data(metadata_address);
            token_base::mint_scaled(
                // In the Solidity implementation, `address(POOL)` can be
                // different per each AToken but here it is always a fixed
                // address `@aave_pool` which is not ideal.
                @aave_pool,
                token_data.treasury,
                amount,
                index,
                metadata_address,
                false
            );
        }
    }

    /// @notice Sets an incentives controller for the aToken
    /// @dev Only callable by the pool_token_logic module
    /// @param admin The address of the admin calling the method
    /// @param metadata_address The address of the aToken
    /// @param incentives_controller The address of the incentives controller
    public(friend) fun set_incentives_controller(
        admin: &signer, metadata_address: address, incentives_controller: Option<address>
    ) {
        token_base::set_incentives_controller(
            admin, metadata_address, incentives_controller
        );
    }

    /// @notice Transfers the underlying asset to `to`
    /// @dev Only callable by the borrow_logic and flashloan_logic module
    /// @param to The recipient of the underlying
    /// @param amount The amount getting transferred
    /// @param metadata_address The address of the aToken
    public(friend) fun transfer_underlying_to(
        to: address, amount: u256, metadata_address: address
    ) acquires TokenData, TokenMap {
        assert_token_exists(metadata_address);
        let token_data = get_token_data(metadata_address);

        fungible_asset_manager::transfer(
            &get_token_account_with_signer(token_data),
            to,
            (amount as u64),
            token_data.underlying_asset
        )
    }

    /// @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
    /// @dev Only callable by the liquidation_logic module
    /// @param from The address getting liquidated, current owner of the aTokens
    /// @param to The recipient
    /// @param amount The amount of tokens getting transferred
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    /// @param rounding_up Whether to round up: true=ray_div_up, false=ray_div (round half up)
    public(friend) fun transfer_on_liquidation(
        from: address,
        to: address,
        amount: u256,
        index: u256,
        metadata_address: address,
        rounding_up: bool
    ) acquires TokenMap {
        assert_token_exists(metadata_address);

        let amount_scaled =
            if (rounding_up) {
                wad_ray_math::ray_div_up(amount, index)
            } else {
                wad_ray_math::ray_div(amount, index)
            };

        if (amount_scaled == 0) { return };

        token_base::transfer(
            from,
            to,
            amount,
            index,
            metadata_address,
            rounding_up
        );

        events::emit_balance_transfer(
            from,
            to,
            amount_scaled,
            index,
            metadata_address
        );
    }

    /// @notice Drops the a token associated data
    /// @dev Only callable by the pool_token_logic module
    /// @param metadata_address The address of the metadata object
    public(friend) fun drop_token(metadata_address: address) acquires TokenMap, TokenData {
        assert_token_exists(metadata_address);

        // remove metadata_address from token map
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        let underlying_asset =
            smart_table::remove(&mut token_map.token_to_underlying, metadata_address);
        smart_table::remove(&mut token_map.underlying_to_token, underlying_asset);

        // remove token_base module's token map
        token_base::drop_token(metadata_address);

        // finally remove the token data at the metadata address
        move_from<TokenData>(metadata_address);
    }

    // Private functions
    /// @notice Initializes the module with a token map
    /// @param signer The signer of the token admin account
    fun init_module(signer: &signer) {
        token_base::only_token_admin(signer);
        move_to(
            signer,
            TokenMap {
                underlying_to_token: smart_table::new(),
                token_to_underlying: smart_table::new()
            }
        )
    }

    /// @notice Asserts that the token exists
    /// @param metadata_address The address of the aToken to check
    fun assert_token_exists(metadata_address: address) acquires TokenMap {
        assert!(is_atoken(metadata_address), error_config::get_etoken_not_exist());
    }

    /// @notice Retrieves the token data for a specific aToken
    /// @param metadata_address The address of the aToken
    /// @return Reference to the token data
    inline fun get_token_data(metadata_address: address): &TokenData {
        borrow_global<TokenData>(metadata_address)
    }

    /// @notice Retrieves the signer of the managed fungible asset
    /// @param token_data The token data of the aToken
    /// @return The signer of the managed fungible asset
    fun get_token_account_with_signer(token_data: &TokenData): signer {
        account::create_signer_with_capability(&token_data.signer_cap)
    }

    /// @notice Checks if the caller is an asset listing admin or pool admin
    /// @param account The account to check
    fun only_asset_listing_or_pool_admins(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_asset_listing_admin(account_address)
                || acl_manage::is_pool_admin(account_address),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        )
    }

    // Test only functions
    #[test_only]
    /// @notice Initialize the module for testing
    /// @param signer The signer of the token admin account
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }

    #[test_only]
    /// @notice Mint tokens for testing
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted aTokens
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    /// @return whether this is the first time we mint aTokens to `on_behalf_of`
    public fun mint_for_testing(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ): bool acquires TokenMap {
        mint(
            caller,
            on_behalf_of,
            amount,
            index,
            metadata_address
        )
    }

    #[test_only]
    /// @notice Assert token exists for testing
    /// @param metadata_address The address of the aToken to check
    public fun assert_token_exists_for_testing(metadata_address: address) acquires TokenMap {
        assert_token_exists(metadata_address);
    }

    #[test_only]
    /// Test helper function that exposes transfer_on_liquidation for testing
    public fun transfer_on_liquidation_for_testing(
        from: address,
        to: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        transfer_on_liquidation(from, to, amount, index, metadata_address, false)
    }
}
