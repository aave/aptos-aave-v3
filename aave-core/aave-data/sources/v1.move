/// @title Aave Data V1
/// @author Aave
/// @notice Module that stores and provides access to Aave protocol configuration data
module aave_data::v1 {
    // imports
    // std
    use std::signer;
    use std::string;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::smart_table;
    use std::option::{Self, Option};
    // locals
    use aave_config::error_config;

    // Global Constants
    /// @notice Prefix for aToken names
    const ATOKEN_NAME_PREFIX: vector<u8> = b"AAVE_A";
    /// @notice Prefix for aToken symbols
    const ATOKEN_SYMBOL_PREFIX: vector<u8> = b"AA";
    /// @notice Prefix for variable debt token names
    const VARTOKEN_NAME_PREFIX: vector<u8> = b"AAVE_V";
    /// @notice Prefix for variable debt token symbols
    const VARTOKEN_SYMBOL_PREFIX: vector<u8> = b"AV";

    // Structs
    /// @notice Main data structure to store all protocol configuration
    struct Data has key {
        /// @dev Price feed addresses for testnet assets
        price_feeds_testnet: smart_table::SmartTable<string::String, vector<u8>>,
        /// @dev Price feed addresses for mainnet assets
        price_feeds_mainnet: smart_table::SmartTable<string::String, vector<u8>>,
        /// @dev Max price age for testnet assets
        asset_max_price_age_testnet: smart_table::SmartTable<string::String, u64>,
        /// @dev Max price age for mainnet assets
        asset_max_price_age_mainnet: smart_table::SmartTable<string::String, u64>,
        /// @dev Underlying asset addresses for testnet
        underlying_assets_testnet: smart_table::SmartTable<string::String, address>,
        /// @dev Underlying asset addresses for mainnet
        underlying_assets_mainnet: smart_table::SmartTable<string::String, address>,
        /// @dev Reserve configurations for testnet
        reserves_config_testnet: smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig>,
        /// @dev Reserve configurations for mainnet
        reserves_config_mainnet: smart_table::SmartTable<string::String, aave_data::v1_values::ReserveConfig>,
        /// @dev Interest rate strategies for testnet
        interest_rate_strategy_testnet: smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy>,
        /// @dev Interest rate strategies for mainnet
        interest_rate_strategy_mainnet: smart_table::SmartTable<string::String, aave_data::v1_values::InterestRateStrategy>,
        /// @dev E-modes configuration for testnet
        emodes_testnet: smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig>,
        /// @dev E-modes configuration for mainnet
        emodes_mainnet: smart_table::SmartTable<u256, aave_data::v1_values::EmodeConfig>,
        /// @dev Oracle configuration for testnet
        oracle_configs_testnet: smart_table::SmartTable<string::String, Option<aave_data::v1_values::CappedAssetData>>,
        /// @dev Oracle configuration for mainnet
        oracle_configs_mainnet: smart_table::SmartTable<string::String, Option<aave_data::v1_values::CappedAssetData>>,

        /// @dev Pool admins addresses for testnet
        pool_admins_testnet: vector<address>,
        /// @dev Asset listing admins addresses for testnet
        asset_listing_admins_testnet: vector<address>,
        /// @dev Risk admins addresses for testnet
        risk_admins_testnet: vector<address>,
        /// @dev Fund admins addresses for testnet
        fund_admins_testnet: vector<address>,
        /// @dev Emergency admins addresses for testnet
        emergency_admins_testnet: vector<address>,
        /// @dev Flash borrower admins addresses for testnet
        flash_borrower_admins_testnet: vector<address>,
        /// @dev Emission admins addresses for testnet
        emission_admins_testnet: vector<address>,
        /// @dev Admin controller ecosystem reserve admins addresses for testnet
        admin_controlled_ecosystem_reserve_funds_admins_testnet: vector<address>,
        /// @dev Rewards controller admins addresses for testnet
        rewards_controller_admins_testnet: vector<address>,

        /// @dev Pool admins addresses for mainnet
        pool_admins_mainnet: vector<address>,
        /// @dev Asset listing admins addresses for mainnet
        asset_listing_admins_mainnet: vector<address>,
        /// @dev Risk admins addresses for mainnet
        risk_admins_mainnet: vector<address>,
        /// @dev Fund admins addresses for mainnet
        fund_admins_mainnet: vector<address>,
        /// @dev Emergency admins addresses for mainnet
        emergency_admins_mainnet: vector<address>,
        /// @dev Flash borrower admins addresses for mainnet
        flash_borrower_admins_mainnet: vector<address>,
        /// @dev Emission admins addresses for mainnet
        emission_admins_mainnet: vector<address>,
        /// @dev Admin controller ecosystem reserve admins addresses for mainnet
        admin_controlled_ecosystem_reserve_funds_admins_mainnet: vector<address>,
        /// @dev Rewards controller admins addresses for mainnet
        rewards_controller_admins_mainnet: vector<address>
    }

    // Private functions
    /// @dev Initializes the module with configuration data
    /// @param account The signer account that initializes the module
    fun init_module(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_data,
            error_config::get_enot_pool_owner()
        );
        move_to(
            account,
            Data {
                price_feeds_testnet: aave_data::v1_values::build_price_feeds_testnet(),
                price_feeds_mainnet: aave_data::v1_values::build_price_feeds_mainnet(),
                asset_max_price_age_testnet: aave_data::v1_values::build_asset_max_price_age_testnet(),
                asset_max_price_age_mainnet: aave_data::v1_values::build_asset_max_price_age_mainnet(),
                underlying_assets_testnet: aave_data::v1_values::build_underlying_assets_testnet(),
                underlying_assets_mainnet: aave_data::v1_values::build_underlying_assets_mainnet(),
                reserves_config_testnet: aave_data::v1_values::build_reserve_config_testnet(),
                reserves_config_mainnet: aave_data::v1_values::build_reserve_config_mainnet(),
                interest_rate_strategy_testnet: aave_data::v1_values::build_interest_rate_strategy_testnet(),
                interest_rate_strategy_mainnet: aave_data::v1_values::build_interest_rate_strategy_mainnet(),
                emodes_testnet: aave_data::v1_values::build_emodes_testnet(),
                emodes_mainnet: aave_data::v1_values::build_emodes_mainnet(),
                pool_admins_testnet: aave_data::v1_values::build_pool_admins_testnet(),
                asset_listing_admins_testnet: aave_data::v1_values::build_asset_listing_admins_testnet(),
                risk_admins_testnet: aave_data::v1_values::build_risk_admins_testnet(),
                fund_admins_testnet: aave_data::v1_values::build_fund_admins_testnet(),
                emergency_admins_testnet: aave_data::v1_values::build_emergency_admins_testnet(),
                flash_borrower_admins_testnet: aave_data::v1_values::build_flash_borrower_admins_testnet(),
                emission_admins_testnet: aave_data::v1_values::build_emission_admins_testnet(),
                admin_controlled_ecosystem_reserve_funds_admins_testnet: aave_data::v1_values::build_admin_controlled_ecosystem_reserve_funds_admins_testnet(),
                rewards_controller_admins_testnet: aave_data::v1_values::build_rewards_controller_admins_testnet(),
                pool_admins_mainnet: aave_data::v1_values::build_pool_admins_mainnet(),
                asset_listing_admins_mainnet: aave_data::v1_values::build_asset_listing_admins_mainnet(),
                risk_admins_mainnet: aave_data::v1_values::build_risk_admins_mainnet(),
                fund_admins_mainnet: aave_data::v1_values::build_fund_admins_mainnet(),
                emergency_admins_mainnet: aave_data::v1_values::build_emergency_admins_mainnet(),
                flash_borrower_admins_mainnet: aave_data::v1_values::build_flash_borrower_admins_mainnet(),
                emission_admins_mainnet: aave_data::v1_values::build_emission_admins_mainnet(),
                admin_controlled_ecosystem_reserve_funds_admins_mainnet: aave_data::v1_values::build_admin_controlled_ecosystem_reserve_funds_admins_mainnet(),
                rewards_controller_admins_mainnet: aave_data::v1_values::build_rewards_controller_admins_mainnet(),
                oracle_configs_testnet: aave_data::v1_values::build_oracle_configs_testnet(),
                oracle_configs_mainnet: aave_data::v1_values::build_oracle_configs_mainnet()
            }
        );
    }

    // Public functions - Token naming
    /// @notice Constructs an aToken name from the underlying asset symbol
    /// @param underlying_asset_symbol The symbol of the underlying asset
    /// @return The aToken name
    public inline fun get_atoken_name(underlying_asset_symbol: String): String {
        let name = utf8(ATOKEN_NAME_PREFIX);
        string::append(&mut name, utf8(b"_"));
        string::append(&mut name, underlying_asset_symbol);
        name
    }

    /// @notice Constructs an aToken symbol from the underlying asset symbol
    /// @param underlying_asset_symbol The symbol of the underlying asset
    /// @return The aToken symbol
    public inline fun get_atoken_symbol(underlying_asset_symbol: String): String {
        let symbol = utf8(ATOKEN_SYMBOL_PREFIX);
        string::append(&mut symbol, utf8(b"_"));
        string::append(&mut symbol, underlying_asset_symbol);
        symbol
    }

    /// @notice Constructs a variable debt token name from the underlying asset symbol
    /// @param underlying_asset_symbol The symbol of the underlying asset
    /// @return The variable debt token name
    public inline fun get_vartoken_name(underlying_asset_symbol: String): String {
        let name = utf8(VARTOKEN_NAME_PREFIX);
        string::append(&mut name, utf8(b"_"));
        string::append(&mut name, underlying_asset_symbol);
        name
    }

    /// @notice Constructs a variable debt token symbol from the underlying asset symbol
    /// @param underlying_asset_symbol The symbol of the underlying asset
    /// @return The variable debt token symbol
    public inline fun get_vartoken_symbol(underlying_asset_symbol: String): String {
        let symbol = utf8(VARTOKEN_SYMBOL_PREFIX);
        string::append(&mut symbol, utf8(b"_"));
        string::append(&mut symbol, underlying_asset_symbol);
        symbol
    }

    /// @notice Gets the price feeds for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, price feed addresses)
    public fun get_price_feeds_testnet_normalized(): (vector<String>, vector<vector<u8>>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).price_feeds_testnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<vector<u8>>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    /// @notice Gets the price feed for a specific asset on testnet
    public fun get_price_feeds_testnet_for_asset(asset: String): Option<vector<u8>> acquires Data {
        let table = &borrow_global<Data>(@aave_data).price_feeds_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the price feeds for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, price feed addresses)
    public fun get_price_feeds_mainnet_normalized(): (vector<String>, vector<vector<u8>>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).price_feeds_mainnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<vector<u8>>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_price_feeds_mainnet_for_asset(asset: String): Option<vector<u8>> acquires Data {
        let table = &borrow_global<Data>(@aave_data).price_feeds_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the underlying assets for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, underlying asset addresses)
    public fun get_underlying_assets_testnet_normalized()
        : (vector<String>, vector<address>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).underlying_assets_testnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<address>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_underlying_for_asset_testnet(asset: String): Option<address> acquires Data {
        let table = &borrow_global<Data>(@aave_data).underlying_assets_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the underlying assets for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, underlying asset addresses)
    public fun get_underlying_assets_mainnet_normalized()
        : (vector<String>, vector<address>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).underlying_assets_mainnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<address>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_underlying_for_asset_mainnet(asset: String): Option<address> acquires Data {
        let table = &borrow_global<Data>(@aave_data).underlying_assets_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the reserve configurations for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, reserve configurations)
    public fun get_reserves_config_testnet_normalized()
        : (vector<String>, vector<aave_data::v1_values::ReserveConfig>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).reserves_config_testnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<aave_data::v1_values::ReserveConfig>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_reserves_config_for_asset_testnet(
        asset: String
    ): Option<aave_data::v1_values::ReserveConfig> acquires Data {
        let table = &borrow_global<Data>(@aave_data).reserves_config_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the reserve configurations for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, reserve configurations)
    public fun get_reserves_config_mainnet_normalized()
        : (vector<String>, vector<aave_data::v1_values::ReserveConfig>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).reserves_config_mainnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<aave_data::v1_values::ReserveConfig>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_reserves_config_for_asset_mainnet(
        asset: String
    ): Option<aave_data::v1_values::ReserveConfig> acquires Data {
        let table = &borrow_global<Data>(@aave_data).reserves_config_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the interest rate strategies for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, interest rate strategies)
    public fun get_interest_rate_strategy_testnet_normalized()
        : (vector<String>, vector<aave_data::v1_values::InterestRateStrategy>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).interest_rate_strategy_testnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<aave_data::v1_values::InterestRateStrategy>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_interest_rate_strategy_for_asset_testnet(
        asset: String
    ): Option<aave_data::v1_values::InterestRateStrategy> acquires Data {
        let table = &borrow_global<Data>(@aave_data).interest_rate_strategy_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the interest rate strategies for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, interest rate strategies)
    public fun get_interest_rate_strategy_mainnet_normalized()
        : (vector<String>, vector<aave_data::v1_values::InterestRateStrategy>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).interest_rate_strategy_mainnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<aave_data::v1_values::InterestRateStrategy>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_interest_rate_strategy_for_asset_mainnet(
        asset: String
    ): Option<aave_data::v1_values::InterestRateStrategy> acquires Data {
        let table = &borrow_global<Data>(@aave_data).interest_rate_strategy_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the E-modes for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (E-mode IDs, E-mode configurations)
    public fun get_emodes_mainnet_normalized()
        : (vector<u256>, vector<aave_data::v1_values::EmodeConfig>) acquires Data {
        let emodes = &borrow_global<Data>(@aave_data).emodes_mainnet;
        let keys = smart_table::keys(emodes);
        let configs = vector::empty<aave_data::v1_values::EmodeConfig>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let config = *smart_table::borrow(emodes, key);
            vector::push_back(&mut configs, config);
            i += 1;
        };
        (keys, configs)
    }

    public fun get_emodes_for_asset_mainnet(
        emode: u256
    ): Option<aave_data::v1_values::EmodeConfig> acquires Data {
        let table = &borrow_global<Data>(@aave_data).emodes_mainnet;
        if (!smart_table::contains(table, emode)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, emode))
    }

    /// @notice Gets the E-modes for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (E-mode IDs, E-mode configurations)
    public fun get_emode_testnet_normalized()
        : (vector<u256>, vector<aave_data::v1_values::EmodeConfig>) acquires Data {
        let emodes = &borrow_global<Data>(@aave_data).emodes_testnet;
        let keys = smart_table::keys(emodes);
        let configs = vector::empty<aave_data::v1_values::EmodeConfig>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let config = *smart_table::borrow(emodes, key);
            vector::push_back(&mut configs, config);
            i += 1;
        };
        (keys, configs)
    }

    public fun get_emodes_for_asset_testnet(
        emode: u256
    ): Option<aave_data::v1_values::EmodeConfig> acquires Data {
        let table = &borrow_global<Data>(@aave_data).emodes_testnet;
        if (!smart_table::contains(table, emode)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, emode))
    }

    /// @notice Gets the asset max price ages for testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset name, max_price_age)
    public fun get_asset_max_price_ages_testnet_normalized(): (vector<String>, vector<u64>) acquires Data {
        let asset_max_price_age =
            &borrow_global<Data>(@aave_data).asset_max_price_age_testnet;
        let keys = smart_table::keys(asset_max_price_age);
        let asset_max_price_ages = vector::empty<u64>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let config = *smart_table::borrow(asset_max_price_age, key);
            vector::push_back(&mut asset_max_price_ages, config);
            i += 1;
        };
        (keys, asset_max_price_ages)
    }

    public fun get_asset_max_price_ages_for_asset_testnet(asset: String): Option<u64> acquires Data {
        let table = &borrow_global<Data>(@aave_data).asset_max_price_age_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the asset max price ages for mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset name, max_price_age)
    public fun get_asset_max_price_ages_mainnet_normalized(): (vector<String>, vector<u64>) acquires Data {
        let asset_max_price_age =
            &borrow_global<Data>(@aave_data).asset_max_price_age_mainnet;
        let keys = smart_table::keys(asset_max_price_age);
        let asset_max_price_ages = vector::empty<u64>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let config = *smart_table::borrow(asset_max_price_age, key);
            vector::push_back(&mut asset_max_price_ages, config);
            i += 1;
        };
        (keys, asset_max_price_ages)
    }

    public fun get_asset_max_price_ages_for_asset_mainnet(asset: String): Option<u64> acquires Data {
        let table = &borrow_global<Data>(@aave_data).asset_max_price_age_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        option::some(*smart_table::borrow(table, asset))
    }

    /// @notice Gets the oracle configs for the assets on testnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, asset oracle configs)
    public fun get_oracle_configs_testnet_normalized()
        : (vector<String>, vector<Option<aave_data::v1_values::CappedAssetData>>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).oracle_configs_testnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<Option<aave_data::v1_values::CappedAssetData>>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_oracle_configs_for_asset_testnet(
        asset: String
    ): Option<aave_data::v1_values::CappedAssetData> acquires Data {
        let table = &borrow_global<Data>(@aave_data).oracle_configs_testnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        *smart_table::borrow(table, asset)
    }

    /// @notice Gets the oracle configs for the assets on mainnet in normalized format (keys and values as separate vectors)
    /// @return Tuple of (asset symbols, asset oracle configs)
    public fun get_oracle_configs_mainnet_normalized()
        : (vector<String>, vector<Option<aave_data::v1_values::CappedAssetData>>) acquires Data {
        let table = &borrow_global<Data>(@aave_data).oracle_configs_mainnet;
        let keys = smart_table::keys(table);
        let views = vector::empty<Option<aave_data::v1_values::CappedAssetData>>();

        let i = 0;
        while (i < vector::length(&keys)) {
            let key = *vector::borrow(&keys, i);
            let val = *smart_table::borrow(table, key);
            vector::push_back(&mut views, val);
            i += 1;
        };
        (keys, views)
    }

    public fun get_oracle_configs_for_asset_mainnet(
        asset: String
    ): Option<aave_data::v1_values::CappedAssetData> acquires Data {
        let table = &borrow_global<Data>(@aave_data).oracle_configs_mainnet;
        if (!smart_table::contains(table, asset)) {
            return option::none();
        };
        *smart_table::borrow(table, asset)
    }

    /// @notice Gets all acl accounts for testnet
    /// @return Tuple of addresses vectors
    public fun get_acl_accounts_testnet()
        : (
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>
    ) acquires Data {
        let global_data = borrow_global<Data>(@aave_data);
        (
            global_data.pool_admins_testnet,
            global_data.asset_listing_admins_testnet,
            global_data.risk_admins_testnet,
            global_data.fund_admins_testnet,
            global_data.emergency_admins_testnet,
            global_data.flash_borrower_admins_testnet,
            global_data.emission_admins_testnet,
            global_data.admin_controlled_ecosystem_reserve_funds_admins_testnet,
            global_data.rewards_controller_admins_testnet
        )
    }

    /// @notice Gets all acl accounts for mainnet
    /// @return Tuple of addresses vectors
    public fun get_acl_accounts_mainnet()
        : (
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>,
        vector<address>
    ) acquires Data {
        let global_data = borrow_global<Data>(@aave_data);
        (
            global_data.pool_admins_mainnet,
            global_data.asset_listing_admins_mainnet,
            global_data.risk_admins_mainnet,
            global_data.fund_admins_mainnet,
            global_data.emergency_admins_mainnet,
            global_data.flash_borrower_admins_mainnet,
            global_data.emission_admins_mainnet,
            global_data.admin_controlled_ecosystem_reserve_funds_admins_mainnet,
            global_data.rewards_controller_admins_mainnet
        )
    }
}
