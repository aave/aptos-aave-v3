/// @title Fungible Asset Manager Module
/// @author Aave
/// @notice A utility module to manage fungible assets in the Aave protocol
/// @dev Provides a standardized interface for interacting with fungible assets
module aave_pool::fungible_asset_manager {
    // imports
    use std::option::Option;
    use std::string::String;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;

    use aave_config::error_config;

    // friend modules
    friend aave_pool::a_token_factory;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::flashloan_logic;

    #[test_only]
    friend aave_pool::fungible_asset_manager_tests;

    // Error constants

    // Global Constants

    // Structs

    // Public view functions
    #[view]
    /// @notice Get the balance of a given store
    /// @param owner The address of the account to check balance for
    /// @param metadata_address The address of the metadata object
    /// @return The balance of the owner's store
    public fun balance_of(owner: address, metadata_address: address): u64 {
        let metadata = get_metadata(metadata_address);
        primary_fungible_store::balance(owner, metadata)
    }

    #[view]
    /// @notice Get the current supply from the metadata object
    /// @param metadata_address The address of the metadata object
    /// @return The current supply of the fungible asset
    public fun supply(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::supply(asset)
    }

    #[view]
    /// @notice Get the maximum supply from the metadata object
    /// @param metadata_address The address of the metadata object
    /// @return The maximum supply of the fungible asset
    public fun maximum(metadata_address: address): Option<u128> {
        let asset = get_metadata(metadata_address);
        fungible_asset::maximum(asset)
    }

    #[view]
    /// @notice Get the name of the fungible asset from the metadata object
    /// @param metadata_address The address of the metadata object
    /// @return The name of the fungible asset
    public fun name(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::name(asset)
    }

    #[view]
    /// @notice Get the symbol of the fungible asset from the metadata object
    /// @param metadata_address The address of the metadata object
    /// @return The symbol of the fungible asset
    public fun symbol(metadata_address: address): String {
        let asset = get_metadata(metadata_address);
        fungible_asset::symbol(asset)
    }

    #[view]
    /// @notice Get the decimals from the metadata object
    /// @param metadata_address The address of the metadata object
    /// @return The number of decimals of the fungible asset
    public fun decimals(metadata_address: address): u8 {
        let asset = get_metadata(metadata_address);
        fungible_asset::decimals(asset)
    }

    // Public functions
    /// @notice Verifies that a token exists at the given metadata address
    /// @param metadata_address The address of the metadata object to check
    /// @dev Aborts if the token does not exist
    public fun assert_token_exists(metadata_address: address) {
        assert!(
            object::object_exists<Metadata>(metadata_address),
            error_config::get_eresource_not_exist()
        )
    }

    // Friend functions
    /// @notice Transfer a given amount of the asset to a recipient
    /// @dev Only callable by the supply_logic, borrow_logic, liquidation_logic, flashloan_logic and a_token_factory module
    /// @param from The account signer of the caller
    /// @param to The recipient of the asset
    /// @param amount The amount to transfer
    /// @param metadata_address The address of the metadata object
    friend fun transfer(
        from: &signer, to: address, amount: u64, metadata_address: address
    ) {
        let asset_metadata = get_metadata(metadata_address);
        primary_fungible_store::transfer(from, asset_metadata, to, amount);
    }

    // Private functions
    /// @notice Return the Object<Metadata> for a given metadata address
    /// @param metadata_address The address of the metadata object
    /// @return The Object<Metadata> representation of the fungible asset
    fun get_metadata(metadata_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(metadata_address)
    }
}
