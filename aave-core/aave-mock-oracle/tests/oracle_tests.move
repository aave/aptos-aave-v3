#[test_only]
module aave_mock_oracle::oracle_tests {
    use std::signer;
    use aave_mock_oracle::oracle::{
        test_init_oracle,
        get_asset_price,
        set_asset_price,
        update_asset_price,
        remove_asset_price
    };
    use aave_acl::acl_manage::{test_init_module, add_pool_admin, add_asset_listing_admin};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_mock_oracle = @aave_mock_oracle)]
    fun test_mock_oracle_functionalities(
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

        // update the oracle price
        update_asset_price(aave_mock_oracle, dai_token_address, 90);

        // assert the updated asset price
        assert!(get_asset_price(dai_token_address) == 90, TEST_SUCCESS);

        // remove the asset price
        remove_asset_price(aave_mock_oracle, dai_token_address);

        // check the asset price which should now be 0
        assert!(get_asset_price(dai_token_address) == 0, TEST_SUCCESS);
    }
}
