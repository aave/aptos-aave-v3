module aave_config::user {
    use aave_config::error as error_config;
    use aave_config::helper;
    use aave_config::reserve as reserve_config;

    const BORROWING_MASK: u256 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    const COLLATERAL_MASK: u256 =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    // 0.9 * 10 ** 4
    const REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD: u256 = 9000;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    // 0.95 * 10 ** 18
    const MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 950000000000000000;

    /**
    * @dev Minimum health factor to consider a user position healthy
    * A value of 1e18 results in 1
    */

    // 1 * 10 ** 18
    const HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 1000000000000000000;

    /**
    * @dev Role identifier for the role allowed to supply isolated reserves as collateral
    */
    const ISOLATED_COLLATERAL_SUPPLIER_ROLE: vector<u8> = b"ISOLATED_COLLATERAL_SUPPLIER";

    const INTEREST_RATE_MODE_NONE: u8 = 0;
    // 1 = Stable Rate, 2 = Variable Rate, Since the Stable Rate service has been removed, only the Variable Rate service is retained.
    const INTEREST_RATE_MODE_VARIABLE: u8 = 2;

    struct UserConfigurationMap has key, copy, store, drop {
        /**
        * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
        * The first bit indicates if an asset is used as collateral by the user, the second whether an
        * asset is borrowed by the user.
        */
        data: u256,
    }

    public fun init(): UserConfigurationMap {
        UserConfigurationMap { data: 0 }
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        let config = init();
        move_to(account, config);
    }

    public fun get_interest_rate_mode_none(): u8 {
        INTEREST_RATE_MODE_NONE
    }

    public fun get_interest_rate_mode_variable(): u8 {
        INTEREST_RATE_MODE_VARIABLE
    }

    public fun get_borrowing_mask(): u256 {
        BORROWING_MASK
    }

    public fun get_collateral_mask(): u256 {
        COLLATERAL_MASK
    }

    public fun get_rebalance_up_liquidity_rate_threshold(): u256 {
        REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD
    }

    public fun get_minimum_health_factor_liquidation_threshold(): u256 {
        MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    public fun get_health_factor_liquidation_threshold(): u256 {
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    public fun get_isolated_collateral_supplier_role(): vector<u8> {
        ISOLATED_COLLATERAL_SUPPLIER_ROLE
    }

    public fun set_borrowing(
        user_configuration: &mut UserConfigurationMap, reserve_index: u256, borrowing: bool
    ) {
        assert!(reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index());
        let bit = 1 << ((reserve_index << 1) as u8);
        if (borrowing) {
            user_configuration.data = user_configuration.data | bit;
        } else {
            user_configuration.data = user_configuration.data & helper::bitwise_negation(bit);
        }
    }

    public fun set_using_as_collateral(
        user_configuration: &mut UserConfigurationMap, reserve_index: u256,
        using_as_collateral: bool,
    ) {
        assert!(reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index());
        let bit: u256 = 1 << (((reserve_index << 1) + 1) as u8);
        if (using_as_collateral) {
            user_configuration.data = user_configuration.data | bit;
        } else {
            user_configuration.data = user_configuration.data & helper::bitwise_negation(bit);
        }
    }

    public fun is_using_as_collateral_or_borrowing(
        user_configuration: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index());
        (user_configuration.data >> ((reserve_index << 1) as u8))
        & 3 != 0
    }

    public fun is_borrowing(
        user_configuration: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index());
        (user_configuration.data >> ((reserve_index << 1) as u8))
        & 1 != 0
    }

    public fun is_using_as_collateral(
        user_configuration: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(reserve_index < (reserve_config::get_max_reserves_count() as u256),
            error_config::get_einvalid_reserve_index());
        (user_configuration.data >> ((reserve_index << 1) as u8) + 1)
        & 1 != 0
    }

    public fun is_using_as_collateral_one(
        user_configuration: &UserConfigurationMap
    ): bool {
        let user_configuration_data = user_configuration.data & COLLATERAL_MASK;
        user_configuration_data != 0 && (user_configuration_data & (user_configuration_data
                    - 1) == 0)
    }

    public fun is_using_as_collateral_any(
        user_configuration: &UserConfigurationMap
    ): bool {
        user_configuration.data & COLLATERAL_MASK != 0
    }

    public fun is_borrowing_one(user_configuration: &UserConfigurationMap): bool {
        let borrowing_data = user_configuration.data & BORROWING_MASK;
        borrowing_data != 0 && (borrowing_data & (borrowing_data - 1) == 0)
    }

    public fun is_borrowing_any(user_configuration: &UserConfigurationMap): bool {
        user_configuration.data & BORROWING_MASK != 0
    }

    public fun is_empty(user_configuration: &UserConfigurationMap): bool {
        user_configuration.data == 0
    }

    public fun get_first_asset_id_by_mask(
        user_configuration: &UserConfigurationMap, mask: u256
    ): u256 {
        let bit_map_data = user_configuration.data & mask;
        let first_asset_position =
            bit_map_data & helper::bitwise_negation(bit_map_data - 1);
        let id: u256 = 0;
        first_asset_position = first_asset_position >> 2;
        while (first_asset_position != 0) {
            id = id + 1;
            first_asset_position = first_asset_position >> 2;
        };
        id
    }

    #[test_only]
    public fun get_user_config_map(): UserConfigurationMap acquires UserConfigurationMap {
        *borrow_global<UserConfigurationMap>(@aave_config)
    }

    #[test_only]
    public fun get_rebalance_up_liquidity_rate_threshold_for_testing(): u256 {
        REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD
    }

    #[test_only]
    public fun get_minimum_health_factor_liquidation_threshold_for_testing(): u256 {
        MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    #[test_only]
    public fun get_health_factor_liquidation_threshold_for_testing(): u256 {
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    #[test_only]
    public fun get_isolated_collateral_supplier_role_for_testing(): vector<u8> {
        ISOLATED_COLLATERAL_SUPPLIER_ROLE
    }
}
