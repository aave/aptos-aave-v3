/// @title WadRayMath library
/// @author Aave
/// @notice Provides functions to perform calculations with Wad and Ray units
/// @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
/// with 27 digits of precision)
/// @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
module aave_math::wad_ray_math {
    // imports
    use aave_config::error_config;

    // Global Constants
    /// @notice Maximum value for u256
    const U256_MAX: u256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    /// @notice 10^18 - Used for calculations in wad (18 decimals)
    const WAD: u256 = 1_000_000_000_000_000_000;
    /// @notice 5 * 10^17 - Half WAD, used for rounding
    const HALF_WAD: u256 = 500_000_000_000_000_000;
    /// @notice 10^27 - Used for calculations in ray (27 decimals)
    const RAY: u256 = 1_000_000_000_000_000_000_000_000_000;
    /// @notice 5 * 10^26 - Half RAY, used for rounding
    const HALF_RAY: u256 = 500_000_000_000_000_000_000_000_000;
    /// @notice 10^9 - The ratio between ray and wad (ray/wad)
    const WAD_RAY_RATIO: u256 = 1_000_000_000;

    // Public functions - Constant getters
    /// @notice Returns the WAD value (10^18)
    /// @return The WAD constant
    public fun wad(): u256 {
        WAD
    }

    /// @notice Returns the HALF_WAD value (5 * 10^17)
    /// @return The HALF_WAD constant
    public fun half_wad(): u256 {
        HALF_WAD
    }

    /// @notice Returns the RAY value (10^27)
    /// @return The RAY constant
    public fun ray(): u256 {
        RAY
    }

    /// @notice Returns the HALF_RAY value (5 * 10^26)
    /// @return The HALF_RAY constant
    public fun half_ray(): u256 {
        HALF_RAY
    }

    // Public functions - Wad operations
    /// @notice Multiplies two wad, rounding half up to the nearest wad
    /// @param a First wad value
    /// @param b Second wad value
    /// @return c Result of a*b, in wad
    public fun wad_mul(a: u256, b: u256): u256 {
        if (b == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - HALF_WAD) / b,
            error_config::get_eoverflow()
        );
        (a * b + HALF_WAD) / WAD
    }

    /// @notice Divides two wad, rounding half up to the nearest wad
    /// @param a Wad numerator
    /// @param b Wad denominator
    /// @return c Result of a/b, in wad
    public fun wad_div(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - b / 2) / WAD,
            error_config::get_eoverflow()
        );
        (a * WAD + b / 2) / b
    }

    // Public functions - Ray operations
    /// @notice Multiplies two ray, rounding half up to the nearest ray
    /// @param a First ray value
    /// @param b Second ray value
    /// @return c Result of a*b, in ray
    public fun ray_mul(a: u256, b: u256): u256 {
        if (a == 0 || b == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - HALF_RAY) / b,
            error_config::get_eoverflow()
        );
        (a * b + HALF_RAY) / RAY
    }

    /// @notice Multiplies two ray, always rounding up to the nearest ray
    /// @param a First ray value
    /// @param b Second ray value
    /// @return c Result of a*b, in ray, rounded up
    public fun ray_mul_up(a: u256, b: u256): u256 {
        if (a == 0 || b == 0) return 0;
        assert!(
            a <= (U256_MAX - RAY + 1) / b,
            error_config::get_eoverflow()
        );
        (a * b + RAY - 1) / RAY
    }

    /// @notice Multiplies two ray, always rounding down to the nearest ray
    /// @param a First ray value
    /// @param b Second ray value
    /// @return c Result of a*b, in ray, rounded down
    public fun ray_mul_down(a: u256, b: u256): u256 {
        if (a == 0 || b == 0) return 0;
        (a * b) / RAY
    }

    /// @notice Divides two ray, rounding half up to the nearest ray
    /// @param a Ray numerator
    /// @param b Ray denominator
    /// @return c Result of a/b, in ray
    public fun ray_div(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) {
            return 0
        };
        assert!(
            a <= (U256_MAX - b / 2) / RAY,
            error_config::get_eoverflow()
        );
        (a * RAY + b / 2) / b
    }

    /// @notice Divides two ray, always rounding up to the nearest ray
    /// @param a Ray numerator
    /// @param b Ray denominator
    /// @return c Result of a/b, in ray, rounded up
    public fun ray_div_up(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) return 0;
        assert!(
            a <= (U256_MAX - b + 1) / RAY,
            error_config::get_eoverflow()
        );
        (a * RAY + b - 1) / b
    }

    /// @notice Divides two ray, always rounding down to the nearest ray
    /// @param a Ray numerator
    /// @param b Ray denominator
    /// @return c Result of a/b, in ray, rounded down
    public fun ray_div_down(a: u256, b: u256): u256 {
        assert!(b > 0, error_config::get_edivision_by_zero());
        if (a == 0) return 0;
        (a * RAY) / b
    }

    // Public functions - Conversion operations
    /// @notice Casts ray down to wad
    /// @param a Ray value to convert
    /// @return b The value converted to wad, rounded half up to the nearest wad
    public fun ray_to_wad(a: u256): u256 {
        let b = a / WAD_RAY_RATIO;
        let remainder = a % WAD_RAY_RATIO;
        if (remainder >= WAD_RAY_RATIO / 2) {
            b = b + 1;
        };
        b
    }

    /// @notice Converts wad up to ray
    /// @param a Wad value to convert
    /// @return b The value converted to ray, rounded half up to the nearest ray
    public fun wad_to_ray(a: u256): u256 {
        assert!(
            a <= U256_MAX / WAD_RAY_RATIO,
            error_config::get_eoverflow()
        );
        a * WAD_RAY_RATIO
    }

    // Test-only functions
    #[test_only]
    /// @dev Returns the WAD constant for testing
    /// @return The WAD value
    public fun get_wad_for_testing(): u256 {
        wad()
    }

    #[test_only]
    /// @dev Returns the HALF_WAD constant for testing
    /// @return The HALF_WAD value
    public fun get_half_wad_for_testing(): u256 {
        half_wad()
    }

    #[test_only]
    /// @dev Returns the RAY constant for testing
    /// @return The RAY value
    public fun get_ray_for_testing(): u256 {
        ray()
    }

    #[test_only]
    /// @dev Returns the HALF_RAY constant for testing
    /// @return The HALF_RAY value
    public fun get_half_ray_for_testing(): u256 {
        half_ray()
    }

    #[test_only]
    /// @dev Returns the WAD_RAY_RATIO constant for testing
    /// @return The WAD_RAY_RATIO value
    public fun get_wad_ray_ratio_for_testing(): u256 {
        WAD_RAY_RATIO
    }

    #[test_only]
    /// @dev Returns the U256_MAX constant for testing
    /// @return The U256_MAX value
    public fun get_u256_max_for_testing(): u256 {
        U256_MAX
    }
}
