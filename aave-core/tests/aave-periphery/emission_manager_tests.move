#[test_only]
module aave_pool::emission_manager_tests {
    use aave_acl::acl_manage::{Self};
    use std::signer;
    use aave_pool::emission_manager::{
        initialize,
        set_pull_rewards_transfer_strategy,
        set_staked_token_transfer_strategy
    };

    #[test(aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1,)]
    fun test_initialize(
        aave_role_super_admin: &signer,
        _periphery_account: &signer,
        _acl_fund_admin: &signer,
        _user_account: &signer,
        _creator: &signer,
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        let rewards_addr = signer::address_of(aave_role_super_admin);

        initialize(aave_role_super_admin, rewards_addr);
    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
    fun test_set_pull_rewards_transfer_strategy(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        _acl_fund_admin: &signer,
        user_account: &signer,
        _creator: &signer,
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        aave_pool::rewards_controller::initialize(
            periphery_account, signer::address_of(periphery_account)
        );

        let user_account_addr = signer::address_of(user_account);

        let pull_rewards_transfer_strategy =
            aave_pool::transfer_strategy::create_pull_rewards_transfer_strategy(
                user_account_addr, user_account_addr, user_account_addr
            );

        let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();

        acl_manage::add_emission_admin_role(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account, rewards_addr);

        set_pull_rewards_transfer_strategy(
            periphery_account,
            signer::address_of(periphery_account),
            pull_rewards_transfer_strategy,
        );

    }

    #[test(aave_role_super_admin = @aave_acl, periphery_account = @aave_pool, _acl_fund_admin = @0x111, user_account = @0x222, _creator = @0x1,)]
    fun test_set_staked_token_transfer_strategy(
        aave_role_super_admin: &signer,
        periphery_account: &signer,
        _acl_fund_admin: &signer,
        user_account: &signer,
        _creator: &signer,
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        aave_pool::rewards_controller::initialize(
            periphery_account, signer::address_of(periphery_account)
        );

        let user_account_addr = signer::address_of(user_account);

        let mock_staked_token =
            aave_pool::staked_token::create_mock_staked_token(user_account_addr);

        let staked_token_transfer_strategy =
            aave_pool::transfer_strategy::create_staked_token_transfer_strategy(
                user_account_addr,
                user_account_addr,
                mock_staked_token,
                user_account_addr,
            );

        let rewards_addr = aave_pool::rewards_controller::rewards_controller_address();

        acl_manage::add_emission_admin_role(
            aave_role_super_admin, signer::address_of(periphery_account)
        );

        initialize(periphery_account, rewards_addr);

        set_staked_token_transfer_strategy(
            periphery_account,
            signer::address_of(periphery_account),
            staked_token_transfer_strategy,
        );

    }
}
