#[test_only]
module aave_pool::emission_manager_tests {
    use std::option;
    use std::signer;
    use std::string;
    use std::string::utf8;
    use std::vector;

    use aptos_std::simple_map;
    use aptos_std::string_utils;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::object;
    use aptos_framework::object::Object;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::token_base;
    use aave_pool::a_token_factory;
    use aave_pool::transfer_strategy;
    use aave_oracle::oracle_tests::Self;
    use aave_oracle::oracle::Self;
    use aave_pool::rewards_controller;
    use aave_pool::pool;
    use aave_pool::token_helper;
    use aave_pool::transfer_strategy::PullRewardsTransferStrategy;
    use aave_pool::rewards_controller::{
        test_initialize as rewards_controller_init,
        create_rewards_config_input,
        rewards_controller_address,
        create_reward_data,
        create_asset_data,
        add_asset,
        enable_reward
    };

    use aave_pool::emission_manager::{
        test_init_module as emission_manager_init,
        get_rewards_controller_for_testing,
        set_pull_rewards_transfer_strategy,
        set_emission_admin,
        get_emission_admin,
        set_rewards_controller,
        test_configure_assets,
        set_distribution_end,
        set_emission_per_second,
        set_claimer,
        emission_manager_object,
        emission_manager_address,
        EmissionManagerData,
        EmissionAdminUpdated,
        initialize,
        configure_assets
    };

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // bare-minimal setup
    fun test_setup(
        _aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
        emission_manager_init(periphery_account);

        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        set_rewards_controller(periphery_account, option::some(rewards_addr));
    }

    // bare-minimal setup with one reward and the default strategy
    fun test_setup_with_pull_rewards_transfer_strategy(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        assert!(get_emission_admin(reward) == @0x0, TEST_SUCCESS);

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        set_pull_rewards_transfer_strategy(
            periphery_account, reward, pull_rewards_transfer_strategy
        );
    }

    // bare-minimal setup with one reward and the default strategy
    fun test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ): (address, address) {
        // init on aave-core
        timestamp::set_time_has_started_for_testing(aptos_framework);
        timestamp::fast_forward_seconds(1);

        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(pool_admin)
        );
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        token_base::test_init_module(pool_admin);
        a_token_factory::test_init_module(pool_admin);

        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);

        // initialize the emission manager
        test_setup(aave_role_super_admin, periphery_account);
        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);

        // prepare a transfer strategy
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                pool_admin,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        // create an AToken
        let i = 0;
        let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
        let symbol = string_utils::format1(&b"U_{}", i);
        let decimals = 6;

        a_token_factory::create_token(
            pool_admin,
            name,
            symbol,
            decimals,
            string::utf8(b""),
            string::utf8(b""),
            option::some(get_rewards_controller_for_testing()),
            underlying_asset,
            // TODO(mengxu): ideally should be an isolated treasury account
            signer::address_of(pool_admin)
        );
        let asset = a_token_factory::token_address(symbol);

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

        let reward_data =
            create_reward_data(
                index,
                emission_per_second,
                max_emission_rate,
                last_update_timestamp,
                distribution_end,
                simple_map::new()
            );
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, reward, reward_data);
        let asset_data = create_asset_data(rewards_map, simple_map::new(), 0, decimals);

        let controller_address = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        add_asset(controller_address, asset, asset_data);
        enable_reward(controller_address, reward);

        // prepare the rewards config
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
        test_configure_assets(periphery_account, configs);

        // return the asset address and rewards controller address
        (asset, controller_address)
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    fun test_initialize(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    fun test_set_pull_rewards_transfer_strategy(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            reward = @0x111,
            new_admin = @0x333
        )
    ]
    fun test_set_emission_admin(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        reward: address,
        new_admin: address
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );

        // set and get new emission admin
        set_emission_admin(periphery_account, reward, new_admin);
        assert!(get_emission_admin(reward) == new_admin, TEST_SUCCESS);

        // check CancelStream emitted events
        let emitted_events = emitted_events<EmissionAdminUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            reward = @0x111,
            new_reward_controller = @0x333
        )
    ]
    #[expected_failure(abort_code = 3022, location = aave_pool::emission_manager)]
    fun test_set_rewards_controller_when_rewards_controller_address_is_invalid(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        reward: address,
        new_reward_controller: address
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );

        // expect failure here because `new_reward_controller` is not a valid
        // address in which a `RewardController` is actually defined.
        set_rewards_controller(periphery_account, option::some(new_reward_controller));
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    fun test_reset_rewards_controller(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );
        set_rewards_controller(periphery_account, option::none());
    }

    #[
        test(
            aptos_framework = @0x1,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            periphery_account = @aave_pool,
            underlying_asset = @0xcafe,
            reward = @0x111,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_configure_assets_test(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
            aptos_framework,
            aave_role_super_admin,
            pool_admin,
            periphery_account,
            underlying_asset,
            reward,
            aave_oracle,
            data_feeds,
            platform
        );
    }

    #[test(periphery_account = @0x31)]
    #[expected_failure(abort_code = 23, location = aave_pool::emission_manager)]
    fun test_initialize_when_account_is_not_pool(
        periphery_account: &signer
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);
    }

    #[
        test(
            aptos_framework = @0x1,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            periphery_account = @aave_pool,
            underlying_asset = @0xcafe,
            reward = @0x111,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_set_distribution_end(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (asset, _) =
            test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                periphery_account,
                underlying_asset,
                reward,
                aave_oracle,
                data_feeds,
                platform
            );

        set_distribution_end(periphery_account, asset, reward, 10);
    }

    #[
        test(
            aptos_framework = @0x1,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            periphery_account = @aave_pool,
            underlying_asset = @0xcafe,
            reward = @0x111,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_set_emission_per_second(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (asset, _) =
            test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                periphery_account,
                underlying_asset,
                reward,
                aave_oracle,
                data_feeds,
                platform
            );

        let rewards_arg = vector[reward];
        let new_emissions_per_second_arg = vector[1];
        set_emission_per_second(
            periphery_account,
            asset,
            rewards_arg,
            new_emissions_per_second_arg
        );
    }

    #[
        test(
            aptos_framework = @0x1,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            periphery_account = @aave_pool,
            underlying_asset = @0xcafe,
            reward = @0x111,
            user_account = @0x222,
            new_claimer = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_set_claimer(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        user_account: address,
        new_claimer: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
            aptos_framework,
            aave_role_super_admin,
            pool_admin,
            periphery_account,
            underlying_asset,
            reward,
            aave_oracle,
            data_feeds,
            platform
        );

        set_claimer(periphery_account, user_account, new_claimer);
    }

    #[test(user1 = @0x333)]
    #[expected_failure(abort_code = 23, location = aave_pool::emission_manager)]
    fun test_init_module_when_account_is_not_pool(user1: &signer) {
        emission_manager_init(user1);
    }

    #[test(periphery_account = @aave_pool, user = @0x333, claimer = @0x444)]
    #[expected_failure(abort_code = 23, location = aave_pool::emission_manager)]
    fun test_set_claimer_when_account_is_not_admin(
        periphery_account: &signer, user: &signer, claimer: address
    ) {
        emission_manager_init(periphery_account);
        set_claimer(user, signer::address_of(user), claimer);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    #[expected_failure(abort_code = 3008, location = aave_pool::emission_manager)]
    fun test_set_pull_rewards_transfer_strategy_when_account_is_not_emission_admin(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        // expect failure here because `aave_role_super_admin` is not an emission admin
        set_pull_rewards_transfer_strategy(
            aave_role_super_admin, reward, pull_rewards_transfer_strategy
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    #[expected_failure(abort_code = 3002, location = aave_pool::emission_manager)]
    fun test_set_pull_rewards_transfer_strategy_with_incentives_controller_mismatch(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                @0x33,
                rewards_vault
            );

        set_pull_rewards_transfer_strategy(
            periphery_account, reward, pull_rewards_transfer_strategy
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    fun test_emission_manager_object(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );
        let emission_manager_address = emission_manager_address();
        let emission_manager_object = emission_manager_object();

        assert!(
            object::address_to_object<EmissionManagerData>(emission_manager_address)
                == emission_manager_object,
            TEST_SUCCESS
        );
    }

    #[test(periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 3009, location = aave_pool::emission_manager)]
    fun test_get_rewards_controller_if_defined_when_rewards_controller_is_none(
        periphery_account: &signer
    ) {
        emission_manager_init(periphery_account);
        get_rewards_controller_for_testing();
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, user1 = @0x333)]
    #[expected_failure(abort_code = 3008, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_account_is_not_emission_admin(
        aave_role_super_admin: &signer, periphery_account: &signer, user1: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        // prepare the rewards config
        let emission_per_second = 0;
        let distribution_end = 0;
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let default_admin = signer::address_of(periphery_account);
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                1000000,
                0,
                distribution_end,
                @0x31,
                @0x32,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);

        // finally configure the assets
        test_configure_assets(user1, configs);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, user1 = @0x31)]
    #[expected_failure(abort_code = 3008, location = aave_pool::emission_manager)]
    fun test_set_distribution_end_when_account_is_not_emission_admin(
        aave_role_super_admin: &signer, periphery_account: &signer, user1: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        let reward = @0x32;
        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);

        set_distribution_end(user1, @0x33, reward, 10);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, user1 = @0x31)]
    #[expected_failure(abort_code = 23, location = aave_pool::emission_manager)]
    fun test_set_emission_admin_when_account_is_not_admin(
        aave_role_super_admin: &signer, periphery_account: &signer, user1: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        let reward = @0x32;
        set_emission_admin(user1, reward, @0x33);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    fun test_set_emission_admin_when_rewards_controller_not_defined(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        acl_manage::test_init_module(aave_role_super_admin);
        emission_manager_init(periphery_account);

        let reward = @0x32;
        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, reward, default_admin);
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            reward = @0x111,
            new_reward_controller = @0x333,
            user1 = @0x444
        )
    ]
    #[expected_failure(abort_code = 23, location = aave_pool::emission_manager)]
    fun test_set_rewards_controller_when_account_is_not_admin(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        reward: address,
        new_reward_controller: address,
        user1: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, reward
        );

        set_rewards_controller(user1, option::some(new_reward_controller));
    }

    #[
        test(
            aptos_framework = @0x1,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            periphery_account = @aave_pool,
            underlying_asset = @0xcafe,
            reward = @0x111,
            user1 = @0x222,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3008, location = aave_pool::emission_manager)]
    fun test_set_emission_per_second_when_account_is_not_emission_admin(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        periphery_account: &signer,
        underlying_asset: address,
        reward: address,
        user1: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (asset, _) =
            test_setup_with_pull_rewards_transfer_strategy_on_one_asset(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                periphery_account,
                underlying_asset,
                reward,
                aave_oracle,
                data_feeds,
                platform
            );

        let rewards_arg = vector[reward];
        let new_emissions_per_second_arg = vector[1];
        set_emission_per_second(
            user1,
            asset,
            rewards_arg,
            new_emissions_per_second_arg
        );
    }

    #[test(periphery_account = @aave_pool, reward = @0x111)]
    fun test_get_emission_admin_when_rewards_controller_not_defined(
        periphery_account: &signer, reward: address
    ) {
        emission_manager_init(periphery_account);
        assert!(get_emission_admin(reward) == @0x0);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    fun test_configure_assets_when_config_is_empty(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        let configs = vector::empty();
        test_configure_assets(periphery_account, configs);
    }

    #[test(periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 3009, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_rewards_controller_not_defined(
        periphery_account: &signer
    ) {
        rewards_controller_init(periphery_account, REWARDS_CONTROLLER_NAME);
        emission_manager_init(periphery_account);

        // prepare a transfer strategy
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let default_admin = signer::address_of(periphery_account);
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let configs = vector::empty();
        let rewards_config_input =
            create_rewards_config_input(
                0,
                0,
                0,
                0,
                @0x31,
                @0x32,
                object::object_address(&pull_rewards_transfer_strategy)
            );
        vector::push_back(&mut configs, rewards_config_input);
        test_configure_assets(periphery_account, configs);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, reward = @0x111)]
    #[expected_failure(abort_code = 3023, location = aave_pool::emission_manager)]
    fun test_set_pull_rewards_transfer_strategy_when_reward_not_exist(
        aave_role_super_admin: &signer, periphery_account: &signer, reward: address
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        let default_admin = signer::address_of(periphery_account);
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        // expect failure here because `reward` is not an existing reward
        set_pull_rewards_transfer_strategy(
            aave_role_super_admin, reward, pull_rewards_transfer_strategy
        );
    }

    #[
        test(
            aave_role_super_admin = @aave_acl,
            periphery_account = @aave_pool,
            asset = @0x31,
            reward = @0x32
        )
    ]
    #[expected_failure(abort_code = 3023, location = aave_pool::emission_manager)]
    fun test_set_distribution_end_when_reward_not_exist(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        asset: address,
        reward: address
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        acl_manage::test_init_module(aave_role_super_admin);

        set_distribution_end(periphery_account, asset, reward, 10);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    fun test_set_emission_per_second_when_rewards_is_empty(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup(aave_role_super_admin, periphery_account);
        let rewards = vector::empty();
        let new_emissions_per_seconds = vector::empty();
        set_emission_per_second(
            periphery_account,
            @0x31,
            rewards,
            new_emissions_per_seconds
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 76, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_inconsistent_params_length(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, @0x111
        );
        let (_, rewards_vault) =
            account::create_resource_account(periphery_account, b"TEST1");

        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &object::create_sticky_object(signer::address_of(periphery_account)),
                signer::address_of(periphery_account),
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let emissions_per_second: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100, 200];
        let assets: vector<address> = vector[@0x12];
        let rewards: vector<address> = vector[@0x12];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_second,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 76, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_inconsistent_params_length1(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, @0x111
        );
        let (_, rewards_vault) =
            account::create_resource_account(periphery_account, b"TEST1");

        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &object::create_sticky_object(signer::address_of(periphery_account)),
                signer::address_of(periphery_account),
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let emissions_per_second: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[@0x12, @0x13];
        let rewards: vector<address> = vector[@0x12];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_second,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 76, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_inconsistent_params_length2(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, @0x111
        );
        let (_, rewards_vault) =
            account::create_resource_account(periphery_account, b"TEST1");

        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &object::create_sticky_object(signer::address_of(periphery_account)),
                signer::address_of(periphery_account),
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let emissions_per_second: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[@0x12];
        let rewards: vector<address> = vector[@0x12, @0x13];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_second,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 76, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_inconsistent_params_length3(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, @0x111
        );
        let (_, rewards_vault) =
            account::create_resource_account(periphery_account, b"TEST1");

        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &object::create_sticky_object(signer::address_of(periphery_account)),
                signer::address_of(periphery_account),
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let emissions_per_second: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[@0x12];
        let rewards: vector<address> = vector[@0x12];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[
            pull_rewards_transfer_strategy_obj,
            pull_rewards_transfer_strategy_obj
        ];

        configure_assets(
            periphery_account,
            emissions_per_second,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool)]
    #[expected_failure(abort_code = 76, location = aave_pool::emission_manager)]
    fun test_configure_assets_when_inconsistent_params_length4(
        aave_role_super_admin: &signer, periphery_account: &signer
    ) {
        test_setup_with_pull_rewards_transfer_strategy(
            aave_role_super_admin, periphery_account, @0x111
        );
        let (_, rewards_vault) =
            account::create_resource_account(periphery_account, b"TEST1");

        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &object::create_sticky_object(signer::address_of(periphery_account)),
                signer::address_of(periphery_account),
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        let emissions_per_second: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100, 200];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[@0x12];
        let rewards: vector<address> = vector[@0x12];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_second,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
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
            periphery_account = @aave_pool
        )
    ]
    fun test_configure_assets_success(
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

        test_setup(aave_role_super_admin, periphery_account);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        assert!(get_emission_admin(a_token_address) == @0x0, TEST_SUCCESS);

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, a_token_address, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        set_pull_rewards_transfer_strategy(
            periphery_account,
            a_token_address,
            pull_rewards_transfer_strategy_obj
        );

        // set asset price for a_token_address
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            a_token_address,
            10
        );

        let emissions_per_seconds: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[a_token_address];
        let rewards: vector<address> = vector[a_token_address];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_seconds,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );

        // check the reward data
        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (
            _, emission_per_second_after, _, distribution_end_after
        ) =
            rewards_controller::get_rewards_data(
                a_token_address, a_token_address, rewards_addr
            );
        assert!(
            *vector::borrow(&emissions_per_seconds, 0)
                == (emission_per_second_after as u128),
            TEST_SUCCESS
        );
        assert!(
            *vector::borrow(&distribution_ends, 0) == (distribution_end_after as u32),
            TEST_SUCCESS
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
            periphery_account = @aave_pool
        )
    ]
    #[expected_failure(abort_code = 3005, location = aave_pool::emission_manager)]
    fun test_configure_assets_with_invalid_reward_config(
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

        test_setup(aave_role_super_admin, periphery_account);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        assert!(get_emission_admin(a_token_address) == @0x0, TEST_SUCCESS);

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, a_token_address, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                get_rewards_controller_for_testing(),
                rewards_vault
            );

        set_pull_rewards_transfer_strategy(
            periphery_account,
            a_token_address,
            pull_rewards_transfer_strategy_obj
        );

        // set asset price for a_token_address
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            a_token_address,
            10
        );

        let emissions_per_seconds: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[@0x33];
        let rewards: vector<address> = vector[a_token_address];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_seconds,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );

        // check the reward data
        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (
            _, emission_per_second_after, _, distribution_end_after
        ) =
            rewards_controller::get_rewards_data(
                a_token_address, a_token_address, rewards_addr
            );
        assert!(
            *vector::borrow(&emissions_per_seconds, 0)
                == (emission_per_second_after as u128),
            TEST_SUCCESS
        );
        assert!(
            *vector::borrow(&distribution_ends, 0) == (distribution_end_after as u32),
            TEST_SUCCESS
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
            periphery_account = @aave_pool
        )
    ]
    #[expected_failure(abort_code = 3002, location = aave_pool::emission_manager)]
    fun test_configure_assets_with_incentives_controller_mismatch(
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

        test_setup(aave_role_super_admin, periphery_account);

        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        assert!(get_emission_admin(a_token_address) == @0x0, TEST_SUCCESS);

        let default_admin = signer::address_of(periphery_account);
        set_emission_admin(periphery_account, a_token_address, default_admin);

        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let constructor_ref = object::create_sticky_object(default_admin);
        let pull_rewards_transfer_strategy_obj =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                default_admin,
                @0x44,
                rewards_vault
            );

        // set asset price for a_token_address
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            a_token_address,
            10
        );

        let emissions_per_seconds: vector<u128> = vector[100];
        let max_emission_rates: vector<u128> = vector[100];
        let distribution_ends: vector<u32> = vector[100];
        let assets: vector<address> = vector[a_token_address];
        let rewards: vector<address> = vector[a_token_address];
        let pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>> = vector[pull_rewards_transfer_strategy_obj];

        configure_assets(
            periphery_account,
            emissions_per_seconds,
            max_emission_rates,
            distribution_ends,
            assets,
            rewards,
            pull_rewards_transfer_strategies
        );

        // check the reward data
        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let (
            _, emission_per_second_after, _, distribution_end_after
        ) =
            rewards_controller::get_rewards_data(
                a_token_address, a_token_address, rewards_addr
            );
        assert!(
            *vector::borrow(&emissions_per_seconds, 0)
                == (emission_per_second_after as u128),
            TEST_SUCCESS
        );
        assert!(
            *vector::borrow(&distribution_ends, 0) == (distribution_end_after as u32),
            TEST_SUCCESS
        );
    }
}
