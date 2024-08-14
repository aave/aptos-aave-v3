#[test_only]
module aave_pool::pool_addresses_provider_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::signer::Self;
    use std::string::Self;
    use std::vector;
    use aptos_framework::event::emitted_events;

    use aave_pool::pool_addresses_provider::{
        ACLAdminUpdated,
        ACLManagerUpdated,
        get_acl_admin,
        get_acl_manager,
        get_address,
        get_market_id,
        get_pool,
        get_pool_configurator,
        get_pool_data_provider,
        get_price_oracle,
        get_price_oracle_sentinel,
        has_id_mapped_account,
        MarketIdSet,
        PoolConfiguratorUpdated,
        PoolDataProviderUpdated,
        PoolUpdated,
        PriceOracleSentinelUpdated,
        PriceOracleUpdated,
        set_acl_admin,
        set_acl_manager,
        set_address,
        set_market_id,
        set_pool_configurator,
        set_pool_data_provider,
        set_pool_impl,
        set_price_oracle,
        set_price_oracle_sentinel,
        test_init_module
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std)]
    fun test_market_id(
        deployer: &signer, super_admin: &signer, fx: &signer
    ) {
        let new_market_id = b"MAIN_MARKET";
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // set market id
        set_market_id(super_admin, string::utf8(new_market_id));
        // check the new market id via getter
        assert!(
            get_market_id() == option::some(string::utf8(new_market_id)),
            TEST_SUCCESS,
        );
        // check emitted events
        let market_id_set_events = emitted_events<MarketIdSet>();
        // make sure event of type was emitted
        assert!(vector::length(&market_id_set_events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_market_id_addr = @0x3)]
    fun test_set_get_address(
        deployer: &signer, super_admin: &signer, fx: &signer, new_market_id_addr: &signer
    ) {
        let id = b"MY_ID";
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get new_market_id_addr
        assert!(get_address(string::utf8(id)) == option::none<address>(), TEST_SUCCESS);
        // set market id and address
        set_address(super_admin, string::utf8(id), signer::address_of(new_market_id_addr));
        // check has mapped account
        assert!(has_id_mapped_account(string::utf8(id)), TEST_SUCCESS);
        // test get market id address
        assert!(
            get_address(string::utf8(id))
                == option::some(signer::address_of(new_market_id_addr)),
            TEST_SUCCESS,
        );
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_pool_impl = @0x3)]
    fun test_set_get_pool(
        deployer: &signer, super_admin: &signer, fx: &signer, new_pool_impl: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get pool address
        assert!(get_pool() == option::none(), TEST_SUCCESS);
        // set pool impl
        set_pool_impl(super_admin, signer::address_of(new_pool_impl));
        // test get pool address
        assert!(
            get_pool() == option::some(signer::address_of(new_pool_impl)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<PoolUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_pool_impl = @0x3)]
    fun test_set_get_pool_configurator(
        deployer: &signer, super_admin: &signer, fx: &signer, new_pool_impl: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get pool configurator address
        assert!(get_pool_configurator() == option::none(), TEST_SUCCESS);
        // set pool configurator impl
        set_pool_configurator(super_admin, signer::address_of(new_pool_impl));
        // test get pool configurator address
        assert!(
            get_pool_configurator() == option::some(signer::address_of(new_pool_impl)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<PoolConfiguratorUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_price_oracle = @0x3)]
    fun test_set_get_price_oracle(
        deployer: &signer, super_admin: &signer, fx: &signer, new_price_oracle: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get price oracle address
        assert!(get_price_oracle() == option::none(), TEST_SUCCESS);
        // set price oracle impl
        set_price_oracle(super_admin, signer::address_of(new_price_oracle));
        // test get price oracle address
        assert!(
            get_price_oracle() == option::some(signer::address_of(new_price_oracle)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<PriceOracleUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_acl_admin = @0x3)]
    fun test_set_get_acl_admin(
        deployer: &signer, super_admin: &signer, fx: &signer, new_acl_admin: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get acl admin address
        assert!(get_acl_admin() == option::none(), TEST_SUCCESS);
        // set acl admin impl
        set_acl_admin(super_admin, signer::address_of(new_acl_admin));
        // test acl admin address
        assert!(
            get_acl_admin() == option::some(signer::address_of(new_acl_admin)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<ACLAdminUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_acl_manager = @0x3)]
    fun test_set_get_acl_manager(
        deployer: &signer, super_admin: &signer, fx: &signer, new_acl_manager: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get acl manager address
        assert!(get_acl_manager() == option::none(), TEST_SUCCESS);
        // set acl manager impl
        set_acl_manager(super_admin, signer::address_of(new_acl_manager));
        // test acl manager address
        assert!(
            get_acl_manager() == option::some(signer::address_of(new_acl_manager)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<ACLManagerUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_price_oracle_sentinel = @0x3)]
    fun test_set_get_price_oracle_sentinel(
        deployer: &signer,
        super_admin: &signer,
        fx: &signer,
        new_price_oracle_sentinel: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get price oracle sentinel address
        assert!(get_price_oracle_sentinel() == option::none(), TEST_SUCCESS);
        // set price oracle sentinel impl
        set_price_oracle_sentinel(
            super_admin, signer::address_of(new_price_oracle_sentinel)
        );
        // test price oracle sentinel address
        assert!(
            get_price_oracle_sentinel()
                == option::some(signer::address_of(new_price_oracle_sentinel)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<PriceOracleSentinelUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }

    #[test(deployer = @aave_pool, super_admin = @aave_acl, fx = @std, new_pool_data_provider_sentinel = @0x3)]
    fun test_set_get_pool_data_provider_sentinel(
        deployer: &signer,
        super_admin: &signer,
        fx: &signer,
        new_pool_data_provider_sentinel: &signer
    ) {
        // add the test events feature flag
        change_feature_flags_for_testing(fx, vector[26], vector[]);
        // init the module
        test_init_module(deployer);
        // test get pool data provider address
        assert!(get_pool_data_provider() == option::none(), TEST_SUCCESS);
        // set pool data provider impl
        set_pool_data_provider(
            super_admin, signer::address_of(new_pool_data_provider_sentinel)
        );
        // test pool data provider address
        assert!(
            get_pool_data_provider()
                == option::some(signer::address_of(new_pool_data_provider_sentinel)),
            TEST_SUCCESS,
        );
        // check emitted events
        let events = emitted_events<PoolDataProviderUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&events) == 1, TEST_SUCCESS);
    }
}
