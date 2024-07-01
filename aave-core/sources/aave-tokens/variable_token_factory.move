module aave_pool::variable_token_factory {
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string;
    use std::string::String;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::Object;

    use aave_acl::acl_manage;
    use aave_config::error as error_config;

    use aave_pool::token_base;

    friend aave_pool::pool;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::variable_token_factory_tests;

    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::pool_tests;

    const ATOKEN_REVISION: u256 = 0x1;

    // error config
    const E_NOT_V_TOKEN_ADMIN: u64 = 1;

    #[event]
    struct Initialized has store, drop {
        underlying_asset: address,
        debt_token_decimals: u8,
        debt_token_name: String,
        debt_token_symbol: String,
    }

    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        underlying_asset: address,
    ) {
        only_token_admin(signer);
        token_base::create_variable_token(
            signer,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
            underlying_asset,
         );

        event::emit(Initialized {
                underlying_asset,
                debt_token_decimals: decimals,
                debt_token_name: name,
                debt_token_symbol: symbol,
            })
    }

    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::mint_scaled(caller, on_behalf_of, amount, index, metadata_address);
    }

    public(friend) fun burn(
        from: address, amount: u256, index: u256, metadata_address: address
    ) {
        token_base::burn_scaled(from, @0x0, amount, index, metadata_address,);
    }

    #[view]
    public fun get_revision(): u256 {
        ATOKEN_REVISION
    }

    #[view]
    public fun get_underlying_asset_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_underlying_asset(&token_data)
    }

    #[view]
    /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata_by_symbol(owner: address, symbol: String): Object<Metadata> {
        let metadata_address =
            object::create_object_address(&owner, *string::bytes(&symbol));
        object::address_to_object<Metadata>(metadata_address)
    }

    #[view]
    public fun token_address(owner: address, symbol: String): address {
        object::create_object_address(&owner, *string::bytes(&symbol))
    }

    #[view]
    public fun asset_metadata(owner: address, symbol: String): Object<Metadata> {
        object::address_to_object<Metadata>(token_address(owner, symbol))
    }

    #[view]
    public fun get_previous_index(user: address, metadata_address: address): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    public fun scale_balance_of(owner: address, metadata_address: address): u256 {
        token_base::scale_balance_of(owner, metadata_address)
    }

    #[view]
    public fun balance_of(owner: address, metadata_address: address): u256 {
        token_base::balance_of(owner, metadata_address)
    }

    #[view]
    public fun scale_total_supply(metadata_address: address): u256 {
        token_base::scale_total_supply(metadata_address)
    }

    #[view]
    public fun supply(metadata_address: address): u256 {
        (*option::borrow(&token_base::supply(metadata_address)) as u256)
    }

    #[view]
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// Get the maximum supply from the `metadata` object.
    public fun maximum(metadata_address: address): Option<u128> {
        token_base::maximum(metadata_address)
    }

    #[view]
    /// Get the name of the fungible asset from the `metadata` object.
    public fun name(metadata_address: address): String {
        token_base::name(metadata_address)
    }

    #[view]
    /// Get the symbol of the fungible asset from the `metadata` object.
    public fun symbol(metadata_address: address): String {
        token_base::symbol(metadata_address)
    }

    #[view]
    /// Get the decimals from the `metadata` object.
    public fun decimals(metadata_address: address): u8 {
        token_base::decimals(metadata_address)
    }

    fun only_token_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(acl_manage::is_asset_listing_admin(account_address) || acl_manage::is_pool_admin(account_address), error_config::get_ecaller_not_asset_listing_or_pool_admin())
    }
}
