#[test_only]
module aave_pool::fungible_asset_manager_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::signer;
    use std::string::utf8;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_pool::fungible_asset_manager;
    use aave_mock_underlyings::mock_underlying_token_factory;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_fungible_asset_manager_and_data_check(
        aave_pool: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // create underlying tokens
        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 3;
        let max_supply = 10000;
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
        fungible_asset_manager::assert_token_exists(underlying_token_address);

        assert!(
            fungible_asset_manager::supply(underlying_token_address) == option::some(0),
            TEST_SUCCESS
        );
        assert!(
            fungible_asset_manager::maximum(underlying_token_address)
                == option::some(max_supply),
            TEST_SUCCESS
        );
        assert!(
            fungible_asset_manager::decimals(underlying_token_address) == decimals,
            TEST_SUCCESS
        );
        assert!(
            fungible_asset_manager::symbol(underlying_token_address) == symbol,
            TEST_SUCCESS
        );
        assert!(
            fungible_asset_manager::name(underlying_token_address) == name,
            TEST_SUCCESS
        );

        let aave_pool_address = signer::address_of(aave_pool);
        let mint_amount = 1000;
        // mint 1000 tokens to aave_pool
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            aave_pool_address,
            mint_amount,
            underlying_token_address
        );

        assert!(
            fungible_asset_manager::balance_of(
                aave_pool_address, underlying_token_address
            ) == mint_amount,
            TEST_SUCCESS
        );
        assert!(
            fungible_asset_manager::supply(underlying_token_address)
                == option::some((mint_amount as u128)),
            TEST_SUCCESS
        );

        // aave_pool transfer 500 tokens to underlying_tokens_admin
        let underlying_tokens_admin_address = signer::address_of(underlying_tokens_admin);
        let transfer_amount = 500;
        fungible_asset_manager::transfer(
            aave_pool,
            underlying_tokens_admin_address,
            transfer_amount,
            underlying_token_address
        );

        // check the balance
        assert!(
            fungible_asset_manager::balance_of(
                underlying_tokens_admin_address, underlying_token_address
            ) == transfer_amount,
            TEST_SUCCESS
        );

        assert!(
            fungible_asset_manager::balance_of(
                aave_pool_address, underlying_token_address
            ) == mint_amount - transfer_amount,
            TEST_SUCCESS
        );

        // check the supply
        assert!(
            fungible_asset_manager::supply(underlying_token_address)
                == option::some((mint_amount as u128)),
            TEST_SUCCESS
        );
    }

    #[test]
    #[expected_failure(abort_code = 1503, location = aave_pool::fungible_asset_manager)]
    fun test_assert_token_exists_when_token_not_exist() {
        let a_token_address = @0x11;
        fungible_asset_manager::assert_token_exists(a_token_address);
    }
}
