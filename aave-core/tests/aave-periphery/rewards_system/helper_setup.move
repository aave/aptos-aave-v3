#[test_only]
module aave_pool::helper_setup {
    use std::option;
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::genesis;
    use aptos_framework::object;
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_math::math_utils::get_seconds_per_year;
    use aave_oracle::oracle;
    use aave_pool::supply_logic;
    use aave_pool::rewards_controller;
    use aave_pool::transfer_strategy;
    use aave_pool::pool;
    use aave_pool::pool_configurator;
    use aave_pool::collector;
    use aave_pool::emission_manager;
    use aave_pool::pool_fee_manager;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::a_token_factory;

    use aave_pool::mock_coin1;
    use aave_pool::mock_coin2;
    use aave_pool::helper_account;
    use aave_pool::helper_asset_listing;

    /// Named structure that captures deployment information for subsequent tests
    struct Context has drop {
        // system accounts
        pool_admin: signer,
        emergency_admin: signer,

        // mocks
        mockcoin1: Object<Metadata>,
        mockcoin2: Object<Metadata>,

        // emission
        emission_admin_default: signer
    }

    /// Setup all packages and necessary testing accounts before any deployment scenarios
    fun generic_setup(): (signer, signer) {
        // aptos framework genesis
        genesis::setup();

        // setup APT
        aptos_coin::ensure_initialized_with_apt_fa_metadata_for_test();
        let apt_token = coin::paired_metadata<aptos_coin::AptosCoin>().destroy_some();

        // kickoff time
        timestamp::fast_forward_seconds(get_seconds_per_year() as u64);

        // setup ChainLink
        let signer_data_feeds = account::create_signer_for_test(@data_feeds);
        data_feeds::registry::set_up_test(
            &signer_data_feeds, &account::create_signer_for_test(@platform)
        );
        data_feeds::router::init_module_for_testing(&signer_data_feeds);

        // setup testing modules
        helper_account::initialize();

        // setup ACL
        let signer_acl = account::create_account_for_test(@aave_acl);
        acl_manage::test_init_module(&signer_acl);

        // setup oracle
        let signer_oracle = account::create_signer_for_test(@aave_oracle);
        oracle::test_init_module(&signer_oracle);

        // setup pool
        let signer_pool = account::create_account_for_test(@aave_pool);
        // setup pool: tokens
        a_token_factory::test_init_module(&signer_pool);
        variable_debt_token_factory::test_init_module(&signer_pool);
        // setup pool: periphery
        pool_fee_manager::init_module_for_testing(&signer_pool);
        collector::init_module_test(&signer_pool);
        emission_manager::test_init_module(&signer_pool);
        // setup pool: core
        pool_configurator::test_init_module(&signer_pool);

        // configure ACL
        let signer_acl = account::create_signer_for_test(@aave_acl);
        let signer_pool_admin = helper_account::new_sys_account();
        acl_manage::add_pool_admin(&signer_acl, signer::address_of(&signer_pool_admin));

        let signer_emergency_admin = helper_account::new_sys_account();
        acl_manage::add_emergency_admin(
            &signer_acl, signer::address_of(&signer_emergency_admin)
        );

        // setup oracle price for APT
        oracle::set_asset_custom_price(
            &signer_pool_admin,
            object::object_address(&apt_token),
            5_000_000_000_000_000_000
        );

        // return system accounts created
        (signer_pool_admin, signer_emergency_admin)
    }

    /// Utility to return the token address pack
    public fun derive_token_addresses(underlying_asset: address): (address, address) {
        let reserve_data = pool::get_reserve_data(underlying_asset);
        let atoken_address = pool::get_reserve_a_token_address(reserve_data);
        let vtoken_address = pool::get_reserve_variable_debt_token_address(reserve_data);
        (atoken_address, vtoken_address)
    }

    /// Simulate the deployment of the protocol with two mock coins
    ///
    /// Summary of context:
    /// - MockCoin1
    ///   - MockCoin1_AToken       is configured to rewared APT, MockCoin1, MockCoin1_AToken
    ///   - MockCoin1_VarDebtToken is configured to rewared APT, MockCoin1, MockCoin1_AToken
    /// - MockCoin2
    ///   - MockCoin2_AToken       is configured to rewared APT, MockCoin2, MockCoin2_AToken
    ///   - MockCoin2_VarDebtToken is configured to rewared APT, MockCoin2, MockCoin2_AToken
    /// All managed by the same `emission_admin` and share the same resource account for vault.
    public fun deploy_with_mocks(): Context {
        let (signer_pool_admin, signer_emergency_admin) = generic_setup();

        // initialize mocks
        let signer_mockcoin1 = helper_account::new_usr_account();
        mock_coin1::initialize(&signer_mockcoin1);

        let signer_mockcoin2 = helper_account::new_usr_account();
        mock_coin2::initialize(&signer_mockcoin2);

        // create and setup reserve
        helper_asset_listing::list_asset(
            &signer_pool_admin,
            helper_asset_listing::default_mockcoin1_config(
                signer::address_of(&signer_mockcoin1)
            )
        );
        helper_asset_listing::list_asset(
            &signer_pool_admin,
            helper_asset_listing::default_mockcoin2_config(
                signer::address_of(&signer_mockcoin2)
            )
        );

        // involved signers
        let signer_aave_acl = account::create_signer_for_test(@aave_acl);
        let signer_aave_pool = account::create_signer_for_test(@aave_pool);

        // involved tokens
        let apt_token = coin::paired_metadata<aptos_coin::AptosCoin>().destroy_some();
        let apt_address = object::object_address(&apt_token);

        let mockcoin1_token =
            mock_coin1::token_metadata(signer::address_of(&signer_mockcoin1));
        let mockcoin1_address = object::object_address(&mockcoin1_token);
        let (mockcoin1_atoken_address, mockcoin1_vtoken_address) =
            derive_token_addresses(mockcoin1_address);

        let mockcoin2_token =
            mock_coin2::token_metadata(signer::address_of(&signer_mockcoin2));
        let mockcoin2_address = object::object_address(&mockcoin2_token);
        let (mockcoin2_atoken_address, mockcoin2_vtoken_address) =
            derive_token_addresses(mockcoin2_address);

        // create the emission admin
        let signer_emission_admin_default = helper_account::new_sys_account();
        let address_emission_admin_default =
            signer::address_of(&signer_emission_admin_default);

        // prepare the associated rewards vault
        let (signer_reward_vault_all, signer_cap_reward_vault_all) =
            account::create_resource_account(
                &signer_emission_admin_default, b"REWARDS_VAULT"
            );
        let address_reward_vault_all = signer::address_of(&signer_reward_vault_all);

        // populate the reward vaults
        primary_fungible_store::deposit(
            address_reward_vault_all,
            aptos_coin::mint_apt_fa_for_test(5_000_000_00000000)
        );
        mock_coin1::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_reward_vault_all, mockcoin1_token
            ),
            10_000_000_000000
        );
        mock_coin2::mint(
            primary_fungible_store::ensure_primary_store_exists(
                address_reward_vault_all, mockcoin2_token
            ),
            10_000_000_000000
        );
        supply_logic::supply(
            &signer_reward_vault_all,
            mockcoin1_address,
            5_000_000_000000,
            address_reward_vault_all,
            0
        );
        supply_logic::supply(
            &signer_reward_vault_all,
            mockcoin2_address,
            5_000_000_000000,
            address_reward_vault_all,
            0
        );

        // now setup the rewards controller
        emission_manager::initialize(
            &signer_aave_pool, b"REWARDS_CONTROLLER_FOR_TESTING"
        );
        emission_manager::set_rewards_controller(
            &signer_aave_pool,
            option::some(
                rewards_controller::rewards_controller_address(
                    b"REWARDS_CONTROLLER_FOR_TESTING"
                )
            )
        );

        // prepare the emission admin roles
        acl_manage::add_emission_admin(
            &signer_aave_acl, address_emission_admin_default
        );

        emission_manager::set_emission_admin(
            &signer_aave_pool, apt_address, address_emission_admin_default
        );
        emission_manager::set_emission_admin(
            &signer_aave_pool,
            mockcoin1_address,
            address_emission_admin_default
        );
        emission_manager::set_emission_admin(
            &signer_aave_pool,
            mockcoin1_atoken_address,
            address_emission_admin_default
        );
        emission_manager::set_emission_admin(
            &signer_aave_pool,
            mockcoin2_address,
            address_emission_admin_default
        );
        emission_manager::set_emission_admin(
            &signer_aave_pool,
            mockcoin2_atoken_address,
            address_emission_admin_default
        );

        // preset the transfer strategy
        let default_transfer_strategy =
            transfer_strategy::create_pull_rewards_transfer_strategy(
                &signer_emission_admin_default,
                &object::create_sticky_object(address_emission_admin_default),
                address_emission_admin_default,
                emission_manager::get_rewards_controller().destroy_some(),
                signer_cap_reward_vault_all
            );

        // actually configure the emission
        let default_emission_per_second = 100;
        let default_max_emission_rates = default_emission_per_second * 2;
        let default_distribution_end =
            (timestamp::now_seconds() as u32) + (get_seconds_per_year() as u32);

        emission_manager::configure_assets(
            &signer_emission_admin_default,
            vector[
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second
            ],
            vector[
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates
            ],
            vector[
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end
            ],
            vector[
                mockcoin1_atoken_address,
                mockcoin1_atoken_address,
                mockcoin1_atoken_address,
                mockcoin1_vtoken_address,
                mockcoin1_vtoken_address,
                mockcoin1_vtoken_address
            ],
            vector[
                apt_address,
                mockcoin1_address,
                mockcoin1_atoken_address,
                apt_address,
                mockcoin1_address,
                mockcoin1_atoken_address
            ],
            vector[
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy
            ]
        );
        emission_manager::configure_assets(
            &signer_emission_admin_default,
            vector[
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second,
                default_emission_per_second
            ],
            vector[
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates,
                default_max_emission_rates
            ],
            vector[
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end,
                default_distribution_end
            ],
            vector[
                mockcoin2_atoken_address,
                mockcoin2_atoken_address,
                mockcoin2_atoken_address,
                mockcoin2_vtoken_address,
                mockcoin2_vtoken_address,
                mockcoin2_vtoken_address
            ],
            vector[
                apt_address,
                mockcoin2_address,
                mockcoin2_atoken_address,
                apt_address,
                mockcoin2_address,
                mockcoin2_atoken_address
            ],
            vector[
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy,
                default_transfer_strategy
            ]
        );

        // return deployment context
        Context {
            pool_admin: signer_pool_admin,
            emergency_admin: signer_emergency_admin,
            mockcoin1: mockcoin1_token,
            mockcoin2: mockcoin2_token,
            emission_admin_default: signer_emission_admin_default
        }
    }

    // Getters for deployment context
    public fun signer_pool_admin(self: &Context): &signer {
        &self.pool_admin
    }

    public fun signer_emergency_admin(self: &Context): &signer {
        &self.emergency_admin
    }

    public fun mockcoin1_metadata(self: &Context): Object<Metadata> {
        self.mockcoin1
    }

    public fun mockcoin1_address(self: &Context): address {
        object::object_address(&self.mockcoin1)
    }

    public fun mockcoin2_metadata(self: &Context): Object<Metadata> {
        self.mockcoin2
    }

    public fun mockcoin2_address(self: &Context): address {
        object::object_address(&self.mockcoin2)
    }

    public fun signer_emission_admin_default(self: &Context): &signer {
        &self.emission_admin_default
    }
}
