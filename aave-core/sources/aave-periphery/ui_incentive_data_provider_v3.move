module aave_pool::ui_incentive_data_provider_v3 {
    use std::string::String;
    use std::vector;
    use aptos_framework::object::{Self, Object};
    use aave_pool::rewards_controller::Self;
    use aave_pool::eac_aggregator_proxy::Self;
    use aave_pool::pool::{Self,};
    use aave_pool::a_token_factory::Self;

    const EMPTY_ADDRESS: address = @0x0;

    const UI_INCENTIVE_DATA_PROVIDER_V3_NAME: vector<u8> = b"AAVE_UI_INCENTIVE_DATA_PROVIDER_V3";

    struct UiIncentiveDataProviderV3Data has key {}

    struct AggregatedReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_incentive_data: IncentiveData,
        v_incentive_data: IncentiveData,
    }

    struct IncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        rewards_token_information: vector<RewardInfo>,
    }

    struct RewardInfo has store, drop {
        reward_token_symbol: String,
        reward_token_address: address,
        reward_oracle_address: address,
        emission_per_second: u256,
        incentives_last_update_timestamp: u256,
        token_incentives_index: u256,
        emission_end_timestamp: u256,
        reward_price_feed: u256,
        reward_token_decimals: u8,
        precision: u8,
        price_feed_decimals: u8,
    }

    struct UserReserveIncentiveData has store, drop {
        underlying_asset: address,
        a_token_incentives_user_data: UserIncentiveData,
        v_token_incentives_user_data: UserIncentiveData,
    }

    struct UserIncentiveData has store, drop {
        token_address: address,
        incentive_controller_address: address,
        user_rewards_information: vector<UserRewardInfo>
    }

    struct UserRewardInfo has store, drop {
        reward_token_symbol: String,
        reward_oracle_address: address,
        reward_token_address: address,
        user_unclaimed_rewards: u256,
        token_incentives_user_index: u256,
        reward_price_feed: u256,
        price_feed_decimals: u8,
        reward_token_decimals: u8,
    }

    fun init_module(sender: &signer,) {
        let state_object_constructor_ref =
            &object::create_named_object(sender, UI_INCENTIVE_DATA_PROVIDER_V3_NAME);
        let state_object_signer = &object::generate_signer(state_object_constructor_ref);

        move_to(
            state_object_signer,
            UiIncentiveDataProviderV3Data {},
        );
    }

    #[test_only]
    public fun init_module_test(sender: &signer) {
        init_module(sender);
    }

    #[view]
    public fun ui_incentive_data_provider_v3_data_address(): address {
        object::create_object_address(&@aave_pool, UI_INCENTIVE_DATA_PROVIDER_V3_NAME)
    }

    #[view]
    public fun ui_incentive_data_provider_v3_data_object()
        : Object<UiIncentiveDataProviderV3Data> {
        object::address_to_object<UiIncentiveDataProviderV3Data>(
            ui_incentive_data_provider_v3_data_address()
        )
    }

    #[view]
    public fun get_full_reserves_incentive_data(user: address)
        : (
        vector<AggregatedReserveIncentiveData>, vector<UserReserveIncentiveData>
    ) {
        (get_reserves_incentives_data(), get_user_reserves_incentives_data(user))
    }

    #[view]
    public fun get_reserves_incentives_data(): vector<AggregatedReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let reserves_incentives_data = vector::empty<AggregatedReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);
            let rewards_controller_address =
                rewards_controller::rewards_controller_address();
            // TODO Waiting for Chainlink oracle functionality
            let reward_oracle_address = @aave_mock_oracle;

            if (rewards_controller_address != EMPTY_ADDRESS) {

                // ===================== a token ====================
                let a_token_address = pool::get_reserve_a_token_address(&base_data);
                let a_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        a_token_address,
                        rewards_controller_address,
                    );
                let reward_information: vector<RewardInfo> = vector[];

                for (j in 0..vector::length(&a_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&a_token_reward_addresses, j);

                    let (
                        token_incentives_index,
                        emission_per_second,
                        incentives_last_update_timestamp,
                        emission_end_timestamp
                    ) =
                        rewards_controller::get_rewards_data(
                            a_token_address,
                            reward_token_address,
                            rewards_controller_address,
                        );

                    let precision =
                        rewards_controller::get_asset_decimals(
                            a_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut reward_information,
                        RewardInfo {
                            reward_token_symbol,
                            reward_token_address,
                            reward_oracle_address,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            token_incentives_index,
                            emission_end_timestamp,
                            reward_price_feed,
                            reward_token_decimals,
                            precision,
                            price_feed_decimals,
                        },
                    );
                };

                let a_incentive_data = IncentiveData {
                    token_address: a_token_address,
                    incentive_controller_address: rewards_controller_address,
                    rewards_token_information: reward_information,
                };

                // ===================== variable debt token ====================
                let variable_debt_token_address =
                    pool::get_reserve_variable_debt_token_address(&base_data);
                let var_debt_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        variable_debt_token_address,
                        rewards_controller_address,
                    );
                let reward_information: vector<RewardInfo> = vector[];

                for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&var_debt_token_reward_addresses, j);

                    let (
                        token_incentives_index,
                        emission_per_second,
                        incentives_last_update_timestamp,
                        emission_end_timestamp
                    ) =
                        rewards_controller::get_rewards_data(
                            variable_debt_token_address,
                            reward_token_address,
                            rewards_controller_address,
                        );

                    let precision =
                        rewards_controller::get_asset_decimals(
                            variable_debt_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut reward_information,
                        RewardInfo {
                            reward_token_symbol,
                            reward_token_address,
                            reward_oracle_address,
                            emission_per_second,
                            incentives_last_update_timestamp,
                            token_incentives_index,
                            emission_end_timestamp,
                            reward_price_feed,
                            reward_token_decimals,
                            precision,
                            price_feed_decimals,
                        },
                    );
                };

                let v_incentive_data = IncentiveData {
                    token_address: variable_debt_token_address,
                    incentive_controller_address: rewards_controller_address,
                    rewards_token_information: reward_information,
                };

                vector::push_back(
                    &mut reserves_incentives_data,
                    AggregatedReserveIncentiveData {
                        underlying_asset,
                        a_incentive_data,
                        v_incentive_data,
                    },
                )
            };
        };
        reserves_incentives_data
    }

    #[view]
    public fun get_user_reserves_incentives_data(user: address)
        : vector<UserReserveIncentiveData> {
        let reserves = pool::get_reserves_list();
        let user_reserves_incentives_data = vector::empty<UserReserveIncentiveData>();

        for (i in 0..vector::length(&reserves)) {
            let underlying_asset = *vector::borrow(&reserves, i);
            let base_data = pool::get_reserve_data(underlying_asset);
            let rewards_controller_address =
                rewards_controller::rewards_controller_address();
            // TODO Waiting for Chainlink oracle functionality
            let reward_oracle_address = @aave_mock_oracle;

            if (rewards_controller_address != EMPTY_ADDRESS) {

                // ===================== a token ====================
                let a_token_address = pool::get_reserve_a_token_address(&base_data);
                let a_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        a_token_address,
                        rewards_controller_address,
                    );
                let user_rewards_information: vector<UserRewardInfo> = vector[];

                for (j in 0..vector::length(&a_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&a_token_reward_addresses, j);

                    let token_incentives_user_index =
                        rewards_controller::get_user_asset_index(
                            user,
                            a_token_address,
                            reward_token_address,
                            rewards_controller_address,
                        );

                    let user_unclaimed_rewards =
                        rewards_controller::get_user_accrued_rewards(
                            user, reward_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut user_rewards_information,
                        UserRewardInfo {
                            reward_token_symbol,
                            reward_oracle_address,
                            reward_token_address,
                            user_unclaimed_rewards,
                            token_incentives_user_index,
                            reward_price_feed,
                            price_feed_decimals,
                            reward_token_decimals,
                        },
                    );
                };

                let a_incentive_data = UserIncentiveData {
                    token_address: a_token_address,
                    incentive_controller_address: rewards_controller_address,
                    user_rewards_information,
                };

                // ===================== variable debt token ====================
                let variable_debt_token_address =
                    pool::get_reserve_variable_debt_token_address(&base_data);
                let var_debt_token_reward_addresses =
                    rewards_controller::get_rewards_by_asset(
                        variable_debt_token_address,
                        rewards_controller_address,
                    );
                let user_rewards_information: vector<UserRewardInfo> = vector[];

                for (j in 0..vector::length(&var_debt_token_reward_addresses)) {
                    let reward_token_address =
                        *vector::borrow(&var_debt_token_reward_addresses, j);

                    let token_incentives_user_index =
                        rewards_controller::get_user_asset_index(
                            user,
                            variable_debt_token_address,
                            reward_token_address,
                            rewards_controller_address,
                        );

                    let user_unclaimed_rewards =
                        rewards_controller::get_user_accrued_rewards(
                            user, reward_token_address, rewards_controller_address
                        );
                    let reward_token_decimals =
                        a_token_factory::decimals(reward_token_address);
                    let reward_token_symbol =
                        a_token_factory::symbol(reward_token_address);

                    let price_feed_decimals = eac_aggregator_proxy::decimals();
                    let reward_price_feed = eac_aggregator_proxy::latest_answer();

                    vector::push_back(
                        &mut user_rewards_information,
                        UserRewardInfo {
                            reward_token_symbol,
                            reward_oracle_address,
                            reward_token_address,
                            user_unclaimed_rewards,
                            token_incentives_user_index,
                            reward_price_feed,
                            price_feed_decimals,
                            reward_token_decimals,
                        },
                    );
                };

                let v_incentive_data = UserIncentiveData {
                    token_address: variable_debt_token_address,
                    incentive_controller_address: rewards_controller_address,
                    user_rewards_information,
                };

                vector::push_back(
                    &mut user_reserves_incentives_data,
                    UserReserveIncentiveData {
                        underlying_asset,
                        a_token_incentives_user_data: a_incentive_data,
                        v_token_incentives_user_data: v_incentive_data,
                    },
                )
            };
        };
        user_reserves_incentives_data
    }
}
