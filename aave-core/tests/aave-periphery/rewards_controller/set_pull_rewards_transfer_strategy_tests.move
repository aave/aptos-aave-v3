#[test_only]
module aave_pool::set_pull_rewards_transfer_strategy_tests_tests {
    use std::option;
    use std::signer;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::object;
    use aave_acl::acl_manage;
    use aave_pool::rewards_controller::{
        rewards_controller_address,
        initialize,
        get_pull_rewards_transfer_strategy,
        set_pull_rewards_transfer_strategy,
        PullRewardsTransferStrategyInstalled
    };
    use aave_pool::rewards_controller_tests::{create_sample_pull_rewards_transfer_strategy};

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(periphery_account = @aave_pool, aave_role_super_admin = @aave_acl, reward = @0xfa)]
    fun test_set_pull_rewards_transfer_strategy(
        periphery_account: &signer, aave_role_super_admin: &signer, reward: address
    ) {
        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        acl_manage::test_init_module(aave_role_super_admin);

        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);
        // TODO(mengxu): not sure whether this function (also this test) needs
        // to exist. To be honest, it doesn't seem right to directly modify
        // `pull_rewards_transfer_strategy_table` of `RewardsControllerData`
        set_pull_rewards_transfer_strategy(
            reward,
            object::object_address(&pull_rewards_transfer_strategy),
            rewards_addr
        );

        // check PullRewardsTransferStrategyInstalled emitted events
        let emitted_events = emitted_events<PullRewardsTransferStrategyInstalled>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
    }

    #[test(periphery_account = @aave_pool, aave_role_super_admin = @aave_acl, reward = @0xfa)]
    fun test_get_pull_rewards_transfer_strategy(
        periphery_account: &signer, aave_role_super_admin: &signer, reward: address
    ) {
        assert!(
            option::is_none(&get_pull_rewards_transfer_strategy(reward, @0x31)),
            TEST_SUCCESS
        );

        initialize(periphery_account, REWARDS_CONTROLLER_NAME);

        acl_manage::test_init_module(aave_role_super_admin);

        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);

        let rewards_addr = rewards_controller_address(REWARDS_CONTROLLER_NAME);

        assert!(
            option::is_none(&get_pull_rewards_transfer_strategy(reward, rewards_addr)),
            TEST_SUCCESS
        );

        // TODO(mengxu): see comments above on whether we need this setter
        set_pull_rewards_transfer_strategy(
            reward,
            object::object_address(&pull_rewards_transfer_strategy),
            rewards_addr
        );

        assert!(
            option::destroy_some(
                get_pull_rewards_transfer_strategy(reward, rewards_addr)
            ) == object::object_address(&pull_rewards_transfer_strategy),
            TEST_SUCCESS
        );
    }

    #[test(periphery_account = @aave_pool, aave_role_super_admin = @aave_acl, reward = @0xfa)]
    #[expected_failure(abort_code = 3022, location = aave_pool::rewards_controller)]
    fun test_set_pull_rewards_transfer_strategy_when_rewards_controller_address_not_exist(
        periphery_account: &signer, aave_role_super_admin: &signer, reward: address
    ) {
        acl_manage::test_init_module(aave_role_super_admin);
        // add emissions admin
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        let pull_rewards_transfer_strategy =
            create_sample_pull_rewards_transfer_strategy(periphery_account);
        set_pull_rewards_transfer_strategy(
            reward,
            object::object_address(&pull_rewards_transfer_strategy),
            @0x31
        );
    }
}
