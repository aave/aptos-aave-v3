#[test_only]
module aave_pool::claim_rewards_tests {

    use std::signer;
    use aptos_std::simple_map;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::transfer_strategy;
    use aave_pool::rewards_controller;
    use aave_pool::rewards_distributor::{
        claim_rewards,
        claim_rewards_internal_for_testing
    };
    use aave_pool::rewards_controller_tests::{test_setup_with_one_asset, test_setup};

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
            recipient = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_claim_rewards(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: &signer,
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
                signer::address_of(user),
                aave_oracle,
                data_feeds,
                platform
            );

        let total_rewards =
            claim_rewards(
                user,
                vector[asset],
                0,
                recipient,
                reward,
                controller_address
            );

        assert!(total_rewards == 0, TEST_SUCCESS)
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            pool_admin = @aave_pool,
            underlying_tokens_admin = @aave_mock_underlyings,
            periphery_account = @aave_pool,
            user = @0x222,
            recipient = @0x0,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 77, location = aave_pool::rewards_distributor)]
    fun test_claim_rewards_when_recipient_is_zero_address_not_valid(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: &signer,
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
                signer::address_of(user),
                aave_oracle,
                data_feeds,
                platform
            );

        claim_rewards(
            user,
            vector[asset],
            10,
            recipient,
            reward,
            controller_address
        );
    }

    #[test(periphery_account = @aave_pool, reward = @0xfa)]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_claim_rewards_when_rewards_controller_address_not_exist(
        periphery_account: &signer, reward: address
    ) {
        claim_rewards(
            periphery_account,
            vector[@0x31],
            10,
            @0x32,
            reward,
            @0x31
        );
    }

    #[test]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_claim_rewards_internal_when_rewards_controller_address_not_exist() {
        claim_rewards_internal_for_testing(
            vector[@0x31],
            10,
            @0x32,
            @0x33,
            @0x34,
            @0x35,
            @0x36
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
            recipient = @0x333,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    fun test_claim_rewards_with_total_rewards_gt_zero(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        user: &signer,
        recipient: address,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer
    ) {
        let (
            asset, reward, controller_address, pull_rewards_transfer_strategy
        ) =
            test_setup(
                aptos_framework,
                aave_role_super_admin,
                pool_admin,
                underlying_tokens_admin,
                periphery_account,
                signer::address_of(user),
                aave_oracle,
                data_feeds,
                platform
            );

        let users_map = simple_map::new();
        let claimer_accrued = 3;
        let user_data = rewards_controller::create_user_data(1, claimer_accrued);
        simple_map::add(&mut users_map, signer::address_of(user), user_data);

        let reward_data = rewards_controller::create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, asset, reward_data);

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, asset);

        // add reward to rewards_list
        rewards_controller::enable_reward(controller_address, asset);
        rewards_controller::add_user_asset_index(
            signer::address_of(user),
            asset,
            reward,
            controller_address,
            user_data
        );

        // mint 1000 reward to rewards_vault
        let rewards_vault_address =
            transfer_strategy::pull_rewards_transfer_strategy_get_rewards_vault(
                pull_rewards_transfer_strategy
            );

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_vault_address,
            1000,
            reward
        );

        let total_rewards =
            claim_rewards(
                user,
                vector[asset],
                10,
                recipient,
                reward,
                controller_address
            );

        assert!(total_rewards == 3, TEST_SUCCESS)
    }
}
