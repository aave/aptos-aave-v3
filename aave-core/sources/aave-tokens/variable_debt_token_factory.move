/// @title Variable Debt Token Factory Module
/// @author Aave
/// @notice Factory for creating and managing variable debt tokens in the Aave protocol
/// @dev Manages the creation, minting, burning, and operations of variable debt tokens
module aave_pool::variable_debt_token_factory {
    // imports
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::String;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::Object;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_math::wad_ray_math;
    use aave_pool::pool;
    use aave_pool::token_base;

    // friend modules
    friend aave_pool::pool_token_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::variable_debt_token_factory_tests;

    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::pool_tests;

    // Error constants

    // Global Constants

    // Structs and Events
    #[event]
    /// @notice Emitted when a debt token is initialized
    /// @param underlying_asset The address of the underlying asset
    /// @param incentives_controller The address of the incentives controller
    /// @param debt_token_decimals The decimals of the debt token
    /// @param debt_token_name The name of the debt token
    /// @param debt_token_symbol The symbol of the debt token
    struct Initialized has store, drop {
        underlying_asset: address,
        incentives_controller: Option<address>,
        debt_token_decimals: u8,
        debt_token_name: String,
        debt_token_symbol: String
    }

    /// @notice Data structure that stores token-specific information
    /// @param underlying_asset The address of the underlying asset
    struct TokenData has key, drop {
        underlying_asset: address
    }

    /// @notice Bi-directional mapping between underlying tokens and variable debt tokens
    /// @dev See NOTES of `TokenMap` in `a_token_factory.move` for why this design is used
    /// @param underlying_to_token Maps underlying token address to variable debt token address
    /// @param token_to_underlying Maps variable debt token address to underlying token address
    struct TokenMap has key {
        underlying_to_token: SmartTable<address, address>,
        token_to_underlying: SmartTable<address, address>
    }

    // Public view functions
    #[view]
    /// @notice Checks if the given address represents a variable debt token
    /// @param metadata_address The address to check
    /// @return True if the address is a variable debt token, false otherwise
    public fun is_variable_debt_token(metadata_address: address): bool acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);
        smart_table::contains(&token_map.token_to_underlying, metadata_address)
            && object::object_exists<TokenData>(metadata_address)
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this debt token
    /// @param metadata_address The address of the metadata object
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
    /// @param metadata_address The address of the variable debt token
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the amount of tokens owned by the account
    /// @param owner The address of the token owner
    /// @param metadata_address The address of the variable debt token
    /// @return The balance of tokens for the owner
    public fun balance_of(owner: address, metadata_address: address): u256 acquires TokenData, TokenMap {
        let current_scaled_balance = scaled_balance_of(owner, metadata_address);
        if (current_scaled_balance == 0) {
            return 0
        };
        let underlying_token_address = get_underlying_asset_address(metadata_address);

        wad_ray_math::ray_mul_up(
            current_scaled_balance,
            pool::get_reserve_normalized_variable_debt(underlying_token_address)
        )
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token
    /// @dev Represents sum(debt/index)
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::scaled_total_supply(metadata_address)
    }

    #[view]
    /// @notice Returns the amount of tokens in existence
    /// @param metadata_address The address of the variable debt token
    /// @return The total supply of tokens
    public fun total_supply(metadata_address: address): u256 acquires TokenData, TokenMap {
        let current_supply_scaled = scaled_total_supply(metadata_address);
        if (current_supply_scaled == 0) {
            return 0
        };

        let underlying_token_address = get_underlying_asset_address(metadata_address);

        wad_ray_math::ray_mul_up(
            current_supply_scaled,
            pool::get_reserve_normalized_variable_debt(underlying_token_address)
        )
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply
    /// @param owner The address of the user
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// @notice Get the name of the fungible asset
    /// @param metadata_address The address of the variable debt token
    /// @return The name of the fungible asset
    public fun name(metadata_address: address): String acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::name(metadata_address)
    }

    #[view]
    /// @notice Get the symbol of the fungible asset
    /// @param metadata_address The address of the variable debt token
    /// @return The symbol of the fungible asset
    public fun symbol(metadata_address: address): String acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::symbol(metadata_address)
    }

    #[view]
    /// @notice Get the decimals of the fungible asset
    /// @param metadata_address The address of the variable debt token
    /// @return The number of decimals
    public fun decimals(metadata_address: address): u8 acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::decimals(metadata_address)
    }

    #[view]
    /// @notice Returns the address of a variable debt token by its symbol
    /// @param symbol The symbol of the variable debt token to find
    /// @return The address of the variable debt token
    public fun token_address(symbol: String): address acquires TokenMap {
        let token_map = borrow_global<TokenMap>(@aave_pool);

        let address_found = option::none<address>();
        smart_table::for_each_ref(
            &token_map.token_to_underlying,
            |metadata_address, _token_data| {
                let token_metadata =
                    object::address_to_object<Metadata>(*metadata_address);
                let token_symbol = fungible_asset::symbol(token_metadata);
                if (token_symbol == symbol) {
                    assert!(
                        std::option::is_none(&address_found),
                        (error_config::get_etoken_already_exists())
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
    /// @notice Returns the metadata object of a variable debt token by its symbol
    /// @param symbol The symbol of the variable debt token to find
    /// @return The metadata object of the variable debt token
    public fun asset_metadata(symbol: String): Object<Metadata> acquires TokenMap {
        object::address_to_object<Metadata>(token_address(symbol))
    }

    // Friend functions
    /// @notice Creates a new variable debt token
    /// @dev Callable by the pool_token_logic module
    /// @param signer The signer of the caller
    /// @param name The name of the variable debt token
    /// @param symbol The symbol of the variable debt token
    /// @param decimals The decimals of the variable debt token
    /// @param icon_uri The icon URI of the variable debt token
    /// @param project_uri The project URI of the variable debt token
    /// @param incentives_controller The incentive controller address, if any
    /// @param underlying_asset The address of the underlying asset
    /// @return The address of the variable debt token
    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        incentives_controller: Option<address>,
        underlying_asset: address
    ): address acquires TokenMap {
        only_asset_listing_or_pool_admins(signer);
        let signer_addr = signer::address_of(signer);

        // create the object that represents this VariableDebtToken first
        // check the NOTES in `a_token_factory::create_token` for why we adopt
        // the `object::create_sticky_object` approach instead of the obvious
        // alternative: `object::create_named_object`.
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

        // mark this object as a VariableDebtToken by storing a `TokenData` at
        // the object address
        let object_signer = object::generate_signer(&constructor_ref);
        move_to(&object_signer, TokenData { underlying_asset });

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
                incentives_controller,
                debt_token_decimals: decimals,
                debt_token_name: name,
                debt_token_symbol: symbol
            }
        );

        // return the token address
        metadata_address
    }

    /// @notice Mints debt token to the `on_behalf_of` address
    /// @dev Only callable by the borrow_logic module
    /// @param caller The address receiving the borrowed underlying, being the delegatee in case
    /// of credit delegate, or same as `on_behalf_of` otherwise
    /// @param on_behalf_of The address receiving the debt tokens
    /// @param amount The amount of debt being minted
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    /// @return whether this is the first time we mint the VariableDebt token to `on_behalf_of`
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ): bool acquires TokenMap {
        assert_token_exists(metadata_address);
        assert!(
            caller == on_behalf_of,
            error_config::get_edifferent_caller_on_behalf_of()
        );
        token_base::mint_scaled(
            caller,
            on_behalf_of,
            amount,
            index,
            metadata_address,
            true
        )
    }

    /// @notice Sets an incentives controller for the variable debt token
    /// @dev Callable by the pool_token_logic module
    /// @param admin The address of the admin calling the method
    /// @param metadata_address The address of the variable debt token
    /// @param incentives_controller The address of the incentives controller
    public(friend) fun set_incentives_controller(
        admin: &signer, metadata_address: address, incentives_controller: Option<address>
    ) {
        token_base::set_incentives_controller(
            admin, metadata_address, incentives_controller
        );
    }

    /// @notice Burns user variable debt
    /// @dev Only callable by the borrow_logic and liquidation_logic module
    /// @dev In some instances, a burn transaction will emit a mint event
    /// if the amount to burn is less than the interest that the user accrued
    /// @param from The address from which the debt will be burned
    /// @param amount The amount getting burned
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    public(friend) fun burn(
        from: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) acquires TokenMap {
        assert_token_exists(metadata_address);
        token_base::burn_scaled(
            from,
            @0x0,
            amount,
            index,
            metadata_address,
            false
        );
    }

    /// @notice Drops the variable debt token associated data
    /// @dev Callable by the pool_token_logic module
    /// @param metadata_address The address of the metadata object
    public(friend) fun drop_token(metadata_address: address) acquires TokenMap, TokenData {
        assert_token_exists(metadata_address);

        // remove metadata_address from variable debt token map
        let token_map = borrow_global_mut<TokenMap>(@aave_pool);
        let underlying_asset =
            smart_table::remove(&mut token_map.token_to_underlying, metadata_address);
        smart_table::remove(&mut token_map.underlying_to_token, underlying_asset);

        // remove metadata_address from token_base module's token map
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
    /// @param metadata_address The address of the token to check
    fun assert_token_exists(metadata_address: address) acquires TokenMap {
        assert!(
            is_variable_debt_token(metadata_address),
            error_config::get_etoken_not_exist()
        );
    }

    /// @notice Retrieves the token data for a specific variable debt token
    /// @param metadata_address The address of the variable debt token
    /// @return Reference to the token data
    inline fun get_token_data(metadata_address: address): &TokenData {
        borrow_global<TokenData>(metadata_address)
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

    #[test_only]
    /// @notice Initialize the module for testing
    /// @param signer The signer of the token admin account
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }

    #[test_only]
    /// @notice Mint tokens for testing
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted tokens
    /// @param amount The amount of tokens getting minted
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the variable debt token
    /// @return whether this is the first time we mint tokens to `on_behalf_of`
    public fun test_mint_for_testing(
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
    /// @param metadata_address The address of the variable debt token to check
    public fun assert_token_exists_for_testing(metadata_address: address) acquires TokenMap {
        assert_token_exists(metadata_address);
    }
}
