#[test_only]
module aave_pool::emode_logic_tests {
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_pool::pool_data_provider;
    use aave_pool::token_helper;
    use aave_pool::emode_logic::{
        configure_emode_category,
        get_emode_category_data,
        get_emode_category_liquidation_bonus,
        get_emode_category_liquidation_threshold,
        get_emode_configuration,
        get_user_emode,
        init_emode,
        is_in_emode_category,
        set_user_emode,
        UserEModeSet,
        get_emode_e_mode_liquidation_bonus,
        get_emode_e_mode_label,
        get_emode_category_ltv,
        get_emode_category_label
    };
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;
    use aave_pool::token_helper::{init_reserves_with_oracle, convert_to_currency_decimals};
    use aave_pool::pool::{get_reserve_data, get_reserve_id};
    use aave_pool::pool_configurator;
    use aave_pool::pool_tests::create_user_config_for_reserve;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(pool = @aave_pool)]
    fun get_nonexisting_emode_category(pool: &signer) {
        // init the emode
        init_emode(pool);

        // get an non-existing emode category
        let id: u8 = 3;
        let (ltv, liquidation_threshold) = get_emode_configuration(id);
        assert!(ltv == 0, TEST_SUCCESS);
        assert!(liquidation_threshold == 0, TEST_SUCCESS);
    }

    #[test(aave_pool = @aave_pool)]
    fun test_emode_config(aave_pool: &signer) {
        // init the emode
        init_emode(aave_pool);

        // configure and assert two emode categories
        let id1: u8 = 1;
        let ltv1: u16 = 100;
        let liquidation_threshold1: u16 = 200;
        let liquidation_bonus1: u16 = 300;
        let label1 = utf8(b"MODE1");
        configure_emode_category(
            id1,
            ltv1,
            liquidation_threshold1,
            liquidation_bonus1,
            label1
        );
        let emode_data1 = get_emode_category_data(id1);
        assert!(
            get_emode_category_liquidation_bonus(&emode_data1) == liquidation_bonus1,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_liquidation_threshold(&emode_data1)
                == liquidation_threshold1,
            TEST_SUCCESS
        );
        let (ltv, liquidation_threshold) = get_emode_configuration(id1);
        assert!(ltv == (ltv1 as u256), TEST_SUCCESS);
        assert!(liquidation_threshold == (liquidation_threshold1 as u256), TEST_SUCCESS);

        let id2: u8 = 2;
        let ltv2: u16 = 101;
        let liquidation_threshold2: u16 = 201;
        let liquidation_bonus2: u16 = 301;
        let label2 = utf8(b"MODE2");
        configure_emode_category(
            id2,
            ltv2,
            liquidation_threshold2,
            liquidation_bonus2,
            label2
        );
        let emode_data2 = get_emode_category_data(id2);
        assert!(
            get_emode_category_liquidation_bonus(&emode_data2) == liquidation_bonus2,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_liquidation_threshold(&emode_data2)
                == liquidation_threshold2,
            TEST_SUCCESS
        );
        let (ltv, liquidation_threshold) = get_emode_configuration(id2);
        assert!(ltv == (ltv2 as u256), TEST_SUCCESS);
        assert!(liquidation_threshold == (liquidation_threshold2 as u256), TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user = @0x042
        )
    ]
    fun test_legitimate_user_emode(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 8800;
        let liquidation_threshold: u16 = 9000;
        let liquidation_bonus: u16 = 10100;
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // get the reserve config
        let underlying_asset_addr =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_asset_addr,
            100
        );

        let reserve_data = get_reserve_data(underlying_asset_addr);
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_asset_addr, emode_cat_id
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(user),
            (get_reserve_id(reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set user emode
        set_user_emode(user, emode_cat_id);

        // get and assert user emode
        let user_emode = get_user_emode(signer::address_of(user));
        assert!(user_emode == emode_cat_id, TEST_SUCCESS);
        assert!(is_in_emode_category(user_emode, emode_cat_id), TEST_SUCCESS);
        assert!(!is_in_emode_category(user_emode, emode_cat_id + 1), TEST_SUCCESS);

        // check emitted events
        let emitted_events = emitted_events<UserEModeSet>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    // Admin adds a category for stablecoins with U_1
    fun test_set_emode_category_for_reserve(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // init reserves
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let new_category_id = 1;
        let ltv = 8800;
        let liquidation_threshold = 9800;
        let liquidation_bonus = 10100;
        let label = utf8(b"MODE1");
        assert!(get_emode_e_mode_liquidation_bonus(new_category_id) == 0, TEST_SUCCESS);
        assert!(get_emode_e_mode_label(new_category_id) == utf8(b""), TEST_SUCCESS);

        pool_configurator::set_emode_category(
            aave_pool,
            new_category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        pool_configurator::set_asset_emode_category(
            aave_pool,
            underlying_u1_token_address,
            new_category_id
        );

        let emode_category_id =
            pool_data_provider::get_reserve_emode_category(underlying_u1_token_address);

        assert!(emode_category_id == (new_category_id as u256), TEST_SUCCESS);

        let emode_category = get_emode_category_data(new_category_id);
        assert!(get_emode_category_ltv(&emode_category) == ltv, TEST_SUCCESS);
        assert!(
            get_emode_category_liquidation_threshold(&emode_category)
                == liquidation_threshold,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_liquidation_bonus(&emode_category) == liquidation_bonus,
            TEST_SUCCESS
        );
        assert!(
            get_emode_e_mode_liquidation_bonus(new_category_id) == liquidation_bonus,
            TEST_SUCCESS
        );
        assert!(
            get_emode_category_label(&emode_category) == label,
            TEST_SUCCESS
        );
        assert!(get_emode_e_mode_label(new_category_id) == label, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user = @0x042
        )
    ]
    fun test_set_user_emode_with_multiple_settings(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 8800;
        let liquidation_threshold: u16 = 9000;
        let liquidation_bonus: u16 = 10100;
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // get the reserve config
        let underlying_asset_addr =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_asset_addr,
            100
        );

        let reserve_data = get_reserve_data(underlying_asset_addr);
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_asset_addr, emode_cat_id
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(user),
            (get_reserve_id(reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set user emode
        set_user_emode(user, emode_cat_id);

        // get and assert user emode
        let user_emode = get_user_emode(signer::address_of(user));
        assert!(user_emode == emode_cat_id, TEST_SUCCESS);
        assert!(is_in_emode_category(user_emode, emode_cat_id), TEST_SUCCESS);
        assert!(!is_in_emode_category(user_emode, emode_cat_id + 1), TEST_SUCCESS);

        // check emitted events
        let emitted_events = emitted_events<UserEModeSet>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // set user emode again
        set_user_emode(user, emode_cat_id);
        // get and assert user emode
        let user_emode = get_user_emode(signer::address_of(user));
        assert!(user_emode == emode_cat_id, TEST_SUCCESS);
        assert!(is_in_emode_category(user_emode, emode_cat_id), TEST_SUCCESS);
        assert!(!is_in_emode_category(user_emode, emode_cat_id + 1), TEST_SUCCESS);

        // check emitted events
        let emitted_events = emitted_events<UserEModeSet>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
    }

    // =================== Test Expected Failure ===================
    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::emode_logic)]
    fun test_init_emode_with_not_pool_owner(user1: &signer) {
        init_emode(user1);
    }

    #[test(pool = @aave_pool)]
    #[expected_failure(abort_code = 16, location = aave_pool::emode_logic)]
    fun zero_emode_id_failure(pool: &signer) {
        // init the emode
        init_emode(pool);

        // configure an illegal emode category
        let id: u8 = 0;
        let ltv: u16 = 100;
        let liquidation_threshold: u16 = 200;
        let liquidation_bonus: u16 = 300;
        let label = utf8(b"MODE1");
        configure_emode_category(
            id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user = @0x042
        )
    ]
    #[expected_failure(abort_code = 58, location = aave_pool::validation_logic)]
    fun test_user_emode_with_non_existing_user_emode(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 8900;
        let liquidation_threshold: u16 = 9200;
        let liquidation_bonus: u16 = 10200;
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // get the reserve config
        let underlying_asset_addr =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = get_reserve_data(underlying_asset_addr);
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_asset_addr, emode_cat_id
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(user),
            (get_reserve_id(reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set user emode
        let non_existing_emode_id = emode_cat_id + 1;
        set_user_emode(user, non_existing_emode_id);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user0 = @0x41,
            user1 = @0x42,
            user2 = @0x43
        )
    ]
    // User 0 mint 1000 U_0, 1000 U_1, 1000 U_2
    // User 1 mint 1000 U_1, 1000 U_2
    // User 2 mint 1000 U_0
    // Admin adds a category for U_0 and U_1
    // Admin adds a category for U_2
    // User 0 activates eMode for category
    // User 0 supplies 100 U_0, user 1 supplies 100 U_2
    // User 0 borrows 98 U_1
    // User 0 tries to activate eMode for other category (revert expected)
    #[expected_failure(abort_code = 58, location = aave_pool::validation_logic)]
    fun test_set_user_emode_when_inconsistent_emode_category(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user0: &signer,
        user1: &signer,
        user2: &signer
    ) {
        // create users
        let user0_address = signer::address_of(user0);
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );
        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // mint 1000 U_0 for user 0
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user0_address,
            (convert_to_currency_decimals(underlying_u0_token_address, 1000) as u64),
            underlying_u0_token_address
        );

        // mint 1000 U_1 for user 0
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user0_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // mint 1000 U_2 for user 0
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user0_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // mint 1000 U_1 for user 1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // mint 1000 U_2 for user 1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000) as u64),
            underlying_u2_token_address
        );

        // mint 1000 U_0 for user 2
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u0_token_address, 1000) as u64),
            underlying_u0_token_address
        );

        // Add a category for U_0 and U_1
        let new_category_id = 1;
        let ltv = 9800;
        let liquidation_threshold = 9800;
        let liquidation_bonus = 10100;
        let label = utf8(b"STABLECOINS");
        pool_configurator::set_emode_category(
            aave_pool,
            new_category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        pool_configurator::set_asset_emode_category(
            aave_pool,
            underlying_u0_token_address,
            new_category_id
        );

        pool_configurator::set_asset_emode_category(
            aave_pool,
            underlying_u1_token_address,
            new_category_id
        );

        // User 0 activates eMode for category
        set_user_emode(user0, new_category_id);

        // Add a category for U_2
        let new_category_id_2 = 2;
        let ltv_2 = 9800;
        let liquidation_threshold_2 = 9800;
        let liquidation_bonus_2 = 10100;
        let label_2 = utf8(b"STABLECOINS");
        pool_configurator::set_emode_category(
            aave_pool,
            new_category_id_2,
            ltv_2,
            liquidation_threshold_2,
            liquidation_bonus_2,
            label_2
        );

        pool_configurator::set_asset_emode_category(
            aave_pool,
            underlying_u2_token_address,
            new_category_id_2
        );

        // User 0 supplies 100 U_0
        supply_logic::supply(
            user0,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 100),
            user0_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user0, underlying_u0_token_address, true
        );

        // User 1 supplies 100 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            user1_address,
            0
        );

        // set asset price for U_0
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u0_token_address,
            10
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // User 0 borrows 98 U_1 and tries to deactivate eMode (revert expected)
        borrow_logic::borrow(
            user0,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 98),
            2,
            0,
            user0_address
        );

        // User 0 tries to activate eMode for other category (revert expected)
        set_user_emode(user0, new_category_id_2);
    }
}
