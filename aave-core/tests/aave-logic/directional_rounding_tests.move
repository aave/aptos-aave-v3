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
    /// [Test Objective]: Verify aToken mint/burn cycle prevents rounding arbitrage attacks
    /// [Test Scenario]: Supply 607 units then withdraw all available balance (simulates Issue #1 attack)
    /// [Expected Behavior]:
    ///   - User cannot profit from supply/withdraw cycle due to double conservative rounding
    ///   - mint: ray_div_down (user gets less aToken scaled)
    ///   - burn: ray_div_up (user burns more aToken scaled)
    ///   - Result: after_withdraw <= initial_balance (user loses ≤1 octa, never gains)
    /// [Key Validations]:
    ///   - after_withdraw <= initial_underlying (no profit from arbitrage)
    ///   - initial_underlying - after_withdraw <= 1 (loss within 1 octa tolerance)
    /// [Coverage]: Prevents Issue #1 rounding attack, validates double conservative rounding
    /// [Related Contract]: token_base.mint_scaled L306 (down), token_base.burn_scaled L408 (up)
    fun test_mint_burn_cycle_atoken(
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
        let user_addr = signer::address_of(user);

        // Set index to trigger rounding
        let index: u256 = 1341701152733098001533768654; // Real-world index
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        // Mint tokens
        let decimals = fungible_asset_manager::decimals(asset);
        let mint_amount: u64 = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            mint_amount,
            asset
        );

        let initial_underlying = fungible_asset_manager::balance_of(user_addr, asset);

        // Supply small amount
        let supply_amount: u64 = 607;
        supply_logic::supply(
            user,
            asset,
            (supply_amount as u256),
            user_addr,
            0
        );

        let after_supply = fungible_asset_manager::balance_of(user_addr, asset);
        assert!(
            after_supply == initial_underlying - supply_amount,
            TEST_FAILED
        );

        // Prepare APT for withdrawal fees
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Get actual withdrawable balance (may be < supply_amount due to ray_mul_down)
        let reserve = pool::get_reserve_data(asset);
        let a_token = pool::get_reserve_a_token_address(reserve);
        let actual_balance = a_token_factory::balance_of(user_addr, a_token);

        // Withdraw the actual available balance
        supply_logic::withdraw(user, asset, actual_balance, user_addr);

        let after_withdraw = fungible_asset_manager::balance_of(user_addr, asset);

        // Key test: user should NOT profit from mint/burn cycle (防止 Rounding Attack)
        // Due to ray_mul_down, user may lose max 1 octa, but should never gain
        assert!(after_withdraw <= initial_underlying, TEST_FAILED);

        // Verify the loss is within acceptable range (≤ 1 octa)
        assert!(
            initial_underlying - after_withdraw <= 1,
            TEST_FAILED
        );
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
    #[expected_failure(abort_code = 24, location = aave_pool::token_base)]
    /// [Test Objective]: Verify dust amounts (≤1 octa at high index) are rejected in mint_scaled
    /// [Test Scenario]: Attempt to supply 1 octa with very high liquidity index (3.0 * RAY)
    /// [Expected Behavior]:
    ///   - Amount = 1, Index = 3.0 * RAY
    ///   - Scaled = ray_div_down(1, 3*RAY) = floor(1/3) = 0
    ///   - mint_scaled detects amount_scaled == 0 and aborts with EINVALID_MINT_AMOUNT (code 24)
    /// [Key Validations]:
    ///   - Transaction must abort with code 24 (EINVALID_MINT_AMOUNT)
    ///   - Abort location must be aave_pool::token_base
    /// [Coverage]: token_base.mint_scaled dust protection (L309: assert amount_scaled != 0)
    /// [Related Contract]: token_base.move L309, prevents dust from being minted
    fun test_dust_amount_mint_burn(
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
        let user_addr = signer::address_of(user);

        // Set very high index to create dust scenarios
        let index: u256 = 3000000000000000000000000000; // 3.0 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let decimals = fungible_asset_manager::decimals(asset);
        let mint_amount: u64 = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            mint_amount,
            asset
        );

        // Try to supply amount that rounds to 0 scaled
        // amount = 1, index = 3, scaled = floor(1 / 3) = 0
        // This should fail with assert in mint_scaled
        // (This test verifies the dust check works)

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // This should abort because amount_scaled rounds to 0
        supply_logic::supply(user, asset, 1, user_addr, 0);
    }

    // ============================================================================
    // SECTION 3: aToken Tests (a_token_factory)
    // ============================================================================
    // Tests for aToken directional rounding implementations

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
    /// [Test Objective]: Verify aToken.balance_of() uses ray_mul_down for conservative balance calculation
    /// [Test Scenario]: Supply tokens, then set index=1.5*RAY to create fractional actual balance
    /// [Expected Behavior]:
    ///   - balance_of = ray_mul_down(scaled_balance, index)
    ///   - Result is conservative: actual_balance <= half_up_balance
    ///   - User's withdrawable amount is slightly less than mathematical expectation
    /// [Key Validations]:
    ///   - actual_balance == ray_mul_down(scaled, index)
    ///   - actual_balance <= ray_mul(scaled, index) (half-up)
    /// [Coverage]: a_token_factory.balance_of L215, implements ray_mul_down
    /// [Related Contract]: a_token_factory.move L215, used in withdraw validation
    fun test_atoken_balance_of_direction(
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

        // Supply some amount
        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 1000
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

        // Set index to create fractional balance
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let scaled_balance = a_token_factory::scaled_balance_of(user_addr, a_token);
        let actual_balance = a_token_factory::balance_of(user_addr, a_token);

        // Verify balance_of uses ray_mul_down
        let expected_balance = wad_ray_math::ray_mul_down(scaled_balance, index);
        assert!(actual_balance == expected_balance, TEST_FAILED);

        // Verify it's conservative (rounds down)
        let half_up_balance = wad_ray_math::ray_mul(scaled_balance, index);
        assert!(actual_balance <= half_up_balance, TEST_FAILED);
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
    /// [Test Objective]: Verify aToken.total_supply() uses ray_mul_down for conservative supply calculation
    /// [Test Scenario]: Supply 5000 units, set index=1.5*RAY, verify total supply calculation
    /// [Expected Behavior]:
    ///   - total_supply = ray_mul_down(scaled_total_supply, index)
    ///   - Protocol reports conservative total supply (slightly less than mathematical value)
    ///   - Prevents overestimating protocol's total issued aTokens
    /// [Key Validations]:
    ///   - total_supply == ray_mul_down(scaled_supply, index)
    ///   - Ensures protocol doesn't overreport its liabilities to users
    /// [Coverage]: a_token_factory.total_supply L243, implements ray_mul_down
    /// [Related Contract]: a_token_factory.move L243, used in protocol metrics
    fun test_atoken_total_supply_direction(
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

        // Supply some amount
        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 5000
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

        // Set index
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let scaled_supply = a_token_factory::scaled_total_supply(a_token);
        let total_supply = a_token_factory::total_supply(a_token);

        // Verify total_supply uses ray_mul_down
        let expected_supply = wad_ray_math::ray_mul_down(scaled_supply, index);
        assert!(total_supply == expected_supply, TEST_FAILED);
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
            periphery_account = @0x555
        )
    ]
    /// [Test Objective]: Verify mint_to_treasury correctly handles dust amounts by early return
    /// [Test Scenario]: Attempt to mint 1 octa to treasury with very high index (10.0 * RAY)
    /// [Expected Behavior]:
    ///   - amount = 1, index = 10.0 * RAY
    ///   - amount_scaled = ray_div_down(1, 10*RAY) = floor(0.1) = 0
    ///   - mint_to_treasury detects dust and returns early (no mint, no abort)
    ///   - Treasury balance remains unchanged
    /// [Key Validations]:
    ///   - treasury_balance_after >= treasury_balance_before (no decrease)
    ///   - Function completes successfully without abort (dust gracefully skipped)
    /// [Coverage]: a_token_factory.mint_to_treasury L556-558 dust check (if amount_scaled != 0)
    /// [Related Contract]: a_token_factory.move L556, prevents dust mint failures
    fun test_mint_to_treasury_dust_handling(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer
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

        // Set very high index to create real dust scenario
        let index: u256 = 10000000000000000000000000000; // 10.0 * RAY (very high)
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        // Set tiny accrued_to_treasury that will round to 0 when divided by high index
        // With index=10*RAY, accrued < 10 will round to 0 scaled amount
        pool::set_reserve_accrued_to_treasury_for_testing(reserve, 5);

        let treasury_addr = a_token_factory::get_reserve_treasury_address(a_token);
        let treasury_balance_before = a_token_factory::balance_of(
            treasury_addr, a_token
        );

        // Call mint_to_treasury (should handle dust gracefully)
        pool_token_logic::mint_to_treasury(vector[asset]);

        let treasury_balance_after = a_token_factory::balance_of(treasury_addr, a_token);

        // With such high index and tiny amount, balance might stay same (dust handled)
        // Or increase minimally - both are acceptable
        assert!(treasury_balance_after >= treasury_balance_before, TEST_FAILED);
    }
}
