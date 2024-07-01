#[test_only]
module aave_oracle::oracle_tests {
    use std::signer;
    use aave_acl::acl_manage::{Self, add_pool_admin, add_asset_listing_admin};
    use std::string;
    use std::option::{Self};
    use aave_oracle::oracle::{
        set_oracle_base_currency,
        get_pyth_oracle_address,
        add_asset_vaa,
        create_base_currency,
        get_oracle_base_currency_for_testing,
        get_asset_identifier_for_testing,
        get_asset_vaa_for_testing,
        test_init_module
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(super_admin = @aave_acl, oracle_admin = @0x01, aave_oracle = @aave_oracle)]
    fun test_oracle_offchain_functionalities(
        super_admin: &signer, oracle_admin: &signer, aave_oracle: &signer
    ) {
        // init the acl module
        acl_manage::test_init_module(super_admin);

        // add the roles for the oracle admin
        add_pool_admin(super_admin, signer::address_of(oracle_admin));
        add_asset_listing_admin(super_admin, signer::address_of(oracle_admin));

        // init the oracle
        test_init_module(aave_oracle);

        // check pyth address
        assert!(get_pyth_oracle_address() == @pyth, TEST_SUCCESS);

        // check the base currency is not set at the beginning
        assert!(get_oracle_base_currency_for_testing() == option::none(), TEST_SUCCESS);

        // now set oracle base currency
        set_oracle_base_currency(oracle_admin, string::utf8(b"USD"), 1);

        // assert oracle base currency
        let expected_base_currency = create_base_currency(string::utf8(b"USD"), 1);
        assert!(get_oracle_base_currency_for_testing()
            == option::some(expected_base_currency), TEST_SUCCESS);

        // asset price feed identifier
        assert!(get_asset_identifier_for_testing(string::utf8(b"BTC"))
            == option::none<vector<u8>>(),
            TEST_SUCCESS);
        assert!(get_asset_vaa_for_testing(string::utf8(b"BTC"))
            == option::none<vector<vector<u8>>>(),
            TEST_SUCCESS);

        let vaa = vector[vector[0, 1, 2], vector[3, 4, 5]];
        add_asset_vaa(oracle_admin, string::utf8(b"BTC"), vaa);
        assert!(get_asset_vaa_for_testing(string::utf8(b"BTC"))
            == option::some<vector<vector<u8>>>(vaa),
            TEST_SUCCESS);
    }
}
