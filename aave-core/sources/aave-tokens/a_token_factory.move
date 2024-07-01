module aave_pool::a_token_factory {
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::event::Self;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::resource_account;

    use aave_config::error as error_config;
    use aave_math::wad_ray_math;

    use aave_pool::token_base;
    use aave_pool::underlying_token_factory::Self;

    friend aave_pool::pool;
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::bridge_logic;
    friend aave_pool::liquidation_logic;

    #[test_only]
    friend aave_pool::a_token_factory_tests;
    #[test_only]
    friend aave_pool::pool_configurator_tests;

    const ATOKEN_REVISION: u256 = 0x1;
    // error config
    const E_NOT_A_TOKEN_ADMIN: u64 = 1;

    #[event]
    struct Initialized has store, drop {
        underlying_asset: address,
        treasury: address,
        a_token_decimals: u8,
        a_token_name: String,
        a_token_symbol: String,
    }

    #[event]
    struct BalanceTransfer has store, drop{
        from: address,
        to: address,
        value: u256,
        index: u256,
    }

    //
    // Entry Functions
    //
    public(friend) fun create_token(
        signer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        icon_uri: String,
        project_uri: String,
        underlying_asset: address,
        treasury: address,
    ) {
        let user_addr = signer::address_of(signer);
        if (!account::exists_at(user_addr)) {
            aptos_framework::aptos_account::create_account(user_addr);
        };
        let seed = *string::bytes(&symbol);
        resource_account::create_resource_account(signer, seed, vector::empty());
        let resource_account =
            account::create_resource_address(&signer::address_of(signer), seed);

        token_base::create_a_token(
            signer,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri,
            underlying_asset,
            treasury,
            resource_account);

        event::emit(Initialized {
                underlying_asset,
                treasury,
                a_token_decimals: decimals,
                a_token_name: name,
                a_token_symbol: symbol,
            })
    }

    public entry fun rescue_tokens(
        account: &signer, token: address, to: address, amount: u256
    ) {
        token_base::only_pool_admin(account);
        assert!(token != get_underlying_asset_address(token),
            error_config::get_eunderlying_cannot_be_rescued());
        let account_address = signer::address_of(account);
        token_base::transfer_internal(account_address, to, (amount as u64), token);
    }

    //
    //  Functions Call between contracts
    //

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
        from: address,
        receiver_of_underlying: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::burn_scaled(from, receiver_of_underlying, amount, index,
            metadata_address,);
        if (receiver_of_underlying != get_token_account_address(metadata_address)) {
            underlying_token_factory::transfer_from(get_token_account_address(
                    metadata_address),
                receiver_of_underlying,
                (amount as u64),
                get_underlying_asset_address(metadata_address))
        }
    }

    public(friend) fun mint_to_treasury(
        amount: u256, index: u256, metadata_address: address
    ) {
        if (amount != 0) {
            let token_data = token_base::get_token_data(metadata_address);
            token_base::mint_scaled(@aave_pool,
                token_base::get_treasury_address(&token_data),
                amount,
                index,
                metadata_address,)
        }
    }

    public(friend) fun transfer_underlying_to(
        to: address, amount: u256, metadata_address: address
    ) {
        underlying_token_factory::transfer_from(get_token_account_address(metadata_address),
            to,
            (amount as u64),
            get_underlying_asset_address(metadata_address))
    }

    public(friend) fun transfer_on_liquidation(
        from: address,
        to: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::transfer(from, to, amount, index, metadata_address);
        // send balance transfer event
        event::emit(BalanceTransfer{
            from,
            to,
            value: wad_ray_math::ray_div(amount,index),
            index
        });
    }

    public fun handle_repayment(
        _user: address, _onBehalfOf: address, _amount: u256, _metadata_address: address
    ) {
        // Intentionally left blank
    }

    //
    //  View functions
    //

    #[view]
    public fun get_revision(): u256 {
        ATOKEN_REVISION
    }

    #[view]
    public fun get_token_account_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_resource_account(&token_data)
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
    public fun get_reserve_treasury_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_treasury_address(&token_data)
    }

    #[view]
    public fun get_underlying_asset_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_underlying_asset(&token_data)
    }

    #[view]
    public fun get_previous_index(user: address, metadata_address: address): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
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
    public fun maximum(metadata_address: address): Option<u128> {
        token_base::maximum(metadata_address)
    }

    #[view]
    public fun name(metadata_address: address): String {
        token_base::name(metadata_address)
    }

    #[view]
    public fun symbol(metadata_address: address): String {
        token_base::symbol(metadata_address)
    }

    #[view]
    public fun decimals(metadata_address: address): u8 {
        token_base::decimals(metadata_address)
    }
}
