#[test_only]
module aave_pool::pool_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::string::utf8;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_config::reserve_config;
    use aave_pool::token_helper;

    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_pool::pool_logic;
    use aave_pool::variable_debt_token_factory;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_pool_cache(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let reserve_config =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let reserve_cache = pool_logic::cache(reserve_data);

        // test get
        assert!(
            pool_logic::get_reserve_cache_configuration(&reserve_cache)
                == reserve_config,
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_reserve_factor(&reserve_cache)
                == reserve_config::get_reserve_factor(&reserve_config),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_curr_liquidity_index(&reserve_cache)
                == (pool::get_reserve_liquidity_index(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_next_liquidity_index(&reserve_cache)
                == (pool::get_reserve_liquidity_index(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_curr_variable_borrow_index(&reserve_cache)
                == (pool::get_reserve_variable_borrow_index(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_next_variable_borrow_index(&reserve_cache)
                == (pool::get_reserve_variable_borrow_index(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_curr_liquidity_rate(&reserve_cache)
                == (pool::get_reserve_current_liquidity_rate(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_curr_variable_borrow_rate(&reserve_cache)
                == (pool::get_reserve_current_variable_borrow_rate(reserve_data) as u256),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_a_token_address(&reserve_cache)
                == pool::get_reserve_a_token_address(reserve_data),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_variable_debt_token_address(&reserve_cache)
                == pool::get_reserve_variable_debt_token_address(reserve_data),
            TEST_SUCCESS
        );

        let variable_debt_token_address =
            pool_logic::get_variable_debt_token_address(&reserve_cache);
        assert!(
            pool_logic::get_curr_scaled_variable_debt(&reserve_cache)
                == variable_debt_token_factory::scaled_total_supply(
                    variable_debt_token_address
                ),
            TEST_SUCCESS
        );

        assert!(
            pool_logic::get_next_scaled_variable_debt(&reserve_cache)
                == variable_debt_token_factory::scaled_total_supply(
                    variable_debt_token_address
                ),
            TEST_SUCCESS
        );

        // test set
        pool_logic::set_curr_liquidity_index(&mut reserve_cache, 100);
        assert!(
            pool_logic::get_curr_liquidity_index(&reserve_cache) == 100,
            TEST_SUCCESS
        );
        pool_logic::set_next_liquidity_index(&mut reserve_cache, 200);
        assert!(
            pool_logic::get_next_liquidity_index(&reserve_cache) == 200,
            TEST_SUCCESS
        );
        pool_logic::set_next_variable_borrow_index(&mut reserve_cache, 300);
        assert!(
            pool_logic::get_next_variable_borrow_index(&reserve_cache) == 300,
            TEST_SUCCESS
        );
        pool_logic::set_curr_liquidity_rate(&mut reserve_cache, 400);
        assert!(pool_logic::get_curr_liquidity_rate(&reserve_cache) == 400, TEST_SUCCESS);
        pool_logic::set_curr_variable_borrow_rate(&mut reserve_cache, 500);
        assert!(
            pool_logic::get_curr_variable_borrow_rate(&reserve_cache) == 500,
            TEST_SUCCESS
        );
        pool_logic::set_next_scaled_variable_debt(&mut reserve_cache, 600);
        assert!(
            pool_logic::get_next_scaled_variable_debt(&reserve_cache) == 600,
            TEST_SUCCESS
        );
    }
}
