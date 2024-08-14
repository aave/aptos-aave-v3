module aave_pool::transfer_strategy {
    use std::option::{Self, Option};
    use std::signer;
    use aptos_framework::event;

    use aave_acl::acl_manage::Self;
    use aave_mock_oracle::oracle::RewardOracle;

    use aave_pool::mock_underlying_token_factory;
    use aave_pool::staked_token::{MockStakedToken, stake, staked_token};

    #[test_only]
    use std::string::utf8;

    // friend aave_pool::underlying_token_factory;

    const ONLY_REWARDS_ADMIN: u64 = 1;
    const CALLER_NOT_INCENTIVES_CONTROLLER: u64 = 1;
    const REWARD_TOKEN_NOT_STAKE_CONTRACT: u64 = 1;
    const TOO_MANY_STRATEGIES: u64 = 1;
    const NOT_EMISSION_ADMIN: u64 = 1;

    const EMISSION_MANAGER_NAME: vector<u8> = b"EMISSION_MANAGER";

    public fun check_is_emission_admin(account: address) {
        assert!(acl_manage::is_emission_admin_role(account), NOT_EMISSION_ADMIN);
    }

    struct PullRewardsTransferStrategy has key, drop, store, copy {
        rewards_admin: address,
        incentives_controller: address,
        rewards_vault: address,
    }

    public fun create_pull_rewards_transfer_strategy(
        rewards_admin: address, incentives_controller: address, rewards_vault: address
    ): PullRewardsTransferStrategy {
        PullRewardsTransferStrategy { rewards_admin, incentives_controller, rewards_vault }
    }

    public fun pull_rewards_transfer_strategy_perform_transfer(
        caller: &signer,
        to: address,
        reward: address,
        amount: u256,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ): bool {
        pull_rewards_transfer_strategy_only_incentives_controller(
            caller, &pull_rewards_transfer_strategy
        );

        mock_underlying_token_factory::transfer_from(
            pull_rewards_transfer_strategy.rewards_vault,
            to,
            (amount as u64),
            reward,
        );

        true
    }

    public fun pull_rewards_transfer_strategy_get_rewards_vault(
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ): address {
        pull_rewards_transfer_strategy.rewards_vault
    }

    fun pull_rewards_transfer_strategy_only_rewards_admin(
        caller: &signer, pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ) {
        assert!(
            signer::address_of(caller) == pull_rewards_transfer_strategy.rewards_admin,
            ONLY_REWARDS_ADMIN,
        );
    }

    fun pull_rewards_transfer_strategy_only_incentives_controller(
        caller: &signer, pull_rewards_transfer_strategy: &PullRewardsTransferStrategy
    ) {
        assert!(
            signer::address_of(caller)
                == pull_rewards_transfer_strategy.incentives_controller,
            CALLER_NOT_INCENTIVES_CONTROLLER,
        );
    }

    public fun pull_rewards_transfer_strategy_get_incentives_controller(
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ): address {
        pull_rewards_transfer_strategy.incentives_controller
    }

    public fun pull_rewards_transfer_strategy_get_rewards_admin(
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy
    ): address {
        pull_rewards_transfer_strategy.rewards_admin
    }

    fun pull_rewards_transfer_strategy_emergency_withdrawal(
        caller: &signer,
        token: address,
        to: address,
        amount: u256,
        pull_rewards_transfer_strategy: PullRewardsTransferStrategy,
    ) {
        pull_rewards_transfer_strategy_only_rewards_admin(
            caller, pull_rewards_transfer_strategy
        );

        mock_underlying_token_factory::transfer_from(
            signer::address_of(caller), to, (amount as u64), token
        );

        emit_emergency_withdrawal_event(caller, token, to, amount);
    }

    struct StakedTokenTransferStrategy has key, drop, store, copy {
        rewards_admin: address,
        incentives_controller: address,
        stake_contract: MockStakedToken,
        underlying_token: address,
    }

    public fun create_staked_token_transfer_strategy(
        rewards_admin: address,
        incentives_controller: address,
        stake_contract: MockStakedToken,
        underlying_token: address
    ): StakedTokenTransferStrategy {
        StakedTokenTransferStrategy {
            rewards_admin,
            incentives_controller,
            stake_contract,
            underlying_token,
        }
    }

    public fun staked_token_transfer_strategy_perform_transfer(
        caller: &signer,
        to: address,
        reward: address,
        amount: u256,
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ): bool {
        staked_token_transfer_strategy_only_incentives_controller(
            caller, &staked_token_transfer_strategy
        );
        assert!(
            reward == staked_token(&staked_token_transfer_strategy.stake_contract),
            REWARD_TOKEN_NOT_STAKE_CONTRACT,
        );

        stake(&staked_token_transfer_strategy.stake_contract, to, amount);

        true
    }

    public fun staked_token_transfer_strategy_get_stake_contract(
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ): address {
        staked_token(&staked_token_transfer_strategy.stake_contract)
    }

    public fun staked_token_transfer_strategy_get_underlying_token(
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ): address {
        staked_token_transfer_strategy.underlying_token
    }

    fun staked_token_transfer_strategy_only_rewards_admin(
        caller: &signer, staked_token_transfer_strategy: StakedTokenTransferStrategy
    ) {
        assert!(
            signer::address_of(caller) == staked_token_transfer_strategy.rewards_admin,
            ONLY_REWARDS_ADMIN,
        );
    }

    fun staked_token_transfer_strategy_only_incentives_controller(
        caller: &signer, staked_token_transfer_strategy: &StakedTokenTransferStrategy
    ) {
        assert!(
            signer::address_of(caller)
                == staked_token_transfer_strategy.incentives_controller,
            CALLER_NOT_INCENTIVES_CONTROLLER,
        );
    }

    public fun staked_token_transfer_strategy_get_incentives_controller(
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ): address {
        staked_token_transfer_strategy.incentives_controller
    }

    public fun staked_token_transfer_strategy_get_rewards_admin(
        staked_token_transfer_strategy: StakedTokenTransferStrategy
    ): address {
        staked_token_transfer_strategy.rewards_admin
    }

    fun staked_token_transfer_strategy_emergency_withdrawal(
        caller: &signer,
        token: address,
        to: address,
        amount: u256,
        staked_token_transfer_strategy: StakedTokenTransferStrategy,
    ) {
        staked_token_transfer_strategy_only_rewards_admin(
            caller, staked_token_transfer_strategy
        );

        mock_underlying_token_factory::transfer_from(
            signer::address_of(caller), to, (amount as u64), token
        );

        emit_emergency_withdrawal_event(caller, token, to, amount);
    }

    struct RewardsConfigInput has store, drop {
        emission_per_second: u128,
        total_supply: u256,
        distribution_end: u32,
        asset: address,
        reward: address,
        staked_token_transfer_strategy: Option<StakedTokenTransferStrategy>,
        pull_rewards_transfer_strategy: Option<PullRewardsTransferStrategy>,
        reward_oracle: RewardOracle
    }

    public fun get_reward(rewards_config_input: &RewardsConfigInput): address {
        rewards_config_input.reward
    }

    public fun get_reward_oracle(
        rewards_config_input: &RewardsConfigInput
    ): RewardOracle {
        rewards_config_input.reward_oracle
    }

    public fun get_asset(rewards_config_input: &RewardsConfigInput): address {
        rewards_config_input.asset
    }

    public fun get_total_supply(rewards_config_input: &RewardsConfigInput): u256 {
        rewards_config_input.total_supply
    }

    public fun get_emission_per_second(
        rewards_config_input: &RewardsConfigInput
    ): u128 {
        rewards_config_input.emission_per_second
    }

    public fun get_distribution_end(
        rewards_config_input: &RewardsConfigInput
    ): u32 {
        rewards_config_input.distribution_end
    }

    public fun set_total_supply(
        rewards_config_input: &mut RewardsConfigInput, total_supply: u256
    ) {
        rewards_config_input.total_supply = total_supply;
    }

    public fun pull_rewards_transfer_strategy_get_strategy(
        rewards_config_input: &RewardsConfigInput
    ): PullRewardsTransferStrategy {
        *option::borrow(&rewards_config_input.pull_rewards_transfer_strategy)
    }

    public fun staked_token_transfer_strategy_get_strategy(
        rewards_config_input: &RewardsConfigInput
    ): StakedTokenTransferStrategy {
        *option::borrow(&rewards_config_input.staked_token_transfer_strategy)
    }

    public fun validate_rewards_config_input(
        rewards_config_input: &RewardsConfigInput
    ) {
        assert!(
            (
                option::is_some(&rewards_config_input.staked_token_transfer_strategy)
                && !option::is_some(
                    &rewards_config_input.pull_rewards_transfer_strategy
                )
            )
            || (
                !option::is_some(&rewards_config_input.staked_token_transfer_strategy)
                && option::is_some(
                    &rewards_config_input.pull_rewards_transfer_strategy
                )
            ),
            TOO_MANY_STRATEGIES,
        );
    }

    public fun has_pull_rewards_transfer_strategy(
        rewards_config_input: &RewardsConfigInput
    ): bool {
        option::is_some(&rewards_config_input.pull_rewards_transfer_strategy)
    }

    #[event]
    struct EmergencyWithdrawal has store, drop {
        caller: address,
        token: address,
        to: address,
        amount: u256
    }

    public fun emit_emergency_withdrawal_event(
        caller: &signer, token: address, to: address, amount: u256
    ) {
        event::emit(
            EmergencyWithdrawal { caller: signer::address_of(caller), token, to, amount },
        );
    }

    #[test(_aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens, aave_pool = @aave_pool)]
    fun test_pull_rewards_transfer_strategy_perform_transfer(
        _aave_role_super_admin: &signer,
        _periphery_account: &signer,
        _acl_fund_admin: &signer,
        _user_account: &signer,
        _creator: &signer,
        underlying_tokens_admin: &signer,
        aave_pool: &signer,
    ) {
        let pull_rewards_transfer_strategy = PullRewardsTransferStrategy {
            rewards_admin: signer::address_of(underlying_tokens_admin),
            incentives_controller: signer::address_of(underlying_tokens_admin),
            rewards_vault: signer::address_of(underlying_tokens_admin),
        };

        mock_underlying_token_factory::test_init_module(aave_pool);
        let underlying_token_name = utf8(b"TOKEN_1");
        let underlying_token_symbol = utf8(b"T1");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b""),
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(underlying_tokens_admin),
            100,
            underlying_token_address,
        );

        let caller: &signer = underlying_tokens_admin;
        let to: address = signer::address_of(underlying_tokens_admin);
        let reward: address = underlying_token_address;
        let amount: u256 = 1;

        pull_rewards_transfer_strategy_perform_transfer(
            caller,
            to,
            reward,
            amount,
            pull_rewards_transfer_strategy,
        );
    }

    #[test(_aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens, aave_pool = @aave_pool,)]
    fun test_pull_rewards_transfer_strategy_emergency_withdrawal(
        _aave_role_super_admin: &signer,
        _periphery_account: &signer,
        _acl_fund_admin: &signer,
        _user_account: &signer,
        _creator: &signer,
        underlying_tokens_admin: &signer,
        aave_pool: &signer,
    ) {
        let pull_rewards_transfer_strategy = PullRewardsTransferStrategy {
            rewards_admin: signer::address_of(underlying_tokens_admin),
            incentives_controller: signer::address_of(underlying_tokens_admin),
            rewards_vault: signer::address_of(underlying_tokens_admin),
        };

        mock_underlying_token_factory::test_init_module(aave_pool);
        let underlying_token_name = utf8(b"TOKEN_1");
        let underlying_token_symbol = utf8(b"T1");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b""),
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(underlying_tokens_admin),
            100,
            underlying_token_address,
        );

        let caller: &signer = underlying_tokens_admin;
        let to: address = signer::address_of(underlying_tokens_admin);
        let reward: address = underlying_token_address;
        let amount: u256 = 1;

        pull_rewards_transfer_strategy_perform_transfer(
            caller,
            to,
            reward,
            amount,
            pull_rewards_transfer_strategy,
        );

        pull_rewards_transfer_strategy_emergency_withdrawal(
            caller,
            underlying_token_address,
            to,
            amount,
            pull_rewards_transfer_strategy,
        );
    }

    #[test(_aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens, aave_pool = @aave_pool,)]
    fun test_staked_token_transfer_strategy_perform_transfer(
        _aave_role_super_admin: &signer,
        _periphery_account: &signer,
        _acl_fund_admin: &signer,
        _user_account: &signer,
        _creator: &signer,
        underlying_tokens_admin: &signer,
        aave_pool: &signer
    ) {
        mock_underlying_token_factory::test_init_module(aave_pool);
        let underlying_token_name = utf8(b"TOKEN_1");
        let underlying_token_symbol = utf8(b"T1");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b""),
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(underlying_tokens_admin),
            100,
            underlying_token_address,
        );

        let staked_token_transfer_strategy = StakedTokenTransferStrategy {
            rewards_admin: signer::address_of(underlying_tokens_admin),
            incentives_controller: signer::address_of(underlying_tokens_admin),
            stake_contract: aave_pool::staked_token::create_mock_staked_token(
                signer::address_of(underlying_tokens_admin)
            ),
            underlying_token: underlying_token_address,
        };

        let caller: &signer = underlying_tokens_admin;
        let to: address = signer::address_of(underlying_tokens_admin);
        let reward: address = signer::address_of(underlying_tokens_admin);
        let amount: u256 = 1;

        staked_token_transfer_strategy_perform_transfer(
            caller,
            to,
            reward,
            amount,
            staked_token_transfer_strategy,
        );
    }

    #[test(_aave_role_super_admin = @aave_acl, _periphery_account = @aave_pool, _acl_fund_admin = @0x111, _user_account = @0x222, _creator = @0x1, underlying_tokens_admin = @underlying_tokens, aave_pool = @aave_pool,)]
    fun test_staked_token_transfer_strategy_emergency_withdrawal(
        _aave_role_super_admin: &signer,
        _periphery_account: &signer,
        _acl_fund_admin: &signer,
        _user_account: &signer,
        _creator: &signer,
        underlying_tokens_admin: &signer,
        aave_pool: &signer,
    ) {
        mock_underlying_token_factory::test_init_module(aave_pool);
        let underlying_token_name = utf8(b"TOKEN_1");
        let underlying_token_symbol = utf8(b"T1");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;

        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b""),
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            signer::address_of(underlying_tokens_admin),
            100,
            underlying_token_address,
        );

        let staked_token_transfer_strategy = StakedTokenTransferStrategy {
            rewards_admin: signer::address_of(underlying_tokens_admin),
            incentives_controller: signer::address_of(underlying_tokens_admin),
            stake_contract: aave_pool::staked_token::create_mock_staked_token(
                signer::address_of(underlying_tokens_admin)
            ),
            underlying_token: underlying_token_address,
        };

        let caller: &signer = underlying_tokens_admin;
        let to: address = signer::address_of(underlying_tokens_admin);
        let reward: address = signer::address_of(underlying_tokens_admin);
        let amount: u256 = 1;

        staked_token_transfer_strategy_perform_transfer(
            caller,
            to,
            reward,
            amount,
            staked_token_transfer_strategy,
        );

        staked_token_transfer_strategy_emergency_withdrawal(
            caller,
            underlying_token_address,
            to,
            amount,
            staked_token_transfer_strategy,
        );
    }
}
