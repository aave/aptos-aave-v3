module aave_pool::a_token_factory {
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

    use aave_pool::mock_underlying_token_factory::Self;
    use aave_pool::token_base;

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
    /// @dev Emitted when an aToken is initialized
    /// @param underlyingAsset The address of the underlying asset
    /// @param treasury The address of the treasury
    /// @param a_token_decimals The decimals of the underlying
    /// @param a_token_name The name of the aToken
    /// @param a_token_symbol The symbol of the aToken
    struct Initialized has store, drop {
        underlying_asset: address,
        treasury: address,
        a_token_decimals: u8,
        a_token_name: String,
        a_token_symbol: String,
    }

    #[event]
    /// @dev Emitted during the transfer action
    /// @param from The user whose tokens are being transferred
    /// @param to The recipient
    /// @param value The scaled amount being transferred
    /// @param index The next liquidity index of the reserve
    struct BalanceTransfer has store, drop {
        from: address,
        to: address,
        value: u256,
        index: u256,
    }

    //
    // Entry Functions
    //
    /// @notice Creates a new aToken
    /// @param signer The signer of the transaction
    /// @param name The name of the aToken
    /// @param symbol The symbol of the aToken
    /// @param decimals The decimals of the aToken
    /// @param icon_uri The icon URI of the aToken
    /// @param project_uri The project URI of the aToken
    /// @param underlying_asset The address of the underlying asset
    /// @param treasury The address of the treasury
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
            resource_account,
        );

        event::emit(
            Initialized {
                underlying_asset,
                treasury,
                a_token_decimals: decimals,
                a_token_name: name,
                a_token_symbol: symbol,
            },
        )
    }

    /// @notice Rescue and transfer tokens locked in this contract
    /// @param token The address of the token
    /// @param to The address of the recipient
    /// @param amount The amount of token to transfer
    public entry fun rescue_tokens(
        account: &signer, token: address, to: address, amount: u256
    ) {
        token_base::only_pool_admin(account);
        assert!(
            token != get_underlying_asset_address(token),
            error_config::get_eunderlying_cannot_be_rescued(),
        );
        let account_address = signer::address_of(account);
        token_base::transfer_internal(account_address, to, (amount as u64), token);
    }

    //
    //  Functions Call between contracts
    //

    /// @notice Mints `amount` aTokens to `user`
    /// @param caller The address performing the mint
    /// @param on_behalf_of The address of the user that will receive the minted aTokens
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun mint(
        caller: address,
        on_behalf_of: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::mint_scaled(caller, on_behalf_of, amount, index, metadata_address);
    }

    /// @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
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
    ) {
        token_base::burn_scaled(
            from,
            receiver_of_underlying,
            amount,
            index,
            metadata_address,
        );
        if (receiver_of_underlying != get_token_account_address(metadata_address)) {
            mock_underlying_token_factory::transfer_from(
                get_token_account_address(metadata_address),
                receiver_of_underlying,
                (amount as u64),
                get_underlying_asset_address(metadata_address),
            )
        }
    }

    /// @notice Mints aTokens to the reserve treasury
    /// @param amount The amount of tokens getting minted
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun mint_to_treasury(
        amount: u256, index: u256, metadata_address: address
    ) {
        if (amount != 0) {
            let token_data = token_base::get_token_data(metadata_address);
            token_base::mint_scaled(
                @aave_pool,
                token_base::get_treasury_address(&token_data),
                amount,
                index,
                metadata_address,
            )
        }
    }

    /// @notice Transfers the underlying asset to `target`.
    /// @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
    /// @param to The recipient of the underlying
    /// @param amount The amount getting transferred
    /// @param metadata_address The address of the aToken
    public(friend) fun transfer_underlying_to(
        to: address, amount: u256, metadata_address: address
    ) {
        mock_underlying_token_factory::transfer_from(
            get_token_account_address(metadata_address),
            to,
            (amount as u64),
            get_underlying_asset_address(metadata_address),
        )
    }

    /// @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
    /// @param from The address getting liquidated, current owner of the aTokens
    /// @param to The recipient
    /// @param amount The amount of tokens getting transferred
    /// @param index The next liquidity index of the reserve
    /// @param metadata_address The address of the aToken
    public(friend) fun transfer_on_liquidation(
        from: address,
        to: address,
        amount: u256,
        index: u256,
        metadata_address: address
    ) {
        token_base::transfer(from, to, amount, index, metadata_address);
        // send balance transfer event
        event::emit(
            BalanceTransfer { from, to, value: wad_ray_math::ray_div(amount, index), index },
        );
    }

    /// @notice Handles the underlying received by the aToken after the transfer has been completed.
    /// @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
    /// transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
    /// to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
    /// @param user The user executing the repayment
    /// @param on_behalf_of The address of the user who will get his debt reduced/removed
    /// @param amount The amount getting repaid
    /// @param metadata_address The address of the aToken
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
    /// @notice Return the address of the managed fungible asset that's created resource account.
    /// @param metadata_address The address of the aToken
    public fun get_token_account_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_resource_account(&token_data)
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
    /// @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
    /// @param metadata_address The address of the aToken
    /// @return Address of the Aave treasury
    public fun get_reserve_treasury_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_treasury_address(&token_data)
    }

    #[view]
    /// @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
    /// @param metadata_address The address of the aToken
    /// @return The address of the underlying asset
    public fun get_underlying_asset_address(metadata_address: address): address {
        let token_data = token_base::get_token_data(metadata_address);
        token_base::get_underlying_asset(&token_data)
    }

    #[view]
    /// @notice Returns last index interest was accrued to the user's balance
    /// @param user The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The last index interest was accrued to the user's balance, expressed in ray
    public fun get_previous_index(
        user: address, metadata_address: address
    ): u256 {
        token_base::get_previous_index(user, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user and the scaled total supply.
    /// @param owner The address of the user
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    /// @return The scaled total supply
    public fun get_scaled_user_balance_and_supply(
        owner: address, metadata_address: address
    ): (u256, u256) {
        token_base::get_scaled_user_balance_and_supply(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled balance of the user.
    /// @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
    /// at the moment of the update
    /// @param owner The user whose balance is calculated
    /// @param metadata_address The address of the aToken
    /// @return The scaled balance of the user
    public fun scaled_balance_of(
        owner: address, metadata_address: address
    ): u256 {
        token_base::scaled_balance_of(owner, metadata_address)
    }

    #[view]
    /// @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
    /// @param metadata_address The address of the aToken
    /// @return The scaled total supply
    public fun scaled_total_supply(metadata_address: address): u256 {
        token_base::scaled_total_supply(metadata_address)
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
