#[test_only]
module aave_pool::claim_all_rewards_tests {
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_framework::account;
    use aptos_framework::object;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_pool::transfer_strategy;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::token_helper;
    use aave_pool::rewards_controller::{
        initialize,
        rewards_controller_address,
        enable_reward,
        add_asset,
        create_asset_data,
        create_user_data,
        create_reward_data,
        set_pull_rewards_transfer_strategy
    };
    use aave_pool::rewards_distributor::{
        claim_all_rewards,
        claim_all_rewards_internal_for_testing
    };
    use aave_pool::rewards_controller_tests::test_setup_with_one_asset;

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
            recipient = @0x333
        )
    ]
    fun test_claim_all_rewards(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        pool_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer,
        claimer: &signer,
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

        let rewards_controller_address =
            rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let u1_underlying_asset =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reward = u1_underlying_asset;
        // add reward to rewards_list
        enable_reward(rewards_controller_address, reward);

        let (rewards_list, claimed_amount) =
            claim_all_rewards(
                claimer,
                vector[u1_underlying_asset],
                recipient,
                rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(vector::length(&claimed_amount) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&rewards_list, 0) == u1_underlying_asset, TEST_SUCCESS);
        assert!(*vector::borrow(&claimed_amount, 0) == 0, TEST_SUCCESS);

        // add u1_underlying_asset to assets and assets_list
        let asset_data = create_asset_data(simple_map::new(), simple_map::new(), 0, 8);
        add_asset(rewards_controller_address, u1_underlying_asset, asset_data);

        let (rewards_list, claimed_amount) =
            claim_all_rewards(
                claimer,
                vector[u1_underlying_asset],
                recipient,
                rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 1, TEST_SUCCESS);
        assert!(vector::length(&claimed_amount) == 1, TEST_SUCCESS);
        assert!(*vector::borrow(&rewards_list, 0) == u1_underlying_asset, TEST_SUCCESS);
        assert!(*vector::borrow(&claimed_amount, 0) == 0, TEST_SUCCESS);

        let u2_underlying_asset =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // add reward to rewards_list
        enable_reward(rewards_controller_address, u2_underlying_asset);

        let users_map = simple_map::new();
        let claimer_accrued = 3;
        let user_data = create_user_data(1, claimer_accrued);
        simple_map::add(&mut users_map, signer::address_of(claimer), user_data);

        let reward_data = create_reward_data(1, 2, 10, 0, 0, users_map);
        let rewards_map = simple_map::new();
        simple_map::add(&mut rewards_map, u2_underlying_asset, reward_data);

        let available_rewards = simple_map::new();
        simple_map::upsert(&mut available_rewards, 0, u2_underlying_asset);

        // add u2_underlying_asset to assets and assets_list
        let asset_data = create_asset_data(rewards_map, available_rewards, 0, 8);
        add_asset(rewards_controller_address, u2_underlying_asset, asset_data);

        // config transfer strategy
        let periphery_address = signer::address_of(periphery_account);
        let (_, rewards_vault) = account::create_resource_account(
            periphery_account, b""
        );
        let rewards_vault_address =
            account::get_signer_capability_address(&rewards_vault);
        let constructor_ref = object::create_sticky_object(periphery_address);
        // make the periphery account behave as emissions_admin
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
        set_pull_rewards_transfer_strategy(
            u2_underlying_asset,
            object::object_address(&pull_rewards_transfer_strategy),
            rewards_controller_address
        );

        // mint some rewards to rewards_vault
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            rewards_vault_address,
            1000,
            u2_underlying_asset
        );

        let (rewards_list, claimed_amount) =
            claim_all_rewards(
                claimer,
                vector[u2_underlying_asset],
                recipient,
                rewards_controller_address
            );
        assert!(vector::length(&rewards_list) == 2, TEST_SUCCESS);
        assert!(vector::length(&claimed_amount) == 2, TEST_SUCCESS);
        assert!(vector::contains(&rewards_list, &u2_underlying_asset), TEST_SUCCESS);
        assert!(vector::contains(&rewards_list, &u1_underlying_asset), TEST_SUCCESS);
        assert!(vector::contains(&claimed_amount, &0), TEST_SUCCESS);
        assert!(
            vector::contains(&claimed_amount, &(claimer_accrued as u256)),
            TEST_SUCCESS
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
            recipient = @0x0,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform
        )
    ]
    #[expected_failure(abort_code = 77, location = aave_pool::rewards_distributor)]
    fun test_claim_all_rewards_when_recipient_is_zero_address_not_valid(
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
        let (asset, _reward, controller_address) =
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

        claim_all_rewards(
            user,
            vector[asset],
            recipient,
            controller_address
        );
    }

    #[test]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_claim_all_rewards_internal_when_rewards_controller_address_not_exist() {
        claim_all_rewards_internal_for_testing(vector[@0xaf], @0x31, @0x32, @0x33, @0x34);
    }
}
