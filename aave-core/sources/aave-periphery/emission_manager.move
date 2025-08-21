/// @title Emission Manager Module
/// @author Aave
/// @notice Implements the management of emissions for protocol rewards
module aave_pool::emission_manager {
    // imports
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::vector;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::object::{
        Self,
        ExtendRef as ObjExtendRef,
        Object,
        ObjectGroup,
        TransferRef as ObjectTransferRef
    };
    use aave_config::error_config;
    use aave_pool::a_token_factory;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::transfer_strategy;
    use aave_pool::rewards_controller;
    use aave_pool::rewards_controller::{
        RewardsConfigInput,
        RewardsControllerData,
        create_reward_input_config
    };
    use aave_pool::transfer_strategy::{PullRewardsTransferStrategy};

    // Constants
    /// @notice Name for the emission manager object
    const EMISSION_MANAGER_NAME: vector<u8> = b"EMISSION_MANAGER";

    // Structs
    #[resource_group_member(group = ObjectGroup)]
    /// @notice Data structure for managing emissions
    /// @dev Stores emission admins and rewards controller information
    struct EmissionManagerData has key {
        emission_admins: SmartTable<address, address>,
        extend_ref: ObjExtendRef,
        transfer_ref: ObjectTransferRef,
        rewards_controller: Option<address>
    }

    // Events
    #[event]
    /// @notice Emitted when an emission admin is updated for a reward
    /// @param reward The address of the reward
    /// @param old_admin The address of the previous admin
    /// @param new_admin The address of the new admin
    struct EmissionAdminUpdated has store, drop {
        reward: address,
        old_admin: address,
        new_admin: address
    }

    // Module initialization
    /// @notice Initializes the emission manager module
    /// @dev Creates the emission manager object
    /// @param sender The signer account that initializes the module (must be pool)
    fun init_module(sender: &signer) {
        assert!(
            signer::address_of(sender) == @aave_pool,
            error_config::get_ecaller_must_be_pool()
        );

        let state_object_constructor_ref =
            &object::create_named_object(sender, EMISSION_MANAGER_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            EmissionManagerData {
                emission_admins: smart_table::new<address, address>(),
                transfer_ref: object::generate_transfer_ref(state_object_constructor_ref),
                extend_ref: object::generate_extend_ref(state_object_constructor_ref),
                rewards_controller: option::none()
            }
        );
    }

    // Public entry functions
    /// @notice Initializes the rewards controller
    /// @dev Only callable by the pool
    /// @param sender The signer account of the caller
    /// @param seed The seed for initializing the rewards controller
    public entry fun initialize(sender: &signer, seed: vector<u8>) {
        assert!(
            signer::address_of(sender) == @aave_pool,
            error_config::get_ecaller_must_be_pool()
        );
        rewards_controller::initialize(sender, seed);
    }

    /// @notice Configures assets for emissions
    /// @dev Configures multiple assets with their emission parameters
    /// @param account The signer account of the caller (must be emission admin for all rewards)
    /// @param emissions_per_second The emission rates per second for each asset
    /// @param max_emission_rates The maximum emission rates for each asset
    /// @param distribution_ends The distribution end timestamps for each asset
    /// @param assets The addresses of the assets to configure
    /// @param rewards The addresses of the rewards for each asset
    /// @param pull_rewards_transfer_strategies The transfer strategies for pulling rewards
    public entry fun configure_assets(
        account: &signer,
        emissions_per_second: vector<u128>,
        max_emission_rates: vector<u128>,
        distribution_ends: vector<u32>,
        assets: vector<address>,
        rewards: vector<address>,
        pull_rewards_transfer_strategies: vector<Object<PullRewardsTransferStrategy>>
    ) acquires EmissionManagerData {
        // ensure all input args have the same length
        let expected_args_count = vector::length(&emissions_per_second);
        assert!(
            vector::length(&distribution_ends) == expected_args_count,
            error_config::get_einconsistent_params_length()
        );
        assert!(
            vector::length(&assets) == expected_args_count,
            error_config::get_einconsistent_params_length()
        );
        assert!(
            vector::length(&rewards) == expected_args_count,
            error_config::get_einconsistent_params_length()
        );
        assert!(
            vector::length(&pull_rewards_transfer_strategies) == expected_args_count,
            error_config::get_einconsistent_params_length()
        );
        assert!(
            vector::length(&max_emission_rates) == expected_args_count,
            error_config::get_einconsistent_params_length()
        );

        let reward_input_configs = vector::empty<RewardsConfigInput>();
        for (i in 0..expected_args_count) {
            let asset = *vector::borrow(&assets, i);
            assert!(
                a_token_factory::is_atoken(asset)
                    || variable_debt_token_factory::is_variable_debt_token(asset),
                error_config::get_einvalid_reward_config()
            );

            vector::push_back(
                &mut reward_input_configs,
                create_reward_input_config(
                    *vector::borrow(&emissions_per_second, i),
                    *vector::borrow(&max_emission_rates, i),
                    0,
                    *vector::borrow(&distribution_ends, i),
                    asset,
                    *vector::borrow(&rewards, i),
                    object::object_address(
                        vector::borrow(&pull_rewards_transfer_strategies, i)
                    )
                )
            );
        };
        configure_assets_internal(account, reward_input_configs);
    }

    /// @notice Sets the pull rewards transfer strategy for a reward
    /// @dev Only callable by the emission admin for the reward
    /// @param caller The signer account of the caller
    /// @param reward The address of the reward
    /// @param pull_rewards_transfer_strategy The transfer strategy for pulling rewards
    public entry fun set_pull_rewards_transfer_strategy(
        caller: &signer,
        reward: address,
        pull_rewards_transfer_strategy: Object<PullRewardsTransferStrategy>
    ) acquires EmissionManagerData {
        only_emission_admin(caller, reward);
        let rewards_controller_address = get_rewards_controller_ensure_defined();
        // sanity check on the strategy
        assert!(
            transfer_strategy::pull_rewards_transfer_strategy_get_incentives_controller(
                pull_rewards_transfer_strategy
            ) == rewards_controller_address,
            error_config::get_eincentives_controller_mismatch()
        );

        rewards_controller::set_pull_rewards_transfer_strategy(
            reward,
            object::object_address(&pull_rewards_transfer_strategy),
            rewards_controller_address
        );
    }

    /// @notice Sets the distribution end timestamp for a reward on an asset
    /// @dev Only callable by the emission admin for the reward
    /// @param caller The signer account of the caller
    /// @param asset The address of the asset
    /// @param reward The address of the reward
    /// @param new_distribution_end The new distribution end timestamp
    public entry fun set_distribution_end(
        caller: &signer,
        asset: address,
        reward: address,
        new_distribution_end: u32
    ) acquires EmissionManagerData {
        only_emission_admin(caller, reward);

        rewards_controller::set_distribution_end(
            asset,
            reward,
            new_distribution_end,
            get_rewards_controller_ensure_defined()
        );
    }

    /// @notice Sets the emission rate per second for rewards on an asset
    /// @dev Only callable by the emission admin for all rewards
    /// @param caller The signer account of the caller
    /// @param asset The address of the asset
    /// @param rewards The addresses of the rewards
    /// @param new_emissions_per_second The new emission rates per second
    public entry fun set_emission_per_second(
        caller: &signer,
        asset: address,
        rewards: vector<address>,
        new_emissions_per_second: vector<u128>
    ) acquires EmissionManagerData {
        let rewards_count = vector::length(&rewards);
        if (rewards_count == 0) { return };
        // sanity check, gas-efficient implementation of `only_emission_admin`
        // applied on every entry in the `config` vector.
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        for (i in 0..rewards_count) {
            assert!(
                *smart_table::borrow_with_default(
                    &emission_manager_data.emission_admins,
                    *vector::borrow(&rewards, i),
                    &@0x0
                ) == signer::address_of(caller),
                error_config::get_enot_emission_admin()
            );
        };

        rewards_controller::set_emission_per_second(
            asset,
            rewards,
            new_emissions_per_second,
            get_rewards_controller_ensure_defined()
        );
    }

    /// @notice Sets a claimer for a user
    /// @dev Only callable by the admin
    /// @param account The signer account of the caller
    /// @param user The address of the user
    /// @param claimer The address of the claimer
    public entry fun set_claimer(
        account: &signer, user: address, claimer: address
    ) acquires EmissionManagerData {
        only_admin(account);

        rewards_controller::set_claimer(
            user, claimer, get_rewards_controller_ensure_defined()
        );
    }

    /// @notice Sets the emission admin for a reward
    /// @dev Only callable by the admin
    /// @param account The signer account of the caller
    /// @param reward The address of the reward
    /// @param new_admin The address of the new admin
    public entry fun set_emission_admin(
        account: &signer, reward: address, new_admin: address
    ) acquires EmissionManagerData {
        only_admin(account);

        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());

        let old_admin =
            *smart_table::borrow_with_default(
                &emission_manager_data.emission_admins, reward, &@0x0
            );
        smart_table::upsert(
            &mut emission_manager_data.emission_admins, reward, new_admin
        );
        event::emit(EmissionAdminUpdated { reward, old_admin, new_admin });
    }

    /// @notice Sets the rewards controller address
    /// @dev Only callable by the admin
    /// @param account The signer account of the caller
    /// @param rewards_controller The new rewards controller address (or None to unset)
    public entry fun set_rewards_controller(
        account: &signer, rewards_controller: Option<address>
    ) acquires EmissionManagerData {
        only_admin(account);
        if (option::is_some(&rewards_controller)) {
            assert!(
                object::object_exists<RewardsControllerData>(
                    *option::borrow(&rewards_controller)
                ),
                error_config::get_einvalid_rewards_controller_address()
            );
        };

        let emission_manager_data =
            borrow_global_mut<EmissionManagerData>(emission_manager_address());
        emission_manager_data.rewards_controller = rewards_controller;
    }

    // Public view functions
    #[view]
    /// @notice Gets the address of the emission manager
    /// @return The address of the emission manager object
    public fun emission_manager_address(): address {
        object::create_object_address(&@aave_pool, EMISSION_MANAGER_NAME)
    }

    #[view]
    /// @notice Gets the emission manager object
    /// @return The emission manager object
    public fun emission_manager_object(): Object<EmissionManagerData> {
        object::address_to_object<EmissionManagerData>(emission_manager_address())
    }

    #[view]
    /// @notice Gets the rewards controller
    /// @return The address of the rewards controller (or None if not set)
    public fun get_rewards_controller(): Option<address> acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());
        emission_manager_data.rewards_controller
    }

    #[view]
    /// @notice Gets the emission admin for a reward
    /// @param reward The address of the reward
    /// @return The address of the emission admin
    public fun get_emission_admin(reward: address): address acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());

        if (!reward_exists(emission_manager_data, reward)) {
            return @0x0
        };

        *smart_table::borrow(&emission_manager_data.emission_admins, reward)
    }

    // Private functions
    /// @notice Checks if the caller is an admin
    /// @dev Reverts if the caller is not the pool admin
    /// @param account The signer account to check
    fun only_admin(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_pool,
            error_config::get_ecaller_must_be_pool()
        );
    }

    /// @notice Checks if the caller is the emission admin for a reward
    /// @dev Reverts if the caller is not the emission admin for the reward
    /// @param account The signer account to check
    /// @param reward The address of the reward
    fun only_emission_admin(account: &signer, reward: address) acquires EmissionManagerData {
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());

        assert!(
            reward_exists(emission_manager_data, reward),
            error_config::get_ereward_not_exist()
        );

        assert!(
            *smart_table::borrow(&emission_manager_data.emission_admins, reward)
                == signer::address_of(account),
            error_config::get_enot_emission_admin()
        );
    }

    /// @notice Gets the rewards controller address, ensuring it's defined
    /// @dev Reverts if the rewards controller is not set
    /// @return The address of the rewards controller
    fun get_rewards_controller_ensure_defined(): address acquires EmissionManagerData {
        let rewards_controller = get_rewards_controller();
        assert!(
            option::is_some(&rewards_controller),
            error_config::get_erewards_controller_not_defined()
        );
        option::destroy_some(rewards_controller)
    }

    /// @notice Configures assets for emissions (internal implementation)
    /// @dev Called by configure_assets after input validation
    /// @param account The signer account of the caller
    /// @param config The rewards configuration inputs
    fun configure_assets_internal(
        account: &signer, config: vector<RewardsConfigInput>
    ) acquires EmissionManagerData {
        let rewards_config_input_count = vector::length(&config);
        if (rewards_config_input_count == 0) { return };

        let rewards_controller = get_rewards_controller_ensure_defined();
        let emission_manager_data =
            borrow_global<EmissionManagerData>(emission_manager_address());

        for (i in 0..rewards_config_input_count) {
            let config_input = vector::borrow(&config, i);

            let reward = rewards_controller::get_reward_from_config(config_input);
            assert!(
                *smart_table::borrow_with_default(
                    &emission_manager_data.emission_admins, reward, &@0x0
                ) == signer::address_of(account),
                error_config::get_enot_emission_admin()
            );

            // sanity check on the strategy
            let strategy =
                rewards_controller::get_rewards_transfer_strategy_from_config(
                    config_input
                );
            assert!(
                transfer_strategy::pull_rewards_transfer_strategy_get_incentives_controller(
                    object::address_to_object(strategy)
                ) == rewards_controller,
                error_config::get_eincentives_controller_mismatch()
            );
        };

        rewards_controller::configure_assets(config, rewards_controller);
    }

    /// @notice Checks if a reward exists in the emission manager
    /// @param emission_manager_data The emission manager data
    /// @param reward The address of the reward
    /// @return True if the reward exists, false otherwise
    fun reward_exists(
        emission_manager_data: &EmissionManagerData, reward: address
    ): bool {
        smart_table::contains(&emission_manager_data.emission_admins, reward)
    }

    // Test-only functions
    #[test_only]
    /// @notice Initializes the module for testing
    /// @param account The signer account for testing
    public fun test_init_module(account: &signer) {
        init_module(account);
    }

    #[test_only]
    /// @notice Configures assets for testing
    /// @param account The signer account for testing
    /// @param config The rewards configuration inputs
    public fun test_configure_assets(
        account: &signer, config: vector<RewardsConfigInput>
    ) acquires EmissionManagerData {
        configure_assets_internal(account, config);
    }

    #[test_only]
    /// @notice Gets the rewards controller for testing
    /// @return The address of the rewards controller
    public fun get_rewards_controller_for_testing(): address acquires EmissionManagerData {
        get_rewards_controller_ensure_defined()
    }
}
