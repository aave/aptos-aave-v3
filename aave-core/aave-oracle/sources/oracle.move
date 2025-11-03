/// @title Oracle
/// @author Aave
/// @notice Provides price feed functionality for the Aave protocol
module aave_oracle::oracle {
    // imports
    use std::option;
    use std::option::Option;
    use std::vector;
    use std::signer;
    use aptos_std::smart_table;
    use aptos_framework::event;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use data_feeds::router::{Self as chainlink_router};
    use data_feeds::registry::{Self as chainlink};
    use aave_acl::acl_manage;
    use aave_config::error_config::Self;
    use aave_math::math_utils::Self;
    use aave_oracle::oracle;
    #[test_only]
    use aptos_std::string_utils::format1;

    // Constants
    /// @notice Seed for the resource account
    const AAVE_ORACLE_SEED: vector<u8> = b"AAVE_ORACLE";
    /// @notice Decimal precision for Chainlink asset prices
    /// @dev Reference: https://docs.chain.link/data-feeds/price-feeds/addresses?network=aptos&page=1
    const CHAINLINK_ASSET_DECIMAL_PRECISION: u8 = 18;

    /// @notice Maximum value for a 192-bit signed integer (192-th bit is sign bit)
    /// @dev All positive values are in [0, 2^191 - 1]
    const I192_MAX: u256 = 3138550867693340381917894711603833208051177722232017256447; // 2^191 - 1

    /// @notice Default maximum age for an oracle price - in seconds
    /// @dev Set for 45 mins for all assets
    const DEFAULT_MAX_PRICE_AGE_SECS: u64 = 45 * 60;

    /// @notice Test maximum age for an oracle price - in seconds
    /// @dev Set to one hour for all assets
    const TEST_MAX_PRICE_AGE_SECS: u64 = 60 * 60;

    /// @notice Minimal ratio increase lifetime in years for overflow protection
    /// @dev This constant defines the minimum acceptable timeframe (3 years) before a ratio could
    ///      potentially overflow due to compound growth in the SUSDE price adapter. It serves as a
    ///      critical safety mechanism to prevent mathematical overflow in ratio calculations.
    ///
    ///      The 3-year timeframe balances safety (preventing immediate overflow risks) with flexibility
    ///      (allowing reasonable growth parameters for liquid staking rewards). This is particularly
    ///      important for SUSDE where the ratio represents the appreciation of staked USDe over time.
    const MINIMAL_RATIO_INCREASE_LIFETIME: u256 = 3;

    /// @notice The type of adapter for retrieving the price
    enum AdapterType has copy, drop, store {
        STABLE,
        SUSDE
    }

    // Event definitions
    #[event]
    struct AssetPriceFeedUpdated has store, drop {
        /// @dev Address of the asset
        asset: address,
        /// @dev Feed ID for the asset
        feed_id: vector<u8>
    }

    #[event]
    /// @notice Emitted when an asset custom price is updated
    struct AssetCustomPriceUpdated has store, drop {
        /// @dev Address of the asset
        asset: address,
        /// @dev Custom price value
        custom_price: u256
    }

    #[event]
    /// @notice Emitted when an asset maximum price age is updated
    struct AssetMaximumPriceAgeUpdated has store, drop {
        /// @dev Address of the asset
        asset: address,
        /// @dev The maximum price age
        maximum_price_age: u64
    }

    #[event]
    /// @notice Emitted when an asset price feed is removed
    struct AssetPriceFeedRemoved has store, drop {
        /// @dev Address of the asset
        asset: address,
        /// @dev Feed ID that was removed
        feed_id: vector<u8>
    }

    #[event]
    /// @notice Emitted when an asset custom price is removed
    struct AssetCustomPriceRemoved has store, drop {
        /// @dev Address of the asset
        asset: address,
        /// @dev Custom price that was removed
        custom_price: u256
    }

    #[event]
    /// @notice Emitted when a price cap is updated for an asset
    struct PriceCapUpdated has store, drop {
        /// @dev Address of the asset
        asset: address
    }

    #[event]
    /// @notice Emitted when a price cap is removed for an asset
    struct PriceCapRemoved has store, drop {
        /// @dev Address of the asset
        asset: address
    }

    #[event]
    /// @notice Emitted when the cap parameters are updated for an asset
    struct CapParametersUpdated has store, drop {
        /// @dev Snapshot ratio
        snapshot_ratio: u256,
        /// @dev Snapshot timestamp
        snapshot_timestamp: u256,
        /// @dev Max ratio growth per second
        max_ratio_growth_per_second: u256,
        /// @dev Max yearly ratio growth percent
        max_yearly_ratio_growth_percent: u256
    }

    // Structs
    /// @notice Main storage for multiple capped asset data
    struct CappedAssetData has store, key, drop, copy {
        /// @dev Adaptor type
        type: AdapterType,
        /// @dev Stable price cap
        stable_price_cap: Option<u256>,
        /// @dev Ratio decimals
        ratio_decimals: Option<u8>,
        /// @dev Minimum snapshot delay
        minimum_snapshot_delay: Option<u256>,
        /// @dev Snapshot timestamp
        snapshot_timestamp: Option<u256>,
        /// @dev Max ratio growth per second
        max_ratio_growth_per_second: Option<u256>,
        /// @dev Max yearly ratio growth percent
        max_yearly_ratio_growth_percent: Option<u256>,
        /// @dev Snapshot ratio
        snapshot_ratio: Option<u256>,
        /// @dev mapped asset ratio multiplier
        mapped_asset_ratio_multiplier: Option<address>
    }

    /// @notice Main storage for oracle data
    struct PriceOracleData has key {
        /// @dev Mapping of asset addresses to their feed IDs
        asset_feed_ids: smart_table::SmartTable<address, vector<u8>>,
        /// @dev Mapping of asset addresses to their custom prices
        custom_asset_prices: smart_table::SmartTable<address, u256>,
        /// @dev Capability to generate the resource account signer
        signer_cap: SignerCapability,
        /// @dev Mapping of asset addresses to their price caps
        capped_assets_data: smart_table::SmartTable<address, CappedAssetData>,
        /// @dev Mapping of asset addresses to their maximum acceptable age in seconds
        max_asset_price_age: smart_table::SmartTable<address, u64>
    }

    // Module initialization
    /// @dev Initializes the oracle module
    /// @param account Admin account that initializes the module
    fun init_module(account: &signer) {
        only_oracle_admin(account);

        // create a resource account
        let (resource_signer, signer_cap) =
            account::create_resource_account(account, AAVE_ORACLE_SEED);

        move_to(
            &resource_signer,
            PriceOracleData {
                asset_feed_ids: smart_table::new(),
                signer_cap,
                custom_asset_prices: smart_table::new(),
                capped_assets_data: smart_table::new(),
                max_asset_price_age: smart_table::new()
            }
        )
    }

    // Public view functions
    #[view]
    /// @notice Checks if an asset's price is capped (actual price exceeds cap)
    /// @param asset Address of the asset to check
    /// @return True if the asset's actual price exceeds its cap
    public fun is_asset_price_capped(asset: address): bool acquires PriceOracleData {
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        if (!smart_table::contains(&price_oracle_data.capped_assets_data, asset)) {
            return false;
        };

        // now get the cap info and check the type
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        let cap_info = *smart_table::borrow(
            &price_oracle_data.capped_assets_data, asset
        );

        match(cap_info.type) {
            AdapterType::SUSDE => {
                // Get sUSDe/USDe exchange rate (already in 18 decimals) WITHOUT capping —
                // this is the adapter’s internal ratio, not a capped quote.
                let (underlying_asset_price, _) = get_asset_price_internal(asset);

                // Get the mapped base asset (e.g., USDT) price THROUGH the capped path.
                let mapped = *option::borrow(&cap_info.mapped_asset_ratio_multiplier);
                let (asset_base_ratio, _) = get_asset_price_and_timestamp(mapped);

                let (_, is_capped) = get_capped_susde_price(
                    underlying_asset_price, asset_base_ratio, &cap_info
                );
                is_capped
            },
            AdapterType::STABLE => {
                let (underlying_asset_price, _) = get_asset_price_internal(asset);
                let (_, is_capped) = get_capped_stable_price(
                    underlying_asset_price, &cap_info
                );
                is_capped
            }
        }
    }

    #[view]
    /// @notice Returns true if a custom price is set for an asset
    /// @param asset Address of the asset
    public fun is_custom_price_set(asset: address): bool acquires PriceOracleData {
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        if (!smart_table::contains(&price_oracle_data.custom_asset_prices, asset)) {
            return false;
        };
        true
    }

    #[view]
    /// @notice Gets the current price of an asset, respecting any price cap
    /// @param asset Address of the asset
    /// @return The asset price (capped if applicable)
    public fun get_asset_price(asset: address): u256 acquires PriceOracleData {
        let (price, _) = get_asset_price_and_timestamp(asset);
        price
    }

    #[view]
    /// @notice Gets the price cap for an asset if it exists
    /// @param asset Address of the asset
    /// @return The price cap if it exists, none otherwise
    public fun get_stable_price_cap(asset: address): Option<u256> acquires PriceOracleData {
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        let capped_assets_data = &price_oracle_data.capped_assets_data;
        if (!smart_table::contains(capped_assets_data, asset)) {
            return option::none<u256>();
        };
        let cap_info = smart_table::borrow(capped_assets_data, asset);
        return match(cap_info.type) {
            AdapterType::SUSDE => { option::none<u256>() },
            AdapterType::STABLE => { cap_info.stable_price_cap }
        }
    }

    #[view]
    /// @notice Gets the asset max price age for an asset if it exists
    /// @param asset Address of the asset
    /// @return The max price age if it exists, none otherwise
    public fun get_max_asset_price_age(asset: address): Option<u64> acquires PriceOracleData {
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        let max_asset_price_ages = &price_oracle_data.max_asset_price_age;
        if (!smart_table::contains(max_asset_price_ages, asset)) {
            return option::none<u64>();
        };
        let max_asset_price_age = *smart_table::borrow(max_asset_price_ages, asset);
        option::some(max_asset_price_age)
    }

    #[view]
    /// @notice Gets prices for multiple assets at once
    /// @param assets Vector of asset addresses
    /// @return Vector of corresponding asset prices
    public fun get_assets_prices(assets: vector<address>): vector<u256> acquires PriceOracleData {
        let (prices, _) = get_asset_prices_and_timestamps(assets);
        prices
    }

    #[view]
    /// @notice Gets the current price of an asset and its timestamp, respecting any price cap
    /// @param asset Address of the asset
    /// @return The asset price and its timestamp as a tuple (capped if applicable)
    public fun get_asset_price_and_timestamp(asset: address): (u256, u256) acquires PriceOracleData {
        let capped_assets_data =
            &borrow_global<PriceOracleData>(oracle_address()).capped_assets_data;
        if (!smart_table::contains(capped_assets_data, asset)) {
            return get_asset_price_internal(asset);
        };

        // now get the cap info and check the type
        let cap_info = *smart_table::borrow(capped_assets_data, asset);

        match(cap_info.type) {
            AdapterType::SUSDE => {
                // sUSDe/USDe exchange rate (18 decimals), from the adapter’s raw (uncapped) internal path
                let (underlying_asset_price, underlying_asset_timestamp) = get_asset_price_internal(
                    asset
                );

                // Mapped base asset (e.g., USDT) fetched through the capped path
                let mapped = *option::borrow(&cap_info.mapped_asset_ratio_multiplier);
                let (asset_base_ratio, asset_base_timestamp) = get_asset_price_and_timestamp(
                    mapped
                );

                let (underlying_asset_capped_price, _) = get_capped_susde_price(
                    underlying_asset_price, asset_base_ratio, &cap_info
                );
                (
                    underlying_asset_capped_price,
                    math_utils::min(underlying_asset_timestamp, asset_base_timestamp)
                )
            },
            AdapterType::STABLE => {
                let (underlying_asset_price, underlying_asset_timestamp) = get_asset_price_internal(
                    asset
                );
                let (underlying_asset_capped_price, _) = get_capped_stable_price(
                    underlying_asset_price, &cap_info
                );
                (underlying_asset_capped_price, underlying_asset_timestamp)
            }
        }
    }

    #[view]
    /// @notice Gets prices and timestamps for multiple assets at once
    /// @param assets Vector of asset addresses
    /// @return Vectors of corresponding asset prices with their timestamps
    public fun get_asset_prices_and_timestamps(
        assets: vector<address>
    ): (vector<u256>, vector<u256>) acquires PriceOracleData {
        let prices = vector<u256>[];
        let timestamps = vector<u256>[];
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let (price, timestamp) = get_asset_price_and_timestamp(asset);
            vector::insert(&mut prices, i, price);
            vector::insert(&mut timestamps, i, timestamp);
        };
        (prices, timestamps)
    }

    #[view]
    /// @notice Gets the oracle's resource account address
    /// @return The oracle's address
    public fun oracle_address(): address {
        account::create_resource_address(&@aave_oracle, AAVE_ORACLE_SEED)
    }

    #[view]
    /// @notice Gets the decimal precision used for asset prices
    /// @return The number of decimal places (always 18)
    public fun get_asset_price_decimals(): u8 {
        // NOTE: all asset prices have exactly 18 dp.
        CHAINLINK_ASSET_DECIMAL_PRECISION
    }

    // Public entry functions
    /// @notice Sets up a SUSDE price adapter for an asset with ratio growth parameters
    /// @param account Admin account that sets the adapter (must be risk or pool admin)
    /// @param asset Address of the asset to configure
    /// @param minimum_snapshot_delay Minimum delay required between snapshots in seconds
    /// @param snapshot_timestamp Initial timestamp for the snapshot in seconds
    /// @param max_yearly_ratio_growth_percent Maximum yearly ratio growth percentage
    /// @param snapshot_ratio Initial snapshot ratio value
    /// @param mapped_asset_ratio_multiplier Mapped asset ration multiplier
    public entry fun set_susde_price_adapter(
        account: &signer,
        asset: address,
        minimum_snapshot_delay: u256,
        snapshot_timestamp: u256,
        max_yearly_ratio_growth_percent: u256,
        snapshot_ratio: u256,
        mapped_asset_ratio_multiplier: Option<address>
    ) acquires PriceOracleData {
        only_risk_or_pool_admin(account);

        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        let capped_assets_data = &price_oracle_data.capped_assets_data;
        let (
            _snapshot_timestamp,
            _snapshot_ratio,
            _max_yearly_ratio_growth_percent,
            _minimum_snapshot_delay
        ) =
            if (smart_table::contains(capped_assets_data, asset)) {
                let _capped_assets_data = smart_table::borrow(capped_assets_data, asset);
                assert!(
                    _capped_assets_data.type == AdapterType::SUSDE,
                    error_config::get_emismatch_adapter_type()
                );
                (
                    *option::borrow_with_default(
                        &_capped_assets_data.snapshot_timestamp, &0
                    ),
                    *option::borrow_with_default(
                        &_capped_assets_data.snapshot_ratio, &0
                    ),
                    *option::borrow_with_default(
                        &_capped_assets_data.max_yearly_ratio_growth_percent, &0
                    ),
                    *option::borrow_with_default(
                        &_capped_assets_data.minimum_snapshot_delay, &0
                    )
                )
            } else {
                (0, 0, 0, 0)
            };

        if (_snapshot_timestamp > 0) {
            // new snapshot timestamp should be gt then stored one, but not gt then timestamp of the current block
            let is_timestamp_check_violated =
                _snapshot_timestamp >= snapshot_timestamp
                    || snapshot_timestamp
                        > ((timestamp::now_seconds() as u256) - _minimum_snapshot_delay);
            assert!(
                !is_timestamp_check_violated,
                error_config::get_einvalid_ratio_timestamp()
            );
        };
        _snapshot_timestamp = snapshot_timestamp;
        _snapshot_ratio = snapshot_ratio;
        _max_yearly_ratio_growth_percent = max_yearly_ratio_growth_percent;
        _minimum_snapshot_delay = minimum_snapshot_delay;

        // if the ratio on the current growth speed can overflow less then in a MINIMAL_RATIO_INCREASE_LIFETIME years, revert
        let _max_ratio_growth_per_second =
            (snapshot_ratio * max_yearly_ratio_growth_percent)
                / math_utils::get_percentage_factor()
                / math_utils::get_seconds_per_year();

        // Calculate the maximum growth over MINIMAL_RATIO_INCREASE_LIFETIME years safely
        let seconds_in_lifetime =
            math_utils::get_seconds_per_year() * MINIMAL_RATIO_INCREASE_LIFETIME;

        // Check if the multiplication would overflow
        assert!(
            _max_ratio_growth_per_second
                <= math_utils::u256_max() / seconds_in_lifetime,
            error_config::get_esnapshot_overflow()
        );

        // Now we can safely calculate the total growth
        let max_total_growth = _max_ratio_growth_per_second * seconds_in_lifetime;

        // Check if adding to snapshot ratio would overflow
        assert!(
            _snapshot_ratio <= math_utils::u256_max() - max_total_growth,
            error_config::get_esnapshot_overflow()
        );

        // validate adapter parameters
        validate_susde_price_adapter_params(
            _minimum_snapshot_delay,
            _max_yearly_ratio_growth_percent,
            _snapshot_ratio,
            _snapshot_timestamp
        );

        let price_oracle_data = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(
            &mut price_oracle_data.capped_assets_data,
            asset,
            CappedAssetData {
                type: AdapterType::SUSDE,
                stable_price_cap: option::none<u256>(),
                ratio_decimals: option::some(oracle::get_asset_price_decimals()),
                minimum_snapshot_delay: option::some(_minimum_snapshot_delay),
                snapshot_timestamp: option::some(_snapshot_timestamp),
                max_yearly_ratio_growth_percent: option::some(
                    _max_yearly_ratio_growth_percent
                ),
                max_ratio_growth_per_second: option::some(_max_ratio_growth_per_second),
                snapshot_ratio: option::some(_snapshot_ratio),
                mapped_asset_ratio_multiplier
            }
        );
        event::emit(
            CapParametersUpdated {
                snapshot_ratio: _snapshot_ratio,
                snapshot_timestamp: _snapshot_timestamp,
                max_ratio_growth_per_second: _max_ratio_growth_per_second,
                max_yearly_ratio_growth_percent: _max_yearly_ratio_growth_percent
            }
        );
    }

    /// @notice Sets a price cap for an asset
    /// @param account Admin account that sets the cap
    /// @param asset Address of the asset
    /// @param price_cap Maximum price value for the asset
    public entry fun set_price_cap_stable_adapter(
        account: &signer, asset: address, stable_price_cap: u256
    ) acquires PriceOracleData {
        only_risk_or_pool_admin(account);
        let (base_price, _) = get_asset_price_internal(asset);
        assert!(
            stable_price_cap >= base_price,
            error_config::get_ecap_lower_than_actual_price()
        );
        let price_oracle_data = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(
            &mut price_oracle_data.capped_assets_data,
            asset,
            CappedAssetData {
                type: AdapterType::STABLE,
                stable_price_cap: option::some(stable_price_cap),
                ratio_decimals: option::none(),
                minimum_snapshot_delay: option::none(),
                snapshot_timestamp: option::none(),
                max_yearly_ratio_growth_percent: option::none(),
                max_ratio_growth_per_second: option::none(),
                snapshot_ratio: option::none(),
                mapped_asset_ratio_multiplier: option::none()
            }
        );
        event::emit(PriceCapUpdated { asset });
    }

    /// @notice Removes a price cap for an asset
    /// @param account Admin account that removes the cap
    /// @param asset Address of the asset
    public entry fun remove_price_cap_stable_adapter(
        account: &signer, asset: address
    ) acquires PriceOracleData {
        only_risk_or_pool_admin(account);
        let price_oracle_data = borrow_global_mut<PriceOracleData>(oracle_address());
        assert!(
            smart_table::contains(&price_oracle_data.capped_assets_data, asset),
            error_config::get_easset_no_price_cap()
        );
        smart_table::remove(&mut price_oracle_data.capped_assets_data, asset);
        event::emit(PriceCapRemoved { asset });
    }

    /// @notice Sets a Chainlink feed ID for an asset
    /// @param account Admin account that sets the feed
    /// @param asset Address of the asset
    /// @param feed_id Chainlink feed ID for the asset
    public entry fun set_asset_feed_id(
        account: &signer, asset: address, feed_id: vector<u8>
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        assert!(!vector::is_empty(&feed_id), error_config::get_eempty_feed_id());
        update_asset_feed_id(asset, feed_id);
    }

    /// @notice Sets a custom price for an asset
    /// @param account Admin account that sets the price
    /// @param asset Address of the asset
    /// @param custom_price Custom price value
    public entry fun set_asset_custom_price(
        account: &signer, asset: address, custom_price: u256
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        assert!(custom_price > 0, error_config::get_ezero_asset_custom_price());
        if (is_asset_price_capped(asset)) {
            // Inspect the adapter type so we compare apples-to-apples.
            let pod = borrow_global<PriceOracleData>(oracle_address());
            if (smart_table::contains(&pod.capped_assets_data, asset)) {
                let cap_info = *smart_table::borrow(&pod.capped_assets_data, asset);

                match(cap_info.type) {
                    // For STABLE: `custom_price` is a USD-denominated price → compare to USD capped price.
                    AdapterType::STABLE => {
                        let (capped_price, _) = get_asset_price_and_timestamp(asset);
                        assert!(
                            custom_price <= capped_price,
                            error_config::get_ecustom_price_above_price_cap()
                        );
                    },

                    // For SUSDE: `custom_price` is a *ratio* (sUSDe/USDe, 18 dp).
                    // Compare directly to the max allowed ratio (unit-consistent), NOT to the USD price.
                    AdapterType::SUSDE => {
                        let max_ratio = get_max_allowed_susde_ratio(&cap_info);
                        assert!(
                            custom_price <= max_ratio,
                            error_config::get_ecustom_price_above_price_cap()
                        );
                    }
                }
            }
        };
        update_asset_custom_price(asset, custom_price);
    }

    /// @notice Sets the max price age for an asset
    /// @param account Admin account that sets the price
    /// @param asset Address of the asset
    /// @param max_asset_price_age Maximum asset price age
    public entry fun set_max_asset_price_age(
        account: &signer, asset: address, max_asset_price_age: u64
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        assert!(
            max_asset_price_age > 0,
            error_config::get_ezero_oracle_max_asset_price_age()
        );
        update_max_asset_price_age(asset, max_asset_price_age);
    }

    /// @notice Sets Chainlink feed IDs for multiple assets at once
    /// @param account Admin account that sets the feeds
    /// @param assets Vector of asset addresses
    /// @param feed_ids Vector of corresponding feed IDs
    public entry fun batch_set_asset_feed_ids(
        account: &signer, assets: vector<address>, feed_ids: vector<vector<u8>>
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        assert!(
            vector::length(&assets) == vector::length(&feed_ids),
            error_config::get_erequested_feed_ids_assets_mismatch()
        );
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let feed_id = *vector::borrow(&feed_ids, i);
            assert!(!vector::is_empty(&feed_id), error_config::get_eempty_feed_id());
            update_asset_feed_id(asset, feed_id);
        };
    }

    /// @notice Sets custom prices for multiple assets at once
    /// @param account Admin account that sets the prices
    /// @param assets Vector of asset addresses
    /// @param custom_prices Vector of corresponding custom prices
    public entry fun batch_set_asset_custom_prices(
        account: &signer, assets: vector<address>, custom_prices: vector<u256>
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        assert!(
            vector::length(&assets) == vector::length(&custom_prices),
            error_config::get_erequested_custom_prices_assets_mismatch()
        );
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let custom_price = *vector::borrow(&custom_prices, i);
            set_asset_custom_price(account, asset, custom_price);
        };
    }

    /// @notice Removes a Chainlink feed ID for an asset
    /// @param account Admin account that removes the feed
    /// @param asset Address of the asset
    public entry fun remove_asset_feed_id(
        account: &signer, asset: address
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        let feed_id = assert_asset_feed_id_exists(asset);
        remove_feed_id(asset, feed_id);
    }

    /// @notice Removes a custom price for an asset
    /// @param account Admin account that removes the price
    /// @param asset Address of the asset
    public entry fun remove_asset_custom_price(
        account: &signer, asset: address
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        let custom_price = assert_asset_custom_price_exists(asset);
        remove_custom_price(asset, custom_price);
    }

    /// @notice Removes Chainlink feed IDs for multiple assets at once
    /// @param account Admin account that removes the feeds
    /// @param assets Vector of asset addresses
    public entry fun batch_remove_asset_feed_ids(
        account: &signer, assets: vector<address>
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let feed_id = assert_asset_feed_id_exists(asset);
            remove_feed_id(asset, feed_id);
        };
    }

    /// @notice Removes custom prices for multiple assets at once
    /// @param account Admin account that removes the prices
    /// @param assets Vector of asset addresses
    public entry fun batch_remove_asset_custom_prices(
        account: &signer, assets: vector<address>
    ) acquires PriceOracleData {
        only_asset_listing_or_pool_admin(account);
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            let custom_price = assert_asset_custom_price_exists(asset);
            remove_custom_price(asset, custom_price);
        };
    }

    /// Max allowed sUSDe/USDe ratio given the snapshot and growth parameters.
    /// Assumes parameters were validated in `set_susde_price_adapter`.
    /// @param cap Capped asset data
    /// @return The max allowed sUSDe/USDe ratio in 18 decimals
    fun get_max_allowed_susde_ratio(cap: &CappedAssetData): u256 {
        let snapshot_ratio = *option::borrow(&cap.snapshot_ratio);
        let snapshot_ts = *option::borrow(&cap.snapshot_timestamp);
        let growth_per_s = *option::borrow(&cap.max_ratio_growth_per_second);
        let now = timestamp::now_seconds() as u256;

        // Saturating behavior not needed because params are pre-validated against overflow
        snapshot_ratio + growth_per_s * (now - snapshot_ts)
    }

    // Private helper functions
    /// @notice Applies stable price capping logic to a base price
    /// @param base_price The original asset price before capping
    /// @param capped_asset_data The capped asset data configuration containing the price cap
    /// @return A tuple containing the final price (capped if necessary) and a boolean indicating if capping was applied
    fun get_capped_stable_price(
        base_price: u256, capped_asset_data: &CappedAssetData
    ): (u256, bool) {
        let price_cap = *option::borrow(&capped_asset_data.stable_price_cap);
        if (base_price > price_cap) {
            return (price_cap, true);
        };
        return (base_price, false)
    }

    /// @notice Validates susde price adapter parameters
    /// @param minimum_snapshot_delay Minimum delay required between snapshots in seconds
    /// @param max_yearly_ratio_growth_percent Maximum yearly ratio growth percentage
    /// @param snapshot_ratio Initial snapshot ratio value
    /// @param snapshot_timestamp Initial snapshot timestamp value
    fun validate_susde_price_adapter_params(
        minimum_snapshot_delay: u256,
        max_yearly_ratio_growth_percent: u256,
        snapshot_ratio: u256,
        snapshot_timestamp: u256
    ) {
        // snapshot timestamp has to be greater than zero
        assert!(
            snapshot_timestamp > 0,
            error_config::get_einvalid_snapshot_timestamp()
        );
        // max yearly growth should be reasonable (1% to 100%)
        assert!(
            max_yearly_ratio_growth_percent >= 100, // 1% minimum
            error_config::get_einvalid_growth_rate()
        );
        assert!(
            max_yearly_ratio_growth_percent <= 10000, // 100% maximum (2x current 50% config)
            error_config::get_einvalid_growth_rate()
        );

        // Bound check: snapshot delay should be reasonable (1 hour to 90 days)
        assert!(
            minimum_snapshot_delay >= 3600, // 1 hour minimum
            error_config::get_einvalid_snapshot_delay()
        );
        assert!(
            minimum_snapshot_delay <= 90 * 24 * 3600, // 90 days maximum
            error_config::get_einvalid_snapshot_delay()
        );

        // Bound check: snapshot ratio should be reasonable (0.1 to 100.0 in 18 decimals)
        assert!(
            snapshot_ratio >= 1_000_000_000_000_000_000, // 1 minimum (1 * 10^18)
            error_config::get_einvalid_snapshot_ratio()
        );
        assert!(
            snapshot_ratio <= 2_000_000_000_000_000_000, // 2 maximum (2 * 10^18)
            error_config::get_einvalid_snapshot_ratio()
        );
    }

    /// @notice Applies SUSDE price capping logic based on ratio growth constraints
    /// @param base_price The original exchange rate sUSDe/USDe before capping, in 18 decimals
    /// @param asset_base_ratio The base asset price (USDT) in 18 decimals
    /// @param capped_asset_data The capped asset data configuration containing ratio parameters
    /// @return A tuple containing the final price (capped based on ratio growth) and a boolean indicating if capping was applied
    fun get_capped_susde_price(
        base_price: u256, asset_base_ratio: u256, capped_asset_data: &CappedAssetData
    ): (u256, bool) {
        let _ratio_decimals = *option::borrow(&capped_asset_data.ratio_decimals);
        let _snapshot_ratio = *option::borrow(&capped_asset_data.snapshot_ratio);
        let _max_ratio_growth_per_second =
            *option::borrow(&capped_asset_data.max_ratio_growth_per_second);
        let _snapshot_timestamp = *option::borrow(&capped_asset_data.snapshot_timestamp);

        // get the current exchange rate sUSDe/USDe, already in 18 decimals
        let current_ratio = base_price; // sUSDe/USDe exchange rate, already in 18 decimals

        if (base_price <= 0 || current_ratio <= 0 || asset_base_ratio <= 0) {
            return (0, false);
        };

        // calculate the ratio based on snapshot ratio and max growth rate
        let max_ratio =
            _snapshot_ratio
                + _max_ratio_growth_per_second
                    * ((timestamp::now_seconds() as u256) - _snapshot_timestamp);

        let is_capped = false;
        // this means the current exchange rate sUSDe/USDe is greater than the max ratio
        // so we need to cap it
        if (max_ratio < current_ratio) {
            is_capped = true;
            current_ratio = max_ratio;
        };

        // calculate the price of the underlying asset
        assert!(_ratio_decimals > 0, error_config::get_ezero_ratio_decimals());
        (
            // final sUSDe price = exchange_rate(sUSDe/USDe) * price(USDT)
            // sUSDe-USDe exchange rate multiplied by USDT pricing <-- same as mainnet Aave
            // Two feeds that you multiply, CL's message forwarded to us
            (current_ratio * asset_base_ratio)
                / math_utils::pow(10, (_ratio_decimals as u256)), // final price = ratio(sUSDe/USDe)*price(USDT/USD)
            is_capped
        )
    }

    /// @dev Gets the price of an asset from either custom price or Chainlink feed
    /// @dev For sUSDe, the price is the sUSDe/USDe exchange rate, in 18 decimals
    /// @dev So we need to multiply it by the USDT price to get the sUSDe price
    /// @param asset Address of the asset
    /// @return The asset price and the timestamp as a tuple
    fun get_asset_price_internal(asset: address): (u256, u256) acquires PriceOracleData {
        if (check_custom_price_exists(asset)) {
            let custom_price = get_asset_custom_price(asset);
            return (custom_price, (timestamp::now_seconds() as u256));
        };

        if (check_price_feed_exists(asset)) {
            let feed_id = get_feed_id(asset);
            let benchmarks =
                chainlink_router::get_benchmarks(
                    &get_resource_account_signer(),
                    vector[feed_id],
                    vector[]
                );
            assert_benchmarks_match_assets(vector::length(&benchmarks), 1);
            let benchmark = vector::borrow(&benchmarks, 0);
            let price = chainlink::get_benchmark_value(benchmark);
            validate_oracle_price(price);
            let timestamp = chainlink::get_benchmark_timestamp(benchmark);
            validate_oracle_timestamp(asset, timestamp);
            return (price, timestamp);
        };

        assert!(false, error_config::get_easset_not_registered_with_oracle());
        (0, 0)
    }

    /// @dev Validates that the returned oracle price timestamp is not too stale
    /// @param price_timestamp_secs The oracle price timestamp in seconds to validate
    fun validate_oracle_timestamp(
        asset: address, price_timestamp_secs: u256
    ) acquires PriceOracleData {
        let price_oracle_data = borrow_global<PriceOracleData>(oracle_address());
        let current_time_secs = timestamp::now_seconds() as u256;
        // ensure oracle timestamp is not from the future
        assert!(
            price_timestamp_secs <= current_time_secs,
            error_config::get_eoracle_price_timestamp_in_future()
        );

        // now check staleness
        let age = current_time_secs - price_timestamp_secs;
        let max_price_age =
            if (smart_table::contains(&price_oracle_data.max_asset_price_age, asset)) {
                *smart_table::borrow(&price_oracle_data.max_asset_price_age, asset)
            } else {
                DEFAULT_MAX_PRICE_AGE_SECS
            };
        assert!(
            age <= (max_price_age as u256),
            error_config::get_estale_oracle_price()
        );
    }

    /// @dev Validates that the oracle price is positive and within allowed range
    /// @param price The price to validate
    fun validate_oracle_price(price: u256) {
        assert!(
            price <= I192_MAX,
            error_config::get_eoracle_price_overflow()
        );
        assert!(
            price > 0,
            error_config::get_ezero_oracle_price()
        );
    }

    /// @dev Checks that the account is either a pool admin or asset listing admin
    /// @param account The account to check
    fun only_asset_listing_or_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_pool_admin(account_address)
                || acl_manage::is_asset_listing_admin(account_address),
            error_config::get_ecaller_not_pool_or_asset_listing_admin()
        );
    }

    /// @dev Checks that the account is either a pool admin or risk admin
    /// @param account The account to check
    fun only_risk_or_pool_admin(account: &signer) {
        let account_address = signer::address_of(account);
        assert!(
            acl_manage::is_pool_admin(account_address)
                || acl_manage::is_risk_admin(account_address),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
    }

    /// @dev Checks that the account is the oracle admin
    /// @param account The account to check
    fun only_oracle_admin(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_oracle,
            error_config::get_eoracle_not_admin()
        );
    }

    /// @dev Gets the resource account signer
    /// @return The resource account signer
    fun get_resource_account_signer(): signer acquires PriceOracleData {
        let oracle_data = borrow_global<PriceOracleData>(oracle_address());
        account::create_signer_with_capability(&oracle_data.signer_cap)
    }

    /// @dev Updates the feed ID for an asset
    /// @param asset Address of the asset
    /// @param feed_id New feed ID
    fun update_asset_feed_id(asset: address, feed_id: vector<u8>) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(&mut asset_price_list.asset_feed_ids, asset, feed_id);
        emit_asset_price_feed_updated(asset, feed_id);
    }

    /// @dev Updates the custom price for an asset
    /// @param asset Address of the asset
    /// @param custom_price New custom price
    fun update_asset_custom_price(asset: address, custom_price: u256) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(
            &mut asset_price_list.custom_asset_prices, asset, custom_price
        );
        emit_asset_custom_price_updated(asset, custom_price);
    }

    /// @dev Updates max price age for an asset
    /// @param asset Address of the asset
    /// @param max_asset_price_age New max asset price age
    fun update_max_asset_price_age(
        asset: address, max_asset_price_age: u64
    ) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::upsert(
            &mut asset_price_list.max_asset_price_age, asset, max_asset_price_age
        );
        emit_asset_max_price_age_updated(asset, max_asset_price_age);
    }

    /// @dev Checks that a feed ID exists for an asset and returns it
    /// @param asset Address of the asset
    /// @return The feed ID
    fun assert_asset_feed_id_exists(asset: address): vector<u8> acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        assert!(
            smart_table::contains(&asset_price_list.asset_feed_ids, asset),
            error_config::get_eno_asset_feed()
        );
        *smart_table::borrow(&asset_price_list.asset_feed_ids, asset)
    }

    /// @dev Checks that a custom price exists for an asset and returns it
    /// @param asset Address of the asset
    /// @return The custom price
    fun assert_asset_custom_price_exists(asset: address): u256 acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        assert!(
            smart_table::contains(&asset_price_list.custom_asset_prices, asset),
            error_config::get_eno_asset_custom_price()
        );
        *smart_table::borrow(&asset_price_list.custom_asset_prices, asset)
    }

    /// @dev Checks if a feed ID exists for an asset
    /// @param asset Address of the asset
    /// @return True if a feed ID exists
    fun check_price_feed_exists(asset: address): bool acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        if (smart_table::contains(&asset_price_list.asset_feed_ids, asset)) {
            return true;
        };
        false
    }

    /// @dev Checks if a custom price exists for an asset
    /// @param asset Address of the asset
    /// @return True if a custom price exists
    fun check_custom_price_exists(asset: address): bool acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        if (smart_table::contains(&asset_price_list.custom_asset_prices, asset)) {
            return true;
        };
        false
    }

    /// @dev Gets the feed ID for an asset
    /// @param asset Address of the asset
    /// @return The feed ID
    fun get_feed_id(asset: address): vector<u8> acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        *smart_table::borrow(&asset_price_list.asset_feed_ids, asset)
    }

    /// @dev Gets the custom price for an asset
    /// @param asset Address of the asset
    /// @return The custom price
    fun get_asset_custom_price(asset: address): u256 acquires PriceOracleData {
        let asset_price_list = borrow_global<PriceOracleData>(oracle_address());
        *smart_table::borrow(&asset_price_list.custom_asset_prices, asset)
    }

    /// @dev Removes the feed ID for an asset
    /// @param asset Address of the asset
    /// @param feed_id Feed ID to remove
    fun remove_feed_id(asset: address, feed_id: vector<u8>) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::remove(&mut asset_price_list.asset_feed_ids, asset);
        emit_asset_price_feed_removed(asset, feed_id);
    }

    /// @dev Removes the custom price for an asset
    /// @param asset Address of the asset
    /// @param custom_price Custom price to remove
    fun remove_custom_price(asset: address, custom_price: u256) acquires PriceOracleData {
        let asset_price_list = borrow_global_mut<PriceOracleData>(oracle_address());
        smart_table::remove(&mut asset_price_list.custom_asset_prices, asset);
        emit_asset_custom_price_removed(asset, custom_price);
    }

    /// @dev Emits an event when an asset price feed is updated
    /// @param asset Address of the asset
    /// @param feed_id New feed ID
    fun emit_asset_price_feed_updated(
        asset: address, feed_id: vector<u8>
    ) {
        event::emit(AssetPriceFeedUpdated { asset, feed_id })
    }

    /// @dev Emits an event when an asset custom price is updated
    /// @param asset Address of the asset
    /// @param custom_price New custom price
    fun emit_asset_custom_price_updated(
        asset: address, custom_price: u256
    ) {
        event::emit(AssetCustomPriceUpdated { asset, custom_price })
    }

    /// @dev Emits an event when an asset maximum price age is updated
    /// @param asset Address of the asset
    /// @param maximum_price_age Asset maximum price age
    fun emit_asset_max_price_age_updated(
        asset: address, maximum_price_age: u64
    ) {
        event::emit(AssetMaximumPriceAgeUpdated { asset, maximum_price_age })
    }

    /// @dev Emits an event when an asset price feed is removed
    /// @param asset Address of the asset
    /// @param feed_id Removed feed ID
    fun emit_asset_price_feed_removed(
        asset: address, feed_id: vector<u8>
    ) {
        event::emit(AssetPriceFeedRemoved { asset, feed_id })
    }

    /// @dev Emits an event when an asset custom price is removed
    /// @param asset Address of the asset
    /// @param custom_price Removed custom price
    fun emit_asset_custom_price_removed(
        asset: address, custom_price: u256
    ) {
        event::emit(AssetCustomPriceRemoved { asset, custom_price })
    }

    /// @dev Verifies that the number of benchmarks matches the number of requested assets
    /// @param benchmarks_len Number of benchmarks
    /// @param requested_assets Number of requested assets
    fun assert_benchmarks_match_assets(
        benchmarks_len: u64, requested_assets: u64
    ) {
        assert!(
            benchmarks_len == requested_assets,
            error_config::get_eoralce_benchmark_length_mismatch()
        );
    }

    // Test-only functions
    #[test_only]
    /// @dev Sets a mock price for a Chainlink feed
    /// @param account Admin account
    /// @param price Mock price
    /// @param feed_id Feed ID to set the price for
    public entry fun set_chainlink_mock_price(
        account: &signer, price: u256, feed_id: vector<u8>
    ) {
        only_asset_listing_or_pool_admin(account);
        assert!(!vector::is_empty(&feed_id), error_config::get_eempty_feed_id());

        // set the price on chainlink
        let feed_timestamp = timestamp::now_seconds() as u256;
        chainlink::perform_update_for_test(
            feed_id,
            feed_timestamp,
            price,
            vector::empty<u8>()
        );
    }

    #[test_only]
    /// @dev Sets a mock Chainlink feed for an asset
    /// @param account Admin account
    /// @param asset Asset address
    /// @param feed_id Feed ID to set
    public entry fun set_chainlink_mock_feed(
        account: &signer, asset: address, feed_id: vector<u8>
    ) {
        only_asset_listing_or_pool_admin(account);
        assert!(!vector::is_empty(&feed_id), error_config::get_eempty_feed_id());

        // set the asset feed id in the oracle
        let feeds_len = chainlink::get_feeds_len();
        let config_id = vector[(feeds_len + 1) as u8];
        chainlink::set_feed_for_test(
            feed_id,
            format1(&b"feed_{}", asset),
            config_id
        );
    }

    #[test_only]
    /// @dev Initializes the module for testing
    /// @param account Admin account
    public fun test_init_module(account: &signer) {
        init_module(account);
    }

    #[test_only]
    /// @dev Gets the resource account signer for testing
    /// @return The resource account signer
    public fun get_resource_account_signer_for_testing(): signer acquires PriceOracleData {
        get_resource_account_signer()
    }

    #[test_only]
    /// @dev Sets an asset feed ID for testing
    /// @param asset Asset address
    /// @param feed_id Feed ID to set
    public fun test_set_asset_feed_id(
        asset: address, feed_id: vector<u8>
    ) acquires PriceOracleData {
        update_asset_feed_id(asset, feed_id);
    }

    #[test_only]
    /// @dev Sets a custom price for testing
    /// @param asset Asset address
    /// @param custom_price Custom price to set
    public fun test_set_asset_custom_price(
        asset: address, custom_price: u256
    ) acquires PriceOracleData {
        update_asset_custom_price(asset, custom_price);
    }

    #[test_only]
    /// @dev Gets a feed ID for testing
    /// @param asset Asset address
    /// @return The feed ID
    public fun test_get_feed_id(asset: address): vector<u8> acquires PriceOracleData {
        get_feed_id(asset)
    }

    #[test_only]
    /// @dev Gets a custom price for testing
    /// @param asset Asset address
    /// @return The custom price
    public fun test_get_asset_custom_price(asset: address): u256 acquires PriceOracleData {
        get_asset_custom_price(asset)
    }

    #[test_only]
    /// @dev Removes a feed ID for testing
    /// @param asset Asset address
    /// @param feed_id Feed ID to remove
    public fun test_remove_feed_id(asset: address, feed_id: vector<u8>) acquires PriceOracleData {
        remove_feed_id(asset, feed_id)
    }

    #[test_only]
    /// @dev Removes a custom price for testing
    /// @param asset Asset address
    /// @param custom_price Custom price to remove
    public fun test_remove_asset_custom_price(
        asset: address, custom_price: u256
    ) acquires PriceOracleData {
        remove_custom_price(asset, custom_price)
    }

    #[test_only]
    /// @dev Tests the admin role check
    /// @param account Account to check
    public fun test_only_risk_or_pool_admin(account: &signer) {
        only_asset_listing_or_pool_admin(account);
    }

    #[test_only]
    /// @dev Tests asset feed ID existence check
    /// @param asset Asset address
    /// @return The feed ID
    public fun test_assert_asset_feed_id_exists(asset: address): vector<u8> acquires PriceOracleData {
        assert_asset_feed_id_exists(asset)
    }

    #[test_only]
    /// @dev Tests asset custom price existence check
    /// @param asset Asset address
    /// @return The custom price
    public fun test_assert_asset_custom_price_exists(asset: address): u256 acquires PriceOracleData {
        assert_asset_custom_price_exists(asset)
    }

    #[test_only]
    /// @dev Initializes the oracle for testing
    /// @param account Admin account
    public fun test_init_oracle(account: &signer) {
        init_module(account);
    }

    #[test_only]
    /// @dev Tests benchmark matching
    /// @param benchmarks_len Number of benchmarks
    /// @param requested_assets Number of requested assets
    public fun test_assert_benchmarks_match_assets(
        benchmarks_len: u64, requested_assets: u64
    ) {
        assert_benchmarks_match_assets(benchmarks_len, requested_assets)
    }

    #[test_only]
    /// @dev Tests oracle admin check
    /// @param account Account to check
    public fun test_only_oracle_admin(account: &signer) {
        only_oracle_admin(account)
    }

    #[test_only]
    /// @dev Tests asset price feed updated event
    /// @param asset Asset address
    /// @param feed_id Feed ID
    public fun test_emit_asset_price_feed_updated(
        asset: address, feed_id: vector<u8>
    ) {
        emit_asset_price_feed_updated(asset, feed_id);
    }

    #[test_only]
    /// @dev Tests asset price feed removed event
    /// @param asset Asset address
    /// @param feed_id Feed ID
    public fun test_emit_asset_price_feed_removed(
        asset: address, feed_id: vector<u8>
    ) {
        emit_asset_price_feed_removed(asset, feed_id);
    }

    #[test_only]
    /// @dev Returns max price age in seconds for testing
    public fun get_test_max_price_age_secs(): u64 {
        TEST_MAX_PRICE_AGE_SECS
    }
}
