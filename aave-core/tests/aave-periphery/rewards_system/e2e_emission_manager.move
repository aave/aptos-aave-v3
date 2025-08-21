#[test_only]
module aave_pool::e2e_emission_manager {
    use std::signer;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use aave_config::user_config;
    use aave_pool::rewards_distributor;
    use aave_pool::emission_manager;
    use aave_pool::rewards_controller;
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;

    use aave_pool::mock_coin1;
    use aave_pool::mock_coin2;
    use aave_pool::helper_account;
    use aave_pool::helper_setup;
    use aave_pool::helper_setup::Context;

    struct PerUserRewards has drop {
        apt_total: u256,
        apt_accrued: u256,
        mockcoin1_total: u256,
        mockcoin1_accrued: u256,
        mockcoin1_atoken_total: u256,
        mockcoin1_atoken_accrued: u256,
        mockcoin2_total: u256,
        mockcoin2_accrued: u256,
        mockcoin2_atoken_total: u256,
        mockcoin2_atoken_accrued: u256
    }

    fun check_per_user_rewards(
        context: &Context, user_address: address, rewards_controller_address: address
    ): PerUserRewards {
        // derive token addresses
        let apt_token = coin::paired_metadata<aptos_coin::AptosCoin>().destroy_some();
        let apt_address = object::object_address(&apt_token);

        let (mockcoin1_atoken, mockcoin1_vtoken) =
            helper_setup::derive_token_addresses(context.mockcoin1_address());
        let (mockcoin2_atoken, mockcoin2_vtoken) =
            helper_setup::derive_token_addresses(context.mockcoin2_address());

        // force data update
        rewards_controller::force_update_internal_data_for_testing(
            vector[
                mockcoin1_atoken,
                mockcoin1_vtoken,
                mockcoin2_atoken,
                mockcoin2_vtoken
            ],
            user_address,
            rewards_controller_address
        );

        // per-user, all rewards
        let (user_reward_assets, user_reward_amounts) =
            rewards_controller::get_all_user_rewards(
                vector[
                    mockcoin1_atoken,
                    mockcoin1_vtoken,
                    mockcoin2_atoken,
                    mockcoin2_vtoken
                ],
                user_address,
                rewards_controller_address
            );
        assert!(user_reward_assets.length() == 5);
        assert!(user_reward_amounts.length() == 5);

        let (found, idx) = user_reward_assets.find(|a| *a == apt_address);
        assert!(found);
        let user_reward_apt = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a
            == context.mockcoin1_address());
        assert!(found);
        let user_reward_mockcoin1 = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a == mockcoin1_atoken);
        assert!(found);
        let user_reward_mockcoin1_atoken = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a
            == context.mockcoin2_address());
        assert!(found);
        let user_reward_mockcoin2 = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a == mockcoin2_atoken);
        assert!(found);
        let user_reward_mockcoin2_atoken = user_reward_amounts[idx];

        // check per-user, per-reward
        assert!(
            user_reward_apt
                == rewards_controller::get_user_rewards(
                    vector[
                        mockcoin1_atoken,
                        mockcoin1_vtoken,
                        mockcoin2_atoken,
                        mockcoin2_vtoken
                    ],
                    user_address,
                    apt_address,
                    rewards_controller_address
                )
        );
        assert!(
            user_reward_mockcoin1
                == rewards_controller::get_user_rewards(
                    vector[
                        mockcoin1_atoken,
                        mockcoin1_vtoken,
                        mockcoin2_atoken,
                        mockcoin2_vtoken
                    ],
                    user_address,
                    context.mockcoin1_address(),
                    rewards_controller_address
                )
        );
        assert!(
            user_reward_mockcoin1_atoken
                == rewards_controller::get_user_rewards(
                    vector[
                        mockcoin1_atoken,
                        mockcoin1_vtoken,
                        mockcoin2_atoken,
                        mockcoin2_vtoken
                    ],
                    user_address,
                    mockcoin1_atoken,
                    rewards_controller_address
                )
        );
        assert!(
            user_reward_mockcoin2
                == rewards_controller::get_user_rewards(
                    vector[
                        mockcoin1_atoken,
                        mockcoin1_vtoken,
                        mockcoin2_atoken,
                        mockcoin2_vtoken
                    ],
                    user_address,
                    context.mockcoin2_address(),
                    rewards_controller_address
                )
        );
        assert!(
            user_reward_mockcoin2_atoken
                == rewards_controller::get_user_rewards(
                    vector[
                        mockcoin1_atoken,
                        mockcoin1_vtoken,
                        mockcoin2_atoken,
                        mockcoin2_vtoken
                    ],
                    user_address,
                    mockcoin2_atoken,
                    rewards_controller_address
                )
        );

        // now collect accrued rewards
        let user_accrued_apt =
            rewards_controller::get_user_accrued_rewards(
                user_address,
                apt_address,
                rewards_controller_address
            );
        assert!(user_accrued_apt <= user_reward_apt);

        let user_accrued_mockcoin1 =
            rewards_controller::get_user_accrued_rewards(
                user_address,
                context.mockcoin1_address(),
                rewards_controller_address
            );
        assert!(user_accrued_mockcoin1 <= user_reward_mockcoin1);

        let user_accrued_mockcoin1_atoken =
            rewards_controller::get_user_accrued_rewards(
                user_address,
                mockcoin1_atoken,
                rewards_controller_address
            );
        assert!(user_accrued_mockcoin1_atoken <= user_reward_mockcoin1_atoken);

        let user_accrued_mockcoin2 =
            rewards_controller::get_user_accrued_rewards(
                user_address,
                context.mockcoin2_address(),
                rewards_controller_address
            );
        assert!(user_accrued_mockcoin2 <= user_reward_mockcoin2);

        let user_accrued_mockcoin2_atoken =
            rewards_controller::get_user_accrued_rewards(
                user_address,
                mockcoin2_atoken,
                rewards_controller_address
            );
        assert!(user_accrued_mockcoin2_atoken <= user_reward_mockcoin2_atoken);

        // summarize the rewards
        PerUserRewards {
            apt_total: user_reward_apt,
            apt_accrued: user_accrued_apt,
            mockcoin1_total: user_reward_mockcoin1,
            mockcoin1_accrued: user_accrued_mockcoin1,
            mockcoin1_atoken_total: user_reward_mockcoin1_atoken,
            mockcoin1_atoken_accrued: user_accrued_mockcoin1_atoken,
            mockcoin2_total: user_reward_mockcoin2,
            mockcoin2_accrued: user_accrued_mockcoin2,
            mockcoin2_atoken_total: user_reward_mockcoin2_atoken,
            mockcoin2_atoken_accrued: user_accrued_mockcoin1_atoken
        }
    }

    fun claim_per_user_rewards_all(
        context: &Context,
        user_signer: &signer,
        summary: &PerUserRewards,
        rewards_controller_address: address
    ) {
        // derive token addresses
        let apt_token = coin::paired_metadata<aptos_coin::AptosCoin>().destroy_some();
        let apt_address = object::object_address(&apt_token);

        let (mockcoin1_atoken, mockcoin1_vtoken) =
            helper_setup::derive_token_addresses(context.mockcoin1_address());
        let (mockcoin2_atoken, mockcoin2_vtoken) =
            helper_setup::derive_token_addresses(context.mockcoin2_address());

        // do the claim
        let (user_reward_assets, user_reward_amounts) =
            rewards_distributor::claim_all_rewards_to_self(
                user_signer,
                vector[
                    mockcoin1_atoken,
                    mockcoin1_vtoken,
                    mockcoin2_atoken,
                    mockcoin2_vtoken
                ],
                rewards_controller_address
            );

        // check the claim result
        assert!(user_reward_assets.length() == 5);
        assert!(user_reward_amounts.length() == 5);

        let (found, idx) = user_reward_assets.find(|a| *a == apt_address);
        assert!(found);
        let user_reward_apt = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a
            == context.mockcoin1_address());
        assert!(found);
        let user_reward_mockcoin1 = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a == mockcoin1_atoken);
        assert!(found);
        let user_reward_mockcoin1_atoken = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a
            == context.mockcoin2_address());
        assert!(found);
        let user_reward_mockcoin2 = user_reward_amounts[idx];

        let (found, idx) = user_reward_assets.find(|a| *a == mockcoin2_atoken);
        assert!(found);
        let user_reward_mockcoin2_atoken = user_reward_amounts[idx];

        // check with the summary
        aptos_std::debug::print(&user_reward_apt);
        aptos_std::debug::print(&summary.apt_accrued);

        assert!(user_reward_apt == summary.apt_accrued);
        assert!(user_reward_mockcoin1 == summary.mockcoin1_accrued);
        assert!(user_reward_mockcoin1_atoken == summary.mockcoin1_atoken_accrued);
        assert!(user_reward_mockcoin2 == summary.mockcoin2_accrued);
        assert!(user_reward_mockcoin2_atoken == summary.mockcoin2_atoken_accrued);
    }

    #[test]
    public fun basic_flow() {
        let context = helper_setup::deploy_with_mocks();

        // create users account and fund them with tokens
        let signer_user1 = helper_account::new_usr_account();
        let address_user1 = signer::address_of(&signer_user1);
        mock_coin1::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_user1, context.mockcoin1_metadata()
            ),
            1_000_000000
        );
        mock_coin2::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_user1, context.mockcoin2_metadata()
            ),
            2_000_000000
        );

        let signer_user2 = helper_account::new_usr_account();
        let address_user2 = signer::address_of(&signer_user2);
        mock_coin1::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_user2, context.mockcoin1_metadata()
            ),
            2_000_000000
        );
        mock_coin2::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_user2, context.mockcoin2_metadata()
            ),
            1_000_000000
        );

        // advanced timestamp by days
        let seconds_per_day = 24 * 60 * 60;

        // both users now supply to the protocol
        timestamp::fast_forward_seconds(seconds_per_day);

        supply_logic::supply(
            &signer_user1,
            context.mockcoin1_address(),
            100_000000,
            address_user1,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            &signer_user1,
            context.mockcoin1_address(),
            true
        );

        supply_logic::supply(
            &signer_user1,
            context.mockcoin2_address(),
            200_000000,
            address_user1,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            &signer_user1,
            context.mockcoin2_address(),
            true
        );

        supply_logic::supply(
            &signer_user2,
            context.mockcoin1_address(),
            200_000000,
            address_user2,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            &signer_user2,
            context.mockcoin1_address(),
            true
        );

        supply_logic::supply(
            &signer_user2,
            context.mockcoin2_address(),
            100_000000,
            address_user2,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            &signer_user2,
            context.mockcoin2_address(),
            true
        );

        // both users now borrow from the protocol
        timestamp::fast_forward_seconds(seconds_per_day);

        borrow_logic::borrow(
            &signer_user1,
            context.mockcoin1_address(),
            50_000000,
            user_config::get_interest_rate_mode_variable(),
            0,
            address_user1
        );
        borrow_logic::borrow(
            &signer_user1,
            context.mockcoin2_address(),
            100_000000,
            user_config::get_interest_rate_mode_variable(),
            0,
            address_user1
        );

        borrow_logic::borrow(
            &signer_user2,
            context.mockcoin1_address(),
            100_000000,
            user_config::get_interest_rate_mode_variable(),
            0,
            address_user2
        );
        borrow_logic::borrow(
            &signer_user2,
            context.mockcoin2_address(),
            50_000000,
            user_config::get_interest_rate_mode_variable(),
            0,
            address_user2
        );

        // address shortcut
        let rewards_controller_address =
            emission_manager::get_rewards_controller().destroy_some();

        // now check for rewwards
        timestamp::fast_forward_seconds(seconds_per_day);

        // check and claim rewards
        let user1_summary =
            check_per_user_rewards(
                &context,
                address_user1,
                rewards_controller_address
            );
        claim_per_user_rewards_all(
            &context,
            &signer_user1,
            &user1_summary,
            rewards_controller_address
        );

        let user2_summary =
            check_per_user_rewards(
                &context,
                address_user2,
                rewards_controller_address
            );
        claim_per_user_rewards_all(
            &context,
            &signer_user2,
            &user2_summary,
            rewards_controller_address
        );

        // now we check again and expect no acurred rewards
        let user1_summary =
            check_per_user_rewards(
                &context,
                address_user1,
                rewards_controller_address
            );
        assert!(user1_summary.apt_accrued == 0);
        assert!(user1_summary.mockcoin1_accrued == 0);
        assert!(user1_summary.mockcoin1_atoken_accrued == 0);
        assert!(user1_summary.mockcoin2_accrued == 0);
        assert!(user1_summary.mockcoin2_atoken_accrued == 0);

        let user2_summary =
            check_per_user_rewards(
                &context,
                address_user2,
                rewards_controller_address
            );
        assert!(user2_summary.apt_accrued == 0);
        assert!(user2_summary.mockcoin1_accrued == 0);
        assert!(user2_summary.mockcoin1_atoken_accrued == 0);
        assert!(user2_summary.mockcoin2_accrued == 0);
        assert!(user2_summary.mockcoin2_atoken_accrued == 0);

        // fast-foward: no activity means no rewards
        timestamp::fast_forward_seconds(seconds_per_day);

        let user1_summary =
            check_per_user_rewards(
                &context,
                address_user1,
                rewards_controller_address
            );
        assert!(user1_summary.apt_accrued == 0);
        assert!(user1_summary.mockcoin1_accrued == 0);
        assert!(user1_summary.mockcoin1_atoken_accrued == 0);
        assert!(user1_summary.mockcoin2_accrued == 0);
        assert!(user1_summary.mockcoin2_atoken_accrued == 0);

        let user2_summary =
            check_per_user_rewards(
                &context,
                address_user2,
                rewards_controller_address
            );
        assert!(user2_summary.apt_accrued == 0);
        assert!(user2_summary.mockcoin1_accrued == 0);
        assert!(user2_summary.mockcoin1_atoken_accrued == 0);
        assert!(user2_summary.mockcoin2_accrued == 0);
        assert!(user2_summary.mockcoin2_atoken_accrued == 0);
    }
}
