#[test_only]
module aave_oracle::oracle_tests {
    use std::option;
    use std::signer;
    use std::vector;
    use std::string::utf8;
    use aave_oracle::oracle::Self;
    use aave_acl::acl_manage::Self;
    use aptos_framework::timestamp::{set_time_has_started_for_testing};
    use data_feeds::registry::Self;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use data_feeds::router;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
    const TEST_ASSET: address = @0x444;
    const TEST_FEED_ID: vector<u8> = x"0003fbba4fce42f65d6032b18aee53efdf526cc734ad296cb57565979d883bdd";
    const TEST_FEED_PRICE: u256 = 63762090573356116000000;
    const TEST_ASSET_CUSTOM_PRICE: u256 = 1200;

    public fun get_test_feed_id(): vector<u8> {
        TEST_FEED_ID
    }

    public fun config_oracle(
        aave_oracle: &signer, data_feeds: &signer, platform: &signer
    ) {
        oracle::test_init_module(aave_oracle);
        set_up_chainlink_oracle(data_feeds, platform);
        let config_id = vector[1];
        registry::set_feed_for_test(TEST_FEED_ID, utf8(b"description"), config_id);
        registry::perform_update_for_test(
            TEST_FEED_ID,
            (timestamp::now_seconds() as u256),
            TEST_FEED_PRICE,
            vector::empty<u8>()
        )
    }

    fun set_up_chainlink_oracle(data_feeds: &signer, platform: &signer) {
        registry::set_up_test(data_feeds, platform);
        router::init_module_for_testing(data_feeds);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1214, location = aave_oracle::oracle)]
    fun test_oracle_price_unknown_asset(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // check assets which are not known fail to return a price
        let undeclared_asset = @0x0;
        oracle::get_asset_price(undeclared_asset);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_single_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // now set a feed for a given token
        oracle::set_asset_feed_id(oracle_admin, TEST_ASSET, TEST_FEED_ID);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedUpdated>();
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // assert the set price
        assert!(oracle::get_asset_price(TEST_ASSET) == TEST_FEED_PRICE, TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_batch_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feedids
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedUpdated>();
        assert!(
            vector::length(&emitted_events) == vector::length(&asset_addresses),
            TEST_SUCCESS
        );

        // get prices and ensure they are all > 0 since mocked
        let prices = oracle::get_assets_prices(asset_addresses);
        assert!(!vector::any(&prices, |price| *price != TEST_FEED_PRICE), TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1214, location = aave_oracle::oracle)]
    fun test_oracle_remove_single_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // now set the chainlink feed for a given token
        let test_token_address = TEST_ASSET;
        oracle::set_asset_feed_id(oracle_admin, test_token_address, TEST_FEED_ID);

        // assert the set price
        assert!(
            oracle::get_asset_price(test_token_address) == TEST_FEED_PRICE,
            TEST_SUCCESS
        );

        // remove the feed for dai
        oracle::remove_asset_feed_id(oracle_admin, test_token_address);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedRemoved>();
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // try to query the price again
        oracle::get_asset_price(test_token_address);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1214, location = aave_oracle::oracle)]
    fun test_oracle_remove_batch_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feed ids which chainlink does not support
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // remove assets as a batch
        oracle::batch_remove_asset_feed_ids(oracle_admin, asset_addresses);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedRemoved>();
        assert!(
            vector::length(&emitted_events) == vector::length(&asset_addresses),
            TEST_SUCCESS
        );

        // try to get prices - this would fail as a batch
        oracle::get_assets_prices(asset_addresses);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_remove_one_in_batch_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feed ids which chainlink does not support
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(oracle_admin, asset_addresses, asset_feed_ids);

        // remove assets as a batch
        let end = vector::length(&asset_addresses);
        let truncated = vector::slice(&mut asset_addresses, 1, end);
        oracle::batch_remove_asset_feed_ids(oracle_admin, truncated);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedRemoved>();
        assert!(
            vector::length(&emitted_events) == vector::length(&truncated), TEST_SUCCESS
        );

        // try to get price for the unremoved asset, should work
        assert!(oracle::get_asset_price(@0x0) == TEST_FEED_PRICE, TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_mock_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // test data
        let (asset_1, price_1, feed_id_1) = (@0x1, 100, vector<u8>[1]);
        let (asset_2, price_2, feed_id_2) = (@0x2, 200, vector<u8>[2]);
        let (asset_3, price_3, feed_id_3) = (@0x3, 300, vector<u8>[3]);

        // set mocked prices for some assets on the CL oracle
        oracle::set_chainlink_mock_feed(oracle_admin, asset_1, feed_id_1);
        oracle::set_chainlink_mock_price(oracle_admin, price_1, feed_id_1);

        oracle::set_chainlink_mock_feed(oracle_admin, asset_2, feed_id_2);
        oracle::set_chainlink_mock_price(oracle_admin, price_2, feed_id_2);

        oracle::set_chainlink_mock_feed(oracle_admin, asset_3, feed_id_3);
        oracle::set_chainlink_mock_price(oracle_admin, price_3, feed_id_3);

        // now set the feed ids on the oracle
        oracle::set_asset_feed_id(oracle_admin, asset_1, feed_id_1);
        oracle::set_asset_feed_id(oracle_admin, asset_2, feed_id_2);
        oracle::set_asset_feed_id(oracle_admin, asset_3, feed_id_3);

        // assert asset prices
        assert!(oracle::get_asset_price(asset_1) == price_1, TEST_SUCCESS);
        assert!(oracle::get_asset_price(asset_2) == price_2, TEST_SUCCESS);
        assert!(oracle::get_asset_price(asset_3) == price_3, TEST_SUCCESS);
    }

    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1201, location = aave_oracle::oracle)]
    fun test_init_oracle_when_non_oracle_admin(user1: &signer) {
        // init aave oracle
        oracle::test_init_oracle(user1);
    }

    #[test(super_admin = @aave_acl, user1 = @0x41)]
    #[expected_failure(abort_code = 1207, location = aave_oracle::oracle)]
    fun test_only_risk_or_pool_admin_when_non_risk_or_pool_admin(
        super_admin: &signer, user1: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(super_admin);
        oracle::test_only_risk_or_pool_admin(user1);
    }

    #[test(aave_oracle = @aave_oracle)]
    #[expected_failure(abort_code = 1203, location = aave_oracle::oracle)]
    fun test_assert_asset_feed_id_exists_when_feed_id_not_exist(
        aave_oracle: &signer
    ) {
        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // set asset feed id
        oracle::test_set_asset_feed_id(TEST_ASSET, TEST_FEED_ID);
        // get asset feed id
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // test assert asset feed id exists
        let asset_feed_id = oracle::test_assert_asset_feed_id_exists(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // remove asset feed id
        oracle::test_remove_feed_id(TEST_ASSET, TEST_FEED_ID);
        oracle::test_assert_asset_feed_id_exists(TEST_ASSET);
    }

    #[test]
    #[expected_failure(abort_code = 1204, location = aave_oracle::oracle)]
    fun test_assert_benchmarks_match_assets_expected_failure() {
        oracle::test_assert_benchmarks_match_assets(1, 2);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_basic_ops(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // only oracle admin can call this function
        oracle::test_only_oracle_admin(aave_oracle);
        oracle::test_only_risk_or_pool_admin(oracle_admin);
        let oracle_address = oracle::oracle_address();

        // test resource account signer
        let resource_account_signer = oracle::get_resource_account_signer_for_testing();
        assert!(
            signer::address_of(&resource_account_signer) == oracle_address,
            TEST_SUCCESS
        );

        // set asset feed id
        oracle::test_set_asset_feed_id(TEST_ASSET, TEST_FEED_ID);
        let emitted_event = emitted_events<oracle::AssetPriceFeedUpdated>();
        assert!(vector::length(&emitted_event) == 1, TEST_SUCCESS);

        // get asset feed id
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // test assert asset feed id exists
        let asset_feed_id = oracle::test_assert_asset_feed_id_exists(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // remove asset feed id
        oracle::test_remove_feed_id(TEST_ASSET, TEST_FEED_ID);
        let emitted_event = emitted_events<oracle::AssetPriceFeedRemoved>();
        assert!(vector::length(&emitted_event) == 1, TEST_SUCCESS);

        // test assert benchmarks match assets
        oracle::test_assert_benchmarks_match_assets(1, 1);
        oracle::test_assert_benchmarks_match_assets(10, 10);
        oracle::test_assert_benchmarks_match_assets(500, 500);
    }

    #[test(aave_oracle = @aave_oracle)]
    #[expected_failure(abort_code = 1211, location = aave_oracle::oracle)]
    fun test_set_custom_price_and_remove(aave_oracle: &signer) {
        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // set asset custom price
        oracle::test_set_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);

        // get asset custom price
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // test assert asset custom price exists
        let asset_custom_price =
            oracle::test_assert_asset_custom_price_exists(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // remove asset custom price
        oracle::test_remove_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);
        oracle::test_assert_asset_custom_price_exists(TEST_ASSET);
    }

    #[test(aave_oracle = @aave_oracle)]
    #[expected_failure(abort_code = 1214, location = aave_oracle::oracle)]
    fun test_set_custom_price_and_feed_id_then_remove_both(
        aave_oracle: &signer
    ) {
        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // set asset custom price
        oracle::test_set_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);

        // get asset custom price
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // test assert asset custom price exists
        let asset_custom_price =
            oracle::test_assert_asset_custom_price_exists(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // remove asset custom price
        oracle::test_remove_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);

        // now try to set feed id
        oracle::test_set_asset_feed_id(TEST_ASSET, TEST_FEED_ID);

        // get asset feed id
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // test assert asset feed id exists
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // remove feed id
        oracle::test_remove_feed_id(TEST_ASSET, TEST_FEED_ID);

        // now try to get the price
        let _ = oracle::get_asset_price(TEST_ASSET);
    }

    #[test(aave_oracle = @aave_oracle, std = @aptos_framework)]
    fun test_set_custom_price_succeeds_even_when_feed_id_exists(
        aave_oracle: &signer, std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(std);

        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // set asset feed id
        oracle::test_set_asset_feed_id(TEST_ASSET, TEST_FEED_ID);

        // get asset feed id
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // test assert asset feed id exists
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // try to set asset custom price now
        oracle::test_set_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);

        // get asset custom price
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // test assert asset custom price exists
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // try to get price - priority is given to the custom one, so the custom should be returned first
        assert!(
            oracle::get_asset_price(TEST_ASSET) == TEST_ASSET_CUSTOM_PRICE,
            TEST_SUCCESS
        );
    }

    #[test(aave_oracle = @aave_oracle, std = @aptos_framework)]
    fun test_set_feed_id_succeeds_even_when_custom_price_exists(
        aave_oracle: &signer, std: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(std);

        // init aave oracle
        oracle::test_init_oracle(aave_oracle);

        // set asset custom price
        oracle::test_set_asset_custom_price(TEST_ASSET, TEST_ASSET_CUSTOM_PRICE);

        // get asset custom price
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // test assert asset custom price exists
        let asset_custom_price = oracle::test_get_asset_custom_price(TEST_ASSET);
        assert!(asset_custom_price == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);

        // try to set feed id
        oracle::test_set_asset_feed_id(TEST_ASSET, TEST_FEED_ID);

        // get asset feed id
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // test assert asset feed id exists
        let asset_feed_id = oracle::test_get_feed_id(TEST_ASSET);
        assert!(asset_feed_id == TEST_FEED_ID, TEST_SUCCESS);

        // try to get price - priority is given to the custom one, so the custom should be returned first
        assert!(
            oracle::get_asset_price(TEST_ASSET) == TEST_ASSET_CUSTOM_PRICE,
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_batch_custom_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feedids
        let asset_addresses = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_custom_prices = vector[
            TEST_ASSET_CUSTOM_PRICE,
            TEST_ASSET_CUSTOM_PRICE + 1,
            TEST_ASSET_CUSTOM_PRICE + 2,
            TEST_ASSET_CUSTOM_PRICE + 3
        ];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_custom_prices(
            oracle_admin, asset_addresses, asset_custom_prices
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetCustomPriceUpdated>();
        assert!(
            vector::length(&emitted_events) == vector::length(&asset_addresses),
            TEST_SUCCESS
        );

        // get prices and ensure they are all > 0 since mocked
        let prices = oracle::get_assets_prices(asset_addresses);
        assert!(*vector::borrow(&prices, 0) == TEST_ASSET_CUSTOM_PRICE, TEST_SUCCESS);
        assert!(
            *vector::borrow(&prices, 1) == TEST_ASSET_CUSTOM_PRICE + 1,
            TEST_SUCCESS
        );
        assert!(
            *vector::borrow(&prices, 2) == TEST_ASSET_CUSTOM_PRICE + 2,
            TEST_SUCCESS
        );
        assert!(
            *vector::borrow(&prices, 3) == TEST_ASSET_CUSTOM_PRICE + 3,
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_remove_mixed_batched_prices(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define assets and feed ids which chainlink does not support
        let asset_addresses_with_feed_ids = vector[@0x0, @0x1, @0x2, @0x3];
        let asset_feed_ids = vector[TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID, TEST_FEED_ID];

        // set in batch mode assets and feed ids
        oracle::batch_set_asset_feed_ids(
            oracle_admin, asset_addresses_with_feed_ids, asset_feed_ids
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedUpdated>();
        assert!(
            vector::length(&emitted_events)
                == vector::length(&asset_addresses_with_feed_ids),
            TEST_SUCCESS
        );

        let asset_addresses_with_custom_prices = vector[@0x4, @0x5, @0x6];
        let asset_custom_prices = vector[
            TEST_ASSET_CUSTOM_PRICE,
            TEST_ASSET_CUSTOM_PRICE + 1,
            TEST_ASSET_CUSTOM_PRICE + 2
        ];

        // set in batch mode assets with custom prices
        oracle::batch_set_asset_custom_prices(
            oracle_admin, asset_addresses_with_custom_prices, asset_custom_prices
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetCustomPriceUpdated>();
        assert!(
            vector::length(&emitted_events)
                == vector::length(&asset_addresses_with_custom_prices),
            TEST_SUCCESS
        );

        // remove assets as a batch
        oracle::batch_remove_asset_feed_ids(oracle_admin, asset_addresses_with_feed_ids);

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetPriceFeedRemoved>();
        assert!(
            vector::length(&emitted_events)
                == vector::length(&asset_addresses_with_feed_ids),
            TEST_SUCCESS
        );

        oracle::batch_remove_asset_custom_prices(
            oracle_admin, asset_addresses_with_custom_prices
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::AssetCustomPriceRemoved>();
        assert!(
            vector::length(&emitted_events)
                == vector::length(&asset_addresses_with_custom_prices),
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_stable_price_cap_adapter_when_price_cap_higher_than_base_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = TEST_FEED_PRICE * 2;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::PriceCapUpdated>();
        assert!(
            vector::length(&emitted_events) == 1,
            TEST_SUCCESS
        );

        // the asset price cap must be retrievable
        assert!(
            *option::borrow(&oracle::get_stable_price_cap(asset_address))
                == asset_capped_price,
            TEST_SUCCESS
        );

        // asset is not capped at this point
        assert!(!oracle::is_asset_price_capped(asset_address), TEST_SUCCESS);

        // check the asset price
        assert!(
            oracle::get_asset_price(asset_address) == TEST_FEED_PRICE,
            TEST_SUCCESS
        );

        // remove the cap
        oracle::remove_price_cap_stable_adapter(oracle_admin, asset_address);

        // check for specific events
        let emitted_events = emitted_events<oracle::PriceCapRemoved>();
        assert!(
            vector::length(&emitted_events) == 1,
            TEST_SUCCESS
        );

        // check the asset price - must be the CL price
        assert!(
            oracle::get_asset_price(asset_address) == TEST_FEED_PRICE,
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_set_stable_price_cap_adapter_success(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = 2 * TEST_FEED_PRICE;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap (that succeeds because the cap is 2 * price asset)
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::PriceCapUpdated>();
        assert!(
            vector::length(&emitted_events) == 1,
            TEST_SUCCESS
        );

        // the asset price cap must be retrievable
        assert!(
            *option::borrow(&oracle::get_stable_price_cap(asset_address))
                == asset_capped_price,
            TEST_SUCCESS
        );

        // now simulate an increase of the price higher than the cap, i.e. price must be capped
        let current_time = timestamp::now_seconds();
        let fresh_timestamp = (current_time * 1000) as u256;
        let new_increased_price = asset_capped_price + 1;
        registry::perform_update_for_test(
            TEST_FEED_ID,
            fresh_timestamp,
            new_increased_price,
            vector::empty<u8>()
        );

        // asset is capped at this point
        assert!(oracle::is_asset_price_capped(asset_address), TEST_SUCCESS);

        // check the asset price
        assert!(
            oracle::get_asset_price(asset_address) == asset_capped_price,
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1229, location = aave_oracle::oracle)]
    fun test_oracle_stable_price_cap_adapter_when_custom_price_higher_than_price_cap(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = 2 * TEST_FEED_PRICE;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap (that succeeds because the cap is 2 * price asset)
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::PriceCapUpdated>();
        assert!(
            vector::length(&emitted_events) == 1,
            TEST_SUCCESS
        );

        // the asset price cap must be retrievable
        assert!(
            *option::borrow(&oracle::get_stable_price_cap(asset_address))
                == asset_capped_price,
            TEST_SUCCESS
        );

        // now simulate an increase of the price higher than the cap, i.e. price must be capped
        let current_time = timestamp::now_seconds();
        let fresh_timestamp = (current_time * 1000) as u256;
        let new_increased_price = asset_capped_price + 1;
        registry::perform_update_for_test(
            TEST_FEED_ID,
            fresh_timestamp,
            new_increased_price,
            vector::empty<u8>()
        );

        // asset is capped at this point
        assert!(oracle::is_asset_price_capped(asset_address), TEST_SUCCESS);

        // check the asset price
        assert!(
            oracle::get_asset_price(asset_address) == asset_capped_price,
            TEST_SUCCESS
        );

        // try and set a custom price higher than the price cap
        let new_custom_price = asset_capped_price + 1;
        oracle::set_asset_custom_price(oracle_admin, asset_address, new_custom_price);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_stable_price_cap_adapter_when_custom_price_lower_than_price_cap(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = 2 * TEST_FEED_PRICE;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap (that succeeds because the cap is 2 * price asset)
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );

        // check for specific events
        let emitted_events = emitted_events<oracle::PriceCapUpdated>();
        assert!(
            vector::length(&emitted_events) == 1,
            TEST_SUCCESS
        );

        // the asset price cap must be retrievable
        assert!(
            *option::borrow(&oracle::get_stable_price_cap(asset_address))
                == asset_capped_price,
            TEST_SUCCESS
        );

        // now simulate an increase of the price higher than the cap, i.e. price must be capped
        let current_time = timestamp::now_seconds();
        let fresh_timestamp = (current_time * 1000) as u256;
        let new_increased_price = asset_capped_price + 1;
        registry::perform_update_for_test(
            TEST_FEED_ID,
            fresh_timestamp,
            new_increased_price,
            vector::empty<u8>()
        );

        // asset is capped at this point
        assert!(oracle::is_asset_price_capped(asset_address), TEST_SUCCESS);

        // check the asset price
        assert!(
            oracle::get_asset_price(asset_address) == asset_capped_price,
            TEST_SUCCESS
        );

        // try and set a custom price lower than the price cap
        let new_custom_price = asset_capped_price - 1;
        oracle::set_asset_custom_price(oracle_admin, asset_address, new_custom_price);

        // check the asset price - must be the new custom price
        assert!(
            oracle::get_asset_price(asset_address) == new_custom_price,
            TEST_SUCCESS
        );

        // asset is no longer capped at this point
        assert!(!oracle::is_asset_price_capped(asset_address), TEST_SUCCESS);
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1215, location = aave_oracle::oracle)]
    fun test_oracle_stable_price_cap_adaptor_when_price_cap_lower_than_base_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = TEST_FEED_PRICE / 2;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 4, location = aave_oracle::oracle)]
    fun test_oracle_stable_price_cap_adaptor_when_non_risk_or_pool_admin(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = TEST_FEED_PRICE / 2;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap
        oracle::set_price_cap_stable_adapter(
            aave_oracle,
            asset_address,
            asset_capped_price
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    fun test_oracle_stable_price_cap_adaptor_with_custom_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos);

        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        assert!(
            acl_manage::is_pool_admin(signer::address_of(oracle_admin)), TEST_SUCCESS
        );
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(oracle_admin)),
            TEST_SUCCESS
        );

        // init aave oracle
        config_oracle(aave_oracle, data_feeds, platform);

        // define asset and price cap
        let asset_address = @0x0;
        let asset_capped_price = TEST_FEED_PRICE * 2;

        // first set the CL feed for the asset
        oracle::set_asset_feed_id(oracle_admin, asset_address, TEST_FEED_ID);

        // set asset price cap
        oracle::set_price_cap_stable_adapter(
            oracle_admin,
            asset_address,
            asset_capped_price
        );

        // check the asset price
        assert!(
            oracle::get_asset_price(asset_address) == TEST_FEED_PRICE,
            TEST_SUCCESS
        );

        // now set custom price for the asset
        oracle::test_set_asset_custom_price(asset_address, TEST_ASSET_CUSTOM_PRICE);

        // check the asset price (cap is way higher than the custom price)
        assert!(
            oracle::get_asset_price(asset_address) == TEST_ASSET_CUSTOM_PRICE,
            TEST_SUCCESS
        );
    }

    #[
        test(
            super_admin = @aave_acl,
            oracle_admin = @0x06,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos = @aptos_framework
        )
    ]
    #[expected_failure(abort_code = 1217, location = aave_oracle::oracle)]
    fun test_stale_price(
        super_admin: &signer,
        oracle_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos: &signer
    ) {
        use aptos_framework::timestamp;

        // start the timer at a known time
        timestamp::set_time_has_started_for_testing(aptos);

        // initialize ACL module and add admin roles
        acl_manage::test_init_module(super_admin);
        acl_manage::add_pool_admin(super_admin, signer::address_of(oracle_admin));
        acl_manage::add_asset_listing_admin(
            super_admin, signer::address_of(oracle_admin)
        );

        // initialize oracle and chainlink
        oracle::test_init_module(aave_oracle);
        set_up_chainlink_oracle(data_feeds, platform);

        // set up test asset
        let test_asset = TEST_ASSET;
        let test_feed_id = TEST_FEED_ID;
        let test_price = 50000000000000000000000u256; // $50,000 in 18 decimals

        // create a feed in the registry
        let config_id = vector[1];
        registry::set_feed_for_test(test_feed_id, utf8(b"Stale Test Feed"), config_id);

        // set a price with CURRENT timestamp (fresh price)
        let current_time = timestamp::now_seconds();
        let fresh_timestamp = (current_time * 1000) as u256;

        registry::perform_update_for_test(
            test_feed_id,
            fresh_timestamp,
            test_price,
            vector::empty<u8>()
        );

        // set the feed ID for our test asset
        oracle::set_asset_feed_id(oracle_admin, test_asset, test_feed_id);

        // verify fresh price works (this should pass)
        let fetched_price = oracle::get_asset_price(test_asset);
        assert!(fetched_price == test_price, 1);

        // fast-forward time by 2 hours (7200 seconds)
        timestamp::fast_forward_seconds(7200);

        // update the registry with STALE price (old timestamp)
        registry::perform_update_for_test(
            test_feed_id,
            fresh_timestamp, // SAME old timestamp (2 hours stale)
            test_price * 2, //different price to prove it's reading stale data
            vector::empty<u8>()
        );

        // try to fetch price - this should FAIL for being stale
        let _ = oracle::get_asset_price(test_asset);
    }
}
