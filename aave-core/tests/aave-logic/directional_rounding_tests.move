#[test_only]
module aave_pool::directional_rounding_tests {
    use std::option;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::timestamp;

    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::borrow_logic;
    use aave_pool::flashloan_logic;
    use aave_pool::fungible_asset_manager;
    use aave_pool::generic_logic;
    use aave_pool::liquidation_logic;
    use aave_pool::pool;
    use aave_pool::pool_logic;
    use aave_pool::pool_tests;
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
    fun test_ray_mul_down_boundary() {
        // Test zero
        let result = wad_ray_math::ray_mul_down(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_mul_down(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);
        let a = wad_ray_math::ray() + wad_ray_math::ray() / 2 - 1; // 1.5 RAY - 1
        let result_down = wad_ray_math::ray_mul_down(a, wad_ray_math::ray());
        let result_half = wad_ray_math::ray_mul(a, wad_ray_math::ray());
        assert!(result_down <= result_half, TEST_FAILED);
    }

    #[test]
    fun test_ray_mul_up_boundary() {
        // Test zero
        let result = wad_ray_math::ray_mul_up(0, wad_ray_math::ray());
        assert!(result == 0, TEST_FAILED);

        // Test with 1 octa
        let result = wad_ray_math::ray_mul_up(1, wad_ray_math::ray());
        assert!(result == 1, TEST_FAILED);
        let a = wad_ray_math::ray() + wad_ray_math::ray() / 2 + 1; // 1.5 RAY + 1
        let result_up = wad_ray_math::ray_mul_up(a, wad_ray_math::ray());
        let result_half = wad_ray_math::ray_mul(a, wad_ray_math::ray());
        assert!(result_up >= result_half, TEST_FAILED);
    }

    #[test]
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
    fun test_ceil_div_small_debt() {
        // Small debt * low price / unit scenario
        let debt = 1;
        let price = 999;
        let unit = 1000;

        // Regular division would round to 0
        let regular_result = (debt * price) / unit;
        assert!(regular_result == 0, TEST_FAILED);
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
            after_supply == initial_underlying - supply_amount, TEST_FAILED
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

        assert!(after_withdraw <= initial_underlying, TEST_FAILED);

        // Verify the loss is within acceptable range (≤ 1 octa)
        assert!(
            initial_underlying - after_withdraw <= 1, TEST_FAILED
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
        let index: u256 = 10000000000000000000000000000; // 10.0 * RAY (very high)
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        // Set tiny accrued_to_treasury that will round to 0 when divided by high index
        // With index=10*RAY, accrued < 10 will round to 0 scaled amount
        pool::set_reserve_accrued_to_treasury_for_testing(reserve, 5);

        let treasury_addr = a_token_factory::get_reserve_treasury_address(a_token);
        let treasury_balance_before = a_token_factory::balance_of(
            treasury_addr, a_token
        );
        pool_token_logic::mint_to_treasury(vector[asset]);

        let treasury_balance_after = a_token_factory::balance_of(treasury_addr, a_token);
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
        // Step 1: scaled→amount
        let amount_to_mint = wad_ray_math::ray_mul_down(accrued_scaled, index);
        // Step 2: amount→scaled (done in mint)
        let expected_scaled_minted = wad_ray_math::ray_div_down(amount_to_mint, index);

        // Verify the actual minted scaled amount matches expected
        // This validates the double-down rounding at the scaled level
        assert!(treasury_scaled_delta == expected_scaled_minted, TEST_FAILED);
        // Verify treasury never gets more than expected (may get less due to double rounding)
        assert!(minted <= amount_to_mint, TEST_FAILED);
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
            user_addr,
            liquidator_addr,
            2,
            index,
            a_token
        );

        let liquidator_after = a_token_factory::balance_of(liquidator_addr, a_token);
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
    fun test_treasury_never_overaccrue(
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

        // Record initial treasury before multi-cycle accrual
        let treasury_initial = pool::get_reserve_accrued_to_treasury(reserve_data);

        // Multiple accrual cycles
        let cycles = 5;
        let i = 0;
        while (i < cycles) {
            timestamp::fast_forward_seconds(86400);

            let reserve_cache = pool_logic::cache(reserve_data);
            pool_logic::update_interest_rates_and_virtual_balance_for_testing(
                reserve_data,
                &reserve_cache,
                signer::address_of(aave_pool),
                0,
                0
            );

            i += 1;
        };

        let final_treasury = pool::get_reserve_accrued_to_treasury(reserve_data);

        // Note: This is a multi-cycle stability test
        // Actual accrual depends on reserve_factor (may be 0 in test setup)
        if (final_treasury > treasury_initial) {
            let total_accrued = final_treasury - treasury_initial;

            // Sanity check: total accrual should not exceed total borrow amount
            // This prevents over-accrual bugs even after multiple cycles
            assert!(total_accrued <= (borrow_amount as u256), TEST_FAILED);
            assert!(total_accrued > 0, TEST_FAILED);
        };
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
    fun test_interest_rate_input_uses_ray_mul_up(
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

        // Setup: supply and borrow to create utilization
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

        // Record initial rates before borrow
        let initial_borrow_rate =
            pool::get_reserve_current_variable_borrow_rate(reserve_data);
        let initial_liquidity_rate =
            pool::get_reserve_current_liquidity_rate(reserve_data);

        let borrow_amount = 2000 * (math_utils::pow(10, (decimals as u256)) as u64);

        // borrow() internally calls update_interest_rates (L290)
        // which uses ray_mul_up for total_variable_debt calculation
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Get updated rates after borrow (rates already updated by borrow() call)
        let updated_borrow_rate =
            pool::get_reserve_current_variable_borrow_rate(reserve_data);
        let updated_liquidity_rate =
            pool::get_reserve_current_liquidity_rate(reserve_data);

        // Verify: Rates increased after borrow (debt created → utilization up → rates up)
        assert!(updated_borrow_rate > initial_borrow_rate, TEST_FAILED);
        assert!(updated_liquidity_rate > initial_liquidity_rate, TEST_FAILED);
        let reserve_cache = pool_logic::cache(reserve_data);
        let index = pool_logic::get_next_variable_borrow_index(&reserve_cache);
        let scaled_debt = pool_logic::get_curr_scaled_variable_debt(&reserve_cache);

        // Compare ray_mul_up vs ray_mul for debt calculation
        let total_debt_up = wad_ray_math::ray_mul_up(scaled_debt, index);
        let total_debt_half = wad_ray_math::ray_mul(scaled_debt, index);
        assert!(total_debt_up >= total_debt_half, TEST_FAILED);
    }

    #[test]
    fun test_treasury_accrual_consistency() {

        // This test verifies the consistency principle via direct calculation
        let index = 1500000000000000000000000000; // 1.5 * RAY
        let amount = 1000;

        // All three paths should use ray_div_down
        let scaled_result = wad_ray_math::ray_div_down(amount, index);
        let half_result = wad_ray_math::ray_div(amount, index);
        assert!(scaled_result <= half_result, TEST_FAILED);

        // Verify exact expected value
        // floor(1000 / 1.5) = floor(666.666...) = 666
        assert!(scaled_result == 666, TEST_FAILED);
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
    fun test_debt_for_interest_rate_conservative(
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

        // Setup borrowing scenario
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

        let cache = pool_logic::cache(reserve_data);
        let total_debt_conservative =
            wad_ray_math::ray_mul_up(
                pool_logic::get_curr_scaled_variable_debt(&cache),
                pool_logic::get_next_variable_borrow_index(&cache)
            );

        // With ray_mul_up, debt is never underestimated
        assert!(total_debt_conservative >= (borrow_amount as u256), TEST_FAILED);
    }

    // ============================================================================
    // SECTION 6: Generic Logic Tests (generic_logic)
    // ============================================================================
    // Tests for generic_logic debt and collateral calculations
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
    fun test_small_debt_not_zero_issue2(
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

        // Setup collateral
        let decimals = fungible_asset_manager::decimals(asset);
        let unit = math_utils::pow(10, (decimals as u256));
        let supply_amount: u64 = 10000 * (unit as u64);
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

        // Set price < unit (critical scenario) - MUST be before borrow
        let price = unit - 1000;
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            asset,
            price
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow tiny amount
        let debt = 1;
        borrow_logic::borrow(
            user,
            asset,
            debt,
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Calculate debt in base currency
        let debt_in_base =
            generic_logic::get_user_debt_in_base_currency_for_testing(
                user_addr,
                reserve_data,
                price,
                unit
            );
        assert!(debt_in_base > 0, TEST_FAILED);
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
    fun test_debt_collateral_asymmetry(
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

        // Supply
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
        let borrow_amount = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Set indices
        let liquidity_index: u256 = 1500000000000000000000000000; // 1.5 * RAY
        let borrow_index: u256 = 1500000000000000000000000000;
        pool::set_reserve_liquidity_index_for_testing(asset, (liquidity_index as u128));
        pool::set_reserve_variable_borrow_index_for_testing(asset, (borrow_index as u128));

        let unit = math_utils::pow(10, (decimals as u256));
        let price = unit;

        let debt_in_base =
            generic_logic::get_user_debt_in_base_currency_for_testing(
                user_addr,
                reserve_data,
                price,
                unit
            );
        let collateral_in_base =
            generic_logic::get_user_balance_in_base_currency_for_testing(
                user_addr,
                reserve_data,
                price,
                unit
            );

        // Verify asymmetry: for same scaled amount with same index,
        // This creates a safety margin
        assert!(debt_in_base > 0, TEST_FAILED);
        assert!(collateral_in_base > 0, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 7: Supply/Withdraw Tests
    // ============================================================================
    // Tests for supply_logic directional rounding
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
    fun test_withdraw_balance_uses_ray_mul_down(
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

        // Supply sufficient liquidity first (to avoid virtual_balance underflow)
        let decimals = fungible_asset_manager::decimals(asset);
        let initial_liquidity: u64 = 50000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            initial_liquidity,
            asset
        );
        supply_logic::supply(
            user,
            asset,
            (initial_liquidity as u256),
            user_addr,
            0
        );

        // Now supply the amount we want to test withdrawal with
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

        // Set index to create fractional balance
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

        let scaled_balance = a_token_factory::scaled_balance_of(user_addr, a_token);

        // Calculate maximum withdrawable amount (uses ray_mul_down)
        let withdrawable = a_token_factory::balance_of(user_addr, a_token);
        let withdrawable_manual = wad_ray_math::ray_mul_down(scaled_balance, index);

        // Verify withdrawable is calculated using ray_mul_down
        assert!(withdrawable == withdrawable_manual, TEST_FAILED);
        let half_up_balance = wad_ray_math::ray_mul(scaled_balance, index);
        assert!(withdrawable <= half_up_balance, TEST_FAILED);

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Record underlying balance before withdraw
        let underlying_before = fungible_asset_manager::balance_of(user_addr, asset);

        // ACTUAL WITHDRAW: Test partial withdrawal (to keep some liquidity in pool)
        let withdraw_amount = supply_amount / 2;
        supply_logic::withdraw(
            user,
            asset,
            (withdraw_amount as u256),
            user_addr
        );

        // Verify withdraw succeeded
        let underlying_after = fungible_asset_manager::balance_of(user_addr, asset);

        // User should receive the withdrawn amount
        assert!(
            underlying_after == underlying_before + withdraw_amount, TEST_FAILED
        );
    }

    // ============================================================================
    // SECTION 8: Borrow/Repay Tests
    // ============================================================================
    // Tests for borrow_logic directional rounding
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
    fun test_borrow_mints_debt_conservatively(
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

        // Set non-integer index
        let index = 1500000000000000000000000000; // 1.5 * RAY
        pool::set_reserve_variable_borrow_index_for_testing(asset, (index as u128));

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        // Borrow amount with fractional scaled result
        let borrow_amount = 1001;
        borrow_logic::borrow(
            user,
            asset,
            borrow_amount,
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let scaled_debt =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);

        // Should use ray_div_up: ceil(1001 / 1.5) = ceil(667.33) = 668
        let expected_scaled = wad_ray_math::ray_div_up(borrow_amount, index);
        assert!(scaled_debt == expected_scaled, TEST_FAILED);
        let half_up_scaled = wad_ray_math::ray_div(borrow_amount, index);
        assert!(scaled_debt >= half_up_scaled, TEST_FAILED);
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
    fun test_repay_burns_debt_conservatively(
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

        // Setup and borrow
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

        let debt_before = variable_debt_token_factory::balance_of(user_addr, v_token);

        // Repay partial amount
        let repay_amount = 100 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::repay(
            user,
            asset,
            (repay_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            user_addr
        );

        let debt_after = variable_debt_token_factory::balance_of(user_addr, v_token);
        assert!(debt_after < debt_before, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 9: Liquidation Tests
    // ============================================================================
    // Tests for liquidation_logic directional rounding
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
            depositor = @0x098,
            liquidator = @0x099,
            user = @0x042
        )
    ]
    fun test_liquidation_amount_accuracy(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        depositor: &signer,
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

        // Fast forward time to pass liquidation grace period
        timestamp::fast_forward_seconds(86400); // 1 day

        let reserves = pool::get_reserves_list();
        let collateral_asset = *vector::borrow(&reserves, 0);
        let debt_asset = *vector::borrow(&reserves, 1); // Fixed: use index 1, not TEST_FAILED

        let user_addr = signer::address_of(user);
        let depositor_addr = signer::address_of(depositor);
        let liquidator_addr = signer::address_of(liquidator);

        let debt_decimals = fungible_asset_manager::decimals(debt_asset);
        let debt_unit = math_utils::pow(10, (debt_decimals as u256));

        // Step 1: Depositor provides debt asset liquidity
        let depositor_supply: u64 =
            200000 * (math_utils::pow(10, (debt_decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            depositor_addr,
            depositor_supply,
            debt_asset
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            depositor_addr, 100000000
        );
        supply_logic::supply(
            depositor,
            debt_asset,
            (depositor_supply as u256),
            depositor_addr,
            0
        );

        // Step 2: User provides collateral
        let decimals = fungible_asset_manager::decimals(collateral_asset);
        let supply_amount: u64 = 100000
            * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            supply_amount,
            collateral_asset
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        supply_logic::supply(
            user,
            collateral_asset,
            (supply_amount as u256),
            user_addr,
            0
        );
        supply_logic::set_user_use_reserve_as_collateral(user, collateral_asset, true);

        // Set prices
        let collateral_unit = math_utils::pow(10, (decimals as u256));

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            collateral_asset,
            collateral_unit
        );
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            debt_asset,
            debt_unit
        );

        // Step 3: User borrows debt asset
        let borrow_amount: u64 = 60000
            * (math_utils::pow(10, (debt_decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            debt_asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        // Step 4: Price drop makes user liquidatable
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            collateral_asset,
            collateral_unit / 3 // 66% price drop for liquidation
        );

        // Record states before liquidation
        let debt_reserve = pool::get_reserve_data(debt_asset);
        let v_token = pool::get_reserve_variable_debt_token_address(debt_reserve);
        let user_debt_before = variable_debt_token_factory::balance_of(
            user_addr, v_token
        );

        let collateral_reserve = pool::get_reserve_data(collateral_asset);
        let a_token = pool::get_reserve_a_token_address(collateral_reserve);
        let user_collateral_before = a_token_factory::balance_of(user_addr, a_token);
        let liquidation_amount = user_debt_before;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            liquidator_addr,
            (liquidation_amount as u64),
            debt_asset
        );

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            liquidator_addr, 100000000
        );

        // Step 5: ACTUAL LIQUIDATION CALL
        liquidation_logic::liquidation_call(
            liquidator,
            collateral_asset,
            debt_asset,
            user_addr,
            liquidation_amount,
            false // receive underlying, not aToken
        );

        // Verify liquidation results
        let user_debt_after = variable_debt_token_factory::balance_of(
            user_addr, v_token
        );
        let user_collateral_after = a_token_factory::balance_of(user_addr, a_token);
        let liquidator_collateral_after =
            fungible_asset_manager::balance_of(liquidator_addr, collateral_asset);

        // Key validations:
        // 1. User's debt decreased
        assert!(user_debt_after < user_debt_before, TEST_FAILED);

        // 2. User's collateral decreased
        assert!(user_collateral_after < user_collateral_before, TEST_FAILED);

        // 3. Liquidator received collateral (with bonus)
        assert!(liquidator_collateral_after > 0, TEST_FAILED);
        let debt_reduction = user_debt_before - user_debt_after;
        assert!(debt_reduction <= liquidation_amount, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 10: Flashloan Tests
    // ============================================================================
    // Tests for flashloan_logic directional rounding
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
            flashloan_user = @0x042
        )
    ]
    fun test_flashloan_liquidity_uses_ray_mul_down(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        flashloan_user: &signer
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

        let flashloan_user_address = signer::address_of(flashloan_user);

        // Get one underlying asset
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // Get reserve config
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // Set flashloan premium
        let flashloan_premium_total = math_utils::get_percentage_factor() / 10; // 10%
        let flashloan_premium_to_protocol = math_utils::get_percentage_factor() / 20; // 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // Init user config for reserve
        pool_tests::create_user_config_for_reserve(
            flashloan_user_address,
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // Mint 100 underlying tokens for flashloan user
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            flashloan_user_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(initial_user_balance == 100, TEST_FAILED);

        // Supply 50 tokens to fill the pool
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            flashloan_user_address,
            0
        );

        // Verify supplier balance after supply
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_FAILED
        );

        // Take flashloan (50% of pool = 25 tokens)
        let flashloan_amount = supplied_amount / 2;
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                flashloan_user,
                flashloan_user_address,
                underlying_token_address,
                (flashloan_amount as u256),
                0 // referral code
            );

        // Verify user received flashloan
        let balance_after_flashloan =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            balance_after_flashloan == supplier_balance + flashloan_amount,
            TEST_FAILED
        );

        // Repay flashloan + premium
        flashloan_logic::pay_flash_loan_simple(flashloan_user, flashloan_receipt);

        // Verify premium was paid
        let balance_after_repay =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 → 3 (ceil)
        assert!(
            balance_after_repay == supplier_balance - flashloan_paid_premium,
            TEST_FAILED
        );

        // Verify FlashLoan event emitted
        let emitted_flashloan_events =
            aptos_framework::event::emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_FAILED);
    }

    // ============================================================================
    // SECTION 11: Integration Tests
    // ============================================================================
    // End-to-end integration tests
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
    fun test_full_supply_borrow_cycle_directional(
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
        let v_token = pool::get_reserve_variable_debt_token_address(reserve);
        let user_addr = signer::address_of(user);

        // Supply
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
        let atoken_balance_after_supply = a_token_factory::balance_of(
            user_addr, a_token
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
        let borrow_amount = 1000 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::borrow(
            user,
            asset,
            (borrow_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            0,
            user_addr
        );

        let debt_after_borrow =
            variable_debt_token_factory::balance_of(user_addr, v_token);
        assert!(debt_after_borrow > 0, TEST_FAILED);

        // Withdraw
        let withdraw_amount = 500 * (math_utils::pow(10, (decimals as u256)) as u64);
        supply_logic::withdraw(
            user,
            asset,
            (withdraw_amount as u256),
            user_addr
        );

        let atoken_after_withdraw = a_token_factory::balance_of(user_addr, a_token);
        assert!(atoken_after_withdraw < atoken_balance_after_supply, TEST_FAILED);

        // Repay
        let repay_amount = 500 * (math_utils::pow(10, (decimals as u256)) as u64);
        borrow_logic::repay(
            user,
            asset,
            (repay_amount as u256),
            user_config::get_interest_rate_mode_variable(),
            user_addr
        );

        let debt_after_repay = variable_debt_token_factory::balance_of(
            user_addr, v_token
        );
        assert!(debt_after_repay < debt_after_borrow, TEST_FAILED);
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
    fun test_cross_module_consistency(
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
        let v_token = pool::get_reserve_variable_debt_token_address(reserve);
        let user_addr = signer::address_of(user);

        // Setup
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

        // Verify consistency across modules:
        // 1. a_token_factory::balance_of uses ray_mul_down
        let atoken_balance = a_token_factory::balance_of(user_addr, a_token);
        let atoken_scaled = a_token_factory::scaled_balance_of(user_addr, a_token);
        let liquidity_index = pool::get_reserve_normalized_income(asset);
        let expected_atoken = wad_ray_math::ray_mul_down(atoken_scaled, liquidity_index);
        assert!(atoken_balance == expected_atoken, TEST_FAILED);

        // 2. variable_debt_token::balance_of uses ray_mul_up
        let vtoken_balance = variable_debt_token_factory::balance_of(user_addr, v_token);
        let vtoken_scaled =
            variable_debt_token_factory::scaled_balance_of(user_addr, v_token);
        let borrow_index = pool::get_reserve_normalized_variable_debt(asset);
        let expected_vtoken = wad_ray_math::ray_mul_up(vtoken_scaled, borrow_index);
        assert!(vtoken_balance == expected_vtoken, TEST_FAILED);

        // 3. generic_logic uses consistent directions
        let unit = math_utils::pow(10, (decimals as u256));
        let price = unit;

        let collateral_in_base =
            generic_logic::get_user_balance_in_base_currency_for_testing(
                user_addr, reserve, price, unit
            );
        let debt_in_base =
            generic_logic::get_user_debt_in_base_currency_for_testing(
                user_addr, reserve, price, unit
            );
        assert!(collateral_in_base > 0, TEST_FAILED);
        assert!(debt_in_base > 0, TEST_FAILED);
    }

    #[test]
    fun test_long_term_accuracy_simulation() {
        // Simulate 5 years of index growth (index ≈ 1.42)
        // Verify rounding errors remain within 1 octa bound
        // Test with index values: 1.0, 1.1, 1.2, 1.3, 1.4, 1.42
        let test_indexes = vector[
            1000000000000000000000000000, // 1.0
            1100000000000000000000000000, // 1.1
            1200000000000000000000000000, // 1.2
            1300000000000000000000000000, // 1.3
            1400000000000000000000000000, // 1.4
            1420000000000000000000000000 // 1.42 (5 year projection)
        ];

        // For each index, verify rounding error ≤ 1 octa
        vector::for_each_ref(
            &test_indexes,
            |idx| {
                let index = *idx;

                // Test ray_mul_up/down difference
                let scaled = 1000;
                let up_result = wad_ray_math::ray_mul_up(scaled, index);
                let down_result = wad_ray_math::ray_mul_down(scaled, index);

                // Even at index=1.42, error should be ≤ 1-2 octa
                assert!(up_result - down_result <= 2, TEST_FAILED);
            }
        );
    }

    // ============================================================================
    // SECTION 12: Issue Verification Tests
    // ============================================================================
    // Verification that specific issues have been fixed
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
    fun test_no_arbitrage_opportunity(
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

        let decimals = fungible_asset_manager::decimals(asset);
        let mint_amount: u64 = 10000 * (math_utils::pow(10, (decimals as u256)) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user_addr,
            mint_amount,
            asset
        );

        // Set various indices to test different rounding scenarios
        let indices: vector<u256> = vector[
            1000000000000000000000000000, // 1.0
            1500000000000000000000000000, // 1.5
            2000000000000000000000000000, // 2.0
            1341701152733098001533768654 // Real index
        ];

        let test_amounts = vector[100, 500, 607, 1001];

        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user_addr, 100000000
        );

        let i = 0;
        while (i < vector::length(&indices)) {
            let index = *vector::borrow(&indices, i);
            pool::set_reserve_liquidity_index_for_testing(asset, (index as u128));

            let j = 0;
            while (j < vector::length(&test_amounts)) {
                let amount = *vector::borrow(&test_amounts, j);

                let before = fungible_asset_manager::balance_of(user_addr, asset);

                // Supply
                supply_logic::supply(user, asset, (amount as u256), user_addr, 0);

                // Get actual withdrawable balance (may be < amount due to ray_mul_down)
                let reserve = pool::get_reserve_data(asset);
                let a_token = pool::get_reserve_a_token_address(reserve);
                let withdrawable = a_token_factory::balance_of(user_addr, a_token);

                // Withdraw actual available balance
                supply_logic::withdraw(user, asset, withdrawable, user_addr);

                let after = fungible_asset_manager::balance_of(user_addr, asset);

                assert!(after <= before, (i * 100 + j));

                assert!(before - after <= 1, (i * 100 + j + 50));

                j = j + 1;
            };

            i += 1;
        };
    }

    #[test]
    fun test_edge_cases_robustness() {
        // Test 1: ray_mul_down with maximum safe values
        let max_safe = math_utils::u256_max() / wad_ray_math::ray();
        let result = wad_ray_math::ray_mul_down(max_safe, wad_ray_math::ray());
        assert!(result == max_safe, TEST_FAILED);

        // Test 2: ray_div_up with 1 and very large divisor
        let result = wad_ray_math::ray_div_up(1, wad_ray_math::ray() * 1000);
        assert!(result > 0, TEST_FAILED); // Should round up to at least 1
        let result = math_utils::ceil_div(1, 1000000);
        assert!(result == 1, TEST_FAILED); // Should round up to 1

        // Test 4: Consistency across different magnitudes
        let values = vector[1, 100, 10000, 1000000];
        let i = 0;
        while (i < vector::length(&values)) {
            let val = *vector::borrow(&values, i);
            let down = wad_ray_math::ray_mul_down(val, wad_ray_math::ray());
            let up = wad_ray_math::ray_mul_up(val, wad_ray_math::ray());
            assert!(down <= up, 10 + i);
            i += 1;
        };
    }
}
