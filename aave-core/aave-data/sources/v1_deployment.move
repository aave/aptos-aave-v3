/// @title Aave Data Deployment
/// @author Aave
/// @notice Module that applies deployment configurations
module aave_data::v1_deployment {
    // imports
    // std
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::debug::print;
    use aptos_std::string_utils::format1;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aave_data::v1_values::Self;

    // locals
    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_oracle::oracle;
    use aave_pool::collector;
    use aave_pool::pool;
    use aave_pool::pool_configurator;
    use aave_pool::a_token_factory;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::pool_data_provider;
    use aave_config::reserve_config;

    // Constants
    // @notice Network identifier for Aptos mainnet
    const APTOS_MAINNET: vector<u8> = b"mainnet";

    // @notice Network identifier for Aptos testnet
    const APTOS_TESTNET: vector<u8> = b"testnet";

    // @notice Success code for deployment verification
    const DEPLOYMENT_SUCCESS: u64 = 1;

    // @notice Failure code for deployment verification
    const DEPLOYMENT_FAILURE: u64 = 2;

    /// @notice Main function to set up various admin roles in the Aave ACL system
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun configure_acl(account: &signer, network: String) {
        // Verify the script is executed by someone who has the default admin role
        assert!(acl_manage::is_default_admin(signer::address_of(account)));

        let (
            pool_admins,
            asset_listing_admins,
            risk_admins,
            fund_admins,
            emergency_admins,
            flash_borrower_admins,
            emission_admins,
            admin_controlled_ecosystem_reserve_funds_admins,
            rewards_controller_admins
        ) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_acl_accounts_mainnet()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_acl_accounts_testnet()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_acl_accounts_testnet()
            };

        // Set up pool administrators
        vector::for_each(
            pool_admins,
            |pool_admin| {
                if (!acl_manage::is_pool_admin(pool_admin)) {
                    acl_manage::add_pool_admin(account, pool_admin);
                    assert!(acl_manage::is_pool_admin(pool_admin), DEPLOYMENT_SUCCESS);
                }
            }
        );

        // Set up asset listing administrators
        vector::for_each(
            asset_listing_admins,
            |asset_listing_admin| {
                if (!acl_manage::is_asset_listing_admin(asset_listing_admin)) {
                    acl_manage::add_asset_listing_admin(account, asset_listing_admin);
                    assert!(
                        acl_manage::is_asset_listing_admin(asset_listing_admin),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up risk administrators
        vector::for_each(
            risk_admins,
            |risk_admin| {
                if (!acl_manage::is_risk_admin(risk_admin)) {
                    acl_manage::add_risk_admin(account, risk_admin);
                    assert!(acl_manage::is_risk_admin(risk_admin), DEPLOYMENT_SUCCESS);
                }
            }
        );

        // Set up fund administrators
        vector::for_each(
            fund_admins,
            |funds_admin| {
                if (!acl_manage::is_funds_admin(funds_admin)) {
                    acl_manage::add_funds_admin(account, funds_admin);
                    assert!(
                        acl_manage::is_funds_admin(funds_admin), DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up emergency administrators
        vector::for_each(
            emergency_admins,
            |emergency_admin| {
                if (!acl_manage::is_emergency_admin(emergency_admin)) {
                    acl_manage::add_emergency_admin(account, emergency_admin);
                    assert!(
                        acl_manage::is_emergency_admin(emergency_admin),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up flash borrower administrators
        vector::for_each(
            flash_borrower_admins,
            |flash_borrower_admin| {
                if (!acl_manage::is_flash_borrower(flash_borrower_admin)) {
                    acl_manage::add_flash_borrower(account, flash_borrower_admin);
                    assert!(
                        acl_manage::is_flash_borrower(flash_borrower_admin),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up emission administrators
        vector::for_each(
            emission_admins,
            |emission_admin| {
                if (!acl_manage::is_emission_admin(emission_admin)) {
                    acl_manage::add_emission_admin(account, emission_admin);
                    assert!(
                        acl_manage::is_emission_admin(emission_admin),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up ecosystem reserve funds administrators
        vector::for_each(
            admin_controlled_ecosystem_reserve_funds_admins,
            |ecosystem_reserve_funds_admin| {
                if (!acl_manage::is_admin_controlled_ecosystem_reserve_funds_admin(
                    ecosystem_reserve_funds_admin
                )) {
                    acl_manage::add_admin_controlled_ecosystem_reserve_funds_admin(
                        account, ecosystem_reserve_funds_admin
                    );
                    assert!(
                        acl_manage::is_admin_controlled_ecosystem_reserve_funds_admin(
                            ecosystem_reserve_funds_admin
                        ),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );

        // Set up rewards controller administrators
        vector::for_each(
            rewards_controller_admins,
            |rewards_controller_admin| {
                if (!acl_manage::is_rewards_controller_admin(rewards_controller_admin)) {
                    acl_manage::add_rewards_controller_admin(
                        account, rewards_controller_admin
                    );
                    assert!(
                        acl_manage::is_rewards_controller_admin(rewards_controller_admin),
                        DEPLOYMENT_SUCCESS
                    );
                }
            }
        );
    }

    /// @notice Method to set up E-Mode categories in the Aave pool
    /// @param account The signer account executing the method (must be a risk admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun configure_emodes(account: &signer, network: String) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_risk_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        // Get E-Mode configurations based on the specified network
        let (_emode_category_ids, emode_configs) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_emodes_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_emode_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_emode_testnet_normalized()
            };

        // Process and configure each E-Mode category
        for (i in 0..vector::length(&emode_configs)) {
            let emode_config = *vector::borrow(&emode_configs, i);

            // Extract E-Mode configuration parameters
            let emode_category_id =
                aave_data::v1_values::get_emode_category_id(&emode_config);
            let emode_liquidation_label =
                aave_data::v1_values::get_emode_liquidation_label(&emode_config);
            let emode_liquidation_threshold =
                aave_data::v1_values::get_emode_liquidation_threshold(&emode_config);
            let emode_liquidation_bonus =
                aave_data::v1_values::get_emode_liquidation_bonus(&emode_config);
            let emode_ltv = aave_data::v1_values::get_emode_ltv(&emode_config);

            // Configure the E-Mode category in the pool
            pool_configurator::set_emode_category(
                account,
                (emode_category_id as u8),
                (emode_ltv as u16),
                (emode_liquidation_threshold as u16),
                (emode_liquidation_bonus as u16),
                emode_liquidation_label
            );
        };
    }

    /// @notice Method to set up pool reserves with appropriate tokens and parameters
    /// @param account The signer account executing the method (must be an asset listing admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun create_reserves(account: &signer, network: String) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // Get underlying assets based on the specified network
        let (underlying_asset_keys, underlying_assets_addresses) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_assets_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_assets_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_underlying_assets_testnet_normalized()
            };

        // Initialize vectors to store reserve configuration data
        let treasuries: vector<address> = vector[];
        let underlying_assets: vector<address> = vector[];
        let underlying_assets_decimals: vector<u8> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let optimal_usage_ratios: vector<u256> = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];
        let base_variable_borrow_rates: vector<u256> = vector[];
        let variable_rate_slope1s: vector<u256> = vector[];
        let variable_rate_slope2s: vector<u256> = vector[];
        let collector_address = collector::collector_address();

        // Get interest rate strategies based on the specified network
        let (_interest_rate_strategy_keys, interest_rate_strategy_maps) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_interest_rate_strategy_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_interest_rate_strategy_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_interest_rate_strategy_testnet_normalized()
            };

        // Prepare configuration data for each reserve
        for (i in 0..vector::length(&underlying_asset_keys)) {
            // Get underlying asset metadata
            let underlying_asset_address =
                *vector::borrow(&underlying_assets_addresses, i);
            let underlying_asset_metadata =
                object::address_to_object<Metadata>(underlying_asset_address);
            let underlying_asset_symbol =
                fungible_asset::symbol(underlying_asset_metadata);
            let underlying_asset_decimals =
                fungible_asset::decimals(underlying_asset_metadata);

            // Add underlying asset information to configuration vectors
            vector::push_back(&mut underlying_assets, underlying_asset_address);
            vector::push_back(
                &mut underlying_assets_decimals,
                underlying_asset_decimals
            );
            vector::push_back(&mut treasuries, collector_address);
            vector::push_back(&mut incentives_controllers, option::none()); // NOTE: currently no incentives controller is being set

            // Set up aToken and variable debt token names and symbols
            vector::push_back(
                &mut atokens_names,
                aave_data::v1::get_atoken_name(underlying_asset_symbol)
            );
            vector::push_back(
                &mut atokens_symbols,
                aave_data::v1::get_atoken_symbol(underlying_asset_symbol)
            );
            vector::push_back(
                &mut var_tokens_names,
                aave_data::v1::get_vartoken_name(underlying_asset_symbol)
            );
            vector::push_back(
                &mut var_tokens_symbols,
                aave_data::v1::get_vartoken_symbol(underlying_asset_symbol)
            );

            // Get interest rate strategy parameters
            let interest_rate_strategy_map = vector::borrow(
                &interest_rate_strategy_maps, i
            );
            let optimal_usage_ratio =
                aave_data::v1_values::get_optimal_usage_ratio(interest_rate_strategy_map);
            let base_variable_borrow_rate =
                aave_data::v1_values::get_base_variable_borrow_rate(
                    interest_rate_strategy_map
                );
            let variable_rate_slope1 =
                aave_data::v1_values::get_variable_rate_slope1(interest_rate_strategy_map);
            let variable_rate_slope2: u256 =
                aave_data::v1_values::get_variable_rate_slope2(interest_rate_strategy_map);

            // Add interest rate parameters to configuration vectors
            vector::push_back(&mut optimal_usage_ratios, optimal_usage_ratio);
            vector::push_back(
                &mut base_variable_borrow_rates, base_variable_borrow_rate
            );
            vector::push_back(&mut variable_rate_slope1s, variable_rate_slope1);
            vector::push_back(&mut variable_rate_slope2s, variable_rate_slope2);
        };

        // Initialize all reserves in a single transaction
        print(&format1(&b"Initializing reserves ... {}", 1));
        pool_configurator::init_reserves(
            account,
            underlying_assets,
            treasuries,
            atokens_names,
            atokens_symbols,
            var_tokens_names,
            var_tokens_symbols,
            incentives_controllers,
            optimal_usage_ratios,
            base_variable_borrow_rates,
            variable_rate_slope1s,
            variable_rate_slope2s
        );
        print(&format1(&b"Finished initializing reserves! {}", 1));
        // ===== Verify deployment was successful ===== //

        // Verify all reserves are present
        assert!(
            vector::length(&pool::get_reserves_list())
                == vector::length(&underlying_assets_addresses),
            DEPLOYMENT_SUCCESS
        );

        // Verify all reserves are active
        assert!(
            pool::number_of_active_reserves()
                == (vector::length(&underlying_assets_addresses) as u256),
            DEPLOYMENT_SUCCESS
        );

        // Verify no reserves have been dropped
        assert!(
            pool::number_of_active_and_dropped_reserves()
                == (vector::length(&underlying_assets_addresses) as u256),
            DEPLOYMENT_SUCCESS
        );

        // Verify each reserve has corresponding aToken and variable debt token
        assert!(
            vector::length(&pool_data_provider::get_all_a_tokens())
                == vector::length(&underlying_assets_addresses),
            DEPLOYMENT_SUCCESS
        );
        assert!(
            vector::length(&pool_data_provider::get_all_var_tokens())
                == vector::length(&underlying_assets_addresses),
            DEPLOYMENT_SUCCESS
        );
        assert!(
            vector::length(&pool_data_provider::get_all_reserves_tokens())
                == vector::length(&underlying_assets_addresses),
            DEPLOYMENT_SUCCESS
        );

        // Verify individual reserve details
        for (i in 0..vector::length(&underlying_assets_addresses)) {
            // Get underlying asset address
            let underlying_asset_address =
                *vector::borrow(&underlying_assets_addresses, i);

            // Verify asset exists in pool
            assert!(pool::asset_exists(underlying_asset_address), DEPLOYMENT_SUCCESS);

            // Get reserve data and associated token addresses
            let reserve_data = pool::get_reserve_data(underlying_asset_address);
            let a_token_address = pool::get_reserve_a_token_address(reserve_data);
            let var_token_address =
                pool::get_reserve_variable_debt_token_address(reserve_data);

            // Verify no accrued interest to treasury at deployment
            assert!(
                pool::get_reserve_accrued_to_treasury(reserve_data) == 0,
                DEPLOYMENT_SUCCESS
            );

            // Verify token contracts are properly deployed
            assert!(a_token_factory::is_atoken(a_token_address), DEPLOYMENT_SUCCESS);
            assert!(
                variable_debt_token_factory::is_variable_debt_token(var_token_address),
                DEPLOYMENT_SUCCESS
            );

            // Verify no collected fees at deployment
            assert!(
                collector::get_collected_fees(a_token_address) == 0, DEPLOYMENT_SUCCESS
            );
        }
    }

    /// @notice Method to configure reserve parameters for each asset in the pool
    /// @param account The signer account executing the method (must be an asset listing admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun configure_reserves(account: &signer, network: String) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // Get all underlying assets based on the specified network
        let (_underlying_asset_keys, underlying_assets_addresses) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_assets_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_assets_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_underlying_assets_testnet_normalized()
            };

        // Fetch all reserve configurations based on the specified network
        let (_reserve_config_keys, reserve_configs) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_reserves_config_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_reserves_config_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_reserves_config_testnet_normalized()
            };

        // Configure each reserve with its specific parameters
        print(&format1(&b"Configuring reserves ... {}", 1));
        for (i in 0..vector::length(&underlying_assets_addresses)) {
            // Get underlying asset metadata
            let underlying_asset_address =
                *vector::borrow(&underlying_assets_addresses, i);
            let underlying_asset_metadata =
                object::address_to_object<Metadata>(underlying_asset_address);
            let underlying_asset_decimals =
                fungible_asset::decimals(underlying_asset_metadata);

            // Extract configuration parameters for this reserve
            let reserve_config = vector::borrow(&reserve_configs, i);
            let debt_ceiling = aave_data::v1_values::get_debt_ceiling(reserve_config);
            let flashLoan_enabled =
                aave_data::v1_values::get_flashLoan_enabled(reserve_config);
            let borrowable_isolation =
                aave_data::v1_values::get_borrowable_isolation(reserve_config);
            let supply_cap = aave_data::v1_values::get_supply_cap(reserve_config);
            let borrow_cap = aave_data::v1_values::get_borrow_cap(reserve_config);
            let ltv = aave_data::v1_values::get_base_ltv_as_collateral(reserve_config);
            let borrowing_enabled =
                aave_data::v1_values::get_borrowing_enabled(reserve_config);
            let reserve_factor = aave_data::v1_values::get_reserve_factor(reserve_config);
            let liquidation_threshold =
                aave_data::v1_values::get_liquidation_threshold(reserve_config);
            let liquidation_bonus =
                aave_data::v1_values::get_liquidation_bonus(reserve_config);
            let liquidation_protocol_fee =
                aave_data::v1_values::get_liquidation_protocol_fee(reserve_config);
            let siloed_borrowing =
                aave_data::v1_values::get_siloed_borrowing(reserve_config);

            // Create and populate new reserve configuration
            let reserve_config_new = reserve_config::init();

            // Set basic parameters
            reserve_config::set_decimals(
                &mut reserve_config_new, (underlying_asset_decimals as u256)
            );
            reserve_config::set_active(&mut reserve_config_new, true);
            reserve_config::set_frozen(&mut reserve_config_new, false);
            reserve_config::set_paused(&mut reserve_config_new, false);

            // Set liquidation parameters
            reserve_config::set_liquidation_threshold(
                &mut reserve_config_new, liquidation_threshold
            );
            reserve_config::set_liquidation_bonus(
                &mut reserve_config_new, liquidation_bonus
            );
            reserve_config::set_liquidation_protocol_fee(
                &mut reserve_config_new, liquidation_protocol_fee
            );

            // Set financial parameters
            reserve_config::set_reserve_factor(&mut reserve_config_new, reserve_factor);
            reserve_config::set_ltv(&mut reserve_config_new, ltv);
            reserve_config::set_debt_ceiling(&mut reserve_config_new, debt_ceiling);
            reserve_config::set_supply_cap(&mut reserve_config_new, supply_cap);
            reserve_config::set_borrow_cap(&mut reserve_config_new, borrow_cap);

            // Set feature flags
            reserve_config::set_flash_loan_enabled(
                &mut reserve_config_new, flashLoan_enabled
            );
            reserve_config::set_borrowable_in_isolation(
                &mut reserve_config_new, borrowable_isolation
            );
            reserve_config::set_siloed_borrowing(
                &mut reserve_config_new, siloed_borrowing
            );
            reserve_config::set_borrowing_enabled(
                &mut reserve_config_new, borrowing_enabled
            );

            // Configure E-Mode category if applicable
            let emode_category = aave_data::v1_values::get_emode_category(reserve_config);
            if (option::is_some(&emode_category)) {
                // Set E-Mode category in the reserve configuration
                reserve_config::set_emode_category(
                    &mut reserve_config_new, *option::borrow(&emode_category)
                );

                // Set the asset's E-Mode category in the pool
                pool_configurator::set_asset_emode_category(
                    account,
                    underlying_asset_address,
                    (*option::borrow(&emode_category) as u8)
                );
            };

            // Apply the configuration to the reserve
            aave_pool::pool::set_reserve_configuration_with_guard(
                account, underlying_asset_address, reserve_config_new
            );
        };
        print(&format1(&b"Finished configuring reserves! {}", 1));
    }

    /// @notice Method to configure interest rate strategies for each asset in the pool
    /// @param account The signer account executing the method (must be an asset listing admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun configure_interest_rates(
        account: &signer, network: String
    ) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // Get all underlying assets based on the specified network
        let (_underlying_asset_keys, underlying_assets_addresses) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_assets_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_assets_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_underlying_assets_testnet_normalized()
            };

        // Fetch all interest rate strategies based on the specified network
        let (_interest_rate_strategy_keys, interest_rate_strategy_maps) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_interest_rate_strategy_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_interest_rate_strategy_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_interest_rate_strategy_testnet_normalized()
            };

        // Configure each asset with its specific interest rate strategy
        print(&format1(&b"Configuring interest rate strategies ... {}", 1));
        for (i in 0..vector::length(&underlying_assets_addresses)) {
            // Get the underlying asset address and its corresponding interest rate strategy
            let underlying_asset_address =
                *vector::borrow(&underlying_assets_addresses, i);
            let interest_rate_strategy_map = vector::borrow(
                &interest_rate_strategy_maps, i
            );

            // Extract interest rate parameters for this asset
            let optimal_usage_ratio =
                aave_data::v1_values::get_optimal_usage_ratio(interest_rate_strategy_map);
            let base_variable_borrow_rate =
                aave_data::v1_values::get_base_variable_borrow_rate(
                    interest_rate_strategy_map
                );
            let variable_rate_slope1 =
                aave_data::v1_values::get_variable_rate_slope1(interest_rate_strategy_map);
            let variable_rate_slope2: u256 =
                aave_data::v1_values::get_variable_rate_slope2(interest_rate_strategy_map);

            // Update the interest rate strategy for this asset in the pool
            pool_configurator::update_interest_rate_strategy(
                account,
                underlying_asset_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );
        };
        print(&format1(&b"Finished configuring interest rate strategies! {}", 1));
    }

    /// @notice Method to set up price feeds for all assets in the Aave protocol
    /// @param account The signer account executing the method (must be a risk admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun configure_price_feeds(
        account: &signer, network: String
    ) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_risk_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        // Get all underlying assets based on the specified network
        let (_underlying_asset_keys, underlying_assets_addresses) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_assets_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_assets_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_underlying_assets_testnet_normalized()
            };

        // Fetch all price feeds based on the specified network
        let (_price_feed_keys, price_feeds) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_price_feeds_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_price_feeds_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_price_feeds_testnet_normalized()
            };

        // Fetch all maximum price ages based on the specified network
        let (_asset_keys, max_price_ages) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_asset_max_price_ages_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_asset_max_price_ages_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_asset_max_price_ages_testnet_normalized()
            };

        // fetch all price configurations
        let (_asset_keys, asset_oracle_configs) =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_oracle_configs_mainnet_normalized()
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_oracle_configs_testnet_normalized()
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_oracle_configs_testnet_normalized()
            };

        // Configure price feeds for each asset and its related tokens
        print(&format1(&b"Configuring price feeds ... {}", 1));
        for (i in 0..vector::length(&underlying_assets_addresses)) {
            // Get the underlying asset address and its reserve data
            let underlying_asset_address =
                *vector::borrow(&underlying_assets_addresses, i);
            let reserve_data = pool::get_reserve_data(underlying_asset_address);

            // Get the price feed for this asset
            let price_feed = vector::borrow(&price_feeds, i);

            // Get the max price age for this asset
            let max_price_age = *vector::borrow(&max_price_ages, i);

            // Set the same price feed for the underlying asset, aToken, and variable debt token
            // This ensures consistent price reporting across all related tokens
            oracle::set_asset_feed_id(account, underlying_asset_address, *price_feed);
            oracle::set_asset_feed_id(
                account, pool::get_reserve_a_token_address(reserve_data), *price_feed
            );
            oracle::set_asset_feed_id(
                account,
                pool::get_reserve_variable_debt_token_address(reserve_data),
                *price_feed
            );
            oracle::set_max_asset_price_age(
                account, underlying_asset_address, max_price_age
            );

            // Verify the price feed is working correctly
            assert!(
                oracle::get_asset_price(underlying_asset_address) > 0,
                DEPLOYMENT_SUCCESS
            );

            let asset_oracle_config = *vector::borrow(&asset_oracle_configs, i);

            if (asset_oracle_config.is_some()) {
                let capped_asset_data = option::borrow(&asset_oracle_config);
                if (aave_data::v1_values::is_stable_adapter(capped_asset_data)) {
                    let stable_price_cap =
                        *option::borrow(
                            &aave_data::v1_values::get_stable_price_cap(capped_asset_data)
                        );
                    oracle::set_price_cap_stable_adapter(
                        account, underlying_asset_address, stable_price_cap
                    );
                    // Verify stable price cap is set
                    assert!(
                        option::is_some(
                            &oracle::get_stable_price_cap(underlying_asset_address)
                        ),
                        DEPLOYMENT_SUCCESS
                    );
                } else if (aave_data::v1_values::is_susde_adapter(capped_asset_data)) {

                    let minimum_snapshot_delay =
                        *option::borrow(
                            &aave_data::v1_values::get_minimum_snapshot_delay(
                                capped_asset_data
                            )
                        );
                    let max_yearly_ratio_growth_percent =
                        *option::borrow(
                            &aave_data::v1_values::get_max_yearly_ratio_growth_percent(
                                capped_asset_data
                            )
                        );
                    let mapped_asset_ratio_multiplier =
                        aave_data::v1_values::get_mapped_asset_ratio_multiplier(
                            capped_asset_data
                        );

                    let (snapshot_ratio, snapshot_timestamp) =
                        oracle::get_asset_price_and_timestamp(underlying_asset_address);

                    oracle::set_susde_price_adapter(
                        account,
                        underlying_asset_address,
                        minimum_snapshot_delay,
                        snapshot_timestamp,
                        max_yearly_ratio_growth_percent,
                        snapshot_ratio,
                        mapped_asset_ratio_multiplier
                    );
                    // Verify no stable price cap is set
                    assert!(
                        option::is_none(
                            &oracle::get_stable_price_cap(underlying_asset_address)
                        ),
                        DEPLOYMENT_SUCCESS
                    );
                };
            };
        };
        print(&format1(&b"Finished configuring price feeds! {}", 1));
    }

    /// @notice Method to set up GHO pool reserve with appropriate tokens and parameters
    /// @param account The signer account executing the method (must be an asset listing admin or pool admin)
    /// @param network The network identifier ("mainnet" or "testnet")
    public entry fun setup_gho_reserve(account: &signer, network: String) {
        // Verify the caller has appropriate permissions
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        // ============================= INITIALIZE GHO RESERVE ======================================== //

        print(&format1(&b"Initializing reserve ... {}", v1_values::get_gho_asset()));
        // Get underlying assets based on the specified network
        let underlying_asset_address =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_underlying_for_asset_mainnet(
                    v1_values::get_gho_asset()
                )
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_underlying_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_underlying_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            };
        let underlying_asset_address = *option::borrow(&underlying_asset_address);
        let underlying_asset_metadata =
            object::address_to_object<Metadata>(underlying_asset_address);
        let underlying_asset_symbol = fungible_asset::symbol(underlying_asset_metadata);
        let underlying_asset_decimals =
            fungible_asset::decimals(underlying_asset_metadata);

        // atokens
        let atoken_name = aave_data::v1::get_atoken_name(underlying_asset_symbol);
        let atoken_symbol = aave_data::v1::get_atoken_symbol(underlying_asset_symbol);

        // var tokens
        let var_token_name = aave_data::v1::get_vartoken_name(underlying_asset_symbol);
        let var_token_symbol =
            aave_data::v1::get_vartoken_symbol(underlying_asset_symbol);

        // treasury
        let treasury = collector::collector_address();

        // Get interest rate strategies based on the specified network
        let interest_rate_strategy =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_interest_rate_strategy_for_asset_mainnet(
                    v1_values::get_gho_asset()
                )
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_interest_rate_strategy_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_interest_rate_strategy_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            };
        let interest_rate_strategy = *option::borrow(&interest_rate_strategy);
        let optimal_usage_ratio =
            aave_data::v1_values::get_optimal_usage_ratio(&interest_rate_strategy);
        let base_variable_borrow_rate =
            aave_data::v1_values::get_base_variable_borrow_rate(
                &interest_rate_strategy
            );
        let variable_rate_slope1 =
            aave_data::v1_values::get_variable_rate_slope1(&interest_rate_strategy);
        let variable_rate_slope2: u256 =
            aave_data::v1_values::get_variable_rate_slope2(&interest_rate_strategy);

        // incentives controller
        let incentives_controller = option::none();

        // Initialize the gho reserve in a single transaction
        print(&format1(&b"Initializing GHO reserve ... {}", 1));
        pool_configurator::init_reserves(
            account,
            vector[underlying_asset_address],
            vector[treasury],
            vector[atoken_name],
            vector[atoken_symbol],
            vector[var_token_name],
            vector[var_token_symbol],
            vector[incentives_controller],
            vector[optimal_usage_ratio],
            vector[base_variable_borrow_rate],
            vector[variable_rate_slope1],
            vector[variable_rate_slope2]
        );
        print(&format1(&b"Finished initializing GHO reserve! {}", 1));

        // Verifications
        // Verify asset exists in pool
        assert!(pool::asset_exists(underlying_asset_address), DEPLOYMENT_SUCCESS);

        // Get reserve data and associated token addresses
        let reserve_data = pool::get_reserve_data(underlying_asset_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let var_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        // Verify no accrued interest to treasury at deployment
        assert!(
            pool::get_reserve_accrued_to_treasury(reserve_data) == 0,
            DEPLOYMENT_SUCCESS
        );

        // Verify token contracts are properly deployed
        assert!(a_token_factory::is_atoken(a_token_address), DEPLOYMENT_SUCCESS);
        assert!(
            variable_debt_token_factory::is_variable_debt_token(var_token_address),
            DEPLOYMENT_SUCCESS
        );

        // Verify no collected fees at deployment
        assert!(collector::get_collected_fees(a_token_address) == 0, DEPLOYMENT_SUCCESS);
        print(&format1(&b"Finished initializing {} reserve!", v1_values::get_gho_asset()));

        // ============================= APPLY GHO RESERVE CONFIGURATION ======================================== //

        print(&format1(&b"Configuring {} reserve ... ", v1_values::get_gho_asset()));
        // read the gho reserve config
        let reserve_config =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_reserves_config_for_asset_mainnet(
                    v1_values::get_gho_asset()
                )
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_reserves_config_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_reserves_config_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            };

        // Extract configuration parameters for this reserve
        let reserve_config = option::borrow(&reserve_config);
        let debt_ceiling = aave_data::v1_values::get_debt_ceiling(reserve_config);
        let flashLoan_enabled =
            aave_data::v1_values::get_flashLoan_enabled(reserve_config);
        let borrowable_isolation =
            aave_data::v1_values::get_borrowable_isolation(reserve_config);
        let supply_cap = aave_data::v1_values::get_supply_cap(reserve_config);
        let borrow_cap = aave_data::v1_values::get_borrow_cap(reserve_config);
        let ltv = aave_data::v1_values::get_base_ltv_as_collateral(reserve_config);
        let borrowing_enabled =
            aave_data::v1_values::get_borrowing_enabled(reserve_config);
        let reserve_factor = aave_data::v1_values::get_reserve_factor(reserve_config);
        let liquidation_threshold =
            aave_data::v1_values::get_liquidation_threshold(reserve_config);
        let liquidation_bonus =
            aave_data::v1_values::get_liquidation_bonus(reserve_config);
        let liquidation_protocol_fee =
            aave_data::v1_values::get_liquidation_protocol_fee(reserve_config);
        let siloed_borrowing = aave_data::v1_values::get_siloed_borrowing(reserve_config);

        // Create and populate new reserve configuration
        let reserve_config_new = reserve_config::init();

        // Set basic parameters
        reserve_config::set_decimals(
            &mut reserve_config_new, (underlying_asset_decimals as u256)
        );
        reserve_config::set_active(&mut reserve_config_new, true);
        reserve_config::set_frozen(&mut reserve_config_new, false);
        reserve_config::set_paused(&mut reserve_config_new, false);

        // Set liquidation parameters
        reserve_config::set_liquidation_threshold(
            &mut reserve_config_new, liquidation_threshold
        );
        reserve_config::set_liquidation_bonus(&mut reserve_config_new, liquidation_bonus);
        reserve_config::set_liquidation_protocol_fee(
            &mut reserve_config_new, liquidation_protocol_fee
        );

        // Set financial parameters
        reserve_config::set_reserve_factor(&mut reserve_config_new, reserve_factor);
        reserve_config::set_ltv(&mut reserve_config_new, ltv);
        reserve_config::set_debt_ceiling(&mut reserve_config_new, debt_ceiling);
        reserve_config::set_supply_cap(&mut reserve_config_new, supply_cap);
        reserve_config::set_borrow_cap(&mut reserve_config_new, borrow_cap);

        // Set feature flags
        reserve_config::set_flash_loan_enabled(
            &mut reserve_config_new, flashLoan_enabled
        );
        reserve_config::set_borrowable_in_isolation(
            &mut reserve_config_new, borrowable_isolation
        );
        reserve_config::set_siloed_borrowing(&mut reserve_config_new, siloed_borrowing);
        reserve_config::set_borrowing_enabled(&mut reserve_config_new, borrowing_enabled);

        // Configure E-Mode category if applicable
        let emode_category = aave_data::v1_values::get_emode_category(reserve_config);
        if (option::is_some(&emode_category)) {
            // Set E-Mode category in the reserve configuration
            reserve_config::set_emode_category(
                &mut reserve_config_new, *option::borrow(&emode_category)
            );

            // Set the asset's E-Mode category in the pool
            pool_configurator::set_asset_emode_category(
                account,
                underlying_asset_address,
                (*option::borrow(&emode_category) as u8)
            );
        };

        // Apply the configuration to the reserve
        aave_pool::pool::set_reserve_configuration_with_guard(
            account, underlying_asset_address, reserve_config_new
        );
        print(&format1(&b"Finished configuring {} reserve!", v1_values::get_gho_asset()));

        // ============================= CONFIGURE INTEREST RATE STRATEGY ======================================== //

        print(
            &format1(
                &b"Configuring {} interest rate strategies ...",
                v1_values::get_gho_asset()
            )
        );
        // Update the interest rate strategy for this asset in the pool
        pool_configurator::update_interest_rate_strategy(
            account,
            underlying_asset_address,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );
        print(
            &format1(
                &b"Finished configuring interest rate strategies for {}",
                v1_values::get_gho_asset()
            )
        );

        // ============================= CONFIGURE PRICE FEEDS + ORACLE ======================================== //

        print(
            &format1(&b"Configuring {} price and oracle ...", v1_values::get_gho_asset())
        );
        // Fetch maximum price age for gho based on the specified network
        let max_price_age =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_asset_max_price_ages_for_asset_mainnet(
                    v1_values::get_gho_asset()
                )
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_asset_max_price_ages_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_asset_max_price_ages_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            };
        let max_price_age = *option::borrow(&max_price_age);

        // fetch gho price configuration
        let asset_oracle_config =
            if (network == utf8(APTOS_MAINNET)) {
                aave_data::v1::get_oracle_configs_for_asset_mainnet(
                    v1_values::get_gho_asset()
                )
            } else if (network == utf8(APTOS_TESTNET)) {
                aave_data::v1::get_oracle_configs_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            } else {
                print(
                    &format1(&b"Unsupported network - {}. Using testnet values", network)
                );
                aave_data::v1::get_oracle_configs_for_asset_testnet(
                    v1_values::get_gho_asset()
                )
            };

        // Set adapter type
        assert!(asset_oracle_config.is_some(), DEPLOYMENT_SUCCESS);
        let capped_asset_data = option::borrow(&asset_oracle_config);
        let stable_price_cap =
            *option::borrow(
                &aave_data::v1_values::get_stable_price_cap(capped_asset_data)
            );
        oracle::set_price_cap_stable_adapter(
            account, underlying_asset_address, stable_price_cap
        );
        // Verify stable price cap is set
        assert!(
            option::is_some(&oracle::get_stable_price_cap(underlying_asset_address)),
            DEPLOYMENT_SUCCESS
        );
        // set max age
        oracle::set_max_asset_price_age(
            account, underlying_asset_address, max_price_age
        );
        // Verify the price is working correctly
        assert!(
            oracle::get_asset_price(underlying_asset_address) > 0,
            DEPLOYMENT_SUCCESS
        );
        print(
            &format1(
                &b"Finished configuring {} price and oracle!",
                v1_values::get_gho_asset()
            )
        );
    }
}
