#[test_only]
module aave_pool::ui_incentive_data_provider_v3_tests {
    use std::option;
    use std::signer;
    use std::string;
    use std::string::utf8;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_pool::token_helper;
    use aave_pool::ui_incentive_data_provider_v3::{
        get_reserves_incentives_data,
        get_user_reserves_incentives_data
    };
    use aave_pool::pool_token_logic;
    use aave_oracle::oracle;
    use aave_oracle::oracle_tests;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::token_base;
    use aave_pool::rewards_controller;
    use aave_pool::pool;
    use aave_pool::a_token_factory;
    use aave_pool::ui_incentive_data_provider_v3;

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER";
    const TEST_FEED_ID: vector<u8> = x"0003fbba4fce42f65d6032b18aee53efdf526cc734ad296cb57565979d883bdd";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            underlying_tokens = @aave_mock_underlyings,
            aave_oracle = @aave_oracle,
            publisher = @data_feeds,
            platform = @platform,
            aave_std = @std
        )
    ]
    fun test_get_full_reserves_incentive_data(
        aave_pool: &signer,
        aave_acl: &signer,
        underlying_tokens: &signer,
        aave_oracle: &signer,
        publisher: &signer,
        platform: &signer,
        aave_std: &signer
    ) {
        account::create_account_for_test(signer::address_of(aave_pool));

        set_time_has_started_for_testing(aave_std);

        // init acl
        acl_manage::test_init_module(aave_acl);

        let role_admin = acl_manage::get_pool_admin_role();
        acl_manage::grant_role(
            aave_acl,
            acl_manage::get_pool_admin_role_for_testing(),
            signer::address_of(aave_pool)
        );
        acl_manage::grant_role(
            aave_acl,
            acl_manage::get_pool_admin_role_for_testing(),
            signer::address_of(aave_acl)
        );
        acl_manage::set_role_admin(
            aave_acl,
            acl_manage::get_pool_admin_role_for_testing(),
            role_admin
        );
        aave_acl::acl_manage::add_pool_admin(
            aave_acl, signer::address_of(underlying_tokens)
        );

        // init the rate module - default strategy
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        // init underlyings token factory
        mock_underlying_token_factory::test_init_module(underlying_tokens);

        // init the oracle module
        aave_oracle::oracle_tests::config_oracle(aave_oracle, publisher, platform);

        // init the APT fa
        token_helper::init_wrapped_apt_fa(aave_std, aave_pool);

        // init tokens base
        token_base::test_init_module(aave_pool);

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init rewards controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);
        let rewards_addr =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        // create two mock tokens as underlying tokens
        let decimals = 6;
        let max_supply = 10000;

        let name1 = string::utf8(b"UNDERLYING_1");
        let symbol1 = string::utf8(b"U_1");
        mock_underlying_token_factory::create_token(
            underlying_tokens,
            max_supply,
            name1,
            symbol1,
            decimals,
            string::utf8(b""),
            string::utf8(b"")
        );
        let underlying_token1_address =
            mock_underlying_token_factory::token_address(symbol1);

        // set price feed to the underlying token 1
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_token1_address, test_feed_id);

        let name2 = string::utf8(b"UNDERLYING_2");
        let symbol2 = string::utf8(b"U_2");
        mock_underlying_token_factory::create_token(
            underlying_tokens,
            max_supply,
            name2,
            symbol2,
            decimals,
            string::utf8(b""),
            string::utf8(b"")
        );
        let underlying_token2_address =
            mock_underlying_token_factory::token_address(symbol2);

        // set price feed to the underlying token 2
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_token2_address, test_feed_id);

        // init the pool
        pool::test_init_pool(aave_pool);

        // set reserve interest rate using the pool admin
        let optimal_usage_ratio: u256 = 200;
        let base_variable_borrow_rate: u256 = 0;
        let variable_rate_slope1: u256 = 0;
        let variable_rate_slope2: u256 = 0;
        default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy_for_testing(
            underlying_token1_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
        default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy_for_testing(
            underlying_token2_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        // create reserves using the pool admin
        let a_token1_symbol = string_utils::format1(&b"a{}", symbol1);
        let variable_debt_token1_symbol = string_utils::format1(&b"vd{}", symbol1);
        pool_token_logic::test_init_reserve(
            aave_pool,
            underlying_token1_address,
            // TODO(mengxu): ideally should be an isolated treasury account
            signer::address_of(aave_pool),
            option::some(rewards_addr),
            string_utils::format1(&b"a{}", name1),
            a_token1_symbol,
            string_utils::format1(&b"vd{}", name1),
            variable_debt_token1_symbol,
            400,
            100,
            200,
            300
        );
        let a_token1_address = a_token_factory::token_address(a_token1_symbol);
        let variable_debt_token1_address =
            variable_debt_token_factory::token_address(variable_debt_token1_symbol);

        let a_token2_symbol = string_utils::format1(&b"a{}", symbol2);
        let variable_debt_token2_symbol = string_utils::format1(&b"vd{}", symbol2);
        pool_token_logic::test_init_reserve(
            aave_pool,
            underlying_token2_address,
            // TODO(mengxu): ideally should be an isolated treasury account
            signer::address_of(aave_pool),
            option::some(rewards_addr),
            string_utils::format1(&b"a{}", name2),
            a_token2_symbol,
            string_utils::format1(&b"vd{}", name2),
            variable_debt_token2_symbol,
            400,
            100,
            200,
            300
        );

        // configure the rewards controller
        // TODO(mengxu): the test setup should not be done in this raw way, this
        // part of testing will have to be refactored, again.
        let rewards_map = simple_map::new();
        simple_map::upsert(
            &mut rewards_map,
            underlying_token1_address,
            rewards_controller::create_reward_data(0, 0, 0, 1, 0, simple_map::new())
        );
        simple_map::upsert(
            &mut rewards_map,
            underlying_token2_address,
            rewards_controller::create_reward_data(0, 0, 0, 1, 0, simple_map::new())
        );

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, underlying_token1_address);
        simple_map::upsert(&mut available_rewards, 1, underlying_token2_address);

        rewards_controller::add_asset(
            rewards_addr,
            a_token1_address,
            rewards_controller::create_asset_data(
                rewards_map,
                available_rewards,
                2,
                decimals
            )
        );

        rewards_controller::add_asset(
            rewards_addr,
            variable_debt_token1_address,
            rewards_controller::create_asset_data(
                rewards_map,
                available_rewards,
                2,
                decimals
            )
        );

        rewards_controller::enable_reward(rewards_addr, underlying_token1_address);
        rewards_controller::enable_reward(rewards_addr, underlying_token2_address);

        let user_data = rewards_controller::create_user_data(0, 0);
        rewards_controller::add_user_asset_index(
            rewards_addr,
            a_token1_address,
            underlying_token1_address,
            rewards_addr,
            user_data
        );
        rewards_controller::add_user_asset_index(
            rewards_addr,
            variable_debt_token1_address,
            underlying_token2_address,
            rewards_addr,
            user_data
        );

        let (reserves_incentives_data, _user_reserves_incentives_data) =
            ui_incentive_data_provider_v3::get_full_reserves_incentive_data(rewards_addr);
        assert!(vector::length(&reserves_incentives_data) != 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_reserves_incentives_data(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);

        account::create_account_for_test(signer::address_of(aave_pool));

        // init reserves
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // case1: no incentives controller
        let aggregated_reserve_incentive_data = get_reserves_incentives_data();
        assert!(vector::length(&aggregated_reserve_incentive_data) == 3, TEST_SUCCESS);

        // case2: incentives controller is set
        let underlying_token1_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to the underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_token1_address, test_feed_id);

        let reserve_data = pool::get_reserve_data(underlying_token1_address);

        // set aToken and variable debt incentives controller
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let u1_vd_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        pool_token_logic::set_incentives_controller(
            aave_pool,
            underlying_token1_address,
            option::some(
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            )
        );

        // init rewards controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        let rewards_map = simple_map::new();
        simple_map::upsert(
            &mut rewards_map,
            underlying_token1_address,
            rewards_controller::create_reward_data(0, 0, 0, 1, 0, simple_map::new())
        );

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, underlying_token1_address);

        rewards_controller::add_asset(
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            u1_a_token_address,
            rewards_controller::create_asset_data(rewards_map, available_rewards, 1, 6)
        );

        let rewards_controller_addresses =
            rewards_controller::get_rewards_by_asset(
                u1_a_token_address,
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            );

        assert!(
            vector::length(&rewards_controller_addresses)
                == simple_map::length(&available_rewards),
            TEST_SUCCESS
        );

        rewards_controller::add_asset(
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            u1_vd_token_address,
            rewards_controller::create_asset_data(rewards_map, available_rewards, 1, 6)
        );

        let rewards_controller_addresses =
            rewards_controller::get_rewards_by_asset(
                u1_vd_token_address,
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            );

        assert!(
            vector::length(&rewards_controller_addresses)
                == simple_map::length(&available_rewards),
            TEST_SUCCESS
        );

        let aggregated_reserve_incentive_data = get_reserves_incentives_data();
        assert!(vector::length(&aggregated_reserve_incentive_data) == 3, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user = @0x31,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_user_reserves_incentives_data(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);

        let user_address = signer::address_of(user);
        account::create_account_for_test(signer::address_of(aave_pool));
        account::create_account_for_test(user_address);

        // init reserves
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // case1: no incentives controller
        let user_reserve_incentive_datas =
            get_user_reserves_incentives_data(user_address);
        assert!(vector::length(&user_reserve_incentive_datas) == 3, TEST_SUCCESS);

        // case2: incentives controller is set
        let underlying_token1_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to the underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_token1_address, test_feed_id);

        let reserve_data = pool::get_reserve_data(underlying_token1_address);

        // set aToken and var debt token incentives controller
        let u1_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let u1_vd_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        pool_token_logic::set_incentives_controller(
            aave_pool,
            underlying_token1_address,
            option::some(
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            )
        );

        // init rewards controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        let rewards_map = simple_map::new();
        simple_map::upsert(
            &mut rewards_map,
            underlying_token1_address,
            rewards_controller::create_reward_data(0, 0, 0, 1, 0, simple_map::new())
        );

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, underlying_token1_address);

        rewards_controller::add_asset(
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            u1_a_token_address,
            rewards_controller::create_asset_data(rewards_map, available_rewards, 1, 6)
        );

        let rewards_controller_addresses =
            rewards_controller::get_rewards_by_asset(
                u1_a_token_address,
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            );

        assert!(
            vector::length(&rewards_controller_addresses)
                == simple_map::length(&available_rewards),
            TEST_SUCCESS
        );

        rewards_controller::add_asset(
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            u1_vd_token_address,
            rewards_controller::create_asset_data(rewards_map, available_rewards, 1, 6)
        );

        let rewards_controller_addresses =
            rewards_controller::get_rewards_by_asset(
                u1_vd_token_address,
                rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME)
            );

        assert!(
            vector::length(&rewards_controller_addresses)
                == simple_map::length(&available_rewards),
            TEST_SUCCESS
        );

        // add user asset index
        let user_data = rewards_controller::create_user_data(1, 0);
        rewards_controller::add_user_asset_index(
            user_address,
            u1_a_token_address,
            underlying_token1_address,
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            user_data
        );
        rewards_controller::add_user_asset_index(
            user_address,
            u1_vd_token_address,
            underlying_token1_address,
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME),
            user_data
        );

        let user_reserve_incentive_datas =
            get_user_reserves_incentives_data(user_address);
        assert!(vector::length(&user_reserve_incentive_datas) == 3, TEST_SUCCESS);
    }
}
