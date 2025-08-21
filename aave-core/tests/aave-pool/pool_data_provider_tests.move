#[test_only]
module aave_pool::pool_data_provider_tests {
    use std::signer;
    use std::string::{utf8};
    use std::vector;
    use aptos_framework::timestamp;
    use aave_config::reserve_config;
    use aave_pool::a_token_factory::Self;
    use aave_pool::variable_debt_token_factory::Self;
    use aave_mock_underlyings::mock_underlying_token_factory::{Self};
    use aave_pool::borrow_logic;
    use aave_pool::supply_logic;
    use aave_pool::token_helper::{
        init_reserves,
        get_test_reserves_count,
        convert_to_currency_decimals,
        init_reserves_with_oracle
    };
    use aave_pool::token_helper;
    use aave_pool::pool_data_provider::{
        get_all_reserves_tokens,
        get_reserve_token_symbol,
        get_reserve_token_address,
        get_all_a_tokens,
        get_all_var_tokens,
        get_a_token_total_supply,
        get_reserve_tokens_addresses,
        get_user_reserve_data,
        get_total_debt,
        get_paused,
        get_debt_ceiling_decimals
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    const TEST_ASSETS_COUNT: u8 = 3;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_all_reserves_tokens(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let reserve_tokens = get_all_reserves_tokens();
        let reserve_tokens_count = vector::length(&reserve_tokens);
        assert!(reserve_tokens_count == (get_test_reserves_count() as u64), TEST_SUCCESS);

        for (i in 0..reserve_tokens_count) {
            let token_data = vector::borrow(&reserve_tokens, i);
            let symbol = get_reserve_token_symbol(token_data);
            let token_address = get_reserve_token_address(token_data);
            assert!(
                symbol == mock_underlying_token_factory::symbol(token_address),
                TEST_SUCCESS
            );
            assert!(
                token_address == mock_underlying_token_factory::token_address(symbol),
                TEST_SUCCESS
            )
        }
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_all_a_tokens(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // Initialize reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let reserve_tokens = get_all_a_tokens();
        let reserve_tokens_count = vector::length(&reserve_tokens);
        assert!(reserve_tokens_count == (get_test_reserves_count() as u64), TEST_SUCCESS);

        for (i in 0..reserve_tokens_count) {
            let token_data = vector::borrow(&reserve_tokens, i);
            let symbol = get_reserve_token_symbol(token_data);
            let token_address = get_reserve_token_address(token_data);
            assert!(symbol == a_token_factory::symbol(token_address), TEST_SUCCESS);
        }
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_all_var_tokens(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // Initialize reserves
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let reserve_tokens = get_all_var_tokens();
        let reserve_tokens_count = vector::length(&reserve_tokens);
        assert!(reserve_tokens_count == (get_test_reserves_count() as u64), TEST_SUCCESS);

        for (i in 0..reserve_tokens_count) {
            let token_data = vector::borrow(&reserve_tokens, i);
            let symbol = get_reserve_token_symbol(token_data);
            let token_address = get_reserve_token_address(token_data);
            assert!(
                symbol == variable_debt_token_factory::symbol(token_address),
                TEST_SUCCESS
            );
        }
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_a_token_total_supply(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let reserve_tokens = get_all_reserves_tokens();
        let reserve_tokens_count = vector::length(&reserve_tokens);
        assert!(reserve_tokens_count == (get_test_reserves_count() as u64), TEST_SUCCESS);

        let aave_pool_address = signer::address_of(aave_pool);
        for (i in 0..reserve_tokens_count) {
            let underlying_token_address =
                get_reserve_token_address(vector::borrow(&reserve_tokens, i));
            // mint 10000000 underlying tokens to aave_pool_address
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                aave_pool_address,
                (convert_to_currency_decimals(underlying_token_address, 10000000) as u64),
                underlying_token_address
            );

            // supply 1000 underlying tokens to aave_pool_address
            let supply_amount =
                convert_to_currency_decimals(underlying_token_address, 1000);
            supply_logic::supply(
                aave_pool,
                underlying_token_address,
                supply_amount,
                aave_pool_address,
                0
            );
            let a_token_total_supply = get_a_token_total_supply(underlying_token_address);
            assert!(a_token_total_supply == supply_amount, TEST_SUCCESS)
        }
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
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    fun test_get_total_debt(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        // Initialize reserves
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

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        // user1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supplied_amount,
            user1_address,
            0
        );

        // user2 supplies 1000 U_1
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000000000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supplied_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrow 10 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 10
        );
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2,
            0,
            user2_address
        );

        let variable_token_total_debt = get_total_debt(underlying_u1_token_address);
        assert!(variable_token_total_debt == borrow_amount, TEST_SUCCESS)
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
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    fun test_get_user_reserve_data(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
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

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        // user1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        // user2 supplies 1000 U_2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (convert_to_currency_decimals(underlying_u2_token_address, 1000000000) as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // user2 supplies 1000 U_2
        let supply_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_u2_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user2 borrow 10 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            user2_address
        );

        // get user2 underlying_u1_token_address reserve data
        let (
            current_a_token_balance,
            current_variable_debt,
            scaled_variable_debt,
            liquidity_rate,
            usage_as_collateral_enabled
        ) = get_user_reserve_data(underlying_u1_token_address, user2_address);

        assert!(current_a_token_balance == 0, TEST_SUCCESS);
        assert!(current_variable_debt == borrow_u1_amount, TEST_SUCCESS);
        assert!(scaled_variable_debt == borrow_u1_amount, TEST_SUCCESS);
        assert!(liquidity_rate == 135000000000000000000000, TEST_SUCCESS);
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // get user2 underlying_u2_token_address reserve data
        let (
            current_a_token_balance,
            current_variable_debt,
            scaled_variable_debt,
            liquidity_rate,
            usage_as_collateral_enabled
        ) = get_user_reserve_data(underlying_u2_token_address, user2_address);

        assert!(current_a_token_balance == supply_u2_amount, TEST_SUCCESS);
        assert!(current_variable_debt == 0, TEST_SUCCESS);
        assert!(scaled_variable_debt == 0, TEST_SUCCESS);
        assert!(liquidity_rate == 0, TEST_SUCCESS);
        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_reserve_tokens_addresses(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let (a_token_address, variable_debt_token_address) =
            get_reserve_tokens_addresses(underlying_u1_token_address);
        assert!(a_token_factory::symbol(a_token_address) == utf8(b"A_1"), TEST_SUCCESS);
        assert!(
            variable_debt_token_factory::symbol(variable_debt_token_address)
                == utf8(b"V_1"),
            TEST_SUCCESS
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let (a_token_address, variable_debt_token_address) =
            get_reserve_tokens_addresses(underlying_u2_token_address);
        assert!(a_token_factory::symbol(a_token_address) == utf8(b"A_2"), TEST_SUCCESS);
        assert!(
            variable_debt_token_factory::symbol(variable_debt_token_address)
                == utf8(b"V_2"),
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_get_paused(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        assert!(get_paused(underlying_u1_token_address) == false, TEST_SUCCESS);
    }

    #[test]
    fun test_get_debt_ceiling_decimals() {
        assert!(
            get_debt_ceiling_decimals() == reserve_config::get_debt_ceiling_decimals(),
            TEST_SUCCESS
        );
    }
}
