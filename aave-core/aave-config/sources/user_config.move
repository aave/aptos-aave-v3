/// @title UserConfiguration library
/// @author Aave
/// @notice Implements the bitmap logic to handle the user configuration
module aave_config::user_config {
    // imports
    use aave_config::error_config;
    use aave_config::helper;
    use aave_config::reserve_config;

    // Global Constants
    /// @notice Bitmap mask for borrowing bits
    const BORROWING_MASK: u256 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    /// @notice Bitmap mask for collateral bits
    const COLLATERAL_MASK: u256 =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /// @notice Minimum health factor allowed under any circumstance
    /// @dev A value of 0.95e18 results in 0.95
    /// @dev 0.95 * 10 ** 18
    const MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 950000000000000000;

    /// @notice Minimum health factor to consider a user position healthy
    /// @dev A value of 1e18 results in 1
    /// @dev 1 * 10 ** 18
    const HEALTH_FACTOR_LIQUIDATION_THRESHOLD: u256 = 1000000000000000000;

    /// @notice Interest rate mode constant indicating no interest rate
    const INTEREST_RATE_MODE_NONE: u8 = 0;
    /// @notice Interest rate mode constant for variable rate
    /// @dev 1 = Stable Rate, 2 = Variable Rate, Since the Stable Rate service has been removed, only the Variable Rate service is retained.
    const INTEREST_RATE_MODE_VARIABLE: u8 = 2;

    // Structs
    /// @notice Structure that stores the user configuration as a bitmap
    struct UserConfigurationMap has copy, store, drop {
        /// @dev Bitmap of the user's collaterals and borrows. It is divided in pairs of bits, one pair per asset.
        /// For each asset, the even bit (2*i) indicates if the asset is borrowed by the user,
        /// and the odd bit (2*i + 1) indicates if the asset is used as collateral by the user.
        /// Each asset's borrow and collateral status are stored in two consecutive bits in the bitmap:
        /// - the right bit (even) for borrowing (0,2,4),
        /// - the left bit (odd) for collateral (1,3,5).
        /// This layout matches the Aave V3 EVM implementation.
        data: u256
    }

    // Public view functions - Constants getters
    /// @notice Returns the interest rate mode none constant
    /// @return The interest rate mode none value
    public fun get_interest_rate_mode_none(): u8 {
        INTEREST_RATE_MODE_NONE
    }

    /// @notice Returns the interest rate mode variable constant
    /// @return The interest rate mode variable value
    public fun get_interest_rate_mode_variable(): u8 {
        INTEREST_RATE_MODE_VARIABLE
    }

    /// @notice Returns the borrowing mask constant
    /// @return The borrowing mask value
    public fun get_borrowing_mask(): u256 {
        BORROWING_MASK
    }

    /// @notice Returns the collateral mask constant
    /// @return The collateral mask value
    public fun get_collateral_mask(): u256 {
        COLLATERAL_MASK
    }

    /// @notice Returns the minimum health factor liquidation threshold constant
    /// @return The minimum health factor liquidation threshold value
    public fun get_minimum_health_factor_liquidation_threshold(): u256 {
        MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    /// @notice Returns the health factor liquidation threshold constant
    /// @return The health factor liquidation threshold value
    public fun get_health_factor_liquidation_threshold(): u256 {
        HEALTH_FACTOR_LIQUIDATION_THRESHOLD
    }

    // Public view functions - Configuration status getters
    /// @notice Returns if a user has been using the reserve for borrowing or as collateral
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
    public fun is_using_as_collateral_or_borrowing(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < reserve_config::get_max_reserves_count(),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) as u8))
        & 3 != 0
    }

    /// @notice Validate a user has been using the reserve for borrowing
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve for borrowing, false otherwise
    public fun is_borrowing(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < reserve_config::get_max_reserves_count(),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) as u8))
        & 1 != 0
    }

    /// @notice Validate a user has been using the reserve as collateral
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @return True if the user has been using a reserve as collateral, false otherwise
    public fun is_using_as_collateral(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(
            reserve_index < reserve_config::get_max_reserves_count(),
            error_config::get_einvalid_reserve_index()
        );
        (self.data >> ((reserve_index << 1) + 1 as u8))
        & 1 != 0
    }

    /// @notice Checks if a user has been supplying only one reserve as collateral
    /// @dev This uses a simple trick - a number is a power of two (only one bit set) if and only if n & (n - 1) == 0
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral one reserve, false otherwise
    public fun is_using_as_collateral_one(self: &UserConfigurationMap): bool {
        let self_data = self.data & COLLATERAL_MASK;
        self_data != 0 && (self_data & (self_data - 1) == 0)
    }

    /// @notice Checks if a user has been supplying any reserve as collateral
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral any reserve, false otherwise
    public fun is_using_as_collateral_any(self: &UserConfigurationMap): bool {
        self.data & COLLATERAL_MASK != 0
    }

    /// @notice Checks if a user has been borrowing only one asset
    /// @dev This uses a simple trick - a number is a power of two (only one bit set) if and only if n & (n - 1) == 0
    /// @param self The configuration object
    /// @return True if the user has been supplying as collateral one reserve, false otherwise
    public fun is_borrowing_one(self: &UserConfigurationMap): bool {
        let borrowing_data = self.data & BORROWING_MASK;
        borrowing_data != 0 && (borrowing_data & (borrowing_data - 1) == 0)
    }

    /// @notice Checks if a user has been borrowing from any reserve
    /// @param self The configuration object
    /// @return True if the user has been borrowing any reserve, false otherwise
    public fun is_borrowing_any(self: &UserConfigurationMap): bool {
        self.data & BORROWING_MASK != 0
    }

    /// @notice Checks if a user has not been using any reserve for borrowing or supply
    /// @param self The configuration object
    /// @return True if the user has not been borrowing or supplying any reserve, false otherwise
    public fun is_empty(self: &UserConfigurationMap): bool {
        self.data == 0
    }

    /// @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
    /// @param self The configuration object
    /// @param mask The mask to apply to the bitmap
    /// @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
    public fun get_first_asset_id_by_mask(
        self: &UserConfigurationMap, mask: u256
    ): u256 {
        let bit_map_data = self.data & mask;
        if (bit_map_data == 0) { return 0 };
        let first_asset_position = bit_map_data
            & helper::bitwise_negation(bit_map_data - 1);
        let id = 0;
        first_asset_position = first_asset_position >> 2;
        while (first_asset_position != 0) {
            id = id + 1;
            first_asset_position = first_asset_position >> 2;
        };
        id
    }

    // Public functions - Initialization and configuration setters
    /// @notice Initializes the user configuration map
    /// @return A new UserConfigurationMap with zero data
    public fun init(): UserConfigurationMap {
        UserConfigurationMap { data: 0 }
    }

    /// @notice Sets if the user is borrowing the reserve identified by reserve_index
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @param borrowing True if the user is borrowing the reserve, false otherwise
    public fun set_borrowing(
        self: &mut UserConfigurationMap, reserve_index: u256, borrowing: bool
    ) {
        assert!(
            reserve_index < reserve_config::get_max_reserves_count(),
            error_config::get_einvalid_reserve_index()
        );
        let bit = 1 << ((reserve_index << 1) as u8);
        if (borrowing) {
            self.data = self.data | bit;
        } else {
            self.data = self.data & helper::bitwise_negation(bit);
        }
    }

    /// @notice Sets if the user is using as collateral the reserve identified by reserve_index
    /// @param self The configuration object
    /// @param reserve_index The index of the reserve in the bitmap
    /// @param using_as_collateral True if the user is using the reserve as collateral, false otherwise
    public fun set_using_as_collateral(
        self: &mut UserConfigurationMap, reserve_index: u256, using_as_collateral: bool
    ) {
        assert!(
            reserve_index < reserve_config::get_max_reserves_count(),
            error_config::get_einvalid_reserve_index()
        );
        let bit = 1 << (((reserve_index << 1) + 1) as u8);
        if (using_as_collateral) {
            self.data = self.data | bit;
        } else {
            self.data = self.data & helper::bitwise_negation(bit);
        }
    }
}
