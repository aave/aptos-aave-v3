#[test_only]
module aave_pool::gho_direct_minter_tests {
    // std
    use std::signer;
    use std::vector;
    use std::option;
    use std::string::utf8;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    // imports from the aave-core
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::pool_token_logic;
    use aave_pool::pool;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::pool_configurator::Self;
    use aave_pool::token_base;
    use aave_pool::a_token_factory;
    use aave_pool::collector;
    use aave_pool::supply_logic::Self;
    use aave_pool::borrow_logic::Self;
    use aave_pool::pool_fee_manager;
    use aave_pool::gho_direct_minter;
    use aave_pool::token_helper;
    use aave_config::reserve_config;
    use aave_oracle::oracle_tests;
    use aave_acl::acl_manage as pool_acl_manage;
    use gho::gho_token;
    use gho::gho_reserve;
    use gho_acl::acl_manage as gho_acl_manage;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
    const GHO_RESERVE_SEED: vector<u8> = b"GHO_RESERVE";

    fun create_test_gho_reserve(aave_pool: &signer): address {
        let test_symbol = b"TEST_GHO";
        let metadata_address = gho_token::get_metadata_address();
        pool_token_logic::test_init_reserve(
            aave_pool,
            metadata_address,
            collector::collector_address(),
            option::none(),
            utf8(b"Test AGHO"),
            utf8(test_symbol),
            utf8(b"Test VGHO"),
            utf8(test_symbol),
            400,
            100,
            200,
            300
        );

        // Enable borrowing on the reserve
        let reserve_config_new =
            pool::get_reserve_configuration(gho_token::get_metadata_address());
        reserve_config::set_reserve_factor(&mut reserve_config_new, 1000); // NOTE: set reserve factor
        reserve_config::set_ltv(&mut reserve_config_new, 8000); // NOTE: set ltv
        reserve_config::set_debt_ceiling(&mut reserve_config_new, 0); // NOTE: set no debt_ceiling
        reserve_config::set_borrowable_in_isolation(&mut reserve_config_new, false); // NOTE: no borrowing in isolation
        reserve_config::set_siloed_borrowing(&mut reserve_config_new, false); // NOTE: no siloed borrowing
        reserve_config::set_flash_loan_enabled(&mut reserve_config_new, true); // NOTE: enable flashloan
        reserve_config::set_borrowing_enabled(&mut reserve_config_new, true); // NOTE: enable borrowing
        reserve_config::set_liquidation_threshold(&mut reserve_config_new, 8500); // NOTE: enable liq. threshold
        reserve_config::set_liquidation_bonus(&mut reserve_config_new, 10500); // NOTE: enable liq. bonus
        pool::test_set_reserve_configuration(
            gho_token::get_metadata_address(), reserve_config_new
        );

        a_token_factory::token_address(utf8(test_symbol))
    }

    #[test(account = @0x33)]
    #[expected_failure(abort_code = 23, location = aave_pool::gho_direct_minter)]
    fun test_init_module(account: &signer) {
        gho_direct_minter::init_module_for_testing(account);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            gho_admin = @gho,
            gho_acl_admin = @gho_acl,
            gho_guardian = @0x222
        )
    ]
    fun test_direct_minter_supply(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        gho_admin: &signer,
        gho_acl_admin: &signer,
        gho_guardian: &signer
    ) {
        // Start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // Initialize the gho-related entities
        gho_acl_manage::test_init_module(gho_acl_admin);
        gho_token::test_init_module(gho_admin);
        gho_reserve::test_init_module(gho_admin);
        gho_acl_manage::add_default_admin(gho_acl_admin, signer::address_of(gho_admin));

        // Init aave pool acl
        pool_acl_manage::test_init_module(aave_acl);
        // Add the aave_pool as pool admin
        pool_acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));
        // Add the gho guardian to the pool acl
        pool_acl_manage::add_gho_guardian(aave_acl, signer::address_of(gho_guardian));
        // Init the gho direct minter module
        gho_direct_minter::init_module_for_testing(aave_pool);
        let gho_reserve_entity = gho_direct_minter::get_direct_minter_signer_address();
        // Add the direct minter to the pool acl as risk admin
        pool_acl_manage::add_risk_admin(aave_acl, gho_reserve_entity);
        // Add the gho address to the gho direct minter
        gho_direct_minter::set_gho_address(aave_pool, gho_token::get_metadata_address());

        // Init the pool and its components
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );
        pool_fee_manager::init_module_for_testing(aave_pool);

        // Simulate minting gho over the bridge to the gho reserve
        let reserve_address = gho_reserve::get_gho_reserve_address(GHO_RESERVE_SEED);
        let mint_amount = 10_000_000; // 10 gho tokens
        gho_token::test_mint_directly_to_user(gho_admin, reserve_address, mint_amount);

        // Add gho_reserve_entity as an entity with a limit
        let entity_limit = 8_000_000; // 8 gho tokens limit
        gho_reserve::add_entity(gho_admin, reserve_address, gho_reserve_entity);
        gho_reserve::set_limit(gho_admin, reserve_address, gho_reserve_entity, entity_limit);

        // Check the entity limit
        let limit = gho_reserve::get_limit(reserve_address,gho_reserve_entity);
        assert!(limit == entity_limit, TEST_SUCCESS);

        // Add gho as a reserve to the pool
        let atoken_address = create_test_gho_reserve(aave_pool);

        // Check the atoken balance of the entity before minting
        let gho_reserve_entity_atoken_balance_before =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_before == 0, TEST_SUCCESS);

        // Check the gho balance of the entity before the supply (should be zero)
        let gho_reserve_entity_balance_before_supply =
            gho_token::get_balance(gho_reserve_entity);
        assert!(gho_reserve_entity_balance_before_supply == 0, TEST_SUCCESS);

        // Use and supply GHO
        let supply_amount = 1_000_000; // 1 gho token
        gho_direct_minter::use_and_supply(gho_guardian, supply_amount);

        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // Check the atoken balance of the entity after minting
        let gho_reserve_entity_atoken_balance_after =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_after == supply_amount, TEST_SUCCESS);

        // Check the gho balance of the entity after the supply (should be zero)
        let gho_balance_after_supply = gho_token::get_balance(gho_reserve_entity);
        assert!(gho_balance_after_supply == 0, TEST_SUCCESS);

        // Check the gho balance of the reserve after the withdraw (should be equal to the initial mint amount minus supply amount)
        let gho_reserve_balance_after_withdraw = gho_token::get_balance(reserve_address);
        assert!(
            gho_reserve_balance_after_withdraw == mint_amount - supply_amount,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            gho_admin = @gho,
            gho_acl_admin = @gho_acl,
            gho_guardian = @0x222
        )
    ]
    #[expected_failure(abort_code = 104, location = aave_pool::gho_direct_minter)]
    fun test_direct_minter_supply_no_guardian(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        gho_admin: &signer,
        gho_acl_admin: &signer,
        gho_guardian: &signer
    ) {
        // Start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // Initialize the gho-related entities
        gho_acl_manage::test_init_module(gho_acl_admin);
        gho_token::test_init_module(gho_admin);
        gho_reserve::test_init_module(gho_admin);
        gho_acl_manage::add_default_admin(gho_acl_admin, signer::address_of(gho_admin));

        // Init aave pool acl
        pool_acl_manage::test_init_module(aave_acl);
        // Add the aave_pool as pool admin
        pool_acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));
        // Init the gho direct minter module
        gho_direct_minter::init_module_for_testing(aave_pool);
        let gho_reserve_entity = gho_direct_minter::get_direct_minter_signer_address();
        // Add the direct minter to the pool acl as risk admin
        pool_acl_manage::add_risk_admin(aave_acl, gho_reserve_entity);
        // Add the gho address to the gho direct minter
        gho_direct_minter::set_gho_address(aave_pool, gho_token::get_metadata_address());

        // Init the pool and its components
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );
        pool_fee_manager::init_module_for_testing(aave_pool);

        // Simulate minting gho over the bridge to the gho reserve
        let reserve_address = gho_reserve::get_gho_reserve_address(GHO_RESERVE_SEED);
        let mint_amount = 10_000_000; // 10 gho tokens
        gho_token::test_mint_directly_to_user(gho_admin, reserve_address, mint_amount);

        // Add gho_reserve_entity as an entity with a limit
        let entity_limit = 8_000_000; // 8 gho tokens limit
        gho_reserve::add_entity(gho_admin, reserve_address, gho_reserve_entity);
        gho_reserve::set_limit(gho_admin, reserve_address, gho_reserve_entity, entity_limit);

        // Check the entity level
        let limit = gho_reserve::get_limit(reserve_address, gho_reserve_entity);
        assert!(limit == entity_limit, TEST_SUCCESS);

        // Add gho as a reserve to the pool
        let atoken_address = create_test_gho_reserve(aave_pool);

        // Check the atoken balance of the entity before minting
        let gho_reserve_entity_atoken_balance_before =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_before == 0, TEST_SUCCESS);

        // Check the gho balance of the entity before the supply (should be zero)
        let gho_reserve_entity_balance_before_supply =
            gho_token::get_balance(gho_reserve_entity);
        assert!(gho_reserve_entity_balance_before_supply == 0, TEST_SUCCESS);

        // Use and supply GHO
        let supply_amount = 1_000_000; // 1 gho token
        gho_direct_minter::use_and_supply(gho_guardian, supply_amount);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            gho_admin = @gho,
            gho_acl_admin = @gho_acl,
            gho_guardian = @0x222
        )
    ]
    #[expected_failure(abort_code = 105, location = aave_pool::gho_direct_minter)]
    fun test_direct_minter_supply_0_entity_limit(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        gho_admin: &signer,
        gho_acl_admin: &signer,
        gho_guardian: &signer
    ) {
        // Start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // Initialize the gho-related entities
        gho_acl_manage::test_init_module(gho_acl_admin);
        gho_token::test_init_module(gho_admin);
        gho_reserve::test_init_module(gho_admin);
        gho_acl_manage::add_default_admin(gho_acl_admin, signer::address_of(gho_admin));

        // Init aave pool acl
        pool_acl_manage::test_init_module(aave_acl);
        // Add the aave_pool as pool admin
        pool_acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));
        // Add the gho guardian to the pool acl
        pool_acl_manage::add_gho_guardian(aave_acl, signer::address_of(gho_guardian));
        // Init the gho direct minter module
        gho_direct_minter::init_module_for_testing(aave_pool);
        let gho_reserve_entity = gho_direct_minter::get_direct_minter_signer_address();
        // Add the direct minter to the pool acl as risk admin
        pool_acl_manage::add_risk_admin(aave_acl, gho_reserve_entity);
        // Add the gho address to the gho direct minter
        gho_direct_minter::set_gho_address(aave_pool, gho_token::get_metadata_address());

        // Init the pool and its components
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );
        pool_fee_manager::init_module_for_testing(aave_pool);

        // Simulate minting gho over the bridge to the gho reserve
        let reserve_address = gho_reserve::get_gho_reserve_address(GHO_RESERVE_SEED);
        let mint_amount = 10_000_000; // 10 gho tokens
        gho_token::test_mint_directly_to_user(gho_admin, reserve_address, mint_amount);

        // Add gho_reserve_entity as an entity with a limit
        let entity_limit = 0; // zero limit
        gho_reserve::add_entity(gho_admin, reserve_address, gho_reserve_entity);
        gho_reserve::set_limit(gho_admin, reserve_address, gho_reserve_entity, entity_limit);

        // Check the entity level
        let limit = gho_reserve::get_limit(reserve_address, gho_reserve_entity);
        assert!(limit == entity_limit, TEST_SUCCESS);

        // Add gho as a reserve to the pool
        let atoken_address = create_test_gho_reserve(aave_pool);

        // Check the atoken balance of the entity before minting
        let gho_reserve_entity_atoken_balance_before =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_before == 0, TEST_SUCCESS);

        // Check the gho balance of the entity before the supply (should be zero)
        let gho_reserve_entity_balance_before_supply =
            gho_token::get_balance(gho_reserve_entity);
        assert!(gho_reserve_entity_balance_before_supply == 0, TEST_SUCCESS);

        // Use and supply GHO
        let supply_amount = 1_000_000; // 1 gho token
        gho_direct_minter::use_and_supply(gho_guardian, supply_amount);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            gho_admin = @gho,
            gho_acl_admin = @gho_acl,
            gho_guardian = @0x222
        )
    ]
    fun test_direct_minter_supply_withdraw(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        gho_admin: &signer,
        gho_acl_admin: &signer,
        gho_guardian: &signer
    ) {
        // Start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // Initialize the gho-related entities
        gho_acl_manage::test_init_module(gho_acl_admin);
        gho_token::test_init_module(gho_admin);
        gho_reserve::test_init_module(gho_admin);
        gho_acl_manage::add_default_admin(gho_acl_admin, signer::address_of(gho_admin));

        // Init aave pool acl
        pool_acl_manage::test_init_module(aave_acl);
        // Add the aave_pool as pool admin
        pool_acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));
        // Add the gho guardian to the pool acl
        pool_acl_manage::add_gho_guardian(aave_acl, signer::address_of(gho_guardian));
        // Init the gho direct minter module
        gho_direct_minter::init_module_for_testing(aave_pool);
        let gho_reserve_entity = gho_direct_minter::get_direct_minter_signer_address();
        // Add the direct minter to the pool acl as risk admin
        pool_acl_manage::add_risk_admin(aave_acl, gho_reserve_entity);
        // Add the gho address to the gho direct minter
        gho_direct_minter::set_gho_address(aave_pool, gho_token::get_metadata_address());

        // Init the pool and its components
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );
        pool_fee_manager::init_module_for_testing(aave_pool);

        // Simulate minting gho over the bridge to the gho reserve
        let reserve_address = gho_reserve::get_gho_reserve_address(GHO_RESERVE_SEED);
        let mint_amount = 10_000_000; // 10 gho tokens
        gho_token::test_mint_directly_to_user(gho_admin, reserve_address, mint_amount);

        // Add gho_reserve_entity as an entity with a limit
        let entity_limit = 8_000_000; // 8 gho tokens limit
        gho_reserve::add_entity(gho_admin, reserve_address, gho_reserve_entity);
        gho_reserve::set_limit(gho_admin, reserve_address, gho_reserve_entity, entity_limit);

        // Check the entity level
        let limit = gho_reserve::get_limit(reserve_address, gho_reserve_entity);
        assert!(limit == entity_limit, TEST_SUCCESS);

        // Add gho as a reserve to the pool
        let atoken_address = create_test_gho_reserve(aave_pool);

        // Check the atoken balance of the entity before minting
        let gho_reserve_entity_atoken_balance_before =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_before == 0, TEST_SUCCESS);

        // Check the gho balance of the entity before the supply (should be zero)
        let gho_reserve_entity_balance_before_supply =
            gho_token::get_balance(gho_reserve_entity);
        assert!(gho_reserve_entity_balance_before_supply == 0, TEST_SUCCESS);

        // Use and supply GHO
        let supply_amount = 1_000_000; // 1 gho token
        gho_direct_minter::use_and_supply(gho_guardian, supply_amount);

        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // Check the atoken balance of the entity after minting
        let gho_reserve_entity_atoken_balance_after =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_after == supply_amount, TEST_SUCCESS);

        // Check the gho balance of the entity after the supply (should be zero)
        let gho_balance_after_supply = gho_token::get_balance(gho_reserve_entity);
        assert!(gho_balance_after_supply == 0, TEST_SUCCESS);

        // Check the gho balance of the reserve after the withdraw (should be equal to the initial mint amount minus supply amount)
        let gho_reserve_balance_after_withdraw = gho_token::get_balance(reserve_address);
        assert!(
            gho_reserve_balance_after_withdraw == mint_amount - supply_amount,
            TEST_SUCCESS
        );

        // withdaw the supplied GHO
        gho_direct_minter::withdraw_and_restore(gho_guardian, supply_amount);

        // Check the atoken balance of the entity after the withdraw (should be zero)
        let gho_reserve_entity_atoken_balance_after =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_after == 0, TEST_SUCCESS);

        // Check the gho balance of the entity after the withdraw (should be zero)
        let gho_balance_after_withdraw = gho_token::get_balance(gho_reserve_entity);
        assert!(gho_balance_after_withdraw == 0, TEST_SUCCESS);

        // Check the gho balance of the reserve after the withdraw (should be equal to the initial mint amount)
        let gho_reserve_balance_after_withdraw = gho_token::get_balance(reserve_address);
        assert!(gho_reserve_balance_after_withdraw == mint_amount, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            gho_admin = @gho,
            gho_acl_admin = @gho_acl,
            gho_guardian = @0x222,
            gho_borrower = @0x333
        )
    ]
    fun test_direct_minter_supply_transfer_excess_to_treasury(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        gho_admin: &signer,
        gho_acl_admin: &signer,
        gho_guardian: &signer,
        gho_borrower: &signer
    ) {
        // Start the timer
        timestamp::set_time_has_started_for_testing(aave_std);

        // Initialize the gho-related entities
        gho_acl_manage::test_init_module(gho_acl_admin);
        gho_token::test_init_module(gho_admin);
        gho_reserve::test_init_module(gho_admin);
        gho_acl_manage::add_default_admin(gho_acl_admin, signer::address_of(gho_admin));

        // Init aave pool acl
        pool_acl_manage::test_init_module(aave_acl);
        // Add the aave_pool as pool admin
        pool_acl_manage::add_pool_admin(aave_acl, signer::address_of(aave_pool));
        pool_acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(aave_pool)
        );
        // Add the gho guardian to the pool acl
        pool_acl_manage::add_gho_guardian(aave_acl, signer::address_of(gho_guardian));
        // Init the gho direct minter module
        gho_direct_minter::init_module_for_testing(aave_pool);
        let gho_reserve_entity = gho_direct_minter::get_direct_minter_signer_address();
        // Add the direct minter to the pool acl as risk admin
        pool_acl_manage::add_risk_admin(aave_acl, gho_reserve_entity);
        // Add the gho address to the gho direct minter
        gho_direct_minter::set_gho_address(aave_pool, gho_token::get_metadata_address());

        // Init the pool and its components
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool_fee_manager::init_module_for_testing(aave_pool);
        collector::init_module_test(aave_pool);
        pool_configurator::test_init_module(aave_pool);

        // Configure the oracle
        oracle_tests::config_oracle(aave_oracle, data_feeds, platform);
        // Set GHO price
        token_helper::set_asset_price(
            aave_acl,
            aave_oracle,
            gho_direct_minter::get_gho_token_address(),
            100
        );

        // Simulate minting gho over the bridge to the gho reserve
        let reserve_address = gho_reserve::get_gho_reserve_address(GHO_RESERVE_SEED);
        let mint_amount = 10_000_000; // 10 gho tokens
        gho_token::test_mint_directly_to_user(gho_admin, reserve_address, mint_amount);

        // Mint some tokens for the borrower
        gho_token::test_mint_directly_to_user(
            gho_admin, signer::address_of(gho_borrower), mint_amount
        );

        // Add gho_reserve_entity as an entity with a limit
        let entity_limit = 8_000_000; // 8 gho tokens limit
        gho_reserve::add_entity(gho_admin, reserve_address, gho_reserve_entity);
        gho_reserve::set_limit(gho_admin, reserve_address, gho_reserve_entity, entity_limit);

        // Check the entity level
        let limit = gho_reserve::get_limit(reserve_address, gho_reserve_entity);
        assert!(limit == entity_limit, TEST_SUCCESS);

        // Add gho as a reserve to the pool
        let atoken_address = create_test_gho_reserve(aave_pool);

        // Check the atoken balance of the entity before minting
        let gho_reserve_entity_atoken_balance_before =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_before == 0, TEST_SUCCESS);

        // Check the gho balance of the entity before the supply (should be zero)
        let gho_reserve_entity_balance_before_supply =
            gho_token::get_balance(gho_reserve_entity);
        assert!(gho_reserve_entity_balance_before_supply == 0, TEST_SUCCESS);

        // Use and supply GHO
        let supply_amount = 7_000_000; // 7 gho tokens
        gho_direct_minter::use_and_supply(gho_guardian, supply_amount);

        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // Check the atoken balance of the entity after minting
        let gho_reserve_entity_atoken_balance_after =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(gho_reserve_entity_atoken_balance_after == supply_amount, TEST_SUCCESS);

        // Check the gho balance of the entity after the supply (should be zero)
        let gho_balance_after_supply = gho_token::get_balance(gho_reserve_entity);
        assert!(gho_balance_after_supply == 0, TEST_SUCCESS);

        // Check the gho balance of the reserve after the withdraw (should be equal to the initial mint amount minus supply amount)
        let gho_reserve_balance_after_withdraw = gho_token::get_balance(reserve_address);
        assert!(
            gho_reserve_balance_after_withdraw == mint_amount - supply_amount,
            TEST_SUCCESS
        );

        // The borrower will supply some gho as collateral and borrow some to generate interest
        supply_logic::supply(
            gho_borrower,
            gho_direct_minter::get_gho_token_address(),
            5_000_000,
            signer::address_of(gho_borrower),
            0
        );

        // Enable the gho as collateral for the borrower
        supply_logic::set_user_use_reserve_as_collateral(
            gho_borrower, gho_direct_minter::get_gho_token_address(), true
        );

        // Make a borrow to generate some interest
        let borrow_amount = 1_000_000; // 1 gho tokens
        borrow_logic::borrow(
            gho_borrower,
            gho_direct_minter::get_gho_token_address(),
            borrow_amount,
            2,
            0,
            signer::address_of(gho_borrower)
        );

        // Fast forward time by 1 year to accrue some interest
        let seconds_per_year = 24 * 60 * 60 * 365;
        timestamp::fast_forward_seconds(seconds_per_year);

        // Check the atoken balance of the entity after some interest has been accrued
        let a_token_entity_balance_after =
            a_token_factory::balance_of(gho_reserve_entity, atoken_address);
        assert!(
            a_token_entity_balance_after > supply_amount,
            TEST_SUCCESS
        );

        // Check the atoken balance of the collector before the transfer is exactly zero
        let a_token_collector_balance_before =
            a_token_factory::balance_of(
                gho_direct_minter::get_collector_address(), atoken_address
            );
        assert!(
            a_token_collector_balance_before == 0,
            TEST_SUCCESS
        );

        // Transfer the excess to the treasury
        gho_direct_minter::transfer_excess_to_treasury();

        // Check the atoken balance of the collector after the transfer is greater than zero
        let a_token_collector_balance_after =
            a_token_factory::balance_of(
                gho_direct_minter::get_collector_address(), atoken_address
            );
        assert!(
            a_token_collector_balance_after > 0,
            TEST_SUCCESS
        );
    }
}
