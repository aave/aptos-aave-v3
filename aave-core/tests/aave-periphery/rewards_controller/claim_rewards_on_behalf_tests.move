#[test_only]
module aave_pool::claim_rewards_on_behalf_tests {
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_pool::transfer_strategy;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::token_helper;
    use aave_oracle::oracle_tests::Self;
    use aave_oracle::oracle::Self;
    use aave_pool::rewards_controller::{
        initialize,
        rewards_controller_address,
        set_claimer,
        get_all_user_rewards,
        create_user_data,
        create_reward_data,
        enable_reward,
        create_rewards_config_input,
        configure_assets,
        add_user_asset_index,
        add_asset,
        create_asset_data,
        Accrued
    };
    use aave_pool::rewards_distributor::{claim_rewards_on_behalf, RewardsClaimed};
    use aave_pool::rewards_controller_tests::{test_setup_with_one_asset};

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            claimer = @0x111,
            user = @0x222,
            recipient = @0x333
        )
    ]
    fun test_claim_rewards_on_behalf(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        claimer: &signer,
        user: address,
        recipient: address
    ) {
        set_time_has_started_for_testing(aptos_framework);

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        // init reserves with assets count
        let asset_count = 6;
        token_helper::init_reserves_with_assets_count_params(
            pool_admin,
            aave_role_super_admin,
            aptos_framework,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            asset_count
        );
        let underlying_asset = mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reward = underlying_asset;

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

        // config transfer strategy
        let periphery_address = signer::address_of(periphery_account);
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );

        let rewards_vault_address =
            account::get_signer_capability_address(&rewards_vault);

        let constructor_ref = object::create_sticky_object(periphery_address);
        // make the periphery account be the emission admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        let pull_rewards_transfer_strategy =
            transfer_strategy::test_create_pull_rewards_transfer_strategy(
                periphery_account,
                &constructor_ref,
                periphery_address,
                rewards_controller_address,
                rewards_vault
            );

        let emission_per_second = 1;
        let max_emission_rate = 100000;
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

        // mint some tokens for rewards_vault
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_vault_address,
            (total_supply as u64),
            underlying_asset
        );

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(periphery_account),
            (total_supply as u64),
            u2_underlying_tokens
        );

        let (rewards_list, unclaimed_amounts) =
            get_all_user_rewards(
                vector[underlying_asset], user, rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&rewards_list, 0) == reward, TEST_SUCCESS);
        assert!(vector::length(&unclaimed_amounts) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&unclaimed_amounts, 0) == 3, TEST_SUCCESS);

        set_claimer(user, signer::address_of(claimer), rewards_controller_address);

        // amount is 0
        claim_rewards_on_behalf(
            claimer,
            vector[underlying_asset],
            0,
            user,
            recipient,
            reward,
            rewards_controller_address
        );

        let u3_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_3"));
        let asset_data = create_asset_data(simple_map::new(), simple_map::new(), 0, 8);
        // add asset for u3_underlying_tokens
        add_asset(rewards_controller_address, u3_underlying_tokens, asset_data);

        let u4_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_4"));

        let users_map = simple_map::new();
        let user_data = create_user_data(1, 3);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, u4_underlying_tokens, reward_data);

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, u4_underlying_tokens);

        let asset_data = create_asset_data(rewards_map, available_rewards, 1, 8);
        // add asset for u4_underlying_tokens
        add_asset(rewards_controller_address, u4_underlying_tokens, asset_data);

        let emission_per_second = 1;
        let max_emission_rate = 100000;
        let distribution_end = 2;
        let total_supply = 100;
        let rewards_config_input =
            create_rewards_config_input(
                emission_per_second,
                max_emission_rate,
                total_supply,
                distribution_end,
                u4_underlying_tokens,
                reward,
                object::object_address(&pull_rewards_transfer_strategy)
            );

        // Configure assets
        let configs = vector::empty();
        vector::push_back(&mut configs, rewards_config_input);
        configure_assets(configs, rewards_controller_address);

        // amount is 10
        claim_rewards_on_behalf(
            claimer,
            vector[
                underlying_asset,
                u2_underlying_tokens,
                u3_underlying_tokens,
                u4_underlying_tokens
            ],
            10,
            user,
            recipient,
            reward,
            rewards_controller_address
        );

        // add user asset index for u4_underlying_tokens
        add_user_asset_index(
            user,
            u4_underlying_tokens,
            reward,
            rewards_controller_address,
            user_data
        );

        claim_rewards_on_behalf(
            claimer,
            vector[u4_underlying_tokens],
            2,
            user,
            recipient,
            reward,
            rewards_controller_address
        );

        // case5: total_rewards is 0
        let u5_underlying_tokens =
            mock_underlying_token_factory::token_address(utf8(b"U_5"));

        let users_map = simple_map::new();
        let user_data = create_user_data(1, 0);
        simple_map::add(&mut users_map, user, user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, u5_underlying_tokens, reward_data);

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, u5_underlying_tokens);

        let asset_data = create_asset_data(rewards_map, available_rewards, 1, 8);
        // add asset for u5_underlying_tokens
        add_asset(rewards_controller_address, u5_underlying_tokens, asset_data);

        let total_rewards =
            claim_rewards_on_behalf(
                claimer,
                vector[u5_underlying_tokens],
                2,
                user,
                recipient,
                reward,
                rewards_controller_address
            );

        assert!(total_rewards == 0, TEST_SUCCESS);

        // check Accrued emitted events
        let emitted_events = emitted_events<Accrued>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        // check RewardsClaimed emitted events
        let emitted_events = emitted_events<RewardsClaimed>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);
    }

    #[test(
        periphery_account = @aave_pool, claimer = @0x111, user = @0x0, to = @0x333
    )]
    #[expected_failure(abort_code = 77, location = aave_pool::rewards_distributor)]
    fun test_claim_rewards_on_behalf_when_user_is_zero_address_not_valid(
        periphery_account: &signer, claimer: &signer, user: address, to: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        claim_rewards_on_behalf(
            claimer,
            vector[@0x33],
            0,
            user,
            to,
            @0x34,
            rewards_controller_address(REWARDS_CONTROLLER_NAME)
        );
    }

    #[test(
        periphery_account = @aave_pool, claimer = @0x111, user = @0x222, to = @0x0
    )]
    #[expected_failure(abort_code = 77, location = aave_pool::rewards_distributor)]
    fun test_claim_rewards_on_behalf_when_to_is_zero_address_not_valid(
        periphery_account: &signer, claimer: &signer, user: address, to: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        claim_rewards_on_behalf(
            claimer,
            vector[@0x33],
            10,
            user,
            to,
            @0x34,
            rewards_controller_address(REWARDS_CONTROLLER_NAME)
        );
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            claimer = @0x111,
            user = @0x222,
            recipient = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 3003, location = aave_pool::rewards_distributor)]
    fun test_claim_rewards_on_behalf_when_claimer_is_unauthorized_claimer(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        claimer: &signer,
        user: address,
        recipient: address,
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

        set_claimer(user, signer::address_of(claimer), controller_address);
        claim_rewards_on_behalf(
            pool_admin,
            vector[asset],
            20,
            user,
            recipient,
            reward,
            controller_address
        );
    }
}
