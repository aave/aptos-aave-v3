/// @title UI Incentive Data Provider V3 Module
/// @author Aave
/// @notice Provides data for UI regarding incentives for Aave protocol assets
module aave_pool::ui_incentive_data_provider_v3 {
    // imports
    use std::option;
    use std::string::String;
    use std::vector;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;

    use aave_pool::token_base;
    use aave_pool::rewards_controller;
    use aave_oracle::oracle::Self;
    use aave_pool::pool;

    // Structs
    /// @notice Aggregated reserve incentive data structure
    /// @param underlying_asset The address of the underlying asset
    /// @param a_incentive_data The incentive data for the aToken
    /// @param v_incentive_data The incentive data for the variable debt token
    struct AggregatedReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_incentive_data: IncentiveData,
        v_incentive_data: IncentiveData
    }

    /// @notice Incentive data structure
    /// @param token_address The address of the token
    /// @param incentive_controller_address The address of the incentive controller
    /// @param rewards_token_information Vector of reward information
    struct IncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        rewards_token_information: vector<RewardInfo>
    }

    /// @notice Reward information structure
    /// @param reward_token_symbol The symbol of the reward token
    /// @param reward_token_address The address of the reward token
    /// @param emission_per_second The emission per second
    /// @param incentives_last_update_timestamp The last update timestamp for incentives
    /// @param token_incentives_index The token incentives index
    /// @param emission_end_timestamp The emission end timestamp
    /// @param reward_price_feed The price feed for the reward
    /// @param reward_token_decimals The decimals of the reward token
    /// @param precision The precision of the reward
    /// @param price_feed_decimals The decimals of the price feed
    struct RewardInfo has store, drop {
        reward_token_symbol: String,
        reward_token_address: address,
        emission_per_second: u256,
        incentives_last_update_timestamp: u256,
        token_incentives_index: u256,
        emission_end_timestamp: u256,
        reward_price_feed: u256,
        reward_token_decimals: u8,
        precision: u8,
        price_feed_decimals: u8
    }

    /// @notice User reserve incentive data structure
    /// @param underlying_asset The address of the underlying asset
    /// @param a_token_incentives_user_data The user incentive data for the aToken
    /// @param v_token_incentives_user_data The user incentive data for the variable debt token
    struct UserReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_token_incentives_user_data: UserIncentiveData,
        v_token_incentives_user_data: UserIncentiveData
    }

    /// @notice User incentive data structure
    /// @param token_address The address of the token
    /// @param incentive_controller_address The address of the incentive controller
    /// @param user_rewards_information Vector of user reward information
    struct UserIncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        user_rewards_information: vector<UserRewardInfo>
    }

    /// @notice User reward information structure
    /// @param reward_token_symbol The symbol of the reward token
    /// @param reward_token_address The address of the reward token
    /// @param user_unclaimed_rewards The user's unclaimed rewards
    /// @param token_incentives_user_index The token incentives user index
    /// @param reward_price_feed The price feed for the reward
    /// @param price_feed_decimals The decimals of the price feed
    /// @param reward_token_decimals The decimals of the reward token
    struct UserRewardInfo has store, drop {
        reward_token_symbol: String,
        reward_token_address: address,
        user_unclaimed_rewards: u256,
        token_incentives_user_index: u256,
        reward_price_feed: u256,
        price_feed_decimals: u8,
        reward_token_decimals: u8
    }

    // Public view functions
    #[view]
    /// @notice Gets full reserves incentive data for a user
    /// @param user The address of the user
    /// @return Tuple containing aggregate reserve incentive data and user reserve incentive data
    public fun get_full_reserves_incentive_data(
        user: address
    ): (vector<AggregatedReserveIncentiveData>, vector<UserReserveIncentiveData>) {
        (get_reserves_incentives_data(), get_user_reserves_incentives_data(user))
    }

    #[view]
    /// @notice Gets reserves incentives data
    /// @return Vector of aggregated reserve incentive data
    public fun get_reserves_incentives_data(): vector<AggregatedReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let reserves_incentives_data = vector::empty<AggregatedReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);

            // ===================== a token ====================
            let a_token_address = pool::get_reserve_a_token_address(base_data);
            let a_token_rewards_controller =
                token_base::get_incentives_controller(a_token_address);

            // NOTE: it's true that `pool::init_reserve` will deploy the AToken
            // and the VariableDebtToken with the same incentives_controller,
            // it's also true that `token_base` allows the admin to change it
            // separately via `token_base::incentives_controller`.
            //
            // Because of this, we cannot make the assumption that the
            // `incentives_controller` is the same for both tokens (even if it's
            // the logical assumption to make), nor can we make the assumption
            // that they are both empty or both present.

            let a_incentive_data =
                if (option::is_none(&a_token_rewards_controller)) {
                    // NOTE: we use @0x0 instead of Option::None to represent
                    // the case where there is no incentive_controller
                    // associated with the AToken because this #[view] function
                    // is primarily intended for UI purpose and returning a zero
                    // address is more aligned with the convention on the
                    // Solidity side.
                    IncentiveData {
                        token_address: a_token_address,
                        incentive_controller_address: @0x0,
                        rewards_token_information: vector[]
                    }
                } else {
                    let a_token_rewards_controller_address =
                        option::destroy_some(a_token_rewards_controller);

                    let a_token_reward_addresses =
                        rewards_controller::get_rewards_by_asset(
                            a_token_address, a_token_rewards_controller_address
                        );
                    let reward_information: vector<RewardInfo> = vector[];

                    for (j in 0..vector::length(&a_token_reward_addresses)) {
                        let reward_token_address =
                            *vector::borrow(&a_token_reward_addresses, j);
                        let reward_token =
                            object::address_to_object<Metadata>(reward_token_address);

                        let (
                            token_incentives_index,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            emission_end_timestamp
                        ) =
                            rewards_controller::get_rewards_data(
                                a_token_address,
                                reward_token_address,
                                a_token_rewards_controller_address
                            );

                        let precision =
                            rewards_controller::get_asset_decimals(
                                a_token_address, a_token_rewards_controller_address
                            );

                        let reward_token_decimals =
                            fungible_asset::decimals(reward_token);
                        let reward_token_symbol = fungible_asset::symbol(reward_token);

                        let (price_feed_decimals, reward_price_feed) =
                            get_reward_token_oracle_precision_and_price(
                                reward_token_address
                            );

                        vector::push_back(
                            &mut reward_information,
                            RewardInfo {
                                reward_token_symbol,
                                reward_token_address,
                                emission_per_second,
                                incentives_last_update_timestamp,
                                token_incentives_index,
                                emission_end_timestamp,
                                reward_price_feed,
                                reward_token_decimals,
                                precision,
                                price_feed_decimals
                            }
                        );
                    };

                    IncentiveData {
                        token_address: a_token_address,
                        incentive_controller_address: a_token_rewards_controller_address,
                        rewards_token_information: reward_information
                    }
                };

            // ===================== variable debt token ====================
            let variable_debt_token_address =
                pool::get_reserve_variable_debt_token_address(base_data);
            let variable_debt_token_rewards_controller =
                token_base::get_incentives_controller(variable_debt_token_address);

            let v_incentive_data =
                if (option::is_none(&variable_debt_token_rewards_controller)) {
                    // NOTE: see comments above on `a_incentive_data` for why
                    // we use @0x0 instead of Option::None to represent the case
                    // where there is no incentive_controller associated.
                    IncentiveData {
                        token_address: variable_debt_token_address,
                        incentive_controller_address: @0x0,
                        rewards_token_information: vector[]
                    }
                } else {
                    let variable_debt_token_rewards_controller_address =
                        option::destroy_some(variable_debt_token_rewards_controller);

                    let var_debt_token_reward_addresses =
                        rewards_controller::get_rewards_by_asset(
                            variable_debt_token_address,
                            variable_debt_token_rewards_controller_address
                        );
                    let reward_information: vector<RewardInfo> = vector[];

                    for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                        let reward_token_address =
                            *vector::borrow(&var_debt_token_reward_addresses, j);
                        let reward_token =
                            object::address_to_object<Metadata>(reward_token_address);

                        let (
                            token_incentives_index,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            emission_end_timestamp
                        ) =
                            rewards_controller::get_rewards_data(
                                variable_debt_token_address,
                                reward_token_address,
                                variable_debt_token_rewards_controller_address
                            );

                        let precision =
                            rewards_controller::get_asset_decimals(
                                variable_debt_token_address,
                                variable_debt_token_rewards_controller_address
                            );
                        let reward_token_decimals =
                            fungible_asset::decimals(reward_token);
                        let reward_token_symbol = fungible_asset::symbol(reward_token);

                        let (price_feed_decimals, reward_price_feed) =
                            get_reward_token_oracle_precision_and_price(
                                reward_token_address
                            );

                        vector::push_back(
                            &mut reward_information,
                            RewardInfo {
                                reward_token_symbol,
                                reward_token_address,
                                emission_per_second,
                                incentives_last_update_timestamp,
                                token_incentives_index,
                                emission_end_timestamp,
                                reward_price_feed,
                                reward_token_decimals,
                                precision,
                                price_feed_decimals
                            }
                        );
                    };

                    IncentiveData {
                        token_address: variable_debt_token_address,
                        incentive_controller_address: variable_debt_token_rewards_controller_address,
                        rewards_token_information: reward_information
                    }
                };

            vector::push_back(
                &mut reserves_incentives_data,
                AggregatedReserveIncentiveData {
                    underlying_asset,
                    a_incentive_data,
                    v_incentive_data
                }
            );
        };
        reserves_incentives_data
    }

    #[view]
    /// @notice Gets user reserves incentives data
    /// @param user The address of the user
    /// @return Vector of user reserve incentive data
    public fun get_user_reserves_incentives_data(user: address)
        : vector<UserReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let user_reserves_incentives_data = vector::empty<UserReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);

            // ===================== a token ====================
            let a_token_address = pool::get_reserve_a_token_address(base_data);
            let a_token_rewards_controller =
                token_base::get_incentives_controller(a_token_address);

            // NOTE: similar to the comments in `get_reserves_incentives_data`,
            // we cannot make the assumption that the `incentives_controller`
            // is the same for both AToken and VariableDebtToken, nor can we
            // make the assumption that they are both empty or both present.

            let a_incentive_data =
                if (option::is_none(&a_token_rewards_controller)) {
                    // NOTE: see comments in `get_reserves_incentives_data` for
                    // why we use @0x0 instead of Option::None to represent the
                    // case where there is no incentive_controller associated.
                    UserIncentiveData {
                        token_address: a_token_address,
                        incentive_controller_address: @0x0,
                        user_rewards_information: vector[]
                    }
                } else {
                    let a_token_rewards_controller_address =
                        option::destroy_some(a_token_rewards_controller);

                    let a_token_reward_addresses =
                        rewards_controller::get_rewards_by_asset(
                            a_token_address, a_token_rewards_controller_address
                        );
                    let user_rewards_information: vector<UserRewardInfo> = vector[];

                    for (j in 0..vector::length(&a_token_reward_addresses)) {
                        let reward_token_address =
                            *vector::borrow(&a_token_reward_addresses, j);
                        let reward_token =
                            object::address_to_object<Metadata>(reward_token_address);

                        let token_incentives_user_index =
                            rewards_controller::get_user_asset_index(
                                user,
                                a_token_address,
                                reward_token_address,
                                a_token_rewards_controller_address
                            );

                        let user_unclaimed_rewards =
                            rewards_controller::get_user_accrued_rewards(
                                user,
                                reward_token_address,
                                a_token_rewards_controller_address
                            );

                        let reward_token_decimals =
                            fungible_asset::decimals(reward_token);
                        let reward_token_symbol = fungible_asset::symbol(reward_token);

                        let (price_feed_decimals, reward_price_feed) =
                            get_reward_token_oracle_precision_and_price(
                                reward_token_address
                            );

                        vector::push_back(
                            &mut user_rewards_information,
                            UserRewardInfo {
                                reward_token_symbol,
                                reward_token_address,
                                user_unclaimed_rewards,
                                token_incentives_user_index,
                                reward_price_feed,
                                price_feed_decimals,
                                reward_token_decimals
                            }
                        );
                    };

                    UserIncentiveData {
                        token_address: a_token_address,
                        incentive_controller_address: a_token_rewards_controller_address,
                        user_rewards_information
                    }
                };

            // ===================== variable debt token ====================
            let variable_debt_token_address =
                pool::get_reserve_variable_debt_token_address(base_data);
            let variable_debt_token_rewards_controller =
                token_base::get_incentives_controller(variable_debt_token_address);

            let v_incentive_data =
                if (option::is_none(&variable_debt_token_rewards_controller)) {
                    // NOTE: see comments above on `a_incentive_data` for why
                    // we use @0x0 instead of Option::None to represent the case
                    // where there is no incentive_controller associated.
                    UserIncentiveData {
                        token_address: variable_debt_token_address,
                        incentive_controller_address: @0x0,
                        user_rewards_information: vector[]
                    }
                } else {
                    let variable_debt_token_rewards_controller_address =
                        option::destroy_some(variable_debt_token_rewards_controller);

                    let var_debt_token_reward_addresses =
                        rewards_controller::get_rewards_by_asset(
                            variable_debt_token_address,
                            variable_debt_token_rewards_controller_address
                        );
                    let user_rewards_information: vector<UserRewardInfo> = vector[];

                    for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                        let reward_token_address =
                            *vector::borrow(&var_debt_token_reward_addresses, j);
                        let reward_token =
                            object::address_to_object<Metadata>(reward_token_address);

                        let token_incentives_user_index =
                            rewards_controller::get_user_asset_index(
                                user,
                                variable_debt_token_address,
                                reward_token_address,
                                variable_debt_token_rewards_controller_address
                            );

                        let user_unclaimed_rewards =
                            rewards_controller::get_user_accrued_rewards(
                                user,
                                reward_token_address,
                                variable_debt_token_rewards_controller_address
                            );
                        let reward_token_decimals =
                            fungible_asset::decimals(reward_token);
                        let reward_token_symbol = fungible_asset::symbol(reward_token);

                        let (price_feed_decimals, reward_price_feed) =
                            get_reward_token_oracle_precision_and_price(
                                reward_token_address
                            );

                        vector::push_back(
                            &mut user_rewards_information,
                            UserRewardInfo {
                                reward_token_symbol,
                                reward_token_address,
                                user_unclaimed_rewards,
                                token_incentives_user_index,
                                reward_price_feed,
                                price_feed_decimals,
                                reward_token_decimals
                            }
                        );
                    };

                    UserIncentiveData {
                        token_address: variable_debt_token_address,
                        incentive_controller_address: variable_debt_token_rewards_controller_address,
                        user_rewards_information
                    }
                };

            vector::push_back(
                &mut user_reserves_incentives_data,
                UserReserveIncentiveData {
                    underlying_asset,
                    a_token_incentives_user_data: a_incentive_data,
                    v_token_incentives_user_data: v_incentive_data
                }
            );
        };
        user_reserves_incentives_data
    }

    // Private functions
    /// @notice Gets reward token oracle precision and price
    /// @param reward_token_address The address of the reward token
    /// @return Tuple containing price feed decimals and reward price feed
    inline fun get_reward_token_oracle_precision_and_price(
        reward_token_address: address
    ): (u8, u256) {
        let price_feed_decimals = oracle::get_asset_price_decimals();
        let reward_price_feed = oracle::get_asset_price(reward_token_address);
        (price_feed_decimals, reward_price_feed)
    }
}
