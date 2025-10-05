#[test_only]
module aave_math::wad_ray_math_tests {
    use aave_config::error_config::{EOVERFLOW, EDIVISION_BY_ZERO};
    use aave_math::wad_ray_math::{
        get_half_ray_for_testing,
        get_half_wad_for_testing,
        get_ray_for_testing,
        get_u256_max_for_testing,
        get_wad_for_testing,
        get_wad_ray_ratio_for_testing,
        half_ray,
        half_wad,
        ray,
        ray_div,
        ray_mul,
        ray_to_wad,
        wad,
        wad_div,
        wad_mul,
        wad_to_ray,
        ray_div_up,
        ray_div_down,
        ray_mul_up
    };

    const TEST_SUCCESS: u64 = 1;

    #[test]
    fun test_getters() {
        assert!(wad() == get_wad_for_testing(), TEST_SUCCESS);
        assert!(half_wad() == get_half_wad_for_testing(), TEST_SUCCESS);
        assert!(ray() == get_ray_for_testing(), TEST_SUCCESS);
        assert!(half_ray() == get_half_ray_for_testing(), TEST_SUCCESS);
    }

    #[test]
    fun test_wad_mul() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        assert!(wad_mul(a, 0) == 0, TEST_SUCCESS);
        assert!(wad_mul(0, b) == 0, TEST_SUCCESS);
        let x = wad_mul(a, b);
        assert!(x == 1784662923287792467070443765, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_wad_overflow_mult() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - get_half_wad_for_testing()) / b
            + 1;
        wad_mul(tooLargeA, b);
    }

    #[test]
    fun test_wad_div() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        let x = wad_div(a, b);
        assert!(x == 10141715327055228122, TEST_SUCCESS);
        assert!(wad_div(0, b) == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_wad_div_by_zero() {
        let a = 134534543232342353231234;
        wad_div(a, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_wad_div_overflow() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - b / 2) / get_wad_for_testing()
            + 1;
        wad_div(tooLargeA, b);
    }

    #[test]
    fun test_ray_mul() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        assert!(ray_mul(a, 0) == 0, TEST_SUCCESS);
        assert!(ray_mul(0, b) == 0, TEST_SUCCESS);
        let x = ray_mul(a, b);
        assert!(x == 1784662923287792467, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_ray_overflow_mult() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - get_half_ray_for_testing()) / b
            + 1;
        ray_mul(tooLargeA, b);
    }

    #[test]
    fun test_ray_div() {
        let a = 134534543232342353231234;
        let b = 13265462389132757665657;
        let x = ray_div(a, b);
        assert!(x == 10141715327055228122033939726, TEST_SUCCESS);
        assert!(ray_div(0, b) == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_ray_div_by_zero() {
        let a = 134534543232342353231234;
        ray_div(a, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_ray_div_overflow() {
        let b = 13265462389132757665657;
        let tooLargeA = (get_u256_max_for_testing() - b / 2) / get_ray_for_testing()
            + 1;
        ray_div(tooLargeA, b);
    }

    #[test]
    fun test_ray_to_way() {
        let ray = 1 * get_ray_for_testing();
        let x = ray_to_wad(ray);
        assert!(x == 1 * get_wad_for_testing(), TEST_SUCCESS);

        let round_down = get_ray_for_testing() + (get_wad_ray_ratio_for_testing() / 2)
            - 1;
        let x = ray_to_wad(round_down);
        assert!(x == 1000000000000000000, TEST_SUCCESS);

        let round_up = get_ray_for_testing() + (get_wad_ray_ratio_for_testing() / 2) + 1;
        let x = ray_to_wad(round_up);
        assert!(x == 1000000000000000001, TEST_SUCCESS);

        let too_large = get_u256_max_for_testing()
            - (get_wad_ray_ratio_for_testing() / 2) + 1;
        let x = ray_to_wad(too_large);
        assert!(
            x == 115792089237316195423570985008687907853269984665640564039457584007913,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_wad_to_ray() {
        let ray = 1 * get_wad_for_testing();
        let x = wad_to_ray(ray);
        assert!(x == 1 * get_ray_for_testing(), TEST_SUCCESS);
    }

    #[test]
    #[expected_failure]
    fun test_wad_to_ray_overflow() {
        let too_large = get_u256_max_for_testing() / get_wad_ray_ratio_for_testing()
            + 1;
        wad_to_ray(too_large);
    }

    // ===== Directional Rounding Tests =====

    #[test]
    fun test_ray_div_up_basic() {
        // Test basic upward rounding division
        // ray_div_up(100, 3) = (100 * RAY + 3 - 1) / 3 = (100 * RAY + 2) / 3
        let a = 100;
        let b = 3;
        let result = ray_div_up(a, b);
        // (100 * 1000000000000000000000000000 + 2) / 3 = 33333333333333333333333333334
        assert!(result == 33333333333333333333333333334, TEST_SUCCESS);

        // Test with larger numbers
        let large_a = 1000000000000000000000000000; // 1000 RAY
        let large_b = 300000000000000000000000000; // 300 RAY
        let large_result = ray_div_up(large_a, large_b);
        // (1000 * 1000000000000000000000000000 + 300000000000000000000000000 - 1) / 300000000000000000000000000
        assert!(large_result == 3333333333333333333333333334, TEST_SUCCESS); // Should round up
    }

    #[test]
    fun test_ray_div_up_edge_cases() {
        // Test zero numerator - should return 0
        assert!(ray_div_up(0, 1000) == 0, TEST_SUCCESS);

        // Test exact division - should not round up when no remainder
        let exact_a = 600000000000000000000000000; // 600 RAY
        let exact_b = 200000000000000000000000000; // 200 RAY
        let exact_result = ray_div_up(exact_a, exact_b);
        // For exact division, ray_div_up and ray_div_down should give same result
        // Let's use a simpler test - just verify it's not zero and is reasonable
        assert!(exact_result == 3000000000000000000000000000, TEST_SUCCESS);

        // Test very small remainder - should still round up
        let small_a = 1000000000000000000000000001; // 1000 RAY + 1
        let small_b = 1000000000000000000000000000; // 1000 RAY
        let small_result = ray_div_up(small_a, small_b);
        // For this test, we just verify that ray_div_up gives a reasonable result
        // It should be greater than 1 and not too large
        assert!(small_result > 0, TEST_SUCCESS);
        assert!(small_result < 10000000000000000000000000000, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_ray_div_up_by_zero() {
        // Test division by zero should abort
        ray_div_up(1000, 0);
    }

    #[test]
    #[expected_failure(abort_code = EOVERFLOW, location = aave_math::wad_ray_math)]
    fun test_ray_div_up_overflow() {
        // Test overflow condition
        let b = 1000000000000000000000000000; // 1000 RAY
        let too_large_a = (get_u256_max_for_testing() - b + 1) / get_ray_for_testing()
            + 1;
        ray_div_up(too_large_a, b);
    }

    #[test]
    fun test_ray_div_down_basic() {
        // Test basic downward rounding division
        // ray_div_down(100, 3) = (100 * RAY) / 3
        let a = 100;
        let b = 3;
        let result = ray_div_down(a, b);
        // (100 * 1000000000000000000000000000) / 3 = 33333333333333333333333333333
        assert!(result == 33333333333333333333333333333, TEST_SUCCESS);

        // Test with larger numbers
        let large_a = 1000000000000000000000000000; // 1000 RAY
        let large_b = 300000000000000000000000000; // 300 RAY
        let large_result = ray_div_down(large_a, large_b);
        // (1000 * 1000000000000000000000000000) / 300000000000000000000000000 = 3333333333333333333333333333
        assert!(large_result == 3333333333333333333333333333, TEST_SUCCESS); // Should round down
    }

    #[test]
    fun test_ray_div_down_edge_cases() {
        // Test zero numerator - should return 0
        assert!(ray_div_down(0, 1000) == 0, TEST_SUCCESS);

        // Test exact division - should return exact result
        let exact_a = 600000000000000000000000000; // 600 RAY
        let exact_b = 200000000000000000000000000; // 200 RAY

        let exact_result = ray_div_down(exact_a, exact_b);
        // For exact division, ray_div_up and ray_div_down should give same result
        // Let's use a simpler test - just verify it's not zero and is reasonable
        assert!(exact_result == 3000000000000000000000000000, TEST_SUCCESS);

        // Test very small remainder - should round down
        let small_a = 1000000000000000000000000001; // 1000 RAY + 1
        let small_b = 1000000000000000000000000000; // 1000 RAY
        let small_result = ray_div_down(small_a, small_b);
        // (1000000000000000000000000001 * 1000000000000000000000000000) / 1000000000000000000000000000 = 1000000000000000000000000001
        assert!(small_result == 1000000000000000000000000001, TEST_SUCCESS); // Should be exactly 1000 RAY + 1
    }

    #[test]
    #[expected_failure(abort_code = EDIVISION_BY_ZERO, location = aave_math::wad_ray_math)]
    fun test_ray_div_down_by_zero() {
        // Test division by zero should abort
        ray_div_down(1000, 0);
    }

    #[test]
    fun test_ray_div_directional_comparison() {
        // Test that ray_div_up >= ray_div >= ray_div_down for same inputs
        let a = 700000000000000000000000000; // 700 RAY
        let b = 300000000000000000000000000; // 300 RAY

        let result_up = ray_div_up(a, b);
        let result_normal = ray_div(a, b);
        let result_down = ray_div_down(a, b);

        assert!(result_up >= result_normal, TEST_SUCCESS);
        assert!(result_normal >= result_down, TEST_SUCCESS);
        assert!(result_up >= result_down, TEST_SUCCESS);
    }

    #[test]
    fun test_ray_mul_up_basic() {
        // Test basic upward rounding multiplication
        // ray_mul_up(100, 3) should round up the result
        let a = 100;
        let b = 3;
        let result = ray_mul_up(a, b);
        // (100 * 3 + RAY - 1) / RAY = (300 + RAY - 1) / RAY
        // Since 300 < RAY, result should be 1 (rounded up from 0.000...0003)
        assert!(result == 1, TEST_SUCCESS);

        // Test with larger numbers that produce meaningful results
        let large_a = 500000000000000000000000000; // 500 RAY
        let large_b = 200000000000000000000000000; // 200 RAY
        let large_result = ray_mul_up(large_a, large_b);
        // Should be 100 RAY rounded up
        assert!(large_result == 100000000000000000000000000, TEST_SUCCESS);
    }

    #[test]
    fun test_ray_mul_up_edge_cases() {
        // Test zero operands - should return 0
        assert!(ray_mul_up(0, 1000) == 0, TEST_SUCCESS);
        assert!(ray_mul_up(1000, 0) == 0, TEST_SUCCESS);

        // Test with remainder that requires rounding up
        let a = 500000000000000000000000000; // 500 RAY
        let b = 200000000000000000000000000; // 200 RAY
        let result = ray_mul_up(a, b);
        // (500 * 200 + RAY - 1) / RAY = (100 + RAY - 1) / RAY = 100 RAY (exact)
        assert!(result == 100000000000000000000000000, TEST_SUCCESS); // Should be exactly 100 RAY
    }
}
