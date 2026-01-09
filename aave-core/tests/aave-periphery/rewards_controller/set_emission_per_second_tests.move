#[test_only]
module aave_pool::set_emission_per_second_tests {
    use std::string::utf8;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aave_math::math_utils;
    use aave_pool::token_helper;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_oracle::oracle::Self;
    use aave_oracle::oracle_tests::Self;
    use aave_pool::rewards_controller::{
        set_emission_per_second,
        rewards_controller_address,
        add_asset,
        create_asset_data,
        initialize,
        get_rewards_data,
        create_rewards_config_input,
        enable_reward,
        create_reward_data,
        create_user_data,
        configure_assets
    };
    use aave_pool::rewards_controller_tests::{
        test_setup_with_one_asset,
        create_sample_pull_rewards_transfer_strategy
    };

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_set_emission_per_second(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (asset, reward, controller_address) =
            test_setup_with_one_asset(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                underlying_tokens_admin,
                periphery_account,
                user,
                aave_oracle,
                data_feeds,
                platform
            );

        set_emission_per_second(
            asset,
            vector[reward],
            vector[1],
            controller_address
        );

        let (
            index, emission_per_second, last_update_timestamp, distribution_end
        ) = get_rewards_data(asset, reward, controller_address);
        assert!(index == 0, TEST_SUCCESS);
        assert!(emission_per_second == 1, TEST_SUCCESS);
        assert!(last_update_timestamp == 1, TEST_SUCCESS);
        assert!(distribution_end == 0, TEST_SUCCESS);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3005, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_with_invalid_reward_config(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (asset, reward, controller_address) =
            test_setup_with_one_asset(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                underlying_tokens_admin,
                periphery_account,
                user,
                aave_oracle,
                data_feeds,
                platform
            );

        set_emission_per_second(
            asset,
            vector[reward],
            vector[1, 2],
            controller_address
        )
    }

    #[test(periphery_account = @aave_pool, asset = @0x222, reward = @0x333)]
    #[expected_failure(abort_code = 3006, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_asset_not_exist(
        periphery_account: &signer, asset: address, reward: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let new_emission_per_second = 1;

        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        )
    }

    #[test(periphery_account = @aave_pool, asset = @0x222, reward = @0x333)]
    #[expected_failure(abort_code = 3006, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_when_reward_not_exist(
        periphery_account: &signer, asset: address, reward: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let new_emission_per_second = 1;

        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 0)
        );

        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        )
    }

    #[
        test(
            pool_admin = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            reward = @0x333,
            user = @0x444,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3006, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_when_decimals_is_zero_or_last_update_timestamp_is_zero(
        pool_admin: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        reward: address,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aave_std);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        token_helper::init_reserves_with_oracle(
            pool_admin,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );

        let asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let index = 1;
        let accrued = 2;
        let users_map = simple_map::new();
        let user_data = create_user_data(index, accrued);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 200000;
        let distribution_end = 2;

        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                0,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let new_emission_per_second = 1;
        // reward exists, but decimals is zero or last_update_timestamp is zero
        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        )
    }

    #[
        test(
            pool_admin = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            reward = @0x333,
            user = @0x444,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3004, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_when_reward_index_overflow(
        pool_admin: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        reward: address,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aave_std);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        token_helper::init_reserves_with_oracle(
            pool_admin,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );

        let asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let index = 1;
        let accrued = 2;
        let users_map = simple_map::new();
        let user_data = create_user_data(index, accrued);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);
        let asset_data = create_asset_data(rewards_map, simple_map::new(), 1, 8);
        add_asset(rewards_controller_address, asset, asset_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 200000;
        let distribution_end = 20;

        let rewards_config_input =
            create_rewards_config_input(
                (emission_per_second as u128),
                max_emission_rate,
                0,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        timestamp::fast_forward_seconds(10);
        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let new_emission_per_second = 1;
        // reward exists, but decimals is zero or last_update_timestamp is zero
        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        );

        let emission_per_second = 2;
        let max_emission_rate = 200000;
        let distribution_end = 20;

        let rewards_config_input =
            create_rewards_config_input(
                (emission_per_second as u128),
                max_emission_rate,
                0,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        // mint some tokens
        mock_underlying_token_factory::mint(underlying_tokens_admin, user, 1000, asset);

        timestamp::fast_forward_seconds(100);
        let new_emission_per_second = 1;
        // reward exists, but decimals is zero or last_update_timestamp is zero
        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        );

        let emission_per_second = math_utils::pow(2, 104);
        let max_emission_rate = math_utils::pow(2, 127);
        let distribution_end = 200;

        let rewards_config_input =
            create_rewards_config_input(
                (emission_per_second as u128),
                (max_emission_rate as u128),
                0,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        // mint some tokens
        mock_underlying_token_factory::mint(underlying_tokens_admin, user, 1000, asset);

        timestamp::fast_forward_seconds(100);
        let new_emission_per_second = 1;
        // reward exists, but decimals is zero or last_update_timestamp is zero
        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        )
    }

    #[test]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_when_rewards_controller_address_not_exist() {
        set_emission_per_second(@0x31, vector[@0x32, @0x33], vector[1, 2], @0x34);
    }

    #[
        test(
            pool_admin = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            reward = @0x333,
            user = @0x444,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3025, location = aave_pool::rewards_controller)]
    fun test_set_emission_per_second_with_invalid_emission_rate(
        pool_admin: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        reward: address,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aave_std);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        token_helper::init_reserves_with_oracle(
            pool_admin,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );

        let asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let index = 1;
        let accrued = 2;
        let users_map = simple_map::new();
        let user_data = create_user_data(index, accrued);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);
        let asset_data = create_asset_data(rewards_map, simple_map::new(), 1, 8);
        add_asset(rewards_controller_address, asset, asset_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 200000;
        let distribution_end = 20;

        let rewards_config_input =
            create_rewards_config_input(
                (emission_per_second as u128),
                max_emission_rate,
                0,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        timestamp::fast_forward_seconds(10);
        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let new_emission_per_second = max_emission_rate + 1;
        // reward exists, but decimals is zero or last_update_timestamp is zero
        set_emission_per_second(
            asset,
            vector[reward],
            vector[new_emission_per_second],
            rewards_controller_address
        );
    }
}
