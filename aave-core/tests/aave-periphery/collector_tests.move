#[test_only]
module aave_pool::collector_tests {
    use std::option;
    use std::signer;
    use std::string::utf8;
    use aptos_framework::account;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_math::wad_ray_math;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::pool_token_logic;
    use aave_pool::pool;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::token_base;
    use aave_pool::a_token_factory;
    use aave_pool::collector;
    use aave_pool::standard_token;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    fun create_test_atoken(
        aave_pool: &signer, creator: &signer, treasury: address
    ): address {
        let test_symbol = b"TEST";
        standard_token::initialize(
            creator,
            0,
            utf8(b"Test Token"),
            utf8(test_symbol),
            8,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"http://example.com"),
            vector[true, true, true],
            @0x1,
            false
        );
        let metadata_address =
            object::create_object_address(&signer::address_of(creator), test_symbol);

        pool_token_logic::test_init_reserve(
            aave_pool,
            metadata_address,
            treasury,
            option::none(),
            utf8(b"Test AToken"),
            utf8(test_symbol),
            utf8(b"Test VToken"),
            utf8(test_symbol),
            400,
            100,
            200,
            300
        );

        a_token_factory::token_address(utf8(test_symbol))
    }

    fun create_test_fa_without_atoken(creator: &signer): address {
        let test_symbol = b"DUMMY";
        standard_token::initialize(
            creator,
            0,
            utf8(b"Dummy Token"),
            utf8(test_symbol),
            8,
            utf8(b"http://example.com/favicon.ico"),
            utf8(b"http://example.com"),
            vector[true, true, true],
            @0x1,
            false
        );
        object::create_object_address(&signer::address_of(creator), test_symbol)
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_pool = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222
        )
    ]
    fun test_basic_flow(
        aptos_framework: &signer,
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        aave_pool: &signer,
        acl_fund_admin: &signer,
        user_account: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);

        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set roles
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // assert role is granted
        assert!(
            acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );

        // init collector
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        collector::init_module_test(aave_pool);
        let treasury = collector::collector_address();

        // create test token
        let metadata = create_test_atoken(aave_pool, fa_creator, treasury);

        // mint fees
        a_token_factory::mint_to_treasury(200, wad_ray_math::ray(), metadata);
        assert!(
            primary_fungible_store::balance(
                treasury, object::address_to_object<Metadata>(metadata)
            ) == 200,
            TEST_SUCCESS
        );

        // assert the fees are in the secondary store
        assert!(collector::get_collected_fees(metadata) == 200, TEST_SUCCESS);

        // transfer some of the fees to the user
        let user_address = signer::address_of(user_account);
        collector::withdraw(acl_fund_admin, metadata, user_address, 50);

        // check user and collector's store balances
        assert!(collector::get_collected_fees(metadata) == 150, TEST_SUCCESS);
        assert!(
            primary_fungible_store::balance(
                user_address, object::address_to_object<Metadata>(metadata)
            ) == 50,
            TEST_SUCCESS
        );

        // transfer back half of the fees to the user
        collector::withdraw(acl_fund_admin, metadata, user_address, 100);

        // check user and collectpr's store balances
        assert!(collector::get_collected_fees(metadata) == 50, TEST_SUCCESS);
        assert!(
            primary_fungible_store::balance(
                user_address, object::address_to_object<Metadata>(metadata)
            ) == 150,
            TEST_SUCCESS
        );
    }

    #[test(
        aave_role_super_admin = @aave_acl,
        collector_account = @aave_pool,
        acl_fund_admin = @0x111
    )]
    fun test_is_funds_admin_pass(
        aave_role_super_admin: &signer, collector_account: &signer, acl_fund_admin: &signer
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set fund admin
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // assert role is granted
        assert!(
            acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );

        // initialize the collector
        collector::init_module_test(collector_account);

        // assert funds admin role is granted
        assert!(
            collector::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );
    }

    #[test(
        aave_role_super_admin = @aave_acl,
        collector_account = @aave_pool,
        acl_fund_admin = @0x111
    )]
    fun test_is_funds_admin_fail(
        aave_role_super_admin: &signer, collector_account: &signer, acl_fund_admin: &signer
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);
        // set fund admin
        let some_acl_funds_admin = @0x222;
        acl_manage::add_funds_admin(aave_role_super_admin, some_acl_funds_admin);
        // assert role is granted
        assert!(acl_manage::is_funds_admin(some_acl_funds_admin), TEST_SUCCESS);

        // initialize the collector
        collector::init_module_test(collector_account);

        // assert funds admin role is granted
        assert!(
            !collector::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_collector_address() {
        assert!(
            collector::collector_address()
                == account::create_resource_address(
                    &@aave_pool, collector::get_collector_name()
                ),
            TEST_SUCCESS
        );
    }

    #[
        test(
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_pool = @aave_pool,
            acl_fund_admin = @0x111
        )
    ]
    fun test_get_collected_fees_when_asset_not_in_atoken(
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        aave_pool: &signer,
        acl_fund_admin: &signer
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set roles
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // init collector
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        collector::init_module_test(aave_pool);
        let treasury = collector::collector_address();

        // create test tokens
        let metadata = create_test_atoken(aave_pool, fa_creator, treasury);
        let dummy_token = create_test_fa_without_atoken(fa_creator);

        // mint fees
        a_token_factory::mint_to_treasury(200, wad_ray_math::ray(), metadata);
        assert!(
            primary_fungible_store::balance(
                treasury, object::address_to_object<Metadata>(metadata)
            ) == 200,
            TEST_SUCCESS
        );

        // assert the fees are in the secondary store
        assert!(collector::get_collected_fees(dummy_token) == 0, TEST_SUCCESS);
    }

    #[
        test(
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_pool = @aave_pool,
            collector_account = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222
        )
    ]
    #[expected_failure(abort_code = 3010, location = aave_pool::collector)]
    fun test_withdraw_when_account_is_not_funds_admin(
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        aave_pool: &signer,
        collector_account: &signer,
        acl_fund_admin: &signer,
        user_account: &signer
    ) {
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set roles
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // assert role is granted
        assert!(
            acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );

        // init collector
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        collector::init_module_test(aave_pool);
        let treasury = collector::collector_address();

        // create test token
        let metadata = create_test_atoken(aave_pool, fa_creator, treasury);

        // mint fees
        a_token_factory::mint_to_treasury(200, wad_ray_math::ray(), metadata);
        assert!(
            primary_fungible_store::balance(
                treasury, object::address_to_object<Metadata>(metadata)
            ) == 200,
            TEST_SUCCESS
        );

        // assert the fees are in the secondary store
        assert!(collector::get_collected_fees(metadata) == 200, TEST_SUCCESS);

        // transfer some of the fees to the user
        let user_address = signer::address_of(user_account);
        collector::withdraw(collector_account, metadata, user_address, 50);
    }

    #[test(user1 = @0x33)]
    #[expected_failure(abort_code = 1, location = aave_pool::collector)]
    fun test_init_module(user1: &signer) {
        collector::init_module_test(user1);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            aave_role_super_admin = @aave_acl,
            aave_pool = @aave_pool,
            acl_fund_admin = @0x111
        )
    ]
    #[expected_failure(abort_code = 11, location = aave_pool::collector)]
    fun test_withdraw_with_caller_not_atoken(
        aptos_framework: &signer,
        aave_role_super_admin: &signer,
        aave_pool: &signer,
        acl_fund_admin: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set roles
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // assert role is granted
        assert!(
            acl_manage::is_funds_admin(signer::address_of(acl_fund_admin)),
            TEST_SUCCESS
        );

        // init collector
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        collector::init_module_test(aave_pool);

        let metadata = @0x31;
        let user_address = @0x312;
        collector::withdraw(acl_fund_admin, metadata, user_address, 100);
    }

    #[
        test(
            aptos_framework = @aptos_framework,
            fa_creator = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_pool = @aave_pool,
            acl_fund_admin = @0x111,
            user_account = @0x222
        )
    ]
    #[expected_failure(abort_code = 11, location = aave_pool::collector)]
    fun test_withdraw_non_atoken(
        aptos_framework: &signer,
        fa_creator: &signer,
        aave_role_super_admin: &signer,
        aave_pool: &signer,
        acl_fund_admin: &signer,
        user_account: &signer
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);

        // init acl
        acl_manage::test_init_module(aave_role_super_admin);

        // set roles
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_funds_admin(
            aave_role_super_admin, signer::address_of(acl_fund_admin)
        );

        // init collector
        token_base::test_init_module(aave_pool);
        a_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::test_init_module(aave_pool);
        pool::test_init_pool(aave_pool);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy_for_testing(
            aave_pool
        );

        collector::init_module_test(aave_pool);
        let treasury = collector::collector_address();

        // create test tokens
        let metadata = create_test_atoken(aave_pool, fa_creator, treasury);

        // mint fees
        a_token_factory::mint_to_treasury(200, wad_ray_math::ray(), metadata);

        // mint dummy tokens
        let dummy_token = create_test_fa_without_atoken(fa_creator);
        standard_token::mint_to_primary_stores(
            fa_creator,
            object::address_to_object(dummy_token),
            vector[treasury],
            vector[200]
        );
        collector::withdraw(
            acl_fund_admin,
            dummy_token,
            signer::address_of(user_account),
            100
        );
    }
}
