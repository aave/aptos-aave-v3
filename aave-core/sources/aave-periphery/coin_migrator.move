/// @title Coin Migrator Module
/// @author Aave
/// @notice Implements functionality to convert Aptos Coin to FungibleAsset
module aave_pool::coin_migrator {
    // imports
    use std::signer;
    use std::option;
    use std::string::String;
    use aptos_std::type_info::Self;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::dispatchable_fungible_asset::Self;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::object;
    use aptos_framework::coin::{Self};
    use aptos_framework::event;
    use aptos_framework::object::Object;
    use aave_config::error_config;

    // Events
    #[event]
    /// @notice Emitted when a Coin is converted to a FungibleAsset
    /// @param user The address of the user who performed the conversion
    /// @param amount The amount of coins converted
    /// @param name The name of the fungible asset
    /// @param symbol The symbol of the fungible asset
    /// @param decimals The number of decimals for the fungible asset
    /// @param coin_address The address of the coin type
    /// @param fa_address The address of the fungible asset
    struct CoinToFaConvertion has store, drop {
        user: address,
        amount: u64,
        name: String,
        symbol: String,
        decimals: u8,
        coin_address: address,
        fa_address: address
    }

    // Public functions
    /// @notice Converts Aptos Coin to FungibleAsset
    /// @dev Withdraws coins from the user's account and converts them to fungible assets
    /// @param account The signer account of the user
    /// @param amount The amount of coins to convert
    public fun coin_to_fa<CoinType>(account: &signer, amount: u64): Object<Metadata> {
        let coin_balance = coin::balance<CoinType>(signer::address_of(account));
        assert!(
            coin_balance >= amount && amount > 0,
            error_config::get_einsufficient_coins_to_wrap()
        );
        let coin_type = type_info::type_of<CoinType>();
        let coin_to_wrap = coin::withdraw<CoinType>(account, amount);
        let wrapped_fa = coin::coin_to_fungible_asset<CoinType>(coin_to_wrap);
        let wrapped_fa_meta = fungible_asset::metadata_from_asset(&wrapped_fa);
        let wrapped_fa_address = object::object_address(&wrapped_fa_meta);
        let account_wallet =
            primary_fungible_store::ensure_primary_store_exists(
                signer::address_of(account), wrapped_fa_meta
            );
        dispatchable_fungible_asset::deposit(account_wallet, wrapped_fa);

        event::emit(
            CoinToFaConvertion {
                user: signer::address_of(account),
                amount,
                name: fungible_asset::name(wrapped_fa_meta),
                symbol: fungible_asset::symbol(wrapped_fa_meta),
                decimals: fungible_asset::decimals(wrapped_fa_meta),
                coin_address: type_info::account_address(&coin_type),
                fa_address: wrapped_fa_address
            }
        );
        wrapped_fa_meta
    }

    // Public view functions
    #[view]
    /// @notice Gets the address of the fungible asset that corresponds to a coin type
    /// @dev Returns the address of the fungible asset metadata object
    /// @return The address of the fungible asset
    public fun get_fa_address<CoinType>(): address {
        let wrapped_fa_meta = coin::paired_metadata<CoinType>();
        assert!(
            option::is_some(&wrapped_fa_meta),
            error_config::get_eunmapped_coin_to_fa()
        );
        let wrapped_fa_meta = option::destroy_some(wrapped_fa_meta);
        object::object_address(&wrapped_fa_meta)
    }

    #[view]
    /// @notice Gets the balance of fungible assets for a given coin type and owner
    /// @dev Returns 0 if the coin type is not mapped to a fungible asset
    /// @param owner The address of the owner
    /// @return The balance of fungible assets
    public fun get_fa_balance<CoinType>(owner: address): u64 {
        let wrapped_fa_meta = coin::paired_metadata<CoinType>();

        if (option::is_none(&wrapped_fa_meta)) {
            return 0;
        };

        let wrapped_fa_meta = option::destroy_some(wrapped_fa_meta);
        if (!primary_fungible_store::primary_store_exists(owner, wrapped_fa_meta)) {
            return 0;
        };

        primary_fungible_store::balance(owner, wrapped_fa_meta)
    }
}
