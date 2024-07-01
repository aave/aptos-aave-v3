module aave_oracle::oracle {

    use std::option::{Self, Option};
    use std::signer;
    use std::string::{String};

    use aptos_std::string_utils::{Self};
    use aptos_framework::coin;
    use aptos_framework::aptos_coin;
    use aptos_framework::timestamp::now_seconds;

    use aave_acl::acl_manage::{is_asset_listing_admin, is_pool_admin};
    use pyth::pyth;
    use pyth::price_identifier;
    use pyth::i64;
    use pyth::price::{Self, Price};

    use aptos_std::math64::pow;
    use aptos_std::smart_table::{Self, SmartTable};

    // Not an asset listing or a pool admin error
    const NOT_ASSET_LISTING_OR_POOL_ADMIN: u64 = 1;
    // base currency not set
    const BASE_CURRENCY_NOT_SET: u64 = 2;
    // identical base currency already added
    const IDENTICAL_BASE_CURRENCY_ALREADY_ADDED: u64 = 3;
    // missing price feed identifier
    const MISSING_PRICE_FEED_IDENTIFIER: u64 = 4;
    // missing price vaa
    const MISSING_PRICE_VAA: u64 = 5;
    // not existing price feed identifier
    const PRICE_FEED_IDENTIFIER_NOT_EXIST: u64 = 6;

    struct BaseCurrency has copy, key, store, drop {
        asset: String,
        unit: u64,
    }

    struct OracleData has key, store {
        pairs_to_indentifiers: SmartTable<String, vector<u8>>,
        pairs_to_vaas: SmartTable<String, vector<vector<u8>>>,
        base_currency: Option<BaseCurrency>,
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        init_module(account);
    }

    fun init_module(account: &signer) {
        move_to(account,
            OracleData {
                pairs_to_indentifiers: smart_table::new<String, vector<u8>>(),
                pairs_to_vaas: smart_table::new<String, vector<vector<u8>>>(),
                base_currency: option::none()
            })
    }

    fun check_base_currency_set(base_currency: &Option<BaseCurrency>) {
        assert!(option::is_some(base_currency), BASE_CURRENCY_NOT_SET);
    }

    fun check_is_asset_listing_or_pool_admin(account: address) {
        assert!(is_asset_listing_admin(account) || is_pool_admin(account),
            NOT_ASSET_LISTING_OR_POOL_ADMIN);
    }

    #[view]
    public fun get_pyth_oracle_address(): address {
        @pyth
    }

    /// sets oracle base currency
    public entry fun set_oracle_base_currency(
        account: &signer, base_currency_asset: String, base_currency_unit: u64
    ) acquires OracleData {
        // ensure only admins can call this method
        check_is_asset_listing_or_pool_admin(signer::address_of(account));
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        oracle_data.base_currency = option::some(BaseCurrency {
                asset: base_currency_asset,
                unit: base_currency_unit,
            })
    }

    /// Gets the oracle base currency
    fun get_oracle_base_currency(): Option<BaseCurrency> acquires OracleData {
        // get the oracle data
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        // check and return if exists
        if (option::is_some(&oracle_data.base_currency)) {
            option::some(*option::borrow(&oracle_data.base_currency))
        } else {
            option::none<BaseCurrency>()
        }
    }

    /// Adds an asset with its identifier
    public entry fun add_asset_identifier(
        account: &signer, asset: String, price_feed_identifier: vector<u8>
    ) acquires OracleData {
        // ensure only admins can call this method
        check_is_asset_listing_or_pool_admin(signer::address_of(account));
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        // check the base currency is set
        check_base_currency_set(&oracle_data.base_currency);
        // check the base currency is different than the asset being added
        assert!((*option::borrow<BaseCurrency>(&oracle_data.base_currency)).asset != asset,
            IDENTICAL_BASE_CURRENCY_ALREADY_ADDED);
        // check the price_feed identifier exists
        assert!(pyth::price_feed_exists(price_identifier::from_byte_vec(
                    price_feed_identifier)),
            PRICE_FEED_IDENTIFIER_NOT_EXIST);
        // build the asset pair
        let asset_pair =
            string_utils::format2(&b"{}_{}", asset, (*option::borrow<BaseCurrency>(&oracle_data
                            .base_currency)).asset);
        // store the identifier for the asset pair
        smart_table::upsert(&mut oracle_data.pairs_to_indentifiers, asset_pair,
            price_feed_identifier);
    }

    /// Adds an asset with its vaa
    public entry fun add_asset_vaa(
        account: &signer, asset: String, vaa: vector<vector<u8>>
    ) acquires OracleData {
        // ensure only admins can call this method
        check_is_asset_listing_or_pool_admin(signer::address_of(account));
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        // check the base currency is set
        check_base_currency_set(&oracle_data.base_currency);
        // check the base currency is different than the asset being added
        assert!((*option::borrow<BaseCurrency>(&oracle_data.base_currency)).asset != asset,
            IDENTICAL_BASE_CURRENCY_ALREADY_ADDED);
        // build the asset pair
        let asset_pair =
            string_utils::format2(&b"{}_{}", asset, (*option::borrow<BaseCurrency>(&oracle_data
                            .base_currency)).asset);
        // store the vaa for the asset pair
        smart_table::upsert(&mut oracle_data.pairs_to_vaas, asset_pair, vaa);
    }

    /// Gets asset identifier if recorded for the current base currency
    fun get_asset_identifier(asset: String): Option<vector<u8>> acquires OracleData {
        // check the asset is not the base currency
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        // construct the asset pair
        let asset_pair =
            string_utils::format2(&b"{}_{}", asset, (*option::borrow<BaseCurrency>(&oracle_data
                            .base_currency)).asset);
        // check and return if listed
        if (smart_table::contains(&oracle_data.pairs_to_indentifiers, asset_pair)) {
            option::some(*smart_table::borrow(&oracle_data.pairs_to_indentifiers, asset_pair))
        } else {
            option::none<vector<u8>>()
        }
    }

    /// Gets asset vaa if recorded for the current base currency
    fun get_asset_vaa(asset: String): Option<vector<vector<u8>>> acquires OracleData {
        // check the asset is not the base currency
        let oracle_data = borrow_global_mut<OracleData>(@aave_oracle);
        // construct the asset pair
        let asset_pair =
            string_utils::format2(&b"{}_{}", asset, (*option::borrow<BaseCurrency>(&oracle_data
                            .base_currency)).asset);
        // check and return if listed
        if (smart_table::contains(&oracle_data.pairs_to_vaas, asset_pair)) {
            option::some(*smart_table::borrow(&oracle_data.pairs_to_vaas, asset_pair))
        } else {
            option::none<vector<vector<u8>>>()
        }
    }

    /// Get the price for a given vaas and a price feed
    fun get_price(oracle_fee_payer: &signer, asset: String): (u64, u64, u64) acquires OracleData {
        // get the price feed identifier
        let price_feed_identifier = get_asset_identifier(asset);
        // assert the identifier is found
        assert!(option::is_some(&price_feed_identifier), MISSING_PRICE_FEED_IDENTIFIER);
        // get the vaa for the asset and the base currency
        let price_vaa = get_asset_vaa(asset);
        // assert the identifier is found
        assert!(option::is_some(&price_vaa), MISSING_PRICE_VAA);
        // using the identifier fetch the price
        let price =
            update_and_fetch_price(oracle_fee_payer, *option::borrow(&price_vaa), *option::borrow(
                    &price_feed_identifier));
        // construct the price
        let price_positive =
            if (i64::get_is_negative(&price::get_price(&price))) {
                i64::get_magnitude_if_negative(&price::get_price(&price))
            } else {
                i64::get_magnitude_if_positive(&price::get_price(&price))
            };
        let expo_magnitude =
            if (i64::get_is_negative(&price::get_expo(&price))) {
                i64::get_magnitude_if_negative(&price::get_expo(&price))
            } else {
                i64::get_magnitude_if_positive(&price::get_expo(&price))
            };
        (price_positive * pow(10, expo_magnitude),
            price::get_conf(&price),
            price::get_timestamp(&price))
    }

    /// Returns a constant for a mocked price
    fun get_price_mock(): (u64, u64, u64) {
        (1000, 80, now_seconds())
    }

    /// Updates the price feeds by paying in aptos coins and fetches the price from the oracle for the asset pair
    fun update_and_fetch_price(
        oracle_fee_payer: &signer, vaas: vector<vector<u8>>, price_feed_identifier: vector<u8>
    ): Price {
        // See https://docs.pyth.network/documentation/pythnet-price-feeds for reference
        let coins =
            coin::withdraw<aptos_coin::AptosCoin>(oracle_fee_payer,
                pyth::get_update_fee(&vaas)); // Get aptos coins to pay for the update
        pyth::update_price_feeds(vaas, coins); // Update price feed with the provided vaas
        pyth::get_price(price_identifier::from_byte_vec(price_feed_identifier)) // Get recent price (will fail if price is too old)
    }

    #[test_only]
    public fun get_pyth_oracle_address_for_testing(): address {
        get_pyth_oracle_address()
    }

    // sets oracle base currency
    #[test_only]
    public entry fun set_oracle_base_currency_for_testing(
        account: &signer, base_currency_asset: String, base_currency_unit: u64
    ) acquires OracleData {
        set_oracle_base_currency(account, base_currency_asset, base_currency_unit)
    }

    // Gets the oracle base currency
    #[test_only]
    public fun get_oracle_base_currency_for_testing(): Option<BaseCurrency> acquires OracleData {
        get_oracle_base_currency()
    }

    // Adds an asset with its identifier
    #[test_only]
    public entry fun add_asset_identifier_for_testing(
        account: &signer, asset: String, price_feed_identifier: vector<u8>
    ) acquires OracleData {
        add_asset_identifier(account, asset, price_feed_identifier)
    }

    // Adds an asset with its vaa
    #[test_only]
    public entry fun add_asset_vaa_for_testing(
        account: &signer, asset: String, vaa: vector<vector<u8>>
    ) acquires OracleData {
        add_asset_vaa(account, asset, vaa);
    }

    // Gets asset identifier if recorded for the current base currency
    #[test_only]
    public fun get_asset_identifier_for_testing(asset: String): Option<vector<u8>> acquires OracleData {
        get_asset_identifier(asset)
    }

    // Gets asset vaa if recorded for the current base currency
    #[test_only]
    public fun get_asset_vaa_for_testing(asset: String): Option<vector<vector<u8>>> acquires OracleData {
        get_asset_vaa(asset)
    }

    // Get a mocked price
    #[test_only]
    public fun get_price_mock_for_testing(): (u64, u64, u64) {
        get_price_mock()
    }

    // Get a mocked price
    #[test_only]
    public fun create_base_currency(asset: String, unit: u64,): BaseCurrency {
        BaseCurrency { asset, unit, }
    }
}
