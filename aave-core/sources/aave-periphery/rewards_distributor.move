/// @title Rewards Distributor Module
/// @author Aave
/// @notice Implements functionality to distribute rewards to users
module aave_pool::rewards_distributor {
    // imports
    use std::option;
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::object;

    use aave_config::error_config;
    use aave_pool::rewards_controller;
    use aave_pool::transfer_strategy;

    // Error constants

    // Events
    #[event]
    /// @notice Emitted when rewards are claimed
    /// @param user The address of the user who claimed rewards
    /// @param reward The address of the reward
    /// @param to The address to which rewards are transferred
    /// @param claimer The address of the claimer
    /// @param amount The amount of rewards claimed
    /// @param rewards_controller_address The address of the rewards controller
    struct RewardsClaimed has store, drop {
        user: address,
        reward: address,
        to: address,
        claimer: address,
        amount: u256,
        rewards_controller_address: address
    }

    // Public functions
    /// @notice Claims rewards for a user
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param amount The amount of rewards to claim
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The amount of rewards claimed
    public fun claim_rewards(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 {
        assert!(to != @0x0, error_config::get_ezero_address_not_valid());

        let claimer = signer::address_of(caller);
        claim_rewards_internal(
            assets,
            amount,
            claimer,
            claimer,
            to,
            reward,
            rewards_controller_address
        )
    }

    /// @notice Claims rewards on behalf of a user
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param amount The amount of rewards to claim
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The amount of rewards claimed
    public fun claim_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 {
        assert!(user != @0x0, error_config::get_ezero_address_not_valid());
        assert!(to != @0x0, error_config::get_ezero_address_not_valid());

        let claimer = signer::address_of(caller);
        only_authorized_claimers(claimer, user, rewards_controller_address);
        claim_rewards_internal(
            assets,
            amount,
            claimer,
            user,
            to,
            reward,
            rewards_controller_address
        )
    }

    /// @notice Claims rewards and transfers them to the caller
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param amount The amount of rewards to claim
    /// @param reward The address of the reward
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The amount of rewards claimed
    public fun claim_rewards_to_self(
        caller: &signer,
        assets: vector<address>,
        amount: u256,
        reward: address,
        rewards_controller_address: address
    ): u256 {
        let claimer = signer::address_of(caller);
        claim_rewards_internal(
            assets,
            amount,
            claimer,
            claimer,
            claimer,
            reward,
            rewards_controller_address
        )
    }

    /// @notice Claims all rewards for a user
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param to The address to which rewards are transferred
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    public fun claim_all_rewards(
        caller: &signer,
        assets: vector<address>,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) {
        assert!(to != @0x0, error_config::get_ezero_address_not_valid());

        let claimer = signer::address_of(caller);
        claim_all_rewards_internal(
            assets,
            claimer,
            claimer,
            to,
            rewards_controller_address
        )
    }

    /// @notice Claims all rewards on behalf of a user
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    public fun claim_all_rewards_on_behalf(
        caller: &signer,
        assets: vector<address>,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) {
        assert!(user != @0x0, error_config::get_ezero_address_not_valid());
        assert!(to != @0x0, error_config::get_ezero_address_not_valid());

        let claimer = signer::address_of(caller);
        only_authorized_claimers(claimer, user, rewards_controller_address);
        claim_all_rewards_internal(
            assets,
            claimer,
            user,
            to,
            rewards_controller_address
        )
    }

    /// @notice Claims all rewards and transfers them to the caller
    /// @param caller The signer account of the caller
    /// @param assets Vector of asset addresses
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    public fun claim_all_rewards_to_self(
        caller: &signer, assets: vector<address>, rewards_controller_address: address
    ): (vector<address>, vector<u256>) {
        let claimer = signer::address_of(caller);
        claim_all_rewards_internal(
            assets,
            claimer,
            claimer,
            claimer,
            rewards_controller_address
        )
    }

    // Private functions
    /// @notice Verifies that the claimer is authorized to claim rewards on behalf of the user
    /// @param claimer The address of the claimer
    /// @param user The address of the user
    /// @param rewards_controller_address The address of the rewards controller
    fun only_authorized_claimers(
        claimer: address, user: address, rewards_controller_address: address
    ) {
        assert!(
            rewards_controller::get_claimer(user, rewards_controller_address)
                == option::some(claimer),
            error_config::get_eunauthorized_claimer()
        );
    }

    /// @notice Transfers rewards using pull rewards transfer strategy
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param amount The amount of rewards to transfer
    /// @param pull_rewards_transfer_strategy The address of the pull rewards transfer strategy
    /// @param rewards_controller_address The address of the rewards controller
    fun transfer_rewards_with_pull_rewards_transfer_strategy(
        to: address,
        reward: address,
        amount: u256,
        pull_rewards_transfer_strategy: address,
        rewards_controller_address: address
    ) {
        let strategy = object::address_to_object(pull_rewards_transfer_strategy);

        // sanity check on the strategy
        assert!(
            transfer_strategy::pull_rewards_transfer_strategy_get_incentives_controller(
                strategy
            ) == rewards_controller_address,
            error_config::get_eincentives_controller_mismatch()
        );

        let success =
            transfer_strategy::pull_rewards_transfer_strategy_perform_transfer(
                rewards_controller_address,
                to,
                reward,
                amount,
                strategy
            );
        assert!(success, error_config::get_ereward_transfer_failed());
    }

    /// @notice Internal function to claim rewards
    /// @param assets Vector of asset addresses
    /// @param amount The amount of rewards to claim
    /// @param claimer The address of the claimer
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The amount of rewards claimed
    fun claim_rewards_internal(
        assets: vector<address>,
        amount: u256,
        claimer: address,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 {
        let total_rewards =
            rewards_controller::claim_rewards_internal_update_data(
                assets,
                amount,
                user,
                reward,
                rewards_controller_address
            );

        if (total_rewards == 0) { return 0 };

        let strategy_opt =
            rewards_controller::get_pull_rewards_transfer_strategy(
                reward, rewards_controller_address
            );
        assert!(
            option::is_some(&strategy_opt),
            error_config::get_eno_transfer_strategy()
        );
        transfer_rewards_with_pull_rewards_transfer_strategy(
            to,
            reward,
            total_rewards,
            option::destroy_some(strategy_opt),
            rewards_controller_address
        );

        event::emit(
            RewardsClaimed {
                user,
                reward,
                to,
                claimer,
                amount: total_rewards,
                rewards_controller_address
            }
        );

        total_rewards
    }

    /// @notice Internal function to claim all rewards
    /// @param assets Vector of asset addresses
    /// @param claimer The address of the claimer
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    fun claim_all_rewards_internal(
        assets: vector<address>,
        claimer: address,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) {
        let (rewards_list, claimed_amounts) =
            rewards_controller::claim_all_rewards_internal_update_data(
                assets, user, rewards_controller_address
            );

        let rewards_list_length = vector::length(&rewards_list);
        for (i in 0..rewards_list_length) {
            let amount = *vector::borrow(&claimed_amounts, i);
            if (amount == 0) {
                continue
            };

            let reward = *vector::borrow(&rewards_list, i);
            let strategy_opt =
                rewards_controller::get_pull_rewards_transfer_strategy(
                    reward, rewards_controller_address
                );
            assert!(
                option::is_some(&strategy_opt),
                error_config::get_eno_transfer_strategy()
            );
            transfer_rewards_with_pull_rewards_transfer_strategy(
                to,
                reward,
                amount,
                option::destroy_some(strategy_opt),
                rewards_controller_address
            );

            event::emit(
                RewardsClaimed {
                    user,
                    reward,
                    to,
                    claimer,
                    amount,
                    rewards_controller_address
                }
            );
        };

        (rewards_list, claimed_amounts)
    }

    // Test only functions
    #[test_only]
    /// @notice Test-only function to claim rewards internal
    /// @param assets Vector of asset addresses
    /// @param amount The amount of rewards to claim
    /// @param claimer The address of the claimer
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The amount of rewards claimed
    public fun claim_rewards_internal_for_testing(
        assets: vector<address>,
        amount: u256,
        claimer: address,
        user: address,
        to: address,
        reward: address,
        rewards_controller_address: address
    ): u256 {
        claim_rewards_internal(
            assets,
            amount,
            claimer,
            user,
            to,
            reward,
            rewards_controller_address
        )
    }

    #[test_only]
    /// @notice Test-only function to claim all rewards internal
    /// @param assets Vector of asset addresses
    /// @param claimer The address of the claimer
    /// @param user The address of the user
    /// @param to The address to which rewards are transferred
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    public fun claim_all_rewards_internal_for_testing(
        assets: vector<address>,
        claimer: address,
        user: address,
        to: address,
        rewards_controller_address: address
    ): (vector<address>, vector<u256>) {
        claim_all_rewards_internal(
            assets,
            claimer,
            user,
            to,
            rewards_controller_address
        )
    }
}
