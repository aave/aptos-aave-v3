/// @title Mock Underlying Token Factory
/// @author Aave
/// @notice Provides functionality to create and manage fungible assets for testing
module aave_mock_underlyings::mock_underlying_token_factory {
    // imports
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::fungible_asset::{Self, BurnRef, Metadata, MintRef, TransferRef};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    // Error constants
    /// @notice Only fungible asset metadata owner can make changes
    const ENOT_OWNER: u64 = 1;
    /// @notice Token with this address already exists
    const E_TOKEN_ALREADY_EXISTS: u64 = 2;

    // Structs
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice Hold refs to control the minting, transfer and burning of fungible assets
    struct ManagedFungibleAsset has key {
        /// @dev Reference to mint new tokens
        mint_ref: MintRef,
        /// @dev Reference to transfer tokens
        transfer_ref: TransferRef,
        /// @dev Reference to burn tokens
        burn_ref: BurnRef
    }

    /// @notice Mapping of token addresses to existence flags
    struct CoinList has key {
        /// @dev Smart table mapping (underlying token address => bool)
        value: SmartTable<address, bool>
    }

    // Module initialization
    /// @dev Initializes the module
    /// @param signer The signer of the transaction
    fun init_module(signer: &signer) {
        only_token_admin(signer);
        move_to(signer, CoinList { value: smart_table::new() })
    }

    // Public functions - Token creation and management
    /// @notice Creates a new underlying token
    /// @param signer The signer of the transaction
    /// @param maximum_supply Maximum supply for the token (0 for unlimited)
    /// @param name The name of the underlying token
    /// @param symbol The symbol of the underlying token
    /// @param decimals The decimals of the underlying token
    /// @param icon_uri The icon URI of the underlying token
    /// @param project_uri The project URI of the underlying token
    public entry fun create_token(
        signer: &signer,
        maximum_supply: u128,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String
    ) acquires CoinList {
        only_token_admin(signer);
        let token_metadata_address =
            object::create_object_address(
                &signer::address_of(signer),
                *string::bytes(&symbol)
            );
        let coin_list = borrow_global_mut<CoinList>(@aave_mock_underlyings);

        assert!(
            !smart_table::contains(&coin_list.value, token_metadata_address),
            E_TOKEN_ALREADY_EXISTS
        );

        smart_table::add(&mut coin_list.value, token_metadata_address, true);

        let max_supply =
            if (maximum_supply != 0) {
                option::some(maximum_supply)
            } else {
                option::none()
            };

        let constructor_ref =
            &object::create_named_object(signer, *string::bytes(&symbol));
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            max_supply,
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
    }

    /// @notice Mints tokens as the owner of metadata object
    /// @param admin Admin signer with minting permission
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    /// @param metadata_address Address of the token metadata
    public entry fun mint(
        admin: &signer,
        to: address,
        amount: u64,
        metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(
            &managed_fungible_asset.transfer_ref, to_wallet, fa
        );
    }

    /// @notice Transfers tokens from one address to another
    /// @param from Source address
    /// @param to Destination address
    /// @param amount Amount of tokens to transfer
    /// @param metadata_address Address of the token metadata
    public fun transfer_from(
        from: address,
        to: address,
        amount: u64,
        metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let transfer_ref = &authorized_borrow_refs_without_permission(asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
    }

    /// @notice Burns fungible assets as the owner of metadata object
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    /// @param metadata_address Address of the token metadata
    public fun burn(
        from: address, amount: u64, metadata_address: address
    ) acquires ManagedFungibleAsset {
        let asset = get_metadata(metadata_address);
        let burn_ref = &authorized_borrow_refs_without_permission(asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    /// @notice Verifies that a token exists
    /// @param token_metadata_address Address of the token metadata
    public fun assert_token_exists(token_metadata_address: address) acquires CoinList {
        let coin_list = borrow_global<CoinList>(@aave_mock_underlyings);
        assert!(
            smart_table::contains(&coin_list.value, token_metadata_address),
            E_TOKEN_ALREADY_EXISTS
        );
    }

    // Public view functions
    #[view]
    /// @notice Gets the metadata object by symbol
    /// @param symbol Token symbol
    /// @return The metadata object
    public fun get_metadata_by_symbol(symbol: String): Object<Metadata> {
        let metadata_address =
            object::create_object_address(
                &@aave_mock_underlyings, *string::bytes(&symbol)
            );
        object::address_to_object<Metadata>(metadata_address)
    }

    #[view]
    /// @notice Gets the token account address
    /// @return The token account address
    public fun get_token_account_address(): address {
        @aave_mock_underlyings
    }

    #[view]
    /// @notice Gets the current supply from the metadata object
    /// @param metadata_address Address of the token metadata
    /// @return The current supply, or none if unlimited
    public fun supply(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::supply(asset)
    }

    #[view]
    /// @notice Gets the maximum supply from the metadata object
    /// @param metadata_address Address of the token metadata
    /// @return The maximum supply, or none if unlimited
    public fun maximum(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::maximum(asset)
    }

    #[view]
    /// @notice Gets the name of the fungible asset from the metadata object
    /// @param metadata_address Address of the token metadata
    /// @return The token name
    public fun name(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::name(asset)
    }

    #[view]
    /// @notice Gets the symbol of the fungible asset from the metadata object
    /// @param metadata_address Address of the token metadata
    /// @return The token symbol
    public fun symbol(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::symbol(asset)
    }

    #[view]
    /// @notice Gets the decimals from the metadata object
    /// @param metadata_address Address of the token metadata
    /// @return The token decimals
    public fun decimals(metadata_address: address): u8 {
        let asset = get_metadata(metadata_address);
        fungible_asset::decimals(asset)
    }

    #[view]
    /// @notice Gets the balance of a given store
    /// @param owner Address of the account to check
    /// @param metadata_address Address of the token metadata
    /// @return The token balance
    public fun balance_of(owner: address, metadata_address: address): u64 {
        let metadata = get_metadata(metadata_address);
        primary_fungible_store::balance(owner, metadata)
    }

    #[view]
    /// @notice Gets the token address from its symbol
    /// @param symbol Token symbol
    /// @return The token address
    public fun token_address(symbol: String): address {
        object::create_object_address(&@aave_mock_underlyings, *string::bytes(&symbol))
    }

    // Helper functions
    /// @dev Returns the metadata object from its address
    /// @param metadata_address Address of the token metadata
    /// @return The metadata object
    inline fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }

    /// @dev Borrows the immutable reference of the refs of `metadata`
    /// @dev Validates that the signer is the metadata object's owner
    /// @param owner Signer to validate ownership
    /// @param asset Metadata object
    /// @return Reference to ManagedFungibleAsset
    inline fun authorized_borrow_refs(
        owner: &signer, asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );

        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    /// @dev Borrows the immutable reference of the refs of `metadata` without permission check
    /// @param asset Metadata object
    /// @return Reference to ManagedFungibleAsset
    inline fun authorized_borrow_refs_without_permission(
        asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    /// @dev Verifies that the account is the token admin
    /// @param account Signer to validate
    fun only_token_admin(account: &signer) {
        assert!(signer::address_of(account) == @aave_mock_underlyings, ENOT_OWNER)
    }

    // Test-only functions
    #[test_only]
    /// @dev Initializes the module for testing
    /// @param signer The signer of the transaction
    public fun test_init_module(signer: &signer) {
        init_module(signer);
    }
}
