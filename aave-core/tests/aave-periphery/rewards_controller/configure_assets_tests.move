#[test_only]
module aave_pool::configure_assets_tests {

    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aave_acl::acl_manage;
    use aave_pool::token_helper;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool;
    use aave_oracle::oracle;
    use aave_oracle::oracle_tests;
    use aave_pool::rewards_controller::{
        initialize,
        rewards_controller_address,
        get_rewards_data,
        create_rewards_config_input,
        add_asset,
        create_asset_data,
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
    fun test_configure_assets(
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
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_configure_assets_when_no_add_asset_before(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

        // init reserves
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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_rewards_controller_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        // initialize the rewards controller
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to the underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_asset, test_feed_id);

        // pre-mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_controller_address,
            100,
            underlying_asset
        );

        let reserve_data = pool::get_reserve_data(underlying_asset);
        let atoken_asset = pool::get_reserve_a_token_address(reserve_data);

        let asset = atoken_asset;
        let reward = underlying_asset;

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

        // case1: Configure assets before adding them
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);

        assert!(index_after == 0, TEST_SUCCESS);
        assert!(emission_per_second_after == (emission_per_second as u256), TEST_SUCCESS);
        assert!(last_update_timestamp_after == 1, TEST_SUCCESS);
        assert!(distribution_end_after == (distribution_end as u256), TEST_SUCCESS);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            user = @0x222,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_configure_assets_when_enable_reward_before(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        user: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_rewards_controller_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        // initialize the rewards controller
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let decimals = mock_underlying_token_factory::decimals(underlying_asset);

        // set price feed to the underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_asset, test_feed_id);

        // setup the pair that makes the tests happy
        // TODO(mengxu): I don't think that the `(asset, reward)` pair should be
        // `(a_token, underlying_token)`, but this is the only way at this stage
        // to make the tests happy, so using it as a hack for now.
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let atoken_asset = pool::get_reserve_a_token_address(reserve_data);

        let asset = atoken_asset;
        let reward = underlying_asset;

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        // enable this asset as rewards
        let index = 0;
        let emission_per_second = 0;
        let max_emission_rate = 0;
        let last_update_timestamp = 1;
        let distribution_end = 2;

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

        // case2: Configure assets before enable rewards
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        let (
            index_after,
            emission_per_second_after,
            last_update_timestamp_after,
            distribution_end_after
        ) = get_rewards_data(asset, reward, rewards_controller_address);
        assert!(index_after == (index as u256), TEST_SUCCESS);
        assert!(emission_per_second_after == (emission_per_second as u256), TEST_SUCCESS);
        assert!(
            last_update_timestamp_after == (last_update_timestamp as u256),
            TEST_SUCCESS
        );
        assert!(distribution_end_after == (distribution_end as u256), TEST_SUCCESS);
    }

    #[test]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_configure_assets_when_rewards_controller_address_not_exist() {
        configure_assets(vector::empty(), @0x31);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3025, location = aave_pool::rewards_controller)]
    fun test_configure_assets_with_invalid_emission_rate(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

        // init reserves
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

        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_rewards_controller_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        // initialize the rewards controller
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set price feed to the underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(underlying_asset, test_feed_id);

        // pre-mint some tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_controller_address,
            100,
            underlying_asset
        );

        let reserve_data = pool::get_reserve_data(underlying_asset);
        let atoken_asset = pool::get_reserve_a_token_address(reserve_data);

        let asset = atoken_asset;
        let reward = underlying_asset;

        // prepare the rewards config
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let emission_per_second = 1000;
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

        // case1: Configure assets before adding them
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);
    }
}
