#[test_only]
module aave_pool::ui_pool_data_provider_v3_tests {
    use std::signer;
    use std::string::utf8;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aave_oracle::oracle;
    use aave_oracle::oracle_tests;
    use aave_pool::pool_configurator;
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;
    use aave_pool::token_helper;
    use aave_pool::pool;
    use aave_pool::emode_logic;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::a_token_factory;
    use aave_pool::ui_pool_data_provider_v3;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_pool::pool_fee_manager;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    const APT_CURRENCY_UNIT: u256 = 100000000;

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            underlying_tokens = @aave_mock_underlyings,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aave_std = @std
        )
    ]
    fun test_get_user_reserves_data(
        aave_pool: &signer,
        aave_acl: &signer,
        underlying_tokens: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aave_std: &signer
    ) {
        // set time
        timestamp::set_time_has_started_for_testing(aave_std);

        let aave_pool_address = signer::address_of(aave_pool);
        account::create_account_for_test(aave_pool_address);

        // init reserves with oracle
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_acl,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens,
            aave_pool
        );

        // case1: no borrow and no emode
        let (_vector_aggregated_reserve_data, user_emode_category) =
            ui_pool_data_provider_v3::get_user_reserves_data(aave_pool_address);

        assert!(user_emode_category == 0, TEST_SUCCESS);

        // case2: have borrow and emode
        let u1_underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 1000 u1 underlying tokens to the aave_pool
        let mint_amount = 1000;
        mock_underlying_token_factory::mint(
            underlying_tokens,
            aave_pool_address,
            mint_amount,
            u1_underlying_token_address
        );

        let aave_pool_balance =
            mock_underlying_token_factory::balance_of(
                aave_pool_address, u1_underlying_token_address
            );
        assert!(aave_pool_balance == mint_amount, TEST_SUCCESS);

        // supply 1000 u1 underlying tokens to the aave_pool
        let supply_amount = 1000;
        supply_logic::supply(
            aave_pool,
            u1_underlying_token_address,
            supply_amount,
            aave_pool_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            aave_pool, u1_underlying_token_address, true
        );

        let aave_pool_balance =
            mock_underlying_token_factory::balance_of(
                aave_pool_address, u1_underlying_token_address
            );
        assert!(
            aave_pool_balance == mint_amount - (supply_amount as u64),
            TEST_SUCCESS
        );

        // set asset feed id for u1 underlying token
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(u1_underlying_token_address, test_feed_id);

        // create the emode
        let emode_category_id = 1;
        let emode_ltv = 8500;
        let emode_threshold = 9000;
        let emode_bonus = 10500;
        let emode_label = utf8(b"EMODE_LABEL");

        pool_configurator::set_emode_category(
            aave_pool,
            emode_category_id,
            (emode_ltv as u16),
            (emode_threshold as u16),
            (emode_bonus as u16),
            emode_label
        );

        // set u1 underlying token emode category
        pool_configurator::set_asset_emode_category(
            aave_pool, u1_underlying_token_address, emode_category_id
        );

        // set user emode for aave_pool
        emode_logic::set_user_emode(aave_pool, emode_category_id);
        assert!(
            emode_logic::get_user_emode(aave_pool_address) == emode_category_id,
            TEST_SUCCESS
        );

        // mint 1 APT to the aave_pool
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            aave_pool_address, mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(aave_pool_address) == mint_apt_amount,
            TEST_SUCCESS
        );

        // borrow 100 u1 underlying tokens from the aave_pool
        let borrow_amount = 100;
        borrow_logic::borrow(
            aave_pool,
            u1_underlying_token_address,
            borrow_amount,
            2,
            0,
            aave_pool_address
        );

        assert!(
            coin::balance<AptosCoin>(aave_pool_address)
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(u1_underlying_token_address),
            TEST_SUCCESS
        );

        let aave_pool_balance =
            mock_underlying_token_factory::balance_of(
                aave_pool_address, u1_underlying_token_address
            );
        assert!((aave_pool_balance as u256) == borrow_amount, TEST_SUCCESS);

        let (_vector_aggregated_reserve_data, user_emode_category) =
            ui_pool_data_provider_v3::get_user_reserves_data(aave_pool_address);

        assert!(
            user_emode_category == emode_category_id,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            underlying_tokens = @aave_mock_underlyings,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aave_std = @std
        )
    ]
    fun test_get_reserves_data(
        aave_pool: &signer,
        aave_acl: &signer,
        underlying_tokens: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aave_std: &signer
    ) {
        set_time_has_started_for_testing(aave_std);

        account::create_account_for_test(signer::address_of(aave_pool));

        // init reserves with oracle
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_acl,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens,
            aave_pool
        );

        // get the undelryings
        let u0_underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        let u1_underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let u2_underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let u3_underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_3"));

        // set asset feed id
        let test_feed_id = oracle_tests::get_test_feed_id();
        oracle::test_set_asset_feed_id(u0_underlying_token_address, test_feed_id);
        oracle::test_set_asset_feed_id(u1_underlying_token_address, test_feed_id);
        oracle::test_set_asset_feed_id(u2_underlying_token_address, test_feed_id);
        oracle::test_set_asset_feed_id(u3_underlying_token_address, test_feed_id);

        let (_aggregated_reserve_datas, _base_currency_info) =
            ui_pool_data_provider_v3::get_reserves_data();

        let reserve_data = pool::get_reserve_data(u0_underlying_token_address);
        let u0_a_token_address = pool::get_reserve_a_token_address(reserve_data);
        // mint 1000 u0 underlying tokens to the pool
        mock_underlying_token_factory::mint(
            underlying_tokens,
            a_token_factory::get_token_account_address(u0_a_token_address),
            1000,
            u0_underlying_token_address
        );

        let (_aggregated_reserve_datas, _base_currency_info) =
            ui_pool_data_provider_v3::get_reserves_data();
    }
}
