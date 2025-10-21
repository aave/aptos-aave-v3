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

    // ============================================================================
    // SECTION 2: Token Base Tests (token_base)
    // ============================================================================
    // Tests for token_base mint_scaled/burn_scaled directional parameters

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @0x555,
            user = @0x042
        )
    ]
    /// [Test Objective]: Verify aToken minting uses ray_div_down for conservative token issuance
    /// [Test Scenario]: Supply 1001 units with liquidity index = 1.5 * RAY
    /// [Expected Behavior]:
    ///   - Scaled balance = floor(1001 / 1.5) = floor(667.33) = 667
    ///   - Protocol mints fewer aTokens than half-up would (conservative)
    /// [Key Validations]:
    ///   - scaled_balance must equal ray_div_down(amount, index)
    ///   - Calculation: floor(1001 * RAY / (1.5 * RAY)) = 667
    /// [Coverage]: token_base.mint_scaled with rounding_up=false (via a_token_factory.mint)
    /// [Related Contract]: token_base.move L306-310, a_token_factory.mint L495
    fun test_mint_scaled_with_rounding_down(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );

        let reserves = pool::get_reserves_list();
        let asset = *vector::borrow(&reserves, 0);
        let reserve = pool::get_reserve_data(asset);
        let a_token = pool::get_reserve_a_token_address(reserve);
        let user_addr = signer::address_of(user);

        // Set index to non-integer value
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        // Mint amount that will have rounding
        let amount = 1001; // Will result in fractional scaled amount

        // Mint for user (supply uses mint_scaled with rounding_up = false)
        let decimals = fungible_asset_manager::decimals(asset);
        let mint_amount: u64 = 1000000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            mint_amount,
            asset
        );

        supply_logic::supply(user, asset, amount, user_addr, 0);

        let scaled_balance = a_token_factory::scaled_balance_of(user_addr, a_token);

        // Verify: scaled should be floor(amount * RAY / index) = floor(1001 * RAY / 1.5 / RAY) = floor(667.33...) = 667
        let expected_scaled = wad_ray_math::ray_div_down(amount, index);
        assert!(scaled_balance == expected_scaled, TEST_FAILED);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @0x555,
            user = @0x042
        )
    ]
    /// [Test Objective]: Verify vToken (debt) minting uses ray_div_up for conservative debt recording
    /// [Test Scenario]: Borrow 1001 units with variable borrow index = 1.5 * RAY
    /// [Expected Behavior]:
    ///   - Scaled debt = ceil(1001 / 1.5) = ceil(667.33) = 668
    ///   - Protocol records more debt than half-up would (conservative, favors protocol)
    /// [Key Validations]:
    ///   - scaled_debt must equal ray_div_up(borrow_amount, index)
    ///   - Calculation: ceil(1001 * RAY / (1.5 * RAY)) = 668
    /// [Coverage]: token_base.mint_scaled with rounding_up=true (via variable_debt_token_factory.mint)
    /// [Related Contract]: token_base.move L306-310, variable_debt_token_factory.mint L348
    fun test_mint_scaled_with_rounding_up(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );

        let reserves = pool::get_reserves_list();
        let asset = *vector::borrow(&reserves, 0);
        let reserve = pool::get_reserve_data(asset);
        let v_token = pool::get_reserve_variable_debt_token_address(reserve);
        let user_addr = signer::address_of(user);

        // Setup: supply collateral first
        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 10000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            supply_amount,
            asset
        );
        supply_logic::supply(
            user,
            asset,
            (supply_amount as u256),
            user_addr,
            0
        );

        // Enable collateral
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        // Set variable borrow index to non-integer value
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        // Prepare APT for fees
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow amount that will have rounding
        let borrow_amount: u64 = 1001;
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let scaled_debt =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);

        // Verify: scaled should be ceil(amount * RAY / index) = ceil(1001 * RAY / 1.5 / RAY) = ceil(667.33...) = 668
        let expected_scaled = wad_ray_math::ray_div_up((borrow_amount as u256), index);
        assert!(scaled_debt == expected_scaled, TEST_FAILED);
    }
}
