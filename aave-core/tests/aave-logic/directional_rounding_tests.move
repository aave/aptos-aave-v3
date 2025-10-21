#[test_only]
module aave_pool::directional_rounding_tests {
    use std::signer;

    use std::vector;
    use aptos_framework::timestamp;

    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::borrow_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::generic_logic;
    use aave_pool::pool;
    use aave_pool::pool_logic;
    use aave_pool::pool_token_logic;
    use aave_pool::supply_logic;
    use aave_pool::token_helper;
    use aave_pool::variable_debt_token_factory;

    use aave_mock_underlyings::mock_underlying_token_factory;

    // Test error code constants
    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // ============================================================================
    // SECTION 1: Math Layer Tests (wad_ray_math)
    // ============================================================================
    // Tests for the new directional rounding functions in wad_ray_math

    #[test]
    /// [Test Objective]: Verify ray_mul_down rounds down correctly
    /// [Test Scenario]: Test zero value, unit value, and boundary values
    /// [Expected Behavior]:
    ///   - Zero returns 0
    ///   - Round down result <= half-up result
    /// [Key Validations]:
    ///   - ray_mul_down(0, RAY) = 0
    ///   - ray_mul_down(1, RAY) = 1
    ///   - ray_mul_down(1.5-1, RAY) <= ray_mul(1.5-1, RAY)
    fun test_ray_mul_down_boundary() {
        // Test zero
        let result = wad_ray_math::ray_mul_down(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_mul_down(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);

        // Test with value that would round up in half-up but down in down
        let a = wad_ray_math::ray() + wad_ray_math::ray() / 2 - 1; // 1.5 RAY - 1
        let result_down = wad_ray_math::ray_mul_down(a, wad_ray_math::ray());
        let result_half = wad_ray_math::ray_mul(a, wad_ray_math::ray());
        assert!(result_down <= result_half, TEST_FAILED);
    }

    #[test]
    /// [Test Objective]: Verify ray_mul_up rounds up correctly
    /// [Test Scenario]: Test zero value, unit value, and boundary values
    /// [Expected Behavior]:
    ///   - Zero returns 0
    ///   - Round up result >= half-up result
    /// [Key Validations]:
    ///   - ray_mul_up(0, RAY) = 0
    ///   - ray_mul_up(1, RAY) = 1
    ///   - ray_mul_up(1.5+1, RAY) >= ray_mul(1.5+1, RAY)
    fun test_ray_mul_up_boundary() {
        // Test zero
        let result = wad_ray_math::ray_mul_up(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_mul_up(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);

        // Test with value that would round down in half-up but up in up
        let a = wad_ray_math::ray() + wad_ray_math::ray() / 2 + 1; // 1.5 RAY + 1
        let result_up = wad_ray_math::ray_mul_up(a, wad_ray_math::ray());
        let result_half = wad_ray_math::ray_mul(a, wad_ray_math::ray());
        assert!(result_up >= result_half, TEST_FAILED);
    }

    #[test]
    /// [Test Objective]: Verify ray_div_down rounds down correctly
    /// [Test Scenario]: Test zero value, unit value, and rounding behavior
    /// [Expected Behavior]: Zero returns 0, round down result <= half-up result
    /// [Key Validations]: ray_div_down(0, RAY)=0, ray_div_down(1.5, RAY+1) <= ray_div(1.5, RAY+1)
    fun test_ray_div_down_boundary() {
        // Test zero
        let result = wad_ray_math::ray_div_down(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_div_down(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);

        // Test rounding down behavior
        let a = 3 * wad_ray_math::ray() / 2; // 1.5
        let b = wad_ray_math::ray() + 1;
        let result_down = wad_ray_math::ray_div_down(a, b);
        let result_half = wad_ray_math::ray_div(a, b);
        assert!(result_down <= result_half, TEST_FAILED);
    }

    #[test]
    /// [Test Objective]: Verify ray_div_up rounds up correctly
    /// [Test Scenario]: Test zero value, unit value, and boundary values
    /// [Expected Behavior]: Zero returns 0, round up result >= half-up result
    /// [Key Validations]: ray_div_up(0, RAY)=0, ray_div_up(1.5, RAY+1) >= ray_div(1.5, RAY+1)
    fun test_ray_div_up_boundary() {
        // Test zero
        let result = wad_ray_math::ray_div_up(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_div_up(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);

        // Test rounding up behavior
        let a = 3 * wad_ray_math::ray() / 2; // 1.5
        let b = wad_ray_math::ray() + 1;
        let result_up = wad_ray_math::ray_div_up(a, b);
        let result_half = wad_ray_math::ray_div(a, b);
        assert!(result_up >= result_half, TEST_FAILED);
    }

    #[test]
    /// [Test Objective]: Verify all directional rounding operators maintain consistent ordering
    /// [Test Scenario]: Compare down/half-up/up rounding results for both ray_mul and ray_div
    /// [Expected Behavior]:
    ///   - For ray_mul: down <= half-up <= up
    ///   - For ray_div: down <= half-up <= up
    ///   - This ordering must hold for all valid inputs
    /// [Key Validations]:
    ///   - ray_mul_down(a,b) <= ray_mul(a,b) <= ray_mul_up(a,b)
    ///   - ray_div_down(a,b) <= ray_div(a,b) <= ray_div_up(a,b)
    /// [Coverage]: Math layer - Validates the mathematical correctness of all 4 new directional operators
    fun test_directional_consistency() {
        let a = 1000000;
        let b = 1500000000000000000000000000; // 1.5 * RAY

        // ray_mul: down <= half <= up
        let mul_down = wad_ray_math::ray_mul_down(a, b);
        let mul_half = wad_ray_math::ray_mul(a, b);
        let mul_up = wad_ray_math::ray_mul_up(a, b);
        assert!(mul_down <= mul_half, TEST_FAILED);
        assert!(mul_half <= mul_up, TEST_FAILED);

        // ray_div: down <= half <= up
        let div_down = wad_ray_math::ray_div_down(a, b);
        let div_half = wad_ray_math::ray_div(a, b);
        let div_up = wad_ray_math::ray_div_up(a, b);
        assert!(div_down <= div_half, TEST_FAILED);
        assert!(div_half <= div_up, TEST_FAILED);
    }

    #[test]
    /// [Test Objective]: Verify ceil_div prevents small debt amounts from being rounded to zero
    /// [Test Scenario]: Simulate low-price asset with minimal debt (1 octa debt, price=999, unit=1000)
    /// [Expected Behavior]:
    ///   - Regular division: (1 * 999) / 1000 = 0 (debt disappears - BAD!)
    ///   - ceil_div: ceil_div(1 * 999, 1000) = 1 (debt preserved - GOOD!)
    /// [Key Validations]:
    ///   - Regular division must equal 0 (demonstrating the problem)
    ///   - ceil_div result must be > 0 (demonstrating the fix)
    ///   - ceil_div result must equal 1 (exact expected value)
    /// [Coverage]: Math layer - Critical for preventing Issue #2 (small debt rounded to zero)
    /// [Related]: generic_logic.get_user_debt_in_base_currency, liquidation_logic debt conversion
    fun test_ceil_div_small_debt() {
        // Small debt * low price / unit scenario
        let debt = 1;
        let price = 999;
        let unit = 1000;

        // Regular division would round to 0
        let regular_result = (debt * price) / unit;
        assert!(regular_result == 0, TEST_FAILED);

        // ceil_div rounds up to prevent dust
        let ceil_result = math_utils::ceil_div(debt * price, unit);
        assert!(ceil_result > 0, TEST_FAILED);
        assert!(ceil_result == 1, TEST_FAILED);
    }
}
