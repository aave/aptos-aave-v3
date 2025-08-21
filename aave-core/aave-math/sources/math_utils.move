/// @title Math Utilities
/// @author Aave
/// @notice Utility functions for mathematical operations and calculations
module aave_math::math_utils {
    // imports
    use aptos_framework::timestamp;
    use aave_config::error_config;
    use aave_math::wad_ray_math;

    // Global Constants
    /// @notice Maximum value for u256
    const U256_MAX: u256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Seconds per year (ignoring leap years)
    const SECONDS_PER_YEAR: u256 = 365 * 24 * 3600;

    /// @notice Maximum percentage factor (100.00%)
    const PERCENTAGE_FACTOR: u256 = 10000;

    /// @notice Half percentage factor (50.00%)
    const HALF_PERCENTAGE_FACTOR: u256 = 5 * 1000;

    // Public functions
    /// @notice Returns the maximum value for u256
    /// @return The maximum u256 value
    public fun u256_max(): u256 {
        U256_MAX
    }

    /// @notice Returns the percentage factor (10000)
    /// @return The percentage factor
    public fun get_percentage_factor(): u256 {
        PERCENTAGE_FACTOR
    }

    /// @notice Calculates the interest accumulated using a linear interest rate formula
    /// @param rate The interest rate, in ray
    /// @param last_update_timestamp The timestamp of the last update of the interest
    /// @return The interest rate linearly accumulated during the timeDelta, in ray
    public fun calculate_linear_interest(
        rate: u256, last_update_timestamp: u64
    ): u256 {
        let time_passed = timestamp::now_seconds() - last_update_timestamp;
        let result = rate * (time_passed as u256);
        wad_ray_math::ray() + (result / SECONDS_PER_YEAR)
    }

    /// @notice Calculates the interest using a compounded interest rate formula
    /// @dev To avoid expensive exponentiation, the calculation is performed using a taylor approximation:
    /// time_elapsed_in_seconds s = n*t
    /// t = s/n, where n is the number of seconds in a year
    /// r = rate, annual rate as input parameter
    /// (1+r/n)^(n*t) = e^(r*t)
    /// e^(r*t) = 1 + r*t + (r*t)^2/2 + (r*t)^3/6 + ...
    ///
    /// The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
    /// gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
    /// error per different time periods
    ///
    /// @param rate The interest rate, in ray
    /// @param last_update_timestamp The timestamp of the last update of the interest
    /// @param current_timestamp The current timestamp at the time of calling the method
    /// @return The interest rate compounded during the timeDelta, in ray
    public fun calculate_compounded_interest(
        rate: u256, last_update_timestamp: u64, current_timestamp: u64
    ): u256 {
        assert!(
            current_timestamp >= last_update_timestamp, error_config::get_eoverflow()
        );
        // s is the time interval in seconds
        let s = ((current_timestamp - last_update_timestamp) as u256);
        if (s == 0) {
            return wad_ray_math::ray()
        };
        let x = s * rate / SECONDS_PER_YEAR;
        // 1 + r*t + (r*t)^2/2 + (r*t)^3/6 = 1 + r*t + (r*t)*((r*t)/2 + (r*t)*((r*t)/6))
        wad_ray_math::ray() + x
            + wad_ray_math::ray_mul(x, (x / 2 + wad_ray_math::ray_mul(x, x / 6)))
    }

    /// @notice Calculates the compounded interest between the timestamp of the last update and the current block timestamp
    /// @param rate The interest rate (in ray)
    /// @param last_update_timestamp The timestamp from which the interest accumulation needs to be calculated
    /// @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
    public fun calculate_compounded_interest_now(
        rate: u256, last_update_timestamp: u64
    ): u256 {
        calculate_compounded_interest(
            rate, last_update_timestamp, timestamp::now_seconds()
        )
    }

    /// @notice Executes a percentage multiplication
    /// @param value The value of which the percentage needs to be calculated
    /// @param percentage The percentage of the value to be calculated
    /// @return result The value multiplied by the percentage and divided by the percentage factor,
    ///         rounded half up to the nearest unit
    public fun percent_mul(value: u256, percentage: u256): u256 {
        if (value == 0 || percentage == 0) {
            return 0
        };
        assert!(
            value <= (U256_MAX - HALF_PERCENTAGE_FACTOR) / percentage,
            error_config::get_eoverflow()
        );
        (value * percentage + HALF_PERCENTAGE_FACTOR) / PERCENTAGE_FACTOR
    }

    /// @notice Executes a percentage division
    /// @param value The value of which the percentage needs to be calculated
    /// @param percentage The percentage of the value to be calculated
    /// @return result The value multiplied by the percentage factor and divided by the percentage,
    ///         rounded half up to the nearest unit
    public fun percent_div(value: u256, percentage: u256): u256 {
        assert!(percentage > 0, error_config::get_edivision_by_zero());
        assert!(
            value <= (U256_MAX - percentage / 2) / PERCENTAGE_FACTOR,
            error_config::get_eoverflow()
        );
        (value * PERCENTAGE_FACTOR + percentage / 2) / percentage
    }

    /// @notice Calculates the power of a base to an exponent
    /// @param base The base value
    /// @param exponent The exponent value
    /// @return The result of base raised to the power of exponent
    public fun pow(base: u256, exponent: u256): u256 {
        let result = 1;
        while (exponent > 0) {
            if (exponent & 1 == 1) {
                result *= base;
            };

            base = base * base;
            exponent = exponent >> 1;
        };
        result
    }

    /// @notice Performs division with ceiling (rounding up)
    /// @dev This function rounds up the result of division, ensuring that any remainder
    ///      is accounted for by adding 1 to the quotient
    /// @param numerator The numerator value
    /// @param denominator The denominator value
    /// @return The result of division rounded up
    public fun ceil_div(numerator: u256, denominator: u256): u256 {
        assert!(denominator > 0, error_config::get_edivision_by_zero());
        if (numerator == 0) {
            return 0
        };
        // Add denominator - 1 to numerator before division to achieve ceiling division
        (numerator + denominator - 1) / denominator
    }

    /// @dev Returns the seconds per year value
    /// @return Seconds per year constant
    public fun get_seconds_per_year(): u256 {
        SECONDS_PER_YEAR
    }

    // Test-only functions
    #[test_only]
    /// @dev Returns the half percentage factor for testing
    /// @return Half percentage factor constant
    public fun get_half_percentage_factor_for_testing(): u256 {
        HALF_PERCENTAGE_FACTOR
    }

    #[test_only]
    /// @dev Returns the maximum u256 value for testing
    /// @return The maximum u256 value
    public fun get_u256_max_for_testing(): u256 {
        u256_max()
    }

    #[test_only]
    /// @dev Returns the percentage factor for testing
    /// @return The percentage factor constant
    public fun get_percentage_factor_for_testing(): u256 {
        PERCENTAGE_FACTOR
    }
}
