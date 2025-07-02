/// @title Rewards Controller Module
/// @author Aave
/// @notice Implements functionality to manage and distribute rewards for Aave protocol assets
module aave_pool::rewards_controller {
    // imports
    use std::option;
    use std::option::Option;
    use std::simple_map;
    use std::vector;
    use aptos_std::simple_map::SimpleMap;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::{Object, ObjectGroup};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use aave_config::error_config;
    use aave_math::math_utils;
    use aave_oracle::oracle;

    // friend modules
    friend aave_pool::token_base;
    friend aave_pool::rewards_distributor;
    friend aave_pool::emission_manager;

    #[test_only]
    friend aave_pool::rewards_controller_tests;
    #[test_only]
    friend aave_pool::claim_all_rewards_on_behalf_tests;
    #[test_only]
    friend aave_pool::claim_rewards_on_behalf_tests;
    #[test_only]
    friend aave_pool::configure_assets_tests;
    #[test_only]
    friend aave_pool::set_distribution_end_tests;
    #[test_only]
    friend aave_pool::set_emission_per_second_tests;
    #[test_only]
    friend aave_pool::set_pull_rewards_transfer_strategy_tests_tests;
    #[test_only]
    friend aave_pool::claim_all_rewards_tests;

    // Error constants

    // Structs
    #[resource_group_member(group = ObjectGroup)]
    struct RewardsControllerData has key {
        authorized_claimers: SmartTable<address, address>,
        pull_rewards_transfer_strategy_table: SmartTable<address, address>,
        assets: SmartTable<address, AssetData>,
        is_reward_enabled: SmartTable<address, bool>
    }

    struct RewardsConfigInput has store, drop {
        emission_per_second: u128,
        max_emission_rate: u128,
        total_supply: u256,
        distribution_end: u32,
        asset: address,
        reward: address,
        pull_rewards_transfer_strategy: address
    }

    struct AssetData has key, store, drop, copy {
        rewards: SimpleMap<address, RewardData>,
        available_rewards: SimpleMap<u128, address>,
        available_rewards_count: u128,
        decimals: u8
    }

    struct RewardData has key, store, drop, copy {
        index: u128,
        emission_per_second: u128,
        max_emission_rate: u128,
        last_update_timestamp: u32,
        distribution_end: u32,
        users_data: SimpleMap<address, UserData>
    }

    struct UserData has key, store, copy, drop {
        index: u128,
        accrued: u128
    }

    struct UserAssetBalance has store, drop, copy {
        asset: address,
        user_balance: u256,
        total_supply: u256
    }

    // Events
    #[event]
    struct ClaimerSet has store, drop {
        /// The address of the user for whom the claimer is being set
        user: address,
        /// The address of the claimer being authorized
        claimer: address,
        /// The address of the rewards controller that manages this relationship
        rewards_controller_address: address
    }

    #[event]
    struct Accrued has store, drop {
        /// The address of the asset for which rewards are being accrued
        asset: address,
        /// The address of the reward token
        reward: address,
        /// The address of the user receiving the rewards
        user: address,
        /// The index of the asset in the rewards distribution
        asset_index: u256,
        /// The user-specific index for this asset and reward
        user_index: u256,
        /// The amount of rewards accrued
        rewards_accrued: u256,
        /// The address of the rewards controller that manages this accrual
        rewards_controller_address: address
    }

    #[event]
    struct AssetConfigUpdated has store, drop {
        /// The address of the asset whose configuration is being updated
        asset: address,
        /// The address of the reward token
        reward: address,
        /// The previous emission rate per second
        old_emission: u256,
        /// The new emission rate per second
        new_emission: u256,
        /// The previous end timestamp for reward distribution
        old_distribution_end: u256,
        /// The new end timestamp for reward distribution
        new_distribution_end: u256,
        /// The current index of the asset in the rewards distribution
        asset_index: u256,
        /// The address of the rewards controller that manages this configuration
        rewards_controller_address: address
    }

    #[event]
    struct PullRewardsTransferStrategyInstalled has store, drop {
        /// The address of the reward token
        reward: address,
        /// The address of the transfer strategy contract
        strategy: address,
        /// The address of the rewards controller that manages this strategy
        rewards_controller_address: address
    }

    // Public view functions
    #[view]
    /// @notice Gets the address of the rewards controller
    /// @param seed The seed used to create the rewards controller object
    /// @return The address of the rewards controller
    public fun rewards_controller_address(seed: vector<u8>): address {
        object::create_object_address(&@aave_pool, seed)
    }

    #[view]
    /// @notice Gets the rewards controller object
    /// @param seed The seed used to create the rewards controller object
    /// @return The rewards controller object
    public fun rewards_controller_object(seed: vector<u8>): Object<RewardsControllerData> {
        object::address_to_object<RewardsControllerData>(rewards_controller_address(seed))
    }

    #[view]
    /// @notice Gets the claimer for a user
    /// @param user The user address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Option containing the claimer address if one exists
    public fun get_claimer(
        user: address, rewards_controller_address: address
    ): Option<address> acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return option::none()
        };
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        if (smart_table::contains(&rewards_controller_data.authorized_claimers, user)) {
            option::some(
                *smart_table::borrow(
                    &rewards_controller_data.authorized_claimers, user
                )
            )
        } else {
            option::none()
        }
    }

    #[view]
    /// @notice Gets the pull rewards transfer strategy for a reward
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Option containing the strategy address if one exists
    public fun get_pull_rewards_transfer_strategy(
        reward: address, rewards_controller_address: address
    ): Option<address> acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return option::none()
        };
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        if (smart_table::contains(
            &rewards_controller_data.pull_rewards_transfer_strategy_table, reward
        )) {
            option::some(
                *smart_table::borrow(
                    &rewards_controller_data.pull_rewards_transfer_strategy_table,
                    reward
                )
            )
        } else {
            option::none()
        }
    }

    #[view]
    /// @notice Looks up asset data for a specific asset
    /// @param asset The asset address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Option containing the asset data if it exists
    public fun lookup_asset_data(
        asset: address, rewards_controller_address: address
    ): Option<AssetData> acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return option::none()
        };

        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        if (!smart_table::contains(&rewards_controller_data.assets, asset)) {
            return option::none()
        };

        option::some(*smart_table::borrow(&rewards_controller_data.assets, asset))
    }

    #[view]
    /// @notice Looks up rewards data for a specific asset and reward
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing Options for asset data and reward data
    public fun lookup_rewards_data(
        asset: address, reward: address, rewards_controller_address: address
    ): (Option<AssetData>, Option<RewardData>) acquires RewardsControllerData {
        let asset_data = lookup_asset_data(asset, rewards_controller_address);
        if (option::is_none(&asset_data)) {
            return (option::none(), option::none())
        };

        let asset_data = option::destroy_some(asset_data);
        if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
            return (option::some(asset_data), option::none())
        };

        let rewards_data = *simple_map::borrow(&asset_data.rewards, &reward);
        (option::some(asset_data), option::some(rewards_data))
    }

    #[view]
    /// @notice Looks up user data for a specific asset, reward, and user
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param user The user address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing Options for asset data, reward data, and user data
    public fun lookup_user_data(
        asset: address,
        reward: address,
        user: address,
        rewards_controller_address: address
    ): (Option<AssetData>, Option<RewardData>, Option<UserData>) acquires RewardsControllerData {
        let (asset_data, reward_data) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        if (option::is_none(&reward_data)) {
            return (asset_data, reward_data, option::none())
        };

        let rewards_data = option::destroy_some(reward_data);
        if (!simple_map::contains_key(&rewards_data.users_data, &user)) {
            return (asset_data, option::some(rewards_data), option::none())
        };

        let user_data = *simple_map::borrow(&rewards_data.users_data, &user);
        return (asset_data, option::some(rewards_data), option::some(user_data))
    }

    #[view]
    /// @notice Gets rewards data for a specific asset and reward
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing index, emission per second, last update timestamp, and distribution end
    public fun get_rewards_data(
        asset: address, reward: address, rewards_controller_address: address
    ): (u256, u256, u256, u256) acquires RewardsControllerData {
        let (_, rewards_data) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        if (option::is_none(&rewards_data)) {
            return (0, 0, 0, 0)
        };

        let RewardData {
            index,
            emission_per_second,
            max_emission_rate: _,
            last_update_timestamp,
            distribution_end,
            users_data: _
        } = option::destroy_some(rewards_data);
        (
            (index as u256),
            (emission_per_second as u256),
            (last_update_timestamp as u256),
            (distribution_end as u256)
        )
    }

    #[view]
    /// @notice Gets user data for a specific asset, reward, and user
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param user The user address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing user index and accrued rewards
    public fun get_user_data(
        asset: address,
        reward: address,
        user: address,
        rewards_controller_address: address
    ): (u256, u256) acquires RewardsControllerData {
        let (_, _, user_data) =
            lookup_user_data(
                asset,
                reward,
                user,
                rewards_controller_address
            );
        if (option::is_none(&user_data)) {
            return (0, 0)
        };

        let UserData { index, accrued } = option::destroy_some(user_data);
        ((index as u256), (accrued as u256))
    }

    #[view]
    /// @notice Gets the asset index for a specific asset and reward
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing the current asset index and new asset index
    public fun get_asset_index(
        asset: address, reward: address, rewards_controller_address: address
    ): (u256, u256) acquires RewardsControllerData {
        let (asset_data, rewards_data) =
            lookup_rewards_data(asset, reward, rewards_controller_address);
        if (option::is_none(&rewards_data)) {
            return (0, 0)
        };

        let asset_data = option::destroy_some(asset_data);
        let rewards_data = option::destroy_some(rewards_data);

        let asset_supply =
            option::destroy_with_default(
                fungible_asset::supply(object::address_to_object<Metadata>(asset)),
                0
            );
        calculate_asset_index_internal(
            &rewards_data,
            (asset_supply as u256),
            math_utils::pow(10, (asset_data.decimals as u256))
        )
    }

    #[view]
    /// @notice Gets the distribution end for a specific asset and reward
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The distribution end timestamp
    public fun get_distribution_end(
        asset: address, reward: address, rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let (_, _, _, distribution_end) =
            get_rewards_data(asset, reward, rewards_controller_address);
        distribution_end
    }

    #[view]
    /// @notice Gets all rewards for a specific asset
    /// @param asset The asset address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Vector of reward addresses
    public fun get_rewards_by_asset(
        asset: address, rewards_controller_address: address
    ): vector<address> acquires RewardsControllerData {
        let asset_data = lookup_asset_data(asset, rewards_controller_address);
        if (option::is_none(&asset_data)) {
            return vector[]
        };

        let asset_data = option::destroy_some(asset_data);
        let rewards_count = asset_data.available_rewards_count;
        let available_rewards = vector[];

        for (i in 0..rewards_count) {
            let el = simple_map::borrow(&asset_data.available_rewards, &i);
            vector::push_back(&mut available_rewards, *el);
        };
        available_rewards
    }

    #[view]
    /// @notice Gets all available rewards
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Vector of reward addresses
    public fun get_rewards_list(
        rewards_controller_address: address
    ): vector<address> acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return vector[]
        };

        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);
        rewards_controller_data.is_reward_enabled.keys()
    }

    #[view]
    /// @notice Gets the user asset index for a specific user, asset, and reward
    /// @param user The user address
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The user asset index
    public fun get_user_asset_index(
        user: address,
        asset: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        let (index, _) = get_user_data(
            asset,
            reward,
            user,
            rewards_controller_address
        );
        index
    }

    #[view]
    /// @notice Gets the user accrued rewards for a specific user and reward
    /// @param user The user address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The user accrued rewards
    public fun get_user_accrued_rewards(
        user: address, reward: address, rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return 0
        };
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        let assets_list = rewards_controller_data.assets.keys();

        let total_accrued = 0;
        for (i in 0..vector::length(&assets_list)) {
            let asset_data =
                smart_table::borrow(
                    &rewards_controller_data.assets,
                    *vector::borrow(&assets_list, i)
                );
            if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                continue
            };

            let reward_data = simple_map::borrow(&asset_data.rewards, &reward);
            if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                continue
            };

            let user_data: &UserData = simple_map::borrow(
                &reward_data.users_data, &user
            );
            total_accrued = total_accrued + (user_data.accrued as u256);
        };

        total_accrued
    }

    #[view]
    /// @notice Gets the user rewards for specific assets, user and reward
    /// @param assets Vector of asset addresses
    /// @param user The user address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The user rewards
    public fun get_user_rewards(
        assets: vector<address>,
        user: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        get_user_reward(
            user,
            reward,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        )
    }

    #[view]
    /// @notice Gets all user rewards for specific assets and user
    /// @param assets Vector of asset addresses
    /// @param user The user address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of reward amounts
    public fun get_all_user_rewards(
        assets: vector<address>, user: address, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return (vector[], vector[])
        };
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        let user_asset_balances = get_user_asset_balances(assets, user);

        let rewards_list = rewards_controller_data.is_reward_enabled.keys();
        let rewards_list_len = vector::length(&rewards_list);

        // initialize the unclaimed amounts vector
        let unclaimed_amounts = vector[];
        for (_i in 0..rewards_list_len) {
            vector::push_back(&mut unclaimed_amounts, 0);
        };

        // go over the asset list and check all rewards
        let assets_list_len = vector::length(&user_asset_balances);
        for (i in 0..assets_list_len) {
            let asset_balance = vector::borrow(&user_asset_balances, i);
            if (!smart_table::contains(
                &rewards_controller_data.assets, asset_balance.asset
            )) {
                continue
            };

            let asset_data =
                smart_table::borrow(
                    &rewards_controller_data.assets, asset_balance.asset
                );
            for (r in 0..rewards_list_len) {
                let reward = *vector::borrow(&rewards_list, r);
                if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                    continue
                };

                let reward_data = simple_map::borrow(&asset_data.rewards, &reward);
                if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                    continue
                };

                let user_data = simple_map::borrow(&reward_data.users_data, &user);
                let unclaimed_amount = vector::borrow_mut(&mut unclaimed_amounts, r);
                *unclaimed_amount = *unclaimed_amount + (user_data.accrued as u256);

                // further calculate pending amount to unclaimed amount
                if (asset_balance.user_balance == 0) {
                    continue
                };
                *unclaimed_amount =
                    *unclaimed_amount
                        + calculate_pending_rewards(
                            asset_balance,
                            asset_data,
                            reward_data,
                            user_data
                        );
            };
        };
        (rewards_list, unclaimed_amounts)
    }

    #[view]
    /// @notice Gets the decimals for a specific asset
    /// @param asset The asset address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The asset decimals
    public fun get_asset_decimals(
        asset: address, rewards_controller_address: address
    ): u8 acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return 0
        };

        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        if (!smart_table::contains(&rewards_controller_data.assets, asset)) {
            return 0
        };

        let asset_data = smart_table::borrow(&rewards_controller_data.assets, asset);

        asset_data.decimals
    }

    // Public functions
    /// @notice Gets the reward from a reward config
    /// @param config The reward config
    /// @return The reward address
    public fun get_reward_from_config(config: &RewardsConfigInput): address {
        config.reward
    }

    /// @notice Gets the rewards transfer strategy from a reward config
    /// @param config The reward config
    /// @return The rewards transfer strategy address
    public fun get_rewards_transfer_strategy_from_config(
        config: &RewardsConfigInput
    ): address {
        config.pull_rewards_transfer_strategy
    }

    // Public friend functions
    /// @notice Initializes the rewards controller
    /// @param sender The sender account
    /// @param seed The seed used to create the rewards controller object
    public(friend) fun initialize(sender: &signer, seed: vector<u8>) {
        let state_object_constructor_ref = &object::create_named_object(sender, seed);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            RewardsControllerData {
                authorized_claimers: smart_table::new(),
                pull_rewards_transfer_strategy_table: smart_table::new(),
                assets: smart_table::new(),
                is_reward_enabled: smart_table::new()
            }
        );
    }

    /// @notice Creates a reward input config
    /// @param emission_per_second The emission per second
    /// @param max_emission_rate The maximum emission rate
    /// @param total_supply The total supply
    /// @param distribution_end The distribution end timestamp
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param pull_rewards_transfer_strategy The pull rewards transfer strategy address
    /// @return The created reward input config
    public(friend) fun create_reward_input_config(
        emission_per_second: u128,
        max_emission_rate: u128,
        total_supply: u256,
        distribution_end: u32,
        asset: address,
        reward: address,
        pull_rewards_transfer_strategy: address
    ): RewardsConfigInput {
        RewardsConfigInput {
            emission_per_second,
            max_emission_rate,
            total_supply,
            distribution_end,
            asset,
            reward,
            pull_rewards_transfer_strategy
        }
    }

    /// @notice Configures assets with reward parameters
    /// @param config_inputs Vector of reward config inputs
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun configure_assets(
        config_inputs: vector<RewardsConfigInput>, rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );

        for (i in 0..vector::length(&config_inputs)) {
            let config = vector::borrow_mut(&mut config_inputs, i);
            let asset_supply =
                option::destroy_with_default(
                    fungible_asset::supply(
                        object::address_to_object<Metadata>(config.asset)
                    ),
                    0
                );

            config.total_supply = (asset_supply as u256);
            install_pull_rewards_transfer_strategy(
                config.reward,
                config.pull_rewards_transfer_strategy,
                rewards_controller_address
            );

            assert!(
                oracle::get_asset_price(config.reward) > 0,
                error_config::get_eprice_oracle_check_failed()
            );
        };
        configure_assets_internal(config_inputs, rewards_controller_address);
    }

    /// @notice Sets the pull rewards transfer strategy for a reward
    /// @param reward The reward address
    /// @param strategy The strategy address
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun set_pull_rewards_transfer_strategy(
        reward: address, strategy: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );

        install_pull_rewards_transfer_strategy(
            reward, strategy, rewards_controller_address
        );
    }

    /// @notice Handles an action for an asset, user, total supply, and user balance
    /// @dev This function is called when a user performs an action that will trigger the mint, burn, or transfer function of a ScaledBalanceToken
    /// @param asset The asset address
    /// @param user The user address
    /// @param total_supply The total supply
    /// @param user_balance The user balance
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun handle_action(
        asset: address,
        user: address,
        total_supply: u256,
        user_balance: u256,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) { return };
        update_data(
            asset,
            user,
            user_balance,
            total_supply,
            rewards_controller_address
        );
    }

    /// @notice Sets the claimer for a user
    /// @param user The user address
    /// @param claimer The claimer address
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun set_claimer(
        user: address, claimer: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::upsert(
            &mut rewards_controller_data.authorized_claimers, user, claimer
        );
        event::emit(ClaimerSet { user, claimer, rewards_controller_address });
    }

    /// @notice Claims rewards internal update data
    /// @param assets Vector of asset addresses
    /// @param amount The amount to claim
    /// @param user The user address
    /// @param reward The reward address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The claimed amount
    public(friend) fun claim_rewards_internal_update_data(
        assets: vector<address>,
        amount: u256,
        user: address,
        reward: address,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );

        if (amount == 0) {
            return 0
        };

        update_data_multiple(
            user,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        let total_rewards = 0;
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            if (!smart_table::contains(&rewards_controller_data.assets, asset)) {
                continue
            };

            let asset_data =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
            if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                continue
            };

            let reward_data = simple_map::borrow_mut(&mut asset_data.rewards, &reward);
            if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                continue
            };

            let user_data = simple_map::borrow_mut(&mut reward_data.users_data, &user);
            total_rewards = total_rewards + (user_data.accrued as u256);

            if (total_rewards <= amount) {
                user_data.accrued = 0;
            } else {
                let difference = total_rewards - amount;
                total_rewards = amount;
                user_data.accrued = (difference as u128);
                break
            };
        };

        if (total_rewards == 0) {
            return 0
        };

        total_rewards
    }

    /// @notice Claims all rewards internal update data
    /// @param assets Vector of asset addresses
    /// @param user The user address
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Tuple containing vector of reward addresses and vector of claimed amounts
    public(friend) fun claim_all_rewards_internal_update_data(
        assets: vector<address>, user: address, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );

        update_data_multiple(
            user,
            get_user_asset_balances(assets, user),
            rewards_controller_address
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        let rewards_list = rewards_controller_data.is_reward_enabled.keys();
        let rewards_list_length = vector::length(&rewards_list);

        let claimed_amounts = vector[];
        for (_i in 0..rewards_list_length) {
            vector::push_back(&mut claimed_amounts, 0);
        };

        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);
            if (!smart_table::contains(&rewards_controller_data.assets, asset)) {
                continue
            };

            let asset_data =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
            for (j in 0..rewards_list_length) {
                let reward = *vector::borrow(&rewards_list, j);
                if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                    continue
                };

                let reward_data = simple_map::borrow_mut(
                    &mut asset_data.rewards, &reward
                );
                if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                    continue
                };

                let user_data = simple_map::borrow_mut(
                    &mut reward_data.users_data, &user
                );

                // update the claimed amount and accrued amount
                let claimed_amount = vector::borrow_mut(&mut claimed_amounts, j);
                *claimed_amount = *claimed_amount + (user_data.accrued as u256);
                user_data.accrued = 0;
            };
        };

        (rewards_list, claimed_amounts)
    }

    /// @notice Sets the distribution end for an asset and reward
    /// @param asset The asset address
    /// @param reward The reward address
    /// @param new_distribution_end The new distribution end timestamp
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun set_distribution_end(
        asset: address,
        reward: address,
        new_distribution_end: u32,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        assert!(
            smart_table::contains(&rewards_controller_data.assets, asset),
            error_config::get_edistribution_does_not_exist()
        );

        let asset_data =
            smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        assert!(
            simple_map::contains_key(&asset_data.rewards, &reward),
            error_config::get_edistribution_does_not_exist()
        );

        let asset_supply =
            option::destroy_with_default(
                fungible_asset::supply(object::address_to_object<Metadata>(asset)),
                0
            );

        let reward_data = simple_map::borrow_mut(&mut asset_data.rewards, &reward);

        let old_distribution_end = reward_data.distribution_end;
        let (new_index, _) =
            update_reward_data(
                reward_data,
                (asset_supply as u256),
                math_utils::pow(10, (asset_data.decimals as u256))
            );

        reward_data.distribution_end = new_distribution_end;
        reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);

        event::emit(
            AssetConfigUpdated {
                asset,
                reward,
                old_emission: (reward_data.emission_per_second as u256),
                new_emission: (reward_data.emission_per_second as u256),
                old_distribution_end: (old_distribution_end as u256),
                new_distribution_end: (new_distribution_end as u256),
                asset_index: new_index,
                rewards_controller_address
            }
        );
    }

    /// @notice Sets the emission per second for assets and rewards
    /// @param asset The asset address
    /// @param rewards Vector of reward addresses
    /// @param new_emissions_per_second Vector of new emissions per second
    /// @param rewards_controller_address The address of the rewards controller
    public(friend) fun set_emission_per_second(
        asset: address,
        rewards: vector<address>,
        new_emissions_per_second: vector<u128>,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_len = vector::length(&rewards);
        assert!(
            rewards_len == vector::length(&new_emissions_per_second),
            error_config::get_einvalid_reward_config()
        );

        assert!(
            rewards_controller_data_exists(rewards_controller_address),
            error_config::get_einvalid_rewards_controller_address()
        );

        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        assert!(
            smart_table::contains(&rewards_controller_data.assets, asset),
            error_config::get_edistribution_does_not_exist()
        );

        let asset_data =
            smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);

        let decimals = asset_data.decimals;
        for (i in 0..rewards_len) {
            let reward = *vector::borrow(&rewards, i);
            assert!(
                simple_map::contains_key(&asset_data.rewards, &reward),
                error_config::get_edistribution_does_not_exist()
            );

            let reward_data = simple_map::borrow_mut(&mut asset_data.rewards, &reward);
            assert!(
                decimals != 0 && reward_data.last_update_timestamp != 0,
                error_config::get_edistribution_does_not_exist()
            );

            // to be on the safe side, record the old value before the update
            let old_emission_per_second = reward_data.emission_per_second;

            let asset_supply =
                option::destroy_with_default(
                    fungible_asset::supply(object::address_to_object<Metadata>(asset)),
                    0
                );

            let (new_index, _) =
                update_reward_data(
                    reward_data,
                    (asset_supply as u256),
                    math_utils::pow(10, (decimals as u256))
                );

            let new_emission_per_second = *vector::borrow(&new_emissions_per_second, i);
            assert!(
                new_emission_per_second <= reward_data.max_emission_rate,
                error_config::get_einvalid_emission_rate()
            );

            reward_data.emission_per_second = new_emission_per_second;
            reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);

            event::emit(
                AssetConfigUpdated {
                    asset,
                    reward: *vector::borrow(&rewards, i),
                    old_emission: (old_emission_per_second as u256),
                    new_emission: (new_emission_per_second as u256),
                    old_distribution_end: (reward_data.distribution_end as u256),
                    new_distribution_end: (reward_data.distribution_end as u256),
                    asset_index: new_index,
                    rewards_controller_address
                }
            );
        }
    }

    // Private functions
    /// @notice Checks if rewards controller data exists
    /// @param rewards_controller_address The address of the rewards controller
    /// @return Whether rewards controller data exists
    fun rewards_controller_data_exists(
        rewards_controller_address: address
    ): bool {
        exists<RewardsControllerData>(rewards_controller_address)
    }

    /// @notice Gets user asset balances for a list of assets and a user
    /// @param assets Vector of asset addresses
    /// @param user The user address
    /// @return Vector of user asset balances
    fun get_user_asset_balances(assets: vector<address>, user: address):
        vector<UserAssetBalance> {
        let user_asset_balances = vector[];
        for (i in 0..vector::length(&assets)) {
            let asset = *vector::borrow(&assets, i);

            let total_supply =
                option::destroy_with_default(
                    fungible_asset::supply(object::address_to_object<Metadata>(asset)),
                    0
                );

            let user_balance =
                primary_fungible_store::balance(
                    user, object::address_to_object<Metadata>(asset)
                );

            vector::push_back(
                &mut user_asset_balances,
                UserAssetBalance {
                    asset,
                    user_balance: (user_balance as u256),
                    total_supply: (total_supply as u256)
                }
            );
        };
        user_asset_balances
    }

    /// @notice Installs a pull rewards transfer strategy for a reward
    /// @param reward The reward address
    /// @param strategy The strategy address
    /// @param rewards_controller_address The address of the rewards controller
    fun install_pull_rewards_transfer_strategy(
        reward: address, strategy: address, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::upsert(
            &mut rewards_controller_data.pull_rewards_transfer_strategy_table,
            reward,
            strategy
        );

        event::emit(
            PullRewardsTransferStrategyInstalled {
                reward,
                strategy,
                rewards_controller_address
            }
        );
    }

    /// @notice Configures assets internal
    /// @param rewards_input Vector of reward config inputs
    /// @param rewards_controller_address The address of the rewards controller
    fun configure_assets_internal(
        rewards_input: vector<RewardsConfigInput>, rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        for (i in 0..vector::length(&rewards_input)) {
            let reward_input = vector::borrow(&rewards_input, i);

            // configure asset
            let asset = reward_input.asset;
            if (!smart_table::contains(&rewards_controller_data.assets, asset)) {
                // this asset is never initialized before
                smart_table::add(
                    &mut rewards_controller_data.assets,
                    asset,
                    AssetData {
                        rewards: simple_map::new(),
                        available_rewards: simple_map::new(),
                        available_rewards_count: 0,
                        decimals: fungible_asset::decimals(
                            object::address_to_object<Metadata>(asset)
                        )
                    }
                );
            };

            let asset_data =
                smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);

            // configure reward
            let reward = reward_input.reward;

            if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                // first time adding this reward to the asset
                simple_map::add(
                    &mut asset_data.rewards,
                    reward,
                    RewardData {
                        index: 0,
                        emission_per_second: 0,
                        max_emission_rate: 0,
                        last_update_timestamp: 0,
                        distribution_end: 0,
                        users_data: simple_map::new()
                    }
                );

                simple_map::add(
                    &mut asset_data.available_rewards,
                    asset_data.available_rewards_count,
                    reward
                );
                asset_data.available_rewards_count = asset_data.available_rewards_count
                    + 1;
            };

            // add reward to global rewards list if still not enabled
            let is_reward_enabled =
                smart_table::borrow_mut_with_default(
                    &mut rewards_controller_data.is_reward_enabled, reward, false
                );
            if (!*is_reward_enabled) {
                *is_reward_enabled = true;
            };

            // update rewards data, set index and last_update_timestamp
            let reward_data = simple_map::borrow_mut(&mut asset_data.rewards, &reward);

            let (new_index, _) =
                update_reward_data(
                    reward_data,
                    reward_input.total_supply,
                    math_utils::pow(10, (asset_data.decimals as u256))
                );

            let old_emissions_per_second = reward_data.emission_per_second;
            let old_distribution_end = reward_data.distribution_end;

            assert!(
                reward_input.emission_per_second <= reward_input.max_emission_rate,
                error_config::get_einvalid_emission_rate()
            );

            reward_data.emission_per_second = reward_input.emission_per_second;
            reward_data.max_emission_rate = reward_input.max_emission_rate;
            reward_data.distribution_end = reward_input.distribution_end;
            reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);

            event::emit(
                AssetConfigUpdated {
                    asset,
                    reward,
                    old_emission: (old_emissions_per_second as u256),
                    new_emission: (reward_data.emission_per_second as u256),
                    old_distribution_end: (old_distribution_end as u256),
                    new_distribution_end: (reward_data.distribution_end as u256),
                    asset_index: new_index,
                    rewards_controller_address
                }
            );
        }
    }

    /// @notice Updates reward data
    /// @param reward_data The reward data
    /// @param total_supply The total supply
    /// @param asset_unit The asset unit
    /// @return Tuple containing the new asset index and whether the index was updated
    fun update_reward_data(
        reward_data: &mut RewardData, total_supply: u256, asset_unit: u256
    ): (u256, bool) {
        let (old_index, new_index) =
            calculate_asset_index_internal(reward_data, total_supply, asset_unit);
        let index_updated = false;
        if (new_index != old_index) {
            assert!(
                new_index < math_utils::pow(2, 104),
                error_config::get_ereward_index_overflow()
            );
            index_updated = true;
            reward_data.index = (new_index as u128);
        };

        (new_index, index_updated)
    }

    /// @notice Updates user data
    /// @param user_data The user data
    /// @param user_balance The user balance
    /// @param new_asset_index The new asset index
    /// @param asset_unit The asset unit
    /// @return Tuple containing the rewards accrued and whether the data was updated
    fun update_user_data(
        user_data: &mut UserData,
        user_balance: u256,
        new_asset_index: u256,
        asset_unit: u256
    ): (u256, bool) {
        let user_index = user_data.index;
        let rewards_accrued = 0;
        let data_updated = user_index != (new_asset_index as u128);
        if (data_updated) {
            user_data.index = (new_asset_index as u128);
            if (user_balance != 0) {
                rewards_accrued = calculate_rewards(
                    user_balance,
                    new_asset_index,
                    (user_index as u256),
                    asset_unit
                );
                user_data.accrued = user_data.accrued + (rewards_accrued as u128);
            };
        };
        (rewards_accrued, data_updated)
    }

    /// @notice Updates data for an asset, user, balance, and total supply
    /// @param asset The asset address
    /// @param user The user address
    /// @param user_balance The user balance
    /// @param total_supply The total supply
    /// @param rewards_controller_address The address of the rewards controller
    fun update_data(
        asset: address,
        user: address,
        user_balance: u256,
        total_supply: u256,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);

        // do nothing when `asset` is not configured in the rewards controller
        if (!smart_table::contains(&rewards_controller_data.assets, asset)) { return };

        let asset_data =
            smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        let num_available_rewards = asset_data.available_rewards_count;
        let asset_unit = math_utils::pow(10, (asset_data.decimals as u256));

        if (num_available_rewards == 0) { return };

        for (r in 0..num_available_rewards) {
            let reward = *simple_map::borrow(&mut asset_data.available_rewards, &r);

            // this borrow is not expected to abort
            let reward_data = simple_map::borrow_mut(&mut asset_data.rewards, &reward);
            let (new_asset_index, reward_data_updated) =
                update_reward_data(reward_data, total_supply, asset_unit);
            if (reward_data_updated) {
                reward_data.last_update_timestamp = (timestamp::now_seconds() as u32);
            };

            // Unlike for the `asset` and `reward` distribution which is fine to
            // "silently exit" because it means that an admin/authed user has
            // not configured it yet for the user's data, we can't handle it in
            // that way.
            //
            // Let's assume that `(asset, reward)` has been configured. When the
            // user performs (as an example) an action on the AToken that will
            // trigger `handle_action` that will call `update_data`, the user
            // record in `reward_data.users_data` does not exist yet, and we
            // need to give it a default value and subsequent logic should
            // properly update it.
            if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                simple_map::add(
                    &mut reward_data.users_data,
                    user,
                    UserData { index: (new_asset_index as u128), accrued: 0 }
                )
            };

            let user_data = simple_map::borrow_mut(&mut reward_data.users_data, &user);
            let (rewards_accrued, user_data_updated) =
                update_user_data(
                    user_data,
                    user_balance,
                    new_asset_index,
                    asset_unit
                );

            if (reward_data_updated || user_data_updated) {
                event::emit(
                    Accrued {
                        asset,
                        reward,
                        user,
                        asset_index: new_asset_index,
                        user_index: new_asset_index,
                        rewards_accrued,
                        rewards_controller_address
                    }
                )
            };
        };
    }

    /// @notice Updates data for multiple assets
    /// @param user The user address
    /// @param user_asset_balances Vector of user asset balances
    /// @param rewards_controller_address The address of the rewards controller
    fun update_data_multiple(
        user: address,
        user_asset_balances: vector<UserAssetBalance>,
        rewards_controller_address: address
    ) acquires RewardsControllerData {
        for (i in 0..vector::length(&user_asset_balances)) {
            let user_asset_balances_i = vector::borrow(&user_asset_balances, i);
            update_data(
                user_asset_balances_i.asset,
                user,
                user_asset_balances_i.user_balance,
                user_asset_balances_i.total_supply,
                rewards_controller_address
            );
        };
    }

    /// @notice Gets the user reward
    /// @param user The user address
    /// @param reward The reward address
    /// @param user_asset_balances Vector of user asset balances
    /// @param rewards_controller_address The address of the rewards controller
    /// @return The user reward amount
    fun get_user_reward(
        user: address,
        reward: address,
        user_asset_balances: vector<UserAssetBalance>,
        rewards_controller_address: address
    ): u256 acquires RewardsControllerData {
        if (!rewards_controller_data_exists(rewards_controller_address)) {
            return 0
        };
        let rewards_controller_data =
            borrow_global<RewardsControllerData>(rewards_controller_address);

        let unclaimed_rewards = 0;
        for (i in 0..vector::length(&user_asset_balances)) {
            let asset_balance = vector::borrow(&user_asset_balances, i);
            if (!smart_table::contains(
                &rewards_controller_data.assets, asset_balance.asset
            )) {
                continue
            };

            let asset_data =
                smart_table::borrow(
                    &rewards_controller_data.assets, asset_balance.asset
                );
            if (!simple_map::contains_key(&asset_data.rewards, &reward)) {
                continue
            };

            let reward_data = simple_map::borrow(&asset_data.rewards, &reward);
            if (!simple_map::contains_key(&reward_data.users_data, &user)) {
                continue
            };

            // collect the accrued amount first
            let user_data = simple_map::borrow(&reward_data.users_data, &user);
            unclaimed_rewards = unclaimed_rewards + (user_data.accrued as u256);

            // further calculate pending amount to unclaimed amount
            if (asset_balance.user_balance == 0) {
                continue
            };
            unclaimed_rewards =
                unclaimed_rewards
                    + calculate_pending_rewards(
                        asset_balance,
                        asset_data,
                        reward_data,
                        user_data
                    );
        };

        unclaimed_rewards
    }

    /// @notice Calculates pending rewards
    /// @param user_asset_balance The user asset balance
    /// @param asset_data The asset data
    /// @param reward_data The reward data
    /// @param user_data The user data
    /// @return The pending rewards
    fun calculate_pending_rewards(
        user_asset_balance: &UserAssetBalance,
        asset_data: &AssetData,
        reward_data: &RewardData,
        user_data: &UserData
    ): u256 {
        let asset_unit = math_utils::pow(10, (asset_data.decimals as u256));
        let (_, next_index) =
            calculate_asset_index_internal(
                reward_data, user_asset_balance.total_supply, asset_unit
            );

        let index = (user_data.index as u256);
        calculate_rewards(
            user_asset_balance.user_balance,
            next_index,
            index,
            asset_unit
        )
    }

    /// @notice Calculates rewards
    /// @param user_balance The user balance
    /// @param reserve_index The reserve index
    /// @param user_index The user index
    /// @param asset_unit The asset unit
    /// @return The calculated rewards
    fun calculate_rewards(
        user_balance: u256,
        reserve_index: u256,
        user_index: u256,
        asset_unit: u256
    ): u256 {
        let result = user_balance * (reserve_index - user_index);
        result / asset_unit
    }

    /// @notice Calculates asset index internal
    /// @param reward_data The reward data
    /// @param total_supply The total supply
    /// @param asset_unit The asset unit
    /// @return Tuple containing the old index and new index
    fun calculate_asset_index_internal(
        reward_data: &RewardData, total_supply: u256, asset_unit: u256
    ): (u256, u256) {
        let old_index = (reward_data.index as u256);
        let distribution_end = (reward_data.distribution_end as u256);
        let emission_per_second = (reward_data.emission_per_second as u256);
        let last_update_timestamp = (reward_data.last_update_timestamp as u256);
        let now = timestamp::now_seconds() as u256;

        if (emission_per_second == 0
            || total_supply == 0
            || last_update_timestamp == now
            || last_update_timestamp >= distribution_end) {
            return (old_index, old_index)
        };

        let current_timestamp =
            if (now > distribution_end) {
                distribution_end
            } else { now };

        let time_delta = current_timestamp - last_update_timestamp;
        let first_term = emission_per_second * time_delta * asset_unit;
        first_term = first_term / total_supply;
        (old_index, (first_term + old_index))
    }

    // Test only functions
    #[test_only]
    public fun test_initialize(sender: &signer, seed: vector<u8>) {
        initialize(sender, seed);
    }

    #[test_only]
    public fun create_rewards_config_input(
        emission_per_second: u128,
        max_emission_rate: u128,
        total_supply: u256,
        distribution_end: u32,
        asset: address,
        reward: address,
        pull_rewards_transfer_strategy: address
    ): RewardsConfigInput {
        RewardsConfigInput {
            emission_per_second,
            max_emission_rate,
            total_supply,
            distribution_end,
            asset,
            reward,
            pull_rewards_transfer_strategy
        }
    }

    #[test_only]
    public fun add_asset(
        rewards_controller_address: address, asset_addr: address, asset: AssetData
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::add(&mut rewards_controller_data.assets, asset_addr, asset);
    }

    #[test_only]
    public fun enable_reward(
        rewards_controller_address: address, reward: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        smart_table::add(&mut rewards_controller_data.is_reward_enabled, reward, true);
    }

    #[test_only]
    public fun add_rewards_by_asset(
        asset: address,
        rewards_controller_address: address,
        i: u128,
        addr: address
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        simple_map::upsert(&mut asset.available_rewards, i, addr);
    }

    #[test_only]
    public fun add_user_asset_index(
        user: address,
        asset: address,
        reward: address,
        rewards_controller_address: address,
        user_data: UserData
    ) acquires RewardsControllerData {
        let rewards_controller_data =
            borrow_global_mut<RewardsControllerData>(rewards_controller_address);
        let asset = smart_table::borrow_mut(&mut rewards_controller_data.assets, asset);
        let reward_data: &mut RewardData =
            simple_map::borrow_mut(&mut asset.rewards, &reward);
        simple_map::upsert(&mut reward_data.users_data, user, user_data);
    }

    #[test_only]
    public fun create_asset_data(
        rewards: SimpleMap<address, RewardData>,
        available_rewards: SimpleMap<u128, address>,
        available_rewards_count: u128,
        decimals: u8
    ): AssetData {
        AssetData { rewards, available_rewards, available_rewards_count, decimals }
    }

    #[test_only]
    public fun create_reward_data(
        index: u128,
        emission_per_second: u128,
        max_emission_rate: u128,
        last_update_timestamp: u32,
        distribution_end: u32,
        users_data: std::simple_map::SimpleMap<address, UserData>
    ): RewardData {
        RewardData {
            index,
            emission_per_second,
            max_emission_rate,
            last_update_timestamp,
            distribution_end,
            users_data
        }
    }

    #[test_only]
    public fun create_user_data(index: u128, accrued: u128): UserData {
        UserData { index, accrued }
    }

    #[test_only]
    public fun force_update_internal_data_for_testing(
        assets: vector<address>, user: address, rewards_controller_address: address
    ): (vector<address>, vector<u256>) acquires RewardsControllerData {
        claim_all_rewards_internal_update_data(assets, user, rewards_controller_address)
    }
}
