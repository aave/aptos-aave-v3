#[test_only]
module aave_pool::rewards_controller_tests {
    use std::option;
    use std::signer;
    use std::string;
    use std::string::utf8;
    use std::vector;

    use aptos_std::string_utils;
    use aptos_std::simple_map;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::object;
    use aptos_framework::object::Object;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage;
    use aave_math::math_utils;
    use aave_pool::token_helper;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::token_base;
    use aave_pool::a_token_factory;
    use aave_pool::transfer_strategy;
    use aave_oracle::oracle::Self;
    use aave_oracle::oracle_tests::Self;
    use aave_pool::transfer_strategy::PullRewardsTransferStrategy;
    use aave_pool::rewards_controller::{
        initialize,
        create_rewards_config_input,
        get_rewards_list,
        get_asset_decimals,
        add_asset,
        enable_reward,
        create_asset_data,
        create_reward_data,
        create_user_data,
        configure_assets,
        get_user_rewards,
        get_all_user_rewards,
        rewards_controller_object,
        rewards_controller_address,
        get_asset_index,
        set_claimer,
        get_claimer,
        handle_action,
        RewardsControllerData,
        get_rewards_data,
        lookup_asset_data,
        lookup_rewards_data,
        lookup_user_data,
        add_user_asset_index,
        get_user_data,
        get_user_accrued_rewards,
        ClaimerSet
    };

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(periphery_account = @aave_pool)]
    fun test_initialize(periphery_account: &signer) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
    }

    public fun create_sample_pull_rewards_transfer_strategy(
        periphery_account: &signer
    ): Object<PullRewardsTransferStrategy> {
        let rewards_controller = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let periphery_address = signer::address_of(periphery_account);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );

        let constructor_ref = object::create_sticky_object(periphery_address);
        transfer_strategy::test_create_pull_rewards_transfer_strategy(
            periphery_account,
            &constructor_ref,
            periphery_address,
            rewards_controller,
            rewards_vault
        )
    }

    public fun test_setup(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ): (
        address, address, address, Object<PullRewardsTransferStrategy>
    ) {
        // init on aave-core
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_rewards_controller_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        token_base::test_init_module(pool_admin);
        a_token_factory::test_init_module(pool_admin);
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);

        // initialize the rewards controller
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        // create the underlying token
        let decimals = 6;
        let underlying_token_name = string::utf8(b"TOKEN_1");
        let underlying_token_symbol = string::utf8(b"T1");

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            10000,
            underlying_token_name,
            underlying_token_symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b"")
        );
        let underlying_asset =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        // pre-mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_controller_address,
            100,
            underlying_asset
        );

        // create an AToken
        let atoken_name = string_utils::format1(&b"A_{}", underlying_token_name);
        let atoken_symbol = string_utils::format1(&b"A_{}", underlying_token_symbol);

        a_token_factory::create_token(
            pool_admin,
            atoken_name,
            atoken_symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b""),
            option::some(rewards_controller_address),
            underlying_asset,
            // TODO(mengxu): ideally should be an isolated treasury account
            signer::address_of(pool_admin)
        );
        let atoken_asset = a_token_factory::token_address(atoken_symbol);

        // setup the pair that makes the tests happy
        // TODO(mengxu): I don't think that the `(asset, reward)` pair should be
        // `(a_token, underlying_token)`, but this is the only way at this stage
        // to make the tests happy, so using it as a hack for now.
        let asset = atoken_asset;
        let reward = underlying_asset;

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        // enable this asset as rewards
        let index = 0;
        let emission_per_second = 0;
        let max_emission_rate = 100000;
        let last_update_timestamp = 1;
        let distribution_end = 0;

        let user_data = create_user_data(index, 0);

        let users_map = simple_map::new();
        simple_map::add(&mut users_map, user, user_data);
        let reward_data =
            create_reward_data(
                index,
                emission_per_second,
                max_emission_rate,
                last_update_timestamp,
                distribution_end,
                users_map
            );

        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);
        let asset_data = create_asset_data(rewards_map, simple_map::new(), 0, decimals);

        add_asset(rewards_controller_address, asset, asset_data);
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

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

        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);

        // finally configure the assets
        configure_assets(configs, rewards_controller_address);

        // return the asset, reward, and controller address triple
        (
            asset,
            reward,
            rewards_controller_address,
            pull_rewards_transfer_strategy
        )
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_rewards_list(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        let rewards_addr = @0x33;
        let rewards_list = get_rewards_list(rewards_addr);
        assert!(rewards_list == vector[], TEST_SUCCESS);

        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let rewards_list = get_rewards_list(rewards_addr);
        assert!(rewards_list == vector[], TEST_SUCCESS);

        let users_map = simple_map::new();
        let user_data = create_user_data(1, 3);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_addr, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 10000;
        let distribution_end = 2;
        let total_supply = 100;
        let asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                total_supply,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_addr);

        let rewards_list = get_rewards_list(rewards_addr);
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
    }

    public fun test_setup_with_one_asset(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ): (address, address, address) {
        // init on aave-core
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_rewards_controller_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        token_base::test_init_module(pool_admin);
        a_token_factory::test_init_module(pool_admin);
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);

        // initialize the rewards controller
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        // create the underlying token
        let decimals = 6;
        let underlying_token_name = string::utf8(b"TOKEN_1");
        let underlying_token_symbol = string::utf8(b"T1");

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            10000,
            underlying_token_name,
            underlying_token_symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b"")
        );
        let underlying_asset =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        // pre-mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_controller_address,
            100,
            underlying_asset
        );

        // create an AToken
        let atoken_name = string_utils::format1(&b"A_{}", underlying_token_name);
        let atoken_symbol = string_utils::format1(&b"A_{}", underlying_token_symbol);

        a_token_factory::create_token(
            pool_admin,
            atoken_name,
            atoken_symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b""),
            option::some(rewards_controller_address),
            underlying_asset,
            // TODO(mengxu): ideally should be an isolated treasury account
            signer::address_of(pool_admin)
        );
        let atoken_asset = a_token_factory::token_address(atoken_symbol);

        // setup the pair that makes the tests happy
        // TODO(mengxu): I don't think that the `(asset, reward)` pair should be
        // `(a_token, underlying_token)`, but this is the only way at this stage
        // to make the tests happy, so using it as a hack for now.
        let asset = atoken_asset;
        let reward = underlying_asset;

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        // enable this asset as rewards
        let index = 0;
        let emission_per_second = 0;
        let max_emission_rate = 100000;
        let last_update_timestamp = 1;
        let distribution_end = 0;

        let user_data = create_user_data(index, 0);

        let users_map = simple_map::new();
        simple_map::add(&mut users_map, user, user_data);
        let reward_data =
            create_reward_data(
                index,
                emission_per_second,
                max_emission_rate,
                last_update_timestamp,
                distribution_end,
                users_map
            );

        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);
        let asset_data = create_asset_data(rewards_map, simple_map::new(), 0, decimals);

        add_asset(rewards_controller_address, asset, asset_data);
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

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

        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);

        // finally configure the assets
        configure_assets(configs, rewards_controller_address);

        // return the asset, reward, and controller address triple
        (asset, reward, rewards_controller_address)
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_asset_index(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (old_index, next_index) =
            get_asset_index(asset, reward, rewards_controller_address);
        assert!(old_index == 0, TEST_SUCCESS);
        assert!(next_index == 0, TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (old_index, next_index) =
            get_asset_index(asset, reward, rewards_controller_address);
        assert!(old_index == 0, TEST_SUCCESS);
        assert!(next_index == 0, TEST_SUCCESS);

        let decimals = mock_underlying_token_factory::decimals(asset);
        // case3: asset exist but reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(
                simple_map::new(),
                simple_map::new(),
                0,
                decimals
            )
        );
        let (old_index, next_index) =
            get_asset_index(asset, reward, rewards_controller_address);
        assert!(old_index == 0, TEST_SUCCESS);
        assert!(next_index == 0, TEST_SUCCESS);

        // case4: asset and reward exists
        let users_map = simple_map::new();
        let user_data = create_user_data(1, 3);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 10000;
        let distribution_end = 2;
        let total_supply = 100;

        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                total_supply,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user,
            (total_supply as u64),
            asset
        );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        timestamp::fast_forward_seconds(1);

        let (old_index, next_index) =
            get_asset_index(asset, reward, rewards_controller_address);
        assert!(old_index == 0, TEST_SUCCESS);

        let current_timestamp = timestamp::now_seconds();
        let time_delta = ((current_timestamp - 1) as u256);
        let first_term =
            (emission_per_second as u256) * time_delta
                * math_utils::pow(10, (decimals as u256));
        first_term = first_term / total_supply;
        assert!(
            next_index == first_term + old_index, TEST_SUCCESS
        );

        timestamp::fast_forward_seconds(10);

        let (old_index, next_index) =
            get_asset_index(asset, reward, rewards_controller_address);

        let time_delta = ((distribution_end - 1) as u256);
        let first_term =
            (emission_per_second as u256) * time_delta
                * math_utils::pow(10, (decimals as u256));
        first_term = first_term / total_supply;
        assert!(
            next_index == first_term + old_index, TEST_SUCCESS
        );
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
    fun test_get_asset_decimals(
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
        let (asset, _reward, controller_address) =
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

        let decimals = get_asset_decimals(asset, controller_address);
        assert!(decimals == a_token_factory::decimals(asset), TEST_SUCCESS);
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
    fun test_of_handle_action(
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
        let (asset, _reward, controller_address) =
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

        handle_action(asset, user, 0, 0, controller_address)
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_user_rewards(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let unclaimed_rewards =
            get_user_rewards(
                vector[asset],
                user,
                reward,
                rewards_controller_address
            );
        assert!(unclaimed_rewards == 0, TEST_SUCCESS);

        // case2: rewards_controller_address exist
        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let users_map = simple_map::new();
        let index = 1;
        let accrued = 3;
        let user_data = create_user_data(index, accrued);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_addr, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 10000;
        let distribution_end = 2;
        let total_supply = 100;
        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                total_supply,
                distribution_end,
                asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_addr);

        let u2_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let u3_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        let unclaimed_rewards =
            get_user_rewards(
                vector[asset, u2_underlying_tokens, u3_underlying_tokens],
                user,
                reward,
                rewards_addr
            );
        assert!(unclaimed_rewards == 0, TEST_SUCCESS);

        // asset exist but user not exist
        add_asset(
            rewards_addr,
            u3_underlying_tokens,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 6)
        );
        let unclaimed_rewards =
            get_user_rewards(
                vector[asset, u2_underlying_tokens, u3_underlying_tokens],
                user,
                reward,
                rewards_addr
            );
        assert!(unclaimed_rewards == 0, TEST_SUCCESS);

        // asset and user exist but reward not exist
        add_user_asset_index(user, asset, reward, rewards_addr, user_data);
        timestamp::fast_forward_seconds(10);

        // user balance is 0
        let unclaimed_rewards =
            get_user_rewards(
                vector[asset, u2_underlying_tokens, u3_underlying_tokens],
                user,
                reward,
                rewards_addr
            );
        assert!(unclaimed_rewards == (accrued as u256), TEST_SUCCESS);

        // user balance gt 0
        // mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user,
            (total_supply as u64),
            asset
        );

        let unclaimed_rewards =
            get_user_rewards(
                vector[asset, u2_underlying_tokens, u3_underlying_tokens],
                user,
                reward,
                rewards_addr
            );
        assert!(unclaimed_rewards == (accrued as u256), TEST_SUCCESS);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_all_user_rewards(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aptos_framework);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // init reserves
        token_helper::init_reserves_with_oracle(
            pool_admin,
            aave_role_super_admin,
            aptos_framework,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            periphery_account
        );
        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to both asset and underlying tokens
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_asset, test_feed_id);
        oracle::test_set_asset_feed_id(reward, test_feed_id);

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (rewards_list, unclaimed_amounts) =
            get_all_user_rewards(
                vector[underlying_asset], user, rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 0, TEST_SUCCESS);
        assert!(vector::length(&unclaimed_amounts) == 0, TEST_SUCCESS);

        // case2: rewards_controller_address exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let users_map = simple_map::new();
        let user_data = create_user_data(1, 3);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1;
        let max_emission_rate = 10000;
        let distribution_end = 2;
        let total_supply = 100;
        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                total_supply,
                distribution_end,
                underlying_asset,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let u2_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let (rewards_list, unclaimed_amounts) =
            get_all_user_rewards(
                vector[underlying_asset, u2_underlying_tokens],
                user,
                rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(vector::length(&unclaimed_amounts) == 1, TEST_SUCCESS);

        // case3: reward and user exist
        add_user_asset_index(
            user,
            underlying_asset,
            reward,
            rewards_controller_address,
            user_data
        );
        timestamp::fast_forward_seconds(10);

        let (rewards_list, unclaimed_amounts) =
            get_all_user_rewards(
                vector[underlying_asset], user, rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&rewards_list, 0) == reward, TEST_SUCCESS);
        assert!(vector::length(&unclaimed_amounts) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&unclaimed_amounts, 0) == 3, TEST_SUCCESS);

        // case4: user balance gt 0
        // mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user,
            (total_supply as u64),
            underlying_asset
        );

        let (rewards_list, unclaimed_amounts) =
            get_all_user_rewards(
                vector[underlying_asset], user, rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&rewards_list, 0) == reward, TEST_SUCCESS);
        assert!(vector::length(&unclaimed_amounts) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&unclaimed_amounts, 0) == 4, TEST_SUCCESS);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            claimer = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_set_claimer(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        claimer: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (_asset, _reward, controller_address) =
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

        set_claimer(user, claimer, controller_address);

        assert!(
            get_claimer(user, controller_address) == option::some(claimer),
            TEST_SUCCESS
        );

        // check ClaimerSet emitted events
        let emitted_events = emitted_events<ClaimerSet>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            claimer = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_claimer(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: address,
        claimer: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        // no initialize
        assert!(option::is_none(&get_claimer(user, @0x31)), TEST_SUCCESS);

        let (_asset, _reward, controller_address) =
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

        // no set claimer
        assert!(option::is_none(&get_claimer(user, controller_address)), TEST_SUCCESS);

        // set claimer
        set_claimer(user, claimer, controller_address);
        assert!(
            option::destroy_some(get_claimer(user, controller_address)) == claimer,
            TEST_SUCCESS
        );
    }

    #[test(periphery_account = @aave_pool)]
    fun test_rewards_controller_object(periphery_account: &signer) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        assert!(
            rewards_controller_object(REWARDS_CONTROLLER_NAME)
                == object::address_to_object<RewardsControllerData>(
                    rewards_controller_address(REWARDS_CONTROLLER_NAME)
                ),
            TEST_SUCCESS
        );
    }

    #[test(periphery_account = @aave_pool, asset = @0xfa)]
    fun test_lookup_asset_data(
        periphery_account: &signer, asset: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let asset_datas = lookup_asset_data(asset, rewards_controller_address);
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let asset_datas = lookup_asset_data(asset, rewards_controller_address);
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);

        // case3: asset exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );
        let asset_datas = lookup_asset_data(asset, rewards_controller_address);
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_lookup_rewards_data(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (asset_datas, reward_datas) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (asset_datas, reward_datas) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);

        // case3: asset exist but reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );
        let (asset_datas, reward_datas) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);

        // case4: asset and reward exists
        let users_map = simple_map::new();
        let user_data = create_user_data(0, 0);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 0;
        let max_emission_rate = 0;
        let distribution_end = 0;

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

        let (asset_datas, reward_datas) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
        assert!(option::is_some(&reward_datas), TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_lookup_user_data(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (asset_datas, reward_datas, user_datas) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);
        assert!(option::is_none(&user_datas), TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (asset_datas, reward_datas, user_datas) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(option::is_none(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);
        assert!(option::is_none(&user_datas), TEST_SUCCESS);

        // case3: asset exist but reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );
        let (asset_datas, reward_datas, user_datas) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
        assert!(option::is_none(&reward_datas), TEST_SUCCESS);
        assert!(option::is_none(&user_datas), TEST_SUCCESS);

        // case4: asset and reward exists, but user not exist
        let users_map = simple_map::new();
        let user_data = create_user_data(0, 0);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 0;
        let max_emission_rate = 0;
        let distribution_end = 0;

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

        let (asset_datas, reward_datas, user_datas) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
        assert!(option::is_some(&reward_datas), TEST_SUCCESS);
        assert!(option::is_none(&user_datas), TEST_SUCCESS);

        // case5: asset and reward and user exists
        add_user_asset_index(
            user,
            asset,
            reward,
            rewards_controller_address,
            user_data
        );

        let (asset_datas, reward_datas, user_datas) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(option::is_some(&asset_datas), TEST_SUCCESS);
        assert!(option::is_some(&reward_datas), TEST_SUCCESS);
        assert!(option::is_some(&user_datas), TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_rewards_data(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);
        assert!(index_after == 0, TEST_SUCCESS);
        assert!(emission_per_second_after == 0, TEST_SUCCESS);
        assert!(last_update_timestamp_after == 0, TEST_SUCCESS);
        assert!(distribution_end_after == 0, TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);
        assert!(index_after == 0, TEST_SUCCESS);
        assert!(emission_per_second_after == 0, TEST_SUCCESS);
        assert!(last_update_timestamp_after == 0, TEST_SUCCESS);
        assert!(distribution_end_after == 0, TEST_SUCCESS);

        // case3: asset exist but reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );
        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);
        assert!(index_after == 0, TEST_SUCCESS);
        assert!(emission_per_second_after == 0, TEST_SUCCESS);
        assert!(last_update_timestamp_after == 0, TEST_SUCCESS);
        assert!(distribution_end_after == 0, TEST_SUCCESS);

        // case4: asset and reward exists
        let users_map = simple_map::new();
        let user_data = create_user_data(0, 0);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);
        assert!(index_after == 0, TEST_SUCCESS);
        assert!(emission_per_second_after == 0, TEST_SUCCESS);
        assert!(last_update_timestamp_after == 0, TEST_SUCCESS);
        assert!(distribution_end_after == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_user_data(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let (index, accrued) =
            get_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(index == 0, TEST_SUCCESS);
        assert!(accrued == 0, TEST_SUCCESS);

        // case2: asset not exist
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let (index, accrued) =
            get_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(index == 0, TEST_SUCCESS);
        assert!(accrued == 0, TEST_SUCCESS);

        // case3: asset exist but reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );
        let (index, accrued) =
            get_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(index == 0, TEST_SUCCESS);
        assert!(accrued == 0, TEST_SUCCESS);

        // case4: asset and reward exists, but user not exist
        let users_map = simple_map::new();
        let user_data = create_user_data(1, 2);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 4, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);

        // enable reward
        enable_reward(rewards_controller_address, reward);

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 0;
        let max_emission_rate = 0;
        let distribution_end = 0;

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

        let (index, accrued) =
            get_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(index == 0, TEST_SUCCESS);
        assert!(accrued == 0, TEST_SUCCESS);

        // case5: asset and reward and user exists
        add_user_asset_index(
            user,
            asset,
            reward,
            rewards_controller_address,
            user_data
        );

        let (index, accrued) =
            get_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        assert!(index == 1, TEST_SUCCESS);
        assert!(accrued == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            reward = @0xfa,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_user_accrued_rewards(
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        set_time_has_started_for_testing(aave_std);
        timestamp::fast_forward_seconds(1);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // create token
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

        // case1: rewards_controller_address not exist
        let rewards_controller_address = @0x33;
        let total_accrued =
            get_user_accrued_rewards(user, reward, rewards_controller_address);
        assert!(total_accrued == 0, TEST_SUCCESS);

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        // case2: reward not exist
        add_asset(
            rewards_controller_address,
            asset,
            create_asset_data(simple_map::new(), simple_map::new(), 0, 8)
        );

        let total_accrued =
            get_user_accrued_rewards(user, reward, rewards_controller_address);
        assert!(total_accrued == 0, TEST_SUCCESS);

        // case3: reward exists, but user not exist
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

        let emission_per_second = 0;
        let max_emission_rate = 0;
        let distribution_end = 0;

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

        let total_accrued =
            get_user_accrued_rewards(user, reward, rewards_controller_address);
        assert!(total_accrued == 0, TEST_SUCCESS);

        // case5: reward and user exists
        add_user_asset_index(
            user,
            asset,
            reward,
            rewards_controller_address,
            user_data
        );

        let total_accrued =
            get_user_accrued_rewards(user, reward, rewards_controller_address);
        assert!(total_accrued == (accrued as u256), TEST_SUCCESS);
    }

    #[
        test(
            pool_admin = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_get_asset_decimals_when_rewards_controller_address_not_exist(
        pool_admin: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
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

        let rewards_controller_address = @0x33;
        let decimals = get_asset_decimals(asset, rewards_controller_address);
        assert!(decimals == 0, TEST_SUCCESS);
    }

    #[
        test(
            pool_admin = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool
        )
    ]
    fun test_get_asset_decimals_when_asset_not_exist(
        pool_admin: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aave_std);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        token_helper::init_reserves(
            pool_admin,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let decimals = get_asset_decimals(asset, rewards_controller_address);
        assert!(decimals == 0, TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_set_claimer_when_rewards_controller_address_not_exist() {
        set_claimer(@0x31, @0x32, @0x33);
    }
}
