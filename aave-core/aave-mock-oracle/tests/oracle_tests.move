#[test_only]
module aave_mock_oracle::oracle_tests {
    use std::signer;
    use std::vector;
    use aave_mock_oracle::oracle::{
        test_init_oracle,
        get_asset_price,
        set_asset_price,
        update_asset_price,
        remove_asset_price,
        batch_set_asset_price,
        create_reward_oracle,
        decimals,
        latest_answer,
        latest_timestamp,
        latest_round,
        get_answer,
        get_timestamp,
        base_currency_unit,
    };
    use aave_acl::acl_manage::{test_init_module, add_pool_admin, add_asset_listing_admin};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_get_set_prices(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        // init the acl module
        test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle
        test_init_oracle(aave_mock_oracle);

        // check assets which are not added return price of 0
        let undeclared_asset = @0x0;
        assert!(get_asset_price(undeclared_asset) == 0, TEST_SUCCESS);

        // now set a price for a given token
        let dai_token_address = @0x42;
        set_asset_price(aave_mock_oracle, dai_token_address, 150);

        // assert the set price
        assert!(get_asset_price(dai_token_address) == 150, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_batch_set_prices(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        // init the acl module
        test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle
        test_init_oracle(aave_mock_oracle);

        // check assets which are not added return price of 0
        let undeclared_asset = @0x0;
        assert!(get_asset_price(undeclared_asset) == 0, TEST_SUCCESS);

        // now set a price for a given token
        let dai_token_address = @0x42;
        let token_addres_43 = @0x43;

        let tokens = vector::empty<address>();
        vector::push_back(&mut tokens, dai_token_address);
        vector::push_back(&mut tokens, token_addres_43);

        let prices = vector::empty<u256>();
        vector::push_back(&mut prices, 150);
        vector::push_back(&mut prices, 89);

        batch_set_asset_price(aave_mock_oracle, tokens, prices);

        // assert the set price
        assert!(get_asset_price(dai_token_address) == 150, TEST_SUCCESS);
        assert!(get_asset_price(token_addres_43) == 89, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_update_prices(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        // init the acl module
        test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle
        test_init_oracle(aave_mock_oracle);

        // check assets which are not added return price of 0
        let undeclared_asset = @0x0;
        let dai_token_address = @0x42;

        assert!(get_asset_price(undeclared_asset) == 0, TEST_SUCCESS);
        set_asset_price(aave_mock_oracle, dai_token_address, 150);

        // update the oracle price
        update_asset_price(aave_mock_oracle, dai_token_address, 90);

        // assert the updated asset price
        assert!(get_asset_price(dai_token_address) == 90, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_remove_price(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        // init the acl module
        test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle
        test_init_oracle(aave_mock_oracle);

        let dai_token_address = @0x42;
        set_asset_price(aave_mock_oracle, dai_token_address, 150);

        // remove the asset price
        remove_asset_price(aave_mock_oracle, dai_token_address);

        // check the asset price which should now be 0
        assert!(get_asset_price(dai_token_address) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_decimals(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the decimals which should now be 0
        assert!(decimals(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_latest_answer(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the latest_answer which should now be 1
        assert!(latest_answer(reward_oracle) == 1, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_latest_timestamp(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the latest_timestamp which should now be 0
        assert!(latest_timestamp(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_latest_round(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the latest_round which should now be 0
        assert!(latest_round(reward_oracle) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_get_answer(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the get_answer which should now be 0
        assert!(get_answer(reward_oracle, 1) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_get_timestamp(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the get_timestamp which should now be 0
        assert!(get_timestamp(reward_oracle, 1) == 0, TEST_SUCCESS);
    }

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_base_currency_unit(
        super_admin: &signer, oracle_admin: &signer, aave_mock_oracle: &signer
    ) {
        let reward_oracle = create_reward_oracle(1);

        // check the base_currency_unit which should now be 0
        assert!(base_currency_unit(reward_oracle, 1) == 0, TEST_SUCCESS);
    }
}
