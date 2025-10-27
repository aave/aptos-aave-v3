/*
* This test-only module provides a suite of unit tests to validate bitwise logic correctness
* and operator precedence for collateral configuration in the AAVE-like protocol.
*
* The primary goals of this module are:
*
* 1. **Validate Logical Equivalence Between Two Implementations**
*    ------------------------------------------------------------
*    - The functions `is_using_as_collateral_old` and `is_using_as_collateral_new` determine
*      whether a given reserve index is marked as "used as collateral" in a user's configuration bitmap.
*    - These functions differ only in the use of parentheses, specifically:
*
*      ```move
*      (self.data >> ((reserve_index << 1) as u8) + 1)    // old
*      (self.data >> (((reserve_index << 1) as u8) + 1))  // new
*      ```
*    - A comprehensive randomized and deterministic test (`test_collateral_logic_equivalence`)
*      validates that both methods always return the same result for all valid reserve indices [0, 127],
*      across various `u256` values including:
*        - 0, 1
*        - All bits set (`0xFFFFFFFFFFFFFFFF`)
*        - Alternating bit patterns (`0xAAAAAAAAAAAAAAAA`, `0x5555555555555555`)
*        - Edge cases like single high bits (`0x100000000`, `0x8000000000000000`)
*        - A random large value using `randomness::u256_range`.
*
*    - The test uses `reserve_config::get_max_reserves_count()` to dynamically determine
*      the number of reserves to validate, ensuring consistency with the protocol configuration.
*
* 2. **Demonstrate Operator Precedence**
*    -----------------------------------
*    - The `test_shift_plus_priority` function confirms that the `+` operator has higher precedence
*      than the bitwise right shift operator `>>`.
*    - Specifically:
*
*      ```move
*      let r1 = 16 >> 2 + 1;       // Interpreted as 16 >> (2 + 1) = 2
*      let r2 = 16 >> (2 + 1);     // Explicitly the same = 2
*      ```
*    - The test ensures both expressions yield the same result, reinforcing that:
*      `+` binds tighter than `>>` in Move operator precedence rules.
*
* 3. **Other Notes**
*    ---------------
*    - This module uses `aptos_framework::randomness` in test mode to safely generate
*      reproducible pseudorandom `u256` values for test inputs.
*    - All tests use `assert!` with error codes `SUCCESS` or `FAILED` for clarity.
*/
#[test_only]
module aave_config::is_using_as_collateral_tests {
    use std::vector;
    use aptos_framework::randomness;
    use aave_config::reserve_config;

    /// @notice Maximum value for u256
    const U256_MAX: u256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // error
    const SUCCESS: u64 = 1;
    const FAILED: u64 = 2;

    // Structs
    /// @notice Structure that stores the user configuration as a bitmap
    struct UserConfigurationMap has copy, store, drop {
        /// @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
        /// The first bit indicates if an asset is used as collateral by the user, the second whether an
        /// asset is borrowed by the user.
        data: u256
    }

    public fun is_using_as_collateral_old(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(reserve_index < 128, 1001);

        (self.data >> ((reserve_index << 1) as u8) + 1)
        & 1 != 0
    }

    public fun is_using_as_collateral_new(
        self: &UserConfigurationMap, reserve_index: u256
    ): bool {
        assert!(reserve_index < 128, 1001);

        (self.data >> (((reserve_index << 1) as u8) + 1))
        & 1 != 0
    }

    #[test(aptos_framework = @aptos_framework)]
    #[lint::allow_unsafe_randomness]
    public fun test_collateral_logic_equivalence(
        aptos_framework: &signer
    ) {
        randomness::initialize_for_testing(aptos_framework);
        let test_datas = vector[
            0,
            1,
            0xFFFFFFFFFFFFFFFF,
            0xAAAAAAAAAAAAAAAA,
            0x5555555555555555,
            0x100000000,
            0x8000000000000000,
            randomness::u256_range(1, U256_MAX)
        ];

        let failed = 0;
        let i = 0;
        while (i < vector::length(&test_datas)) {
            let data = *vector::borrow(&test_datas, i);
            let config = UserConfigurationMap { data };

            let j = 0;
            while (j < reserve_config::get_max_reserves_count()) {
                let idx = j;
                let res_old = is_using_as_collateral_old(&config, idx);
                let res_new = is_using_as_collateral_new(&config, idx);

                if (res_old != res_new) {
                    failed = failed + 1;
                    assert!(false, FAILED);
                };

                j = j + 1;
            };

            i += 1;
        };

        assert!(failed == 0, SUCCESS);
    }

    #[test]
    public fun test_shift_plus_priority() {
        let r1 = 16 >> 2 + 1; // If + has higher precedence -> 16 >> (2 + 1) = 16 >> 3 = 2
        let r2 = 16 >> (2 + 1); // Explicit parentheses, should also be 2
        assert!(r1 == r2, SUCCESS);
    }
}
