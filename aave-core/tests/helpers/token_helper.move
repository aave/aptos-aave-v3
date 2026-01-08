#[test_only]
module aave_pool::token_helper {
    use std::debug;
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::option::Option;
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::string_utils;
    use aptos_framework::event::emitted_events;
    use aptos_framework::aptos_coin;
    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage;
    use aave_config::reserve_config;
    use aave_pool::coin_migrator::Self;
    use aave_math::math_utils;
    use aave_oracle::oracle_tests;
    use aave_oracle::oracle::Self;
    use aave_pool::fungible_asset_manager;
    use aave_pool::pool_fee_manager;
    use aave_pool::pool_token_logic::ReserveInitialized;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::a_token_factory::Self;
    use aave_pool::collector::Self;
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::pool::{Self, number_of_active_and_dropped_reserves};
    use aave_pool::pool_configurator::Self;
    use aave_pool::token_base;
    use aave_pool::variable_debt_token_factory::Self;

    /// Whether to enable debug log
    const DEBUG_ENABLED: bool = true;
    const TEST_RESERVES_COUNT: u8 = 3;

    // error codes
    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    /// Package debug printing (according to switch control)
    public fun debug_log<T>(val: &T) {
        if (DEBUG_ENABLED) {
            debug::print(val);
        };
    }

    /// General initialization function
    public fun init_test_env(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);
        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init the acl module and make aave_pool the asset listing/pool admin
        acl_manage::test_init_module(aave_role_super_admin);

        // init collector
        collector::init_module_test(aave_pool);

        // init token base (a tokens and var tokens)
        token_base::test_init_module(aave_pool);

        // init a token factory
        a_token_factory::test_init_module(aave_pool);

        // init debt token factory
        variable_debt_token_factory::test_init_module(aave_pool);

        // init underlying tokens
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init pool_configurator & reserves module
        pool_configurator::test_init_module(aave_pool);

        // init fee manager module
        pool_fee_manager::init_module_for_testing(aave_pool);
    }

    public fun init_reserves(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // init test env
        init_test_env(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // add pool and asset listing admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);

        // init token base (a tokens and var tokens)
        init_tokens(
            aave_pool,
            underlying_tokens_admin,
            TEST_RESERVES_COUNT,
            false
        );
    }

    public fun init_reserves_with_oracle(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer
    ) {
        // init test env
        init_test_env(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // add pool and asset listing admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);
        // add emission admin for periphery_account
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);
        init_wrapped_apt_fa(aave_std, aave_pool);

        // init token base (a tokens and var tokens)
        init_tokens(
            aave_pool,
            underlying_tokens_admin,
            TEST_RESERVES_COUNT,
            false
        );
    }

    public fun init_reserves_with_oracle_and_wrapped_coins(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        periphery_account: &signer
    ) {
        // init test env
        init_test_env(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // add pool and asset listing admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);
        // add emission admin for periphery_account
        acl_manage::add_emission_admin(
            aave_role_super_admin, signer::address_of(periphery_account)
        );
        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);
        init_wrapped_apt_fa(aave_std, aave_pool);

        // init token base (a tokens and var tokens)
        init_tokens(
            aave_pool,
            underlying_tokens_admin,
            TEST_RESERVES_COUNT,
            true
        );
    }

    public fun init_reserves_with_assets_count_params(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        reserves_count: u256
    ) {
        // init test env
        init_test_env(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // add pool and asset listing admin for aave_pool
        let aave_pool_address = signer::address_of(aave_pool);
        acl_manage::add_asset_listing_admin(aave_role_super_admin, aave_pool_address);
        acl_manage::add_pool_admin(aave_role_super_admin, aave_pool_address);

        // init oracle module
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);
        init_wrapped_apt_fa(aave_std, aave_pool);

        // init token base (a tokens and var tokens)
        init_tokens(
            aave_pool,
            underlying_tokens_admin,
            (reserves_count as u8),
            false
        );
    }

    // init token base (a tokens and var tokens)
    fun init_tokens(
        aave_pool: &signer,
        underlying_tokens_admin: &signer,
        reserves_count: u8,
        init_coins: bool
    ) {
        // create underlying_token, aToken, vToken
        let underlying_assets: vector<address> = vector[];
        let treasuries: vector<address> = vector[];
        let atokens_names: vector<String> = vector[];
        let atokens_symbols: vector<String> = vector[];
        let var_tokens_names: vector<String> = vector[];
        let var_tokens_symbols: vector<String> = vector[];
        let incentives_controllers: vector<Option<address>> = vector[];
        let optimal_usage_ratios: vector<u256> = vector[];
        let base_variable_borrow_rates: vector<u256> = vector[];
        let variable_rate_slope1s: vector<u256> = vector[];
        let variable_rate_slope2s: vector<u256> = vector[];
        for (i in 0..reserves_count) {
            let name = string_utils::format1(&b"APTOS_UNDERLYING_{}", i);
            let symbol = string_utils::format1(&b"U_{}", i);
            let decimals = 8;
            let max_supply = 100000000000000000000000;
            mock_underlying_token_factory::create_token(
                underlying_tokens_admin,
                max_supply,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b"")
            );

            let underlying_token_address =
                mock_underlying_token_factory::token_address(symbol);

            // init the default interest rate strategy for the underlying_token_address
            let optimal_usage_ratio: u256 = 800;
            let base_variable_borrow_rate: u256 = 0;
            let variable_rate_slope1: u256 = 4000;
            let variable_rate_slope2: u256 = 7500;
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy_for_testing(
                underlying_token_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );

            vector::push_back(&mut underlying_assets, underlying_token_address);
            vector::push_back(&mut treasuries, collector::collector_address());
            vector::push_back(
                &mut atokens_names, string_utils::format1(&b"APTOS_A_TOKEN_{}", i)
            );
            vector::push_back(&mut atokens_symbols, string_utils::format1(&b"A_{}", i));
            vector::push_back(
                &mut var_tokens_names,
                string_utils::format1(&b"APTOS_VAR_TOKEN_{}", i)
            );
            vector::push_back(
                &mut var_tokens_symbols, string_utils::format1(&b"V_{}", i)
            );
            vector::push_back(&mut incentives_controllers, option::none());
            vector::push_back(&mut optimal_usage_ratios, 400);
            vector::push_back(&mut base_variable_borrow_rates, 100);
            vector::push_back(&mut variable_rate_slope1s, 200);
            vector::push_back(&mut variable_rate_slope2s, 300);
        };

        // ===========================
        if (init_coins) {
            // add the wrapped apt fa token
            let apt_fa_address = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();

            vector::push_back(&mut underlying_assets, apt_fa_address);
            vector::push_back(&mut treasuries, collector::collector_address());
            vector::push_back(
                &mut atokens_names,
                string_utils::format1(&b"APTOS_A_TOKEN_{}", reserves_count + 1)
            );
            vector::push_back(
                &mut atokens_symbols,
                string_utils::format1(&b"A_{}", reserves_count + 1)
            );
            vector::push_back(
                &mut var_tokens_names,
                string_utils::format1(&b"APTOS_VAR_TOKEN_{}", reserves_count + 1)
            );
            vector::push_back(
                &mut var_tokens_symbols,
                string_utils::format1(&b"V_{}", reserves_count + 1)
            );
            vector::push_back(&mut incentives_controllers, option::none());
            vector::push_back(&mut optimal_usage_ratios, 400);
            vector::push_back(&mut base_variable_borrow_rates, 100);
            vector::push_back(&mut variable_rate_slope1s, 200);
            vector::push_back(&mut variable_rate_slope2s, 300);

            let optimal_usage_ratio: u256 = 800;
            let base_variable_borrow_rate: u256 = 0;
            let variable_rate_slope1: u256 = 4000;
            let variable_rate_slope2: u256 = 7500;
            default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy_for_testing(
                apt_fa_address,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );
        };
        // ===========================

        // create pool reserves
        pool_configurator::init_reserves(
            aave_pool,
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
        let total_reserves =
            if (init_coins) {
                reserves_count + 1
            } else {
                reserves_count
            };
        // check emitted events
        let emitted_events = emitted_events<ReserveInitialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == (total_reserves as u64), TEST_SUCCESS);
        // test reserves count
        assert!(
            number_of_active_and_dropped_reserves() == (total_reserves as u256),
            TEST_SUCCESS
        );

        // create reserve configurations
        for (j in 0..total_reserves) {
            let underlying_asset = *vector::borrow(&underlying_assets, (j as u64));
            let reserve_config_new = pool::get_reserve_configuration(underlying_asset);
            reserve_config::set_reserve_factor(&mut reserve_config_new, 1000); // NOTE: set reserve factor
            reserve_config::set_ltv(&mut reserve_config_new, 8000); // NOTE: set ltv
            reserve_config::set_debt_ceiling(&mut reserve_config_new, 0); // NOTE: set no debt_ceiling
            reserve_config::set_borrowable_in_isolation(&mut reserve_config_new, false); // NOTE: no borrowing in isolation
            reserve_config::set_siloed_borrowing(&mut reserve_config_new, false); // NOTE: no siloed borrowing
            reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true); // NOTE: enable flashloan
            reserve_config::set_borrowing_enabled(&mut reserve_config_new, true); // NOTE: enable borrowing
            reserve_config::set_liquidation_threshold(&mut reserve_config_new, 8500); // NOTE: enable liq. threshold
            reserve_config::set_liquidation_bonus(&mut reserve_config_new, 10500); // NOTE: enable liq. bonus
            pool::test_set_reserve_configuration(underlying_asset, reserve_config_new);
        };
    }

    public fun init_wrapped_apt_fa(aave_std: &signer, aave_pool: &signer) {
        // init the APT fa
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aave_std);
        let coin = coin::mint(100, &mint_cap);
        let fa = coin::coin_to_fungible_asset(coin);
        primary_fungible_store::deposit(signer::address_of(aave_std), fa);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_burn_cap(burn_cap);

        // get the wrapped token address
        let apt_fa_address = coin_migrator::get_fa_address<aptos_coin::AptosCoin>();

        // set unit price for the apt native wrapped APT fa
        let test_feed_id = vector<u8>[1];
        oracle::set_chainlink_mock_feed(aave_pool, apt_fa_address, test_feed_id);
        oracle::set_chainlink_mock_price(aave_pool, 1, test_feed_id);
        oracle::set_asset_feed_id(aave_pool, apt_fa_address, test_feed_id);
    }

    public fun convert_to_currency_decimals(
        token_address: address, amount: u256
    ): u256 {
        let decimals = fungible_asset_manager::decimals(token_address);
        amount * math_utils::pow(10, (decimals as u256))
    }

    public fun get_test_reserves_count(): u8 {
        TEST_RESERVES_COUNT
    }

    public fun set_asset_price(
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        underlying_asset: address,
        price: u256
    ) {
        // add pool admin for aave_oracle
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_oracle)
        );

        oracle::test_set_asset_custom_price(underlying_asset, price);
    }
}
