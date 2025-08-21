/// @title Aave Data V1 Values
/// @author Aave
/// @notice Module that defines data structures and values for Aave protocol configuration
module aave_data::v1_values {
    // imports
    // std
    use std::option;
    use std::option::Option;
    use std::string;
    use std::string::{String, utf8};
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::aptos_coin;
    use aptos_framework::timestamp;
    use aave_math::math_utils::Self;
    use aave_oracle::oracle;
    // locals
    use aave_pool::coin_migrator;

    // Global Constants
    /// @notice Asset symbol for APT
    const APT_ASSET: vector<u8> = b"APT";
    /// @notice Asset symbol for USDC
    const USDC_ASSET: vector<u8> = b"USDC";
    /// @notice Asset symbol for USDT
    const USDT_ASSET: vector<u8> = b"USDT";
    /// @notice Asset symbol for sUSDe
    const SUSDE_ASSET: vector<u8> = b"sUSDe";

    // Structs
    /// @notice Configuration parameters for a reserve
    struct ReserveConfig has store, copy, drop {
        /// @dev Maximum loan-to-value ratio
        base_ltv_as_collateral: u256,
        /// @dev Liquidation threshold
        liquidation_threshold: u256,
        /// @dev Liquidation bonus
        liquidation_bonus: u256,
        /// @dev Protocol fee on liquidations
        liquidation_protocol_fee: u256,
        /// @dev Whether borrowing is enabled
        borrowing_enabled: bool,
        /// @dev Whether flash loans are enabled
        flashLoan_enabled: bool,
        /// @dev Reserve factor
        reserve_factor: u256,
        /// @dev Supply cap
        supply_cap: u256,
        /// @dev Borrow cap
        borrow_cap: u256,
        /// @dev Debt ceiling for isolation mode
        debt_ceiling: u256,
        /// @dev Whether the asset is borrowable in isolation mode
        borrowable_isolation: bool,
        /// @dev Whether the asset has siloed borrowing
        siloed_borrowing: bool,
        /// @dev E-Mode category id (if any)
        emode_category: Option<u256>
    }

    /// @notice Interest rate strategy parameters
    struct InterestRateStrategy has store, copy, drop {
        /// @dev Optimal usage ratio
        optimal_usage_ratio: u256,
        /// @dev Base variable borrow rate
        base_variable_borrow_rate: u256,
        /// @dev Variable rate slope 1
        variable_rate_slope1: u256,
        /// @dev Variable rate slope 2
        variable_rate_slope2: u256
    }

    /// @notice E-Mode category configuration
    struct EmodeConfig has store, copy, drop {
        /// @dev Category identifier
        category_id: u256,
        /// @dev Loan-to-value ratio
        ltv: u256,
        /// @dev Liquidation threshold
        liquidation_threshold: u256,
        /// @dev Liquidation bonus
        liquidation_bonus: u256,
        /// @dev Human-readable label
        label: String
    }

    /// @notice The type of adapter for retrieving the price
    enum AdapterType has copy, drop, store {
        STABLE,
        SUSDE
    }

    /// @notice Main storage for multiple capped asset data
    struct CappedAssetData has copy, store, key, drop {
        /// @dev adapter type
        type: AdapterType,
        /// @dev stable price cap if stable adapter defined
        stable_price_cap: Option<u256>,
        /// @dev decimals ratio if defined
        ratio_decimals: Option<u8>,
        /// @dev minimum snapshot delay if defined
        minimum_snapshot_delay: Option<u256>,
        /// @dev snapshot timestamp if defined
        snapshot_timestamp: Option<u256>,
        /// @dev snapshot timestamp if defined
        max_yearly_ratio_growth_percent: Option<u256>,
        /// @dev max ratio growth per second if defined
        max_ratio_growth_per_second: Option<u256>,
        /// @dev snapshot ratio if defined
        snapshot_ratio: Option<u256>,
        /// @dev mapped asset ratio multiplier
        mapped_asset_ratio_multiplier: Option<address>
    }

    // Public functions - EmodeConfig getters
    /// @notice Get the E-Mode category ID
    /// @param emode_config The E-Mode configuration
    /// @return The category ID
    public fun get_emode_category_id(emode_config: &EmodeConfig): u256 {
        emode_config.category_id
    }

    /// @notice Get the E-Mode loan-to-value ratio
    /// @param emode_config The E-Mode configuration
    /// @return The loan-to-value ratio
    public fun get_emode_ltv(emode_config: &EmodeConfig): u256 {
        emode_config.ltv
    }

    /// @notice Get the E-Mode liquidation threshold
    /// @param emode_config The E-Mode configuration
    /// @return The liquidation threshold
    public fun get_emode_liquidation_threshold(
        emode_config: &EmodeConfig
    ): u256 {
        emode_config.liquidation_threshold
    }

    /// @notice Get the E-Mode liquidation bonus
    /// @param emode_config The E-Mode configuration
    /// @return The liquidation bonus
    public fun get_emode_liquidation_bonus(emode_config: &EmodeConfig): u256 {
        emode_config.liquidation_bonus
    }

    /// @notice Get the E-Mode label
    /// @param emode_config The E-Mode configuration
    /// @return The label
    public fun get_emode_liquidation_label(emode_config: &EmodeConfig): String {
        emode_config.label
    }

    // Public functions - InterestRateStrategy getters
    /// @notice Get the optimal usage ratio
    /// @param ir_strategy The interest rate strategy
    /// @return The optimal usage ratio
    public fun get_optimal_usage_ratio(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.optimal_usage_ratio
    }

    /// @notice Get the base variable borrow rate
    /// @param ir_strategy The interest rate strategy
    /// @return The base variable borrow rate
    public fun get_base_variable_borrow_rate(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.base_variable_borrow_rate
    }

    /// @notice Get the variable rate slope 1
    /// @param ir_strategy The interest rate strategy
    /// @return The variable rate slope 1
    public fun get_variable_rate_slope1(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.variable_rate_slope1
    }

    /// @notice Get the variable rate slope 2
    /// @param ir_strategy The interest rate strategy
    /// @return The variable rate slope 2
    public fun get_variable_rate_slope2(
        ir_strategy: &InterestRateStrategy
    ): u256 {
        ir_strategy.variable_rate_slope2
    }

    // Public functions - ReserveConfig getters
    /// @notice Get the base loan-to-value ratio
    /// @param reserve_config The reserve configuration
    /// @return The base loan-to-value ratio
    public fun get_base_ltv_as_collateral(reserve_config: &ReserveConfig): u256 {
        reserve_config.base_ltv_as_collateral
    }

    /// @notice Get the liquidation threshold
    /// @param reserve_config The reserve configuration
    /// @return The liquidation threshold
    public fun get_liquidation_threshold(reserve_config: &ReserveConfig): u256 {
        reserve_config.liquidation_threshold
    }

    /// @notice Get the liquidation bonus
    /// @param reserve_config The reserve configuration
    /// @return The liquidation bonus
    public fun get_liquidation_bonus(reserve_config: &ReserveConfig): u256 {
        reserve_config.liquidation_bonus
    }

    /// @notice Get the liquidation protocol fee
    /// @param reserve_config The reserve configuration
    /// @return The liquidation protocol fee
    public fun get_liquidation_protocol_fee(
        reserve_config: &ReserveConfig
    ): u256 {
        reserve_config.liquidation_protocol_fee
    }

    /// @notice Check if borrowing is enabled
    /// @param reserve_config The reserve configuration
    /// @return True if borrowing is enabled, false otherwise
    public fun get_borrowing_enabled(reserve_config: &ReserveConfig): bool {
        reserve_config.borrowing_enabled
    }

    /// @notice Check if flash loans are enabled
    /// @param reserve_config The reserve configuration
    /// @return True if flash loans are enabled, false otherwise
    public fun get_flashLoan_enabled(reserve_config: &ReserveConfig): bool {
        reserve_config.flashLoan_enabled
    }

    /// @notice Get the reserve factor
    /// @param reserve_config The reserve configuration
    /// @return The reserve factor
    public fun get_reserve_factor(reserve_config: &ReserveConfig): u256 {
        reserve_config.reserve_factor
    }

    /// @notice Get the supply cap
    /// @param reserve_config The reserve configuration
    /// @return The supply cap
    public fun get_supply_cap(reserve_config: &ReserveConfig): u256 {
        reserve_config.supply_cap
    }

    /// @notice Get the borrow cap
    /// @param reserve_config The reserve configuration
    /// @return The borrow cap
    public fun get_borrow_cap(reserve_config: &ReserveConfig): u256 {
        reserve_config.borrow_cap
    }

    /// @notice Get the debt ceiling
    /// @param reserve_config The reserve configuration
    /// @return The debt ceiling
    public fun get_debt_ceiling(reserve_config: &ReserveConfig): u256 {
        reserve_config.debt_ceiling
    }

    /// @notice Check if the asset is borrowable in isolation mode
    /// @param reserve_config The reserve configuration
    /// @return True if borrowable in isolation mode, false otherwise
    public fun get_borrowable_isolation(reserve_config: &ReserveConfig): bool {
        reserve_config.borrowable_isolation
    }

    /// @notice Check if the asset has siloed borrowing
    /// @param reserve_config The reserve configuration
    /// @return True if siloed borrowing is enabled, false otherwise
    public fun get_siloed_borrowing(reserve_config: &ReserveConfig): bool {
        reserve_config.siloed_borrowing
    }

    /// @notice Get the E-Mode category
    /// @param reserve_config The reserve configuration
    /// @return The E-Mode category if set, none otherwise
    public fun get_emode_category(reserve_config: &ReserveConfig): Option<u256> {
        reserve_config.emode_category
    }

    /// @notice Checks if the adapter type is STABLE
    /// @param capped_asset_data The capped asset data configuration
    /// @return True if the adapter type is STABLE, false otherwise
    public fun is_stable_adapter(capped_asset_data: &CappedAssetData): bool {
        match(capped_asset_data.type) {
            AdapterType::STABLE => true,
            AdapterType::SUSDE => false
        }
    }

    /// @notice Checks if the adapter type is SUSDE
    /// @param capped_asset_data The capped asset data configuration
    /// @return True if the adapter type is SUSDE, false otherwise
    public fun is_susde_adapter(capped_asset_data: &CappedAssetData): bool {
        match(capped_asset_data.type) {
            AdapterType::STABLE => false,
            AdapterType::SUSDE => true
        }
    }

    /// @notice Get the stable price cap for the asset
    /// @param capped_asset_data The capped asset data configuration
    /// @return The stable price cap if set, none otherwise
    public fun get_stable_price_cap(capped_asset_data: &CappedAssetData): Option<u256> {
        capped_asset_data.stable_price_cap
    }

    /// @notice Get the maximum ratio growth per second
    /// @param capped_asset_data The capped asset data configuration
    /// @return The maximum ratio growth per second if set, none otherwise
    public fun get_max_ratio_growth_per_second(
        capped_asset_data: &CappedAssetData
    ): Option<u256> {
        capped_asset_data.max_ratio_growth_per_second
    }

    /// @notice Get the snapshot timestamp
    /// @param capped_asset_data The capped asset data configuration
    /// @return The snapshot timestamp if set, none otherwise
    public fun get_snapshot_timestamp(
        capped_asset_data: &CappedAssetData
    ): Option<u256> {
        capped_asset_data.snapshot_timestamp
    }

    /// @notice Get the maximum yearly ratio growth percentage
    /// @param capped_asset_data The capped asset data configuration
    /// @return The maximum yearly ratio growth percentage if set, none otherwise
    public fun get_max_yearly_ratio_growth_percent(
        capped_asset_data: &CappedAssetData
    ): Option<u256> {
        capped_asset_data.max_yearly_ratio_growth_percent
    }

    /// @notice Get the snapshot ratio
    /// @param capped_asset_data The capped asset data configuration
    /// @return The snapshot ratio if set, none otherwise
    public fun get_snapshot_ratio(capped_asset_data: &CappedAssetData): Option<u256> {
        capped_asset_data.snapshot_ratio
    }

    /// @notice Get the minimum snapshot delay
    /// @param capped_asset_data The capped asset data configuration
    /// @return The minimum snapshot delay if set, none otherwise
    public fun get_minimum_snapshot_delay(
        capped_asset_data: &CappedAssetData
    ): Option<u256> {
        capped_asset_data.minimum_snapshot_delay
    }

    /// @notice Get the ratio decimals
    /// @param capped_asset_data The capped asset data configuration
    /// @return The ratio decimals if set, none otherwise
    public fun get_ratio_decimals(capped_asset_data: &CappedAssetData): Option<u8> {
        capped_asset_data.ratio_decimals
    }

    /// @notice Get the mapped asset ratio multiplier
    /// @param capped_asset_data The capped asset data configuration
    /// @return The mapped asset ratio multiplier, none otherwise
    public fun get_mapped_asset_ratio_multiplier(
        capped_asset_data: &CappedAssetData
    ): Option<address> {
        capped_asset_data.mapped_asset_ratio_multiplier
    }

    // Public functions - Data builders
    /// @notice Build E-Mode configurations for testnet
    /// @return SmartTable of E-Mode configurations for testnet
    public fun build_emodes_testnet(): SmartTable<u256, EmodeConfig> {
        let emodes = smart_table::new<u256, EmodeConfig>();
        smart_table::add(
            &mut emodes,
            1,
            EmodeConfig {
                category_id: 1,
                ltv: (90 * math_utils::get_percentage_factor()) / 100,
                liquidation_threshold: (92 * math_utils::get_percentage_factor()) / 100,
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (4 * math_utils::get_percentage_factor()) / 100,
                label: string::utf8(b"sUSDe/Stablecoin")
            }
        );
        emodes
    }

    /// @notice Build E-Mode configurations for mainnet
    /// @return SmartTable of E-Mode configurations for mainnet
    public fun build_emodes_mainnet(): SmartTable<u256, EmodeConfig> {
        let emodes = smart_table::new<u256, EmodeConfig>();
        smart_table::add(
            &mut emodes,
            1,
            EmodeConfig {
                category_id: 1,
                ltv: (90 * math_utils::get_percentage_factor()) / 100,
                liquidation_threshold: (92 * math_utils::get_percentage_factor()) / 100,
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (4 * math_utils::get_percentage_factor()) / 100,
                label: string::utf8(b"sUSDe/Stablecoin")
            }
        );
        emodes
    }

    /// @notice Build pool admins for testnet
    /// @return Vector of pool admin addresses for testnet
    public fun build_pool_admins_testnet(): vector<address> {
        vector[
            @0x859d111e05bd4deed6fc1a94cec995e12ac2ad7bbe7cec425ef6aaebfaf5238c
        ]
    }

    /// @notice Build asset listing admins for testnet
    /// @return Vector of asset listing addresses for testnet
    public fun build_asset_listing_admins_testnet(): vector<address> {
        vector[
            @0xe2b13e2d2804ecf30d4c76e9b05b07105a6cf9f59c26885379fb72e8a5e8655a
        ]
    }

    /// @notice Build risk admins for testnet
    /// @return Vector of risk admin addresses for testnet
    public fun build_risk_admins_testnet(): vector<address> {
        vector[
            @0xae4b8e0abd04f47185bb3bfe759cd989a382b23af3b210a65a702798589a2dc1
        ]
    }

    /// @notice Build fund admins for testnet
    /// @return Vector of fund admin addresses for testnet
    public fun build_fund_admins_testnet(): vector<address> {
        vector[
            @0xf417afab0311d4af56757c1927456e0a85fe79180d45f75441c5d61ac493cbd7
        ]
    }

    /// @notice Build emergency admins for testnet
    /// @return Vector of emergency admin addresses for testnet
    public fun build_emergency_admins_testnet(): vector<address> {
        vector[
            @0xefe507f987ed9a478515a4886138a28749638f227aed74afa19d45ac7f4485a8
        ]
    }

    /// @notice Build flash borrower admins for testnet
    /// @return Vector of flash borrower admin addresses for testnet
    public fun build_flash_borrower_admins_testnet(): vector<address> {
        vector[
            @0x1df092149bd414a6b6130460d010b3bec7fd303677f5f0ddaa14dcf405a2b389
        ]
    }

    /// @notice Build emission admins for testnet
    /// @return Vector of emission admin addresses for testnet
    public fun build_emission_admins_testnet(): vector<address> {
        vector[
            @0x50dd0012a77fc9884b4bc460ec5c8249992e9a3d3e422b89883b4a982bfdcec9
        ]
    }

    /// @notice Build admin controlled ecosystem reserve admins for testnet
    /// @return Vector of admin controlled ecosystem reserve admin addresses for testnet
    public fun build_admin_controlled_ecosystem_reserve_funds_admins_testnet():
        vector<address> {
        vector[
            @0x056d32138643b7d247be191d6e27f0d1f5352b4049a1129e2fc69eba66296361
        ]
    }

    /// @notice Build rewards controller admins for testnet
    /// @return Vector of rewards controller admin addresses for testnet
    public fun build_rewards_controller_admins_testnet(): vector<address> {
        vector[
            @0x00af70319d7b1adea014e941d07bf9276c969abd76d0f0134616025bed4061fe
        ]
    }

    // --------------

    /// @notice Build pool admins for mainnet
    /// @return Vector of pool admin addresses for mainnet
    public fun build_pool_admins_mainnet(): vector<address> {
        vector[
            @0x6b8d9c9f788bc100c2688ae5bddd849d5bd7308cb493f245b12e56a2d8c3ebec
        ]
    }

    /// @notice Build asset listing admins for mainnet
    /// @return Vector of asset listing addresses for mainnet
    public fun build_asset_listing_admins_mainnet(): vector<address> {
        vector[
            @0xf759723ee0df506efdb74b5b17ddfd4a825456d2b6dec58703ce17da18cc6f1f
        ]
    }

    /// @notice Build risk admins for mainnet
    /// @return Vector of risk admin addresses for mainnet
    public fun build_risk_admins_mainnet(): vector<address> {
        vector[
            @0x37843f5025265c4023364d3eb88ca3acdc6cb6e989908381197ad8e331be6922
        ]
    }

    /// @notice Build fund admins for mainnet
    /// @return Vector of fund admin addresses for mainnet
    public fun build_fund_admins_mainnet(): vector<address> {
        vector[
            @0xeb0fb04fc3b2ab1a46811482bce030a2e698b4bc38892292a8ed1945755cd6f5
        ]
    }

    /// @notice Build emergency admins for mainnet
    /// @return Vector of emergency admin addresses for mainnet
    public fun build_emergency_admins_mainnet(): vector<address> {
        vector[
            @0xee407d2dcba8127984d67b974d7ec3eaa88ca7f945796f1bfbb8aa331054b732
        ]
    }

    /// @notice Build flash borrower admins for mainnet
    /// @return Vector of flash borrower admin addresses for mainnet
    public fun build_flash_borrower_admins_mainnet(): vector<address> {
        vector[
            @0xe2b13e2d2804ecf30d4c76e9b05b07105a6cf9f59c26885379fb72e8a5e8655a
        ]
    }

    /// @notice Build emission admins for mainnet
    /// @return Vector of emission admin addresses for mainnet
    public fun build_emission_admins_mainnet(): vector<address> {
        vector[
            @0x859d111e05bd4deed6fc1a94cec995e12ac2ad7bbe7cec425ef6aaebfaf5238c
        ]
    }

    /// @notice Build admin controlled ecosystem reserve admins for mainnet
    /// @return Vector of admin controlled ecosystem reserve admin addresses for mainnet
    public fun build_admin_controlled_ecosystem_reserve_funds_admins_mainnet():
        vector<address> {
        vector[
            @0xefe507f987ed9a478515a4886138a28749638f227aed74afa19d45ac7f4485a8
        ]
    }

    /// @notice Build rewards controller admins for mainnet
    /// @return Vector of rewards controller admin addresses for mainnet
    public fun build_rewards_controller_admins_mainnet(): vector<address> {
        vector[
            @0xae4b8e0abd04f47185bb3bfe759cd989a382b23af3b210a65a702798589a2dc1
        ]
    }

    /// @notice Build oracle configuration for testnet
    /// @return SmartTable mapping asset symbols to oracle configurations
    public fun build_oracle_configs_testnet():
        SmartTable<string::String, Option<CappedAssetData>> {
        let oracle_config = smart_table::new<String, Option<CappedAssetData>>();
        let price_scaling_factor =
            math_utils::pow(10, (oracle::get_asset_price_decimals() as u256));
        smart_table::upsert(
            &mut oracle_config,
            utf8(APT_ASSET),
            option::none<CappedAssetData>()
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(USDC_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::STABLE,
                    stable_price_cap: option::some<u256>(
                        (104 * price_scaling_factor) / 100
                    ), // 1.04 USD
                    ratio_decimals: option::none<u8>(),
                    minimum_snapshot_delay: option::none<u256>(),
                    snapshot_timestamp: option::none<u256>(),
                    max_yearly_ratio_growth_percent: option::none<u256>(),
                    max_ratio_growth_per_second: option::none<u256>(),
                    snapshot_ratio: option::none<u256>(),
                    mapped_asset_ratio_multiplier: option::none<address>()
                }
            )
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(USDT_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::STABLE,
                    stable_price_cap: option::some<u256>(
                        (104 * price_scaling_factor) / 100
                    ), // 1.04 USD
                    ratio_decimals: option::none<u8>(),
                    minimum_snapshot_delay: option::none<u256>(),
                    snapshot_timestamp: option::none<u256>(),
                    max_yearly_ratio_growth_percent: option::none<u256>(),
                    max_ratio_growth_per_second: option::none<u256>(),
                    snapshot_ratio: option::none<u256>(),
                    mapped_asset_ratio_multiplier: option::none<address>()
                }
            )
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(SUSDE_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::SUSDE,
                    stable_price_cap: option::none<u256>(),
                    ratio_decimals: option::some<u8>(oracle::get_asset_price_decimals()),
                    minimum_snapshot_delay: option::some<u256>(14 * 24 * 3600), // 14 days in seconds
                    snapshot_timestamp: option::some<u256>((
                        timestamp::now_seconds() as u256
                    )), // in secs - will be overwritten later in set_susde_price_adapter
                    max_yearly_ratio_growth_percent: option::some<u256>(
                        (50 * math_utils::get_percentage_factor()) / 100
                    ), // 50 %
                    max_ratio_growth_per_second: option::none<u256>(), // Note: gets initialized in the set_susde_price_adapter method
                    snapshot_ratio: option::some<u256>(0), // must be in the oracle precision - will be overwritten later in set_susde_price_adapter
                    mapped_asset_ratio_multiplier: option::some<address>(
                        @0xd5d0d561493ea2b9410f67da804653ae44e793c2423707d4f11edb2e38192050
                    ) // USDT address
                }
            )
        );
        oracle_config
    }

    /// @notice Build oracle configuration for mainnet
    /// @return SmartTable mapping asset symbols to oracle configurations
    public fun build_oracle_configs_mainnet():
        SmartTable<string::String, Option<CappedAssetData>> {
        let oracle_config = smart_table::new<String, Option<CappedAssetData>>();
        let price_scaling_factor =
            math_utils::pow(10, (oracle::get_asset_price_decimals() as u256));
        smart_table::upsert(
            &mut oracle_config,
            utf8(APT_ASSET),
            option::none<CappedAssetData>()
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(USDC_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::STABLE,
                    stable_price_cap: option::some<u256>(
                        (104 * price_scaling_factor) / 100
                    ), // 1.04 USD
                    ratio_decimals: option::none<u8>(),
                    minimum_snapshot_delay: option::none<u256>(),
                    snapshot_timestamp: option::none<u256>(),
                    max_yearly_ratio_growth_percent: option::none<u256>(),
                    max_ratio_growth_per_second: option::none<u256>(),
                    snapshot_ratio: option::none<u256>(),
                    mapped_asset_ratio_multiplier: option::none<address>()
                }
            )
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(USDT_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::STABLE,
                    stable_price_cap: option::some<u256>(
                        (104 * price_scaling_factor) / 100
                    ), // 1.04 USD
                    ratio_decimals: option::none<u8>(),
                    minimum_snapshot_delay: option::none<u256>(),
                    snapshot_timestamp: option::none<u256>(),
                    max_yearly_ratio_growth_percent: option::none<u256>(),
                    max_ratio_growth_per_second: option::none<u256>(),
                    snapshot_ratio: option::none<u256>(),
                    mapped_asset_ratio_multiplier: option::none<address>()
                }
            )
        );
        smart_table::upsert(
            &mut oracle_config,
            utf8(SUSDE_ASSET),
            option::some(
                CappedAssetData {
                    type: AdapterType::SUSDE,
                    stable_price_cap: option::none<u256>(),
                    ratio_decimals: option::some<u8>(oracle::get_asset_price_decimals()),
                    minimum_snapshot_delay: option::some<u256>(14 * 24 * 3600), // 14 days in seconds
                    snapshot_timestamp: option::some<u256>((
                        timestamp::now_seconds() as u256
                    )), // in secs - will be overwritten later in set_susde_price_adapter
                    max_yearly_ratio_growth_percent: option::some<u256>(
                        (50 * math_utils::get_percentage_factor()) / 100
                    ), // 50 %
                    max_ratio_growth_per_second: option::none<u256>(), // Note: gets initialized in the set_susde_price_adapter method
                    snapshot_ratio: option::some<u256>(0), // must be in the oracle precision - will be overwritten later in set_susde_price_adapter
                    mapped_asset_ratio_multiplier: option::some<address>(
                        @0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b
                    ) // USDT address
                }
            )
        );
        oracle_config
    }

    /// @notice Build price feed addresses for testnet
    /// @return SmartTable mapping asset symbols to price feed addresses
    public fun build_price_feeds_testnet(): SmartTable<String, vector<u8>> {
        let price_feeds_testnet = smart_table::new<string::String, vector<u8>>();
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(APT_ASSET),
            x"011e22d6bf000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(USDC_ASSET),
            x"01a80ff216000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(USDT_ASSET),
            x"016d06ebb6000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_testnet,
            string::utf8(SUSDE_ASSET),
            x"01532c3a7e000332000000000000000000000000000000000000000000000000"
        );
        price_feeds_testnet
    }

    /// @notice Build price feed addresses for mainnet
    /// @return SmartTable mapping asset symbols to price feed addresses
    public fun build_price_feeds_mainnet(): SmartTable<String, vector<u8>> {
        let price_feeds_mainnet = smart_table::new<string::String, vector<u8>>();
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(APT_ASSET),
            x"011e22d6bf000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(USDC_ASSET),
            x"01a80ff216000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(USDT_ASSET),
            x"016d06ebb6000332000000000000000000000000000000000000000000000000"
        );
        smart_table::add(
            &mut price_feeds_mainnet,
            string::utf8(SUSDE_ASSET),
            x"01532c3a7e000332000000000000000000000000000000000000000000000000"
        );
        price_feeds_mainnet
    }

    /// @notice Build price feed addresses for testnet
    /// @return SmartTable mapping asset symbols to max price ages (in seconds)
    public fun build_asset_max_price_age_testnet(): SmartTable<String, u64> {
        let asset_max_price_ages_testnet = smart_table::new<string::String, u64>();
        smart_table::add(
            &mut asset_max_price_ages_testnet,
            string::utf8(APT_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_testnet,
            string::utf8(USDC_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_testnet,
            string::utf8(USDT_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_testnet,
            string::utf8(SUSDE_ASSET),
            45 * 60 // 45 minutes
        );
        asset_max_price_ages_testnet
    }

    /// @notice Build price feed addresses for mainnet
    /// @return SmartTable mapping asset symbols to max price ages (in seconds)
    public fun build_asset_max_price_age_mainnet(): SmartTable<String, u64> {
        let asset_max_price_ages_mainnet = smart_table::new<string::String, u64>();
        smart_table::add(
            &mut asset_max_price_ages_mainnet,
            string::utf8(APT_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_mainnet,
            string::utf8(USDC_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_mainnet,
            string::utf8(USDT_ASSET),
            45 * 60 // 45 minutes
        );
        smart_table::add(
            &mut asset_max_price_ages_mainnet,
            string::utf8(SUSDE_ASSET),
            45 * 60 // 45 minutes
        );
        asset_max_price_ages_mainnet
    }

    /// @notice Build underlying asset addresses for testnet
    /// @return SmartTable mapping asset symbols to asset addresses
    public fun build_underlying_assets_testnet(): SmartTable<String, address> {
        let apt_mapped_fa_asset = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        let underlying_assets_testnet = smart_table::new<String, address>();
        smart_table::upsert(
            &mut underlying_assets_testnet, utf8(APT_ASSET), apt_mapped_fa_asset
        );
        smart_table::upsert(
            &mut underlying_assets_testnet,
            utf8(USDC_ASSET),
            @0x69091fbab5f7d635ee7ac5098cf0c1efbe31d68fec0f2cd565e8d168daf52832
        );
        smart_table::upsert(
            &mut underlying_assets_testnet,
            utf8(USDT_ASSET),
            @0xd5d0d561493ea2b9410f67da804653ae44e793c2423707d4f11edb2e38192050
        ); // canonical copy
        smart_table::upsert(
            &mut underlying_assets_testnet,
            utf8(SUSDE_ASSET),
            @0x8e67e42c4ff61e16dca908b737d1260b312143c1f7ba1577309f075a27cb4d90
        );
        underlying_assets_testnet
    }

    /// @notice Build underlying asset addresses for mainnet
    /// @return SmartTable mapping asset symbols to asset addresses
    public fun build_underlying_assets_mainnet(): SmartTable<String, address> {
        let apt_mapped_fa_asset = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        let underlying_assets_mainnet = smart_table::new<String, address>();
        smart_table::upsert(
            &mut underlying_assets_mainnet, utf8(APT_ASSET), apt_mapped_fa_asset
        );
        smart_table::upsert(
            &mut underlying_assets_mainnet,
            utf8(USDC_ASSET),
            @0xbae207659db88bea0cbead6da0ed00aac12edcdda169e591cd41c94180b46f3b
        );
        smart_table::upsert(
            &mut underlying_assets_mainnet,
            utf8(USDT_ASSET),
            @0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b
        );
        smart_table::upsert(
            &mut underlying_assets_mainnet,
            utf8(SUSDE_ASSET),
            @0xb30a694a344edee467d9f82330bbe7c3b89f440a1ecd2da1f3bca266560fce69
        );
        underlying_assets_mainnet
    }

    /// @notice Build reserve configurations for testnet
    /// @return SmartTable mapping asset symbols to reserve configurations
    public fun build_reserve_config_testnet(): SmartTable<string::String, ReserveConfig> {
        let reserve_config = smart_table::new<String, ReserveConfig>();
        smart_table::upsert(
            &mut reserve_config,
            utf8(APT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (58 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (63 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (10 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (20 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 12_500, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: false, // ok
                siloed_borrowing: false, // ok
                emode_category: option::none() // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDC_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (78 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (5 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (10 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 23_500, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: true, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (78 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (5 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (10 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 23_125, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: true, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(SUSDE_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (65 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (85 * math_utils::get_percentage_factor()) / 1000, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: false, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (20 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 0, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: false, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        reserve_config
    }

    /// @notice Build reserve configurations for mainnet
    /// @return SmartTable mapping asset symbols to reserve configurations
    public fun build_reserve_config_mainnet(): SmartTable<string::String, ReserveConfig> {
        let reserve_config = smart_table::new<String, ReserveConfig>();
        smart_table::upsert(
            &mut reserve_config,
            utf8(APT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (58 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (63 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (10 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (20 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 12_500, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: false, // ok
                siloed_borrowing: false, // ok
                emode_category: option::none() // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDC_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (78 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (5 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (10 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 23_500, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: true, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(USDT_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (78 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (5 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: true, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (10 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 23_125, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: true, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        smart_table::upsert(
            &mut reserve_config,
            utf8(SUSDE_ASSET),
            ReserveConfig {
                base_ltv_as_collateral: (65 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_threshold: (75 * math_utils::get_percentage_factor()) / 100, // ok
                liquidation_bonus: math_utils::get_percentage_factor()
                    + (85 * math_utils::get_percentage_factor()) / 1000, // ok
                liquidation_protocol_fee: (10 * math_utils::get_percentage_factor())
                    / 100, // ok
                borrowing_enabled: false, // ok
                flashLoan_enabled: true, // ok
                reserve_factor: (20 * math_utils::get_percentage_factor()) / 100, // ok
                supply_cap: 25_000, // ok
                borrow_cap: 0, // ok
                debt_ceiling: 0, // ok
                borrowable_isolation: false, // ok
                siloed_borrowing: false, // ok
                emode_category: option::some<u256>(1) // ok
            }
        );
        reserve_config
    }

    /// @notice Build interest rate strategies for mainnet
    /// @return SmartTable mapping asset symbols to interest rate strategies
    public fun build_interest_rate_strategy_mainnet():
        SmartTable<string::String, InterestRateStrategy> {
        let interest_rate_config = smart_table::new<String, InterestRateStrategy>();
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(APT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((45 * math_utils::get_percentage_factor()) / 100),
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((7 * math_utils::get_percentage_factor()) / 100),
                variable_rate_slope2: ((300 * math_utils::get_percentage_factor()) / 100)
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDC_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100),
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100),
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100)
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100),
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100),
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100)
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(SUSDE_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100),
                base_variable_borrow_rate: 0, // TODO: need correct value
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100),
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100)
            }
        );
        interest_rate_config
    }

    /// @notice Build interest rate strategies for testnet
    /// @return SmartTable mapping asset symbols to interest rate strategies
    public fun build_interest_rate_strategy_testnet():
        SmartTable<string::String, InterestRateStrategy> {
        let interest_rate_config = smart_table::new<String, InterestRateStrategy>();
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(APT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((45 * math_utils::get_percentage_factor()) / 100), // ok
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((7 * math_utils::get_percentage_factor()) / 100), // ok
                variable_rate_slope2: ((300 * math_utils::get_percentage_factor()) / 100) // ok
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDC_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100), // ok
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100), // ok
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100) // ok
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(USDT_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100), // ok
                base_variable_borrow_rate: 0, // ok
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100), // ok
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100) // ok
            }
        );
        smart_table::upsert(
            &mut interest_rate_config,
            utf8(SUSDE_ASSET),
            InterestRateStrategy {
                optimal_usage_ratio: ((90 * math_utils::get_percentage_factor()) / 100),
                base_variable_borrow_rate: 0, // TODO: need correct value
                variable_rate_slope1: ((6 * math_utils::get_percentage_factor()) / 100),
                variable_rate_slope2: ((40 * math_utils::get_percentage_factor()) / 100)
            }
        );
        interest_rate_config
    }
}
