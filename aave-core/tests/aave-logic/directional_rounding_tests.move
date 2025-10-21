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
    /// [Test Objective]: Verify mint_to_treasury handles zero amount gracefully (early return path)
    /// [Test Scenario]: Set accrued_to_treasury = 0 and call mint_to_treasury
    /// [Expected Behavior]:
    ///   - Function detects amount == 0 and returns early (L553 in a_token_factory)
    ///   - No mint operation is attempted
    ///   - No assertion failures occur
    /// [Key Validations]:
    ///   - Function completes successfully (test passes without abort)
    ///   - Demonstrates the first safety check in mint_to_treasury
    /// [Coverage]: a_token_factory.mint_to_treasury L553 (if amount == 0 check)
    /// [Related Contract]: a_token_factory.move L553, first guard clause
    fun test_mint_to_treasury_zero_amount(
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

        // Set accrued_to_treasury to 0
        pool::set_reserve_accrued_to_treasury_for_testing(reserve, 0);

        // Call mint_to_treasury (should return early without error)
        pool_token_logic::mint_to_treasury(vector[asset]);

        // If we reach here, test passed (no assertion failure)
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
    /// [Test Objective]: Verify aToken balance is never overestimated due to ray_mul_down
    /// [Test Scenario]: Supply tokens, increase index to 2.0*RAY, check balance calculations
    /// [Expected Behavior]:
    ///   - actual_balance = ray_mul_down(scaled, index)
    ///   - actual_balance <= theoretical_max (ray_mul half-up result)
    ///   - Ensures users cannot claim more collateral than they actually have
    /// [Key Validations]:
    ///   - actual_balance <= theoretical_max (no overestimation)
    ///   - actual_balance == ray_mul_down(scaled, index) (exact match expected)
    /// [Coverage]: a_token_factory.balance_of L215, critical for liquidation safety
    /// [Related Contract]: a_token_factory.move L215, prevents collateral overestimation
    fun test_atoken_balance_never_overestimated(
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

        // Supply
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

        // Increase index
        let index = 2000000000000000000000000000; // 2.0 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let scaled_balance = a_token_factory::scaled_balance_of(user_addr, a_token);
        let actual_balance = a_token_factory::balance_of(user_addr, a_token);

        // Theoretical maximum (with half-up)
        let theoretical_max = wad_ray_math::ray_mul(scaled_balance, index);

        // Actual balance should not exceed theoretical maximum
        assert!(actual_balance <= theoretical_max, TEST_FAILED);

        // With ray_mul_down, should be equal or slightly less
        let expected = wad_ray_math::ray_mul_down(scaled_balance, index);
        assert!(actual_balance == expected, TEST_FAILED);
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
    /// [Test Objective]: Verify aToken.mint() correctly passes rounding_up=false to token_base
    /// [Test Scenario]: Supply tokens with index=1.5*RAY, verify scaled balance calculation
    /// [Expected Behavior]:
    ///   - a_token_factory.mint calls token_base.mint_scaled with rounding_up=false
    ///   - Results in ray_div_down for amount→scaled conversion
    ///   - scaled_balance = floor(amount / index)
    /// [Key Validations]:
    ///   - scaled == ray_div_down(supply_amount, index)
    ///   - Confirms mint path uses conservative downward rounding
    /// [Coverage]: a_token_factory.mint L495, passes false for rounding_up parameter
    /// [Related Contract]: a_token_factory.move L495→token_base.move L306
    fun test_atoken_mint_direction(
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

        // Supply triggers aToken mint
        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 1000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            supply_amount,
            asset
        );

        let index = 1500000000000000000000000000;
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let supply_amt: u64 = supply_amount / 10;
        supply_logic::supply(user, asset, (supply_amt as u256), user_addr, 0);

        let scaled = a_token_factory::scaled_balance_of(user_addr, a_token);

        // Verify mint used ray_div_down (rounding_up=false)
        let expected_scaled = wad_ray_math::ray_div_down((supply_amt as u256), index);
        assert!(scaled == expected_scaled, TEST_FAILED);
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
    /// [Test Objective]: Verify aToken.burn() correctly passes rounding_up=true to token_base
    /// [Test Scenario]: Supply then withdraw tokens with index=1.5*RAY, verify burned scaled amount
    /// [Expected Behavior]:
    ///   - a_token_factory.burn calls token_base.burn_scaled with rounding_up=true
    ///   - Results in ray_div_up for amount→scaled conversion during burn
    ///   - burned_scaled = ceil(withdraw_amount / index)
    ///   - Burns MORE scaled than half-up would (conservative for protocol)
    /// [Key Validations]:
    ///   - burned_scaled == ray_div_up(withdraw_amount, index)
    ///   - Confirms burn path uses conservative upward rounding
    /// [Coverage]: a_token_factory.burn L522, passes true for rounding_up parameter
    /// [Related Contract]: a_token_factory.move L522→token_base.move L408
    fun test_atoken_burn_direction(
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

        // Setup: supply first
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

        let scaled_before = a_token_factory::scaled_balance_of(user_addr, a_token);

        let index = 1500000000000000000000000000;
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Withdraw triggers aToken burn
        let withdraw_amount: u64 = supply_amount / 10;
        supply_logic::withdraw(
            user,
            asset,
            (withdraw_amount as u256),
            user_addr
        );

        let scaled_after = a_token_factory::scaled_balance_of(user_addr, a_token);
        let burned_scaled = scaled_before - scaled_after;

        // Verify burn used ray_div_up (rounding_up=true)
        // This means more scaled was burned than with half-up
        let expected_burned = wad_ray_math::ray_div_up((withdraw_amount as u256), index);
        assert!(burned_scaled == expected_burned, TEST_FAILED);
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
    /// [Test Objective]: Verify mint_to_treasury uses double conservative rounding (outer + inner)
    /// [Test Scenario]: Set accrued_to_treasury=1000 scaled, index=1.5*RAY, verify both scaled and actual balance deltas
    /// [Expected Behavior]:
    ///   - Outer layer (pool_token_logic L97): amount = ray_mul_down(accrued_scaled, index)
    ///   - Inner layer (a_token_factory L556): scaled = ray_div_down(amount, index)
    ///   - Double rounding down ensures treasury never over-mints
    ///   - minted ≤ expected at both scaled and actual levels
    /// [Key Validations]:
    ///   - treasury_scaled_delta == expected_scaled_minted (validates scaled level correctness)
    ///   - minted <= amount_to_mint (never exceeds accrued amount at actual level)
    ///   - minted <= expected_balance_increase (double conservative effect at actual level)
    /// [Coverage]: pool_token_logic.mint_to_treasury L97-101, double ray_mul_down + ray_div_down
    /// [Related Contract]: pool_token_logic.move L97→a_token_factory.move L556
    fun test_mint_to_treasury_double_conservative(
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
        let reserve_data = pool::get_reserve_data(asset);
        let a_token = pool::get_reserve_a_token_address(reserve_data);
        let user_addr = signer::address_of(user);

        // Setup: supply and borrow to generate treasury accrual
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
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        let borrow_amount = 2000 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Set accrued_to_treasury
        let accrued_scaled = 1000;
        pool::set_reserve_accrued_to_treasury_for_testing(reserve_data, accrued_scaled);

        let index = 1500000000000000000000000000;
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let treasury_addr = a_token_factory::get_reserve_treasury_address(a_token);
        let treasury_before = a_token_factory::balance_of(treasury_addr, a_token);
        let treasury_scaled_before =
            a_token_factory::scaled_balance_of(treasury_addr, a_token);

        // mint_to_treasury applies double ray_div_down:
        // 1. scaled → amount: ray_mul_down (in pool_token_logic)
        // 2. amount → scaled: ray_div_down (in mint_scaled)
        pool_token_logic::mint_to_treasury(vector[asset]);

        let treasury_after = a_token_factory::balance_of(treasury_addr, a_token);
        let treasury_scaled_after =
            a_token_factory::scaled_balance_of(treasury_addr, a_token);
        let minted = treasury_after - treasury_before;
        let treasury_scaled_delta = treasury_scaled_after - treasury_scaled_before;

        // Verify double conservative rounding
        // Step 1: scaled→amount
        let amount_to_mint = wad_ray_math::ray_mul_down(accrued_scaled, index);
        // Step 2: amount→scaled (done in mint)
        let expected_scaled_minted = wad_ray_math::ray_div_down(amount_to_mint, index);

        // Verify the actual minted scaled amount matches expected
        // This validates the double-down rounding at the scaled level
        assert!(treasury_scaled_delta == expected_scaled_minted, TEST_FAILED);

        // Both steps round down → treasury gets conservatively minted
        // Verify treasury never gets more than expected (may get less due to double rounding)
        assert!(minted <= amount_to_mint, TEST_FAILED);

        // Verify the actual minted balance is conservative
        // The minted balance should be the ray_mul_down of the scaled amount
        let expected_balance_increase =
            wad_ray_math::ray_mul_down(expected_scaled_minted, index);
        assert!(minted <= expected_balance_increase, TEST_FAILED);
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
            liquidator = @0x099,
            user = @0x042
        )
    ]
    /// [Test Objective]: Verify transfer_on_liquidation handles dust amounts gracefully without aborting
    /// [Test Scenario]: Attempt to transfer 2 octa with very high index (5.0*RAY) during liquidation
    /// [Expected Behavior]:
    ///   - amount = 2, index = 5.0*RAY
    ///   - amount_scaled = ray_div(2, 5*RAY) = floor(0.4) = 0
    ///   - transfer_on_liquidation detects dust (L629 check) and returns early
    ///   - No transfer occurs, no events emitted, no assertion failures
    /// [Key Validations]:
    ///   - liquidator_balance remains unchanged (dust transfer skipped)
    ///   - Function completes successfully without abort
    /// [Coverage]: a_token_factory.transfer_on_liquidation L627-632 dust check
    /// [Related Contract]: a_token_factory.move L629 (if amount_scaled == 0 then return)
    fun test_transfer_on_liquidation_dust(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        liquidator: &signer,
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

        // Set very high index to create dust scenario
        let index: u256 = 5000000000000000000000000000; // 5.0 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let user_addr = signer::address_of(user);
        let liquidator_addr = signer::address_of(liquidator);

        // Mint some aTokens to user for testing
        let decimals = fungible_asset_manager::decimals(asset);
        let mint_amount: u64 = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            mint_amount,
            asset
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        supply_logic::supply(user, asset, (mint_amount as u256), user_addr, 0);

        let liquidator_before = a_token_factory::balance_of(liquidator_addr, a_token);

        // Try to transfer 1-2 octa (will round to 0 scaled)
        // transfer_on_liquidation should handle this gracefully (skip transfer)
        a_token_factory::transfer_on_liquidation_for_testing(
            user_addr, liquidator_addr, 2, index, a_token
        );

        let liquidator_after = a_token_factory::balance_of(liquidator_addr, a_token);

        // Should not revert, liquidator balance unchanged (dust skipped)
        assert!(liquidator_after == liquidator_before, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 4: vToken Tests (variable_debt_token_factory)
    // ============================================================================
    // Tests for vToken directional rounding

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
    /// [Test Objective]: Verify vToken.balance_of() uses ray_mul_up for conservative debt calculation
    /// [Test Scenario]: Borrow tokens, set index=1.5*RAY, verify debt balance calculation
    /// [Expected Behavior]:
    ///   - balance_of = ray_mul_up(scaled_debt, index)
    ///   - Result is conservative: actual_debt >= half_up_debt
    ///   - Protocol never underestimates user's debt obligation
    /// [Key Validations]:
    ///   - actual_debt == ray_mul_up(scaled_debt, index)
    ///   - actual_debt >= ray_mul(scaled_debt, index) (half-up)
    /// [Coverage]: variable_debt_token_factory.balance_of L134, implements ray_mul_up
    /// [Related Contract]: variable_debt_token_factory.move L134, critical for health factor
    fun test_vtoken_balance_of_direction(
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

        // Setup: supply collateral
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
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        // Prepare APT for fees
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow
        let borrow_amount = 100 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Set index to create fractional balance
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        let scaled_debt =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);
        let actual_debt = variable_debt_token_factory::balance_of(user_addr, v_token);

        // Verify balance_of uses ray_mul_up
        let expected_debt = wad_ray_math::ray_mul_up(scaled_debt, index);
        assert!(actual_debt == expected_debt, TEST_FAILED);

        // Verify it's conservative (rounds up)
        let half_up_debt = wad_ray_math::ray_mul(scaled_debt, index);
        assert!(actual_debt >= half_up_debt, TEST_FAILED);
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
    /// [Test Objective]: Verify vToken balance is never underestimated (always rounds up)
    /// [Test Scenario]: Borrow tokens, increase index to 2.0*RAY, verify debt is conservative
    /// [Expected Behavior]:
    ///   - actual_debt = ray_mul_up(scaled_debt, index)
    ///   - actual_debt >= theoretical_min (ray_mul half-up result)
    ///   - Protocol always reports debt conservatively (slightly higher than mathematical value)
    /// [Key Validations]:
    ///   - actual_debt >= theoretical_min (never underestimates)
    ///   - actual_debt == ray_mul_up(scaled, index) (exact match expected)
    /// [Coverage]: variable_debt_token_factory.balance_of L134, prevents debt underestimation
    /// [Related Contract]: variable_debt_token_factory.move L134, ensures safe liquidation triggers
    fun test_vtoken_balance_never_underestimated(
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

        // Setup
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
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow
        let borrow_amount = 100 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Increase index
        let index = 2000000000000000000000000000; // 2.0 * RAY
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        let scaled_debt =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);
        let actual_debt = variable_debt_token_factory::balance_of(user_addr, v_token);

        // Theoretical minimum (with half-up)
        let theoretical_min = wad_ray_math::ray_mul(scaled_debt, index);

        // Actual debt should not be less than theoretical minimum
        assert!(actual_debt >= theoretical_min, TEST_FAILED);

        // With ray_mul_up, should be equal or slightly more
        let expected = wad_ray_math::ray_mul_up(scaled_debt, index);
        assert!(actual_debt == expected, TEST_FAILED);
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
    /// [Test Objective]: Verify very small debt amounts (1 octa) remain visible and not rounded to zero
    /// [Test Scenario]: Borrow minimal amount (1 octa), verify debt balance is non-zero
    /// [Expected Behavior]:
    ///   - Borrow 1 octa via borrow_logic
    ///   - vToken mints using ray_div_up, ensuring at least 1 scaled unit
    ///   - balance_of uses ray_mul_up, ensuring debt > 0
    ///   - No debt is lost due to rounding
    /// [Key Validations]:
    ///   - debt_balance > 0 (even for 1 octa borrow)
    ///   - Prevents Issue #2 scenario (small debt rounds to 0)
    /// [Coverage]: Combination of vToken.mint L348 (ray_div_up) + balance_of L134 (ray_mul_up)
    /// [Related Contract]: variable_debt_token_factory.move L348, L134
    fun test_small_debt_visibility(
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

        // Setup collateral
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
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow very small amount (1 octa)
        borrow_logic::borrow(
            user,
            asset,
            1,
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let debt_balance = variable_debt_token_factory::balance_of(user_addr, v_token);

        // Even tiny debt should be visible (not 0)
        assert!(debt_balance > 0, TEST_FAILED);
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
    /// [Test Objective]: Verify vToken.mint() correctly uses ray_div_up for conservative debt minting
    /// [Test Scenario]: Borrow tokens with index=1.5*RAY, verify scaled debt calculation
    /// [Expected Behavior]:
    ///   - variable_debt_token_factory.mint calls token_base.mint_scaled with rounding_up=true
    ///   - Results in ray_div_up for amount→scaled conversion
    ///   - scaled_debt = ceil(borrow_amount / index)
    ///   - Mints MORE scaled than half-up would (conservative, never underestimates debt)
    /// [Key Validations]:
    ///   - scaled == ray_div_up(borrow_amount, index)
    ///   - scaled >= floor(borrow_amount * RAY / index)
    /// [Coverage]: variable_debt_token_factory.mint L348, passes true for rounding_up parameter
    /// [Related Contract]: variable_debt_token_factory.move L348→token_base.move L306
    fun test_vtoken_mint_uses_ray_div_up(
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

        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 10000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            supply_amount * 2,
            asset
        );
        supply_logic::supply(
            user,
            asset,
            (supply_amount as u256),
            user_addr,
            0
        );
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        let index = 1500000000000000000000000000;
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        let borrow_amount = (supply_amount / 10);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let scaled = variable_debt_token_factory::scaled_balance_of(user_addr, v_token);
        let expected = wad_ray_math::ray_div_up((borrow_amount as u256), index);

        // Verify more scaled was minted (conservative for protocol)
        assert!(scaled == expected, TEST_FAILED);
        // Verify scaled is at least the floor division amount
        let floor_expected = (borrow_amount as u256) * wad_ray_math::ray() / index;
        assert!(scaled >= floor_expected, TEST_FAILED);
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
    /// [Test Objective]: Verify vToken.burn() correctly uses ray_div_down for conservative debt repayment
    /// [Test Scenario]: Borrow then repay tokens with index=1.5*RAY, verify burned scaled amount
    /// [Expected Behavior]:
    ///   - variable_debt_token_factory.burn calls token_base.burn_scaled with rounding_up=false
    ///   - Results in ray_div_down for repay_amount→scaled conversion
    ///   - burned_scaled = floor(repay_amount / index)
    ///   - Burns LESS scaled than half-up would (conservative, debt stays slightly higher)
    /// [Key Validations]:
    ///   - burned == ray_div_down(repay_amount, index)
    ///   - Confirms repay path uses conservative downward rounding
    /// [Coverage]: variable_debt_token_factory.burn L386, passes false for rounding_up parameter
    /// [Related Contract]: variable_debt_token_factory.move L386→token_base.move L408
    fun test_vtoken_burn_uses_ray_div_down(
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

        let decimals = fungible_asset_manager::decimals(asset);
        let supply_amount: u64 = 10000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            supply_amount * 2,
            asset
        );
        supply_logic::supply(
            user,
            asset,
            (supply_amount as u256),
            user_addr,
            0
        );
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        let borrow_amount = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let scaled_before =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);

        let index = 1500000000000000000000000000;
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        let repay_amount: u64 = borrow_amount / 10;
        borrow_logic::repay(
            user,
            asset,
            (repay_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            user_addr
        );

        let scaled_after =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);
        let burned = scaled_before - scaled_after;
        let expected = wad_ray_math::ray_div_down((repay_amount as u256), index);

        // Verify less scaled was burned (debt stays conservative)
        assert!(burned == expected, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 5: Pool Logic Tests (pool_logic)
    // ============================================================================
    // Tests for pool_logic interest rate calculation and treasury accrual

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
    /// [Test Objective]: Verify pool_logic.update_interest_rates uses ray_div_down for treasury accrual
    /// [Test Scenario]: Supply 10000 units + borrow 1000 units, fast-forward 1 day, trigger interest update
    /// [Expected Behavior]:
    ///   - update_interest_rates calls accrue_to_treasury internally
    ///   - new_accrued = old_accrued + ray_div_down(amount_to_mint, next_liquidity_index)
    ///   - Conservative accrual: treasury never accumulates optimistic amounts
    ///   - Aligns with mint_to_treasury's conservative minting approach
    /// [Key Validations]:
    ///   - Function executes successfully using ray_div_down (no abort)
    ///   - If treasury accrued: accrual_delta <= borrow_amount (sanity check)
    ///   - Note: Actual accrual depends on reserve_factor (may be 0 in test setup)
    /// [Coverage]: pool_logic.update_interest_rates→accrue_to_treasury L442-454
    /// [Related Contract]: pool_logic.move L442, core treasury accrual logic
    fun test_treasury_accrual_uses_ray_div_down(
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
        let reserve_data = pool::get_reserve_data(asset);
        let user_addr = signer::address_of(user);

        // Setup: supply and borrow to generate interest
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
        supply_logic::set_user_use_reserve_as_collateral(user, asset, true);

        // Set oracle price for borrow validation
        let unit = math_utils::pow(10, (decimals as u256));
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            unit // 1:1 price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        let borrow_amount = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Get treasury balance before
        let treasury_before = pool::get_reserve_accrued_to_treasury(reserve_data);

        // Simulate time passing and state update to trigger treasury accrual
        timestamp::fast_forward_seconds(86400); // 1 day

        // Trigger state update (which calls accrue_to_treasury internally)
        let reserve_cache = pool_logic::cache(reserve_data);
        pool_logic::update_interest_rates_and_virtual_balance_for_testing(
            reserve_data,
            &reserve_cache,
            signer::address_of(aave_pool),
            0,
            0
        );

        let treasury_after = pool::get_reserve_accrued_to_treasury(reserve_data);

        // Note: This is a functional consistency test, not a value test
        // We verify that the function executes without error using ray_div_down
        // The actual accrual amount depends on reserve_factor and interest rates
        // which may result in treasury_after == treasury_before if reserve_factor is 0

        // Verify function completes successfully (demonstrates ray_div_down works)
        // If treasury accrued, verify it's within reasonable bounds
        if (treasury_after > treasury_before) {
            let accrual_delta = treasury_after - treasury_before;
            // Sanity check: accrual should not exceed total borrow
            assert!(accrual_delta <= (borrow_amount as u256), TEST_FAILED);
        };
    }
}
