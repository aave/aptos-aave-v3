module aave_pool::variable_debt_token_factory {
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
    friend aave_pool::variable_debt_token_factory_tests;

    #[test_only]
    friend aave_pool::pool_configurator_tests;
    #[test_only]
    friend aave_pool::pool_tests;

    const DEBT_TOKEN_REVISION: u256 = 0x1;

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

        event::emit(
            Initialized {
                underlying_asset,
                debt_token_decimals: decimals,
                debt_token_name: name,
                debt_token_symbol: symbol,
            },
        )
    }

    /// @notice Mints debt token to the `on_behalf_of` address
    /// @param caller The address receiving the borrowed underlying, being the delegatee in case
    /// of credit delegate, or same as `on_behalf_of` otherwise
    /// @param on_behalf_of The address receiving the debt tokens
    /// @param amount The amount of debt being minted
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::mint_scaled(caller, on_behalf_of, amount, index, metadata_address);
    }

    /// @notice Burns user variable debt
    /// @dev In some instances, a burn transaction will emit a mint event
    /// if the amount to burn is less than the interest that the user accrued
    /// @param from The address from which the debt will be burned
    /// @param amount The amount getting burned
    /// @param index The variable debt index of the reserve
    /// @param metadata_address The address of the metadata object
    public(friend) fun burn(
        from: address, amount: u256, index: u256, metadata_address: address
    ) {
        token_base::burn_scaled(from, @0x0, amount, index, metadata_address);
    }

    #[view]
    public fun get_revision(): u256 {
        DEBT_TOKEN_REVISION
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
    /// @param metadata_address The address of the metadata object
    /// @return The address of the underlying asset
    public fun get_underlying_asset_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_underlying_asset(&token_data)
    }

    #[view]
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
    /// @notice Returns last index interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the variable debt token
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user.
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 {
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 {
        token_base::scaled_total_supply(metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply.
    /// @param owner The address of the user
    /// @param metadata_address The address of the variable debt token
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
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
        assert!(
            acl_manage::is_asset_listing_admin(account_address)
                || acl_manage::is_pool_admin(account_address),
            error_config::get_ecaller_not_asset_listing_or_pool_admin(),
        )
    }
}
