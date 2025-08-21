/// @title Transfer Strategy Module
/// @author Aave
/// @notice Implements functionality to transfer rewards using various strategies
module aave_pool::transfer_strategy {
    // imports
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::dispatchable_fungible_asset;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::{Object, ConstructorRef};
    use aptos_framework::primary_fungible_store;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_pool::pool_token_logic;
    use aave_pool::a_token_factory;

    // friend modules
    friend aave_pool::rewards_distributor;

    #[test_only]
    friend aave_pool::transfer_strategy_tests;

    // Structs
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice An object representing the pull-reward transfer strategy
    /// @dev This strategy pulls rewards (as `FungibleAsset`) from a vault resource
    /// account to the recipient address.
    struct PullRewardsTransferStrategy has key {
        rewards_admin: address,
        incentives_controller: address,
        /// @dev The `rewards_vault` is essentially a resource account, marked by the
        ///      associated `SignerCapability`.
        ///      Rewards will be stored in the primary `FungibleStore`s of this
        ///      resource account, each store is associated with a FungibleAsset.
        rewards_vault: SignerCapability
    }

    // Events
    #[event]
    /// @notice Emitted when an emergency withdrawal is performed
    /// @param caller The address of the caller
    /// @param token The address of the token
    /// @param to The address to which tokens are transferred
    /// @param amount The amount of tokens transferred
    struct EmergencyWithdrawal has store, drop {
        caller: address,
        token: address,
        to: address,
        amount: u256
    }

    // Public view functions
    #[view]
    /// @notice Gets the incentives controller for a pull rewards transfer strategy
    /// @param strategy The pull rewards transfer strategy object
    /// @return The address of the incentives controller
    public fun pull_rewards_transfer_strategy_get_incentives_controller(
        strategy: Object<PullRewardsTransferStrategy>
    ): address acquires PullRewardsTransferStrategy {
        borrow_global<PullRewardsTransferStrategy>(object::object_address(&strategy)).incentives_controller
    }

    #[view]
    /// @notice Gets the rewards admin for a pull rewards transfer strategy
    /// @param strategy The pull rewards transfer strategy object
    /// @return The address of the rewards admin
    public fun pull_rewards_transfer_strategy_get_rewards_admin(
        strategy: Object<PullRewardsTransferStrategy>
    ): address acquires PullRewardsTransferStrategy {
        borrow_global<PullRewardsTransferStrategy>(object::object_address(&strategy)).rewards_admin
    }

    #[view]
    /// @notice Gets the rewards vault for a pull rewards transfer strategy
    /// @param strategy The pull rewards transfer strategy object
    /// @return The address of the rewards vault
    public fun pull_rewards_transfer_strategy_get_rewards_vault(
        strategy: Object<PullRewardsTransferStrategy>
    ): address acquires PullRewardsTransferStrategy {
        account::get_signer_capability_address(
            &borrow_global<PullRewardsTransferStrategy>(object::object_address(&strategy))
            .rewards_vault
        )
    }

    // Public functions
    /// @notice Creates a new pull rewards transfer strategy
    /// @param sender The signer account of the sender
    /// @param constructor_ref The constructor reference
    /// @param rewards_admin The address of the rewards admin
    /// @param incentives_controller The address of the incentives controller
    /// @param rewards_vault The signer capability of the rewards vault
    /// @return The pull rewards transfer strategy object
    public fun create_pull_rewards_transfer_strategy(
        sender: &signer,
        constructor_ref: &ConstructorRef,
        rewards_admin: address,
        incentives_controller: address,
        rewards_vault: SignerCapability
    ): Object<PullRewardsTransferStrategy> {
        assert!(
            acl_manage::is_emission_admin((signer::address_of(sender))),
            error_config::get_enot_emission_admin()
        );
        let object_signer = object::generate_signer(constructor_ref);
        move_to(
            &object_signer,
            PullRewardsTransferStrategy {
                rewards_admin,
                incentives_controller,
                rewards_vault
            }
        );
        object::object_from_constructor_ref(constructor_ref)
    }

    /// @notice Performs an emergency withdrawal of rewards
    /// @param caller The signer account of the caller
    /// @param token The address of the token
    /// @param to The address to which tokens are transferred
    /// @param amount The amount of tokens to transfer
    /// @param strategy The pull rewards transfer strategy object
    public entry fun pull_rewards_transfer_strategy_emergency_withdrawal(
        caller: &signer,
        token: address,
        to: address,
        amount: u256,
        strategy: Object<PullRewardsTransferStrategy>
    ) acquires PullRewardsTransferStrategy {
        let strategy_data = borrow_global(object::object_address(&strategy));
        pull_rewards_transfer_strategy_only_rewards_admin(caller, strategy_data);

        transfer_via_pull_rewards_transfer_strategy(to, token, amount, strategy_data);
        event::emit(
            EmergencyWithdrawal { caller: signer::address_of(caller), token, to, amount }
        );
    }

    // Friend functions
    /// @notice Performs a transfer using a pull rewards transfer strategy
    /// @param incentives_controller The address of the incentives controller
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param amount The amount of rewards to transfer
    /// @param strategy The pull rewards transfer strategy object
    /// @return Whether the transfer was successful
    public(friend) fun pull_rewards_transfer_strategy_perform_transfer(
        incentives_controller: address,
        to: address,
        reward: address,
        amount: u256,
        strategy: Object<PullRewardsTransferStrategy>
    ): bool acquires PullRewardsTransferStrategy {
        let strategy_data = borrow_global(object::object_address(&strategy));
        pull_rewards_transfer_strategy_only_incentives_controller(
            incentives_controller, strategy_data
        );

        transfer_via_pull_rewards_transfer_strategy(to, reward, amount, strategy_data);
        true
    }

    // Private functions
    /// @notice Validates that the caller is the rewards admin
    /// @param caller The signer account of the caller
    /// @param strategy_data The pull rewards transfer strategy data
    inline fun pull_rewards_transfer_strategy_only_rewards_admin(
        caller: &signer, strategy_data: &PullRewardsTransferStrategy
    ) {
        assert!(
            signer::address_of(caller) == strategy_data.rewards_admin,
            error_config::get_enot_rewards_admin()
        );
    }

    /// @notice Validates that the caller is the incentives controller
    /// @param incentives_controller The address of the incentives controller
    /// @param strategy_data The pull rewards transfer strategy data
    inline fun pull_rewards_transfer_strategy_only_incentives_controller(
        incentives_controller: address, strategy_data: &PullRewardsTransferStrategy
    ) {
        assert!(
            incentives_controller == strategy_data.incentives_controller,
            error_config::get_eincentives_controller_mismatch()
        );
    }

    /// @notice Transfers rewards using a pull rewards transfer strategy
    /// @param to The address to which rewards are transferred
    /// @param reward The address of the reward
    /// @param amount The amount of rewards to transfer
    /// @param strategy_data The pull rewards transfer strategy data
    fun transfer_via_pull_rewards_transfer_strategy(
        to: address,
        reward: address,
        amount: u256,
        strategy_data: &PullRewardsTransferStrategy
    ) {
        let vault_signer =
            account::create_signer_with_capability(&strategy_data.rewards_vault);

        if (a_token_factory::is_atoken(reward)) {
            pool_token_logic::transfer(&vault_signer, to, amount, reward);
        } else {
            let metadata = object::address_to_object<Metadata>(reward);
            let store_from =
                primary_fungible_store::primary_store(
                    signer::address_of(&vault_signer), metadata
                );
            let store_to =
                primary_fungible_store::ensure_primary_store_exists(to, metadata);

            dispatchable_fungible_asset::transfer(
                &vault_signer,
                store_from,
                store_to,
                (amount as u64)
            );
        };
    }

    // Test only functions
    #[test_only]
    /// @notice Test-only function to create a pull rewards transfer strategy
    /// @param sender The signer account of the sender
    /// @param constructor_ref The constructor reference
    /// @param rewards_admin The address of the rewards admin
    /// @param incentives_controller The address of the incentives controller
    /// @param rewards_vault The signer capability of the rewards vault
    /// @return The pull rewards transfer strategy object
    public fun test_create_pull_rewards_transfer_strategy(
        sender: &signer,
        constructor_ref: &ConstructorRef,
        rewards_admin: address,
        incentives_controller: address,
        rewards_vault: SignerCapability
    ): Object<PullRewardsTransferStrategy> {
        create_pull_rewards_transfer_strategy(
            sender,
            constructor_ref,
            rewards_admin,
            incentives_controller,
            rewards_vault
        )
    }
}
