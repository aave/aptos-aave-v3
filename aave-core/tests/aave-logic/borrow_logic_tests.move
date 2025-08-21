#[test_only]
module aave_pool::borrow_logic_tests {
    use std::signer;
    use std::string::{utf8};
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::fungible_asset_manager;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::pool_token_logic;
    use aave_pool::token_helper::{convert_to_currency_decimals, init_reserves_with_oracle};
    use aave_pool::pool;
    use aave_pool::token_helper;
    use aave_pool::a_token_factory::Self;
    use aave_pool::borrow_logic::Self;
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::events::IsolationModeTotalDebtUpdated;
    use aave_pool::pool_data_provider;
    use aave_pool::pool_configurator;
    use aave_pool::supply_logic::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            supply_user = @0x042
        )
    ]
    /// Reserve allows borrowing and being used as collateral.
    /// User config allows only borrowing for the reserve.
    /// User supplies and withdraws parts of the supplied amount
    fun test_supply_borrow(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        supply_user: &signer
    ) {
        let supply_user_address = signer::address_of(supply_user);
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);

        // user1 mint 1000 U_1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            supply_user_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        // mint 10 APT to the supply_user_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            supply_user_address, 1_000_000_000
        );

        // set asset price for U_1 token
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        // user1 deposit 1000 U_1 to the pool
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            supply_user,
            underlying_u1_token_address,
            supply_u1_amount,
            supply_user_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            supply_user, underlying_u1_token_address, true
        );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let user1_balance =
            a_token_factory::balance_of(supply_user_address, a_token_address);
        assert!(user1_balance == supply_u1_amount, TEST_SUCCESS);

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // user1 borrow 100 U_1
        let borrow_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 100);
        borrow_logic::borrow(
            supply_user,
            underlying_u1_token_address,
            borrow_u1_amount,
            2,
            0,
            supply_user_address
        );

        // check emitted events
        let emitted_borrow_events = emitted_events<borrow_logic::Borrow>();
        assert!(vector::length(&emitted_borrow_events) == 1, TEST_SUCCESS);
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
    // User 1 supply 1000 U_1
    // User 2 supply 2000 U_2
    // Configures isolated assets U_2.
    // User 2 borrows 10 U_1. Check debt ceiling
    fun test_borrow_with_isolation_mode(
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
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // mint 10000000 U_1 to user 1
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            10
        );

        // supply 1000 U_1 to user 1
        let supply_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        aave_pool::supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_u1_amount,
            user1_address,
            0
        );

        // mint 10000000 U_2 to user 2
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            10
        );

        // set debt ceiling
        pool_configurator::set_debt_ceiling(
            aave_pool, underlying_u2_token_address, 10000
        );

        // supply 2000 U_2 to user 2
        let supply_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 2000);
        aave_pool::supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_u2_amount,
            user2_address,
            0
        );
        // Enables collateral
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u2_token_address, user2_address
            );
        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // User 2 borrow 10 U_1 to user 2
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

        // check isolation mode total debt emitted events
        let emitted_events = emitted_events<IsolationModeTotalDebtUpdated>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // check borrow event
        let emitted_events = emitted_events<borrow_logic::Borrow>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);

        assert!(isolation_mode_total_debt == 1000, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // User 1 deposits 1000 U_1
    // User 2 deposits 1000 U_2
    // User 2 borrows 1 U_1
    // User 2 borrows 1 U_1 again
    // User 2 borrows 1 U_1 again
    // User 2 borrows 1 U_1 again
    // See if there is any arbitrage possibility
    fun test_borrow_with_multiple_borrow(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000 U_1 for user 1
        let mint_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 1000
        );
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_amount as u64),
            underlying_u1_token_address
        );
        // user 1 supplies 100 U_1
        let supply_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        // set asset price for U_1
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        // mint 1000 U_2 for user 2
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        let mint_amount = convert_to_currency_decimals(
            underlying_u2_token_address, 1000
        );
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_amount as u64),
            underlying_u2_token_address
        );
        // user 2 supplies 1000 U_2
        let supply_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset price for U_2
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::fast_forward_seconds(1000);

        let borrow_amount = convert_to_currency_decimals(underlying_u1_token_address, 1);
        // set variable borrow index is 1.5 ray
        let variable_borrow_index = 15 * math_utils::pow(10, 26);
        pool::set_reserve_variable_borrow_index_for_testing(
            underlying_u1_token_address,
            (variable_borrow_index as u128)
        );

        // user 2 first borrows 1 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 2 second borrows 1 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 2 third borrows 1 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 2 fourth borrows 1 U_1
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // repay all debt
        let repay_amount = borrow_amount * 4;
        // check total debt before repay
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let total_debt =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(total_debt > repay_amount, TEST_SUCCESS);

        borrow_logic::repay(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2, // variable interest rate mode
            user2_address
        );

        // check total debt after repay
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let total_debt =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(total_debt > 0, TEST_SUCCESS); // There is still debt to be repaid, No arbitrage possible

        // check emitted events
        let emitted_borrow_events = emitted_events<borrow_logic::Borrow>();
        assert!(vector::length(&emitted_borrow_events) == 4, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // User 1 deposits 100 U_1, user 2 deposits 100 U_2, borrows 50 U_1
    // User 2 receives 25 aToken from user 1, repays half of the debt
    fun test_repay_with_a_tokens_with_repay_half_of_the_debt(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 10 APT to the user1_address and user2_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 100 U_1 for user 1
        let mint_amount = convert_to_currency_decimals(underlying_u1_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 100 U_1
        let supply_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 100
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 100 U_2 for user 2
        let mint_amount = convert_to_currency_decimals(underlying_u2_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 100 U_2
        let supply_amount = convert_to_currency_decimals(
            underlying_u2_token_address, 100
        );
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::fast_forward_seconds(1000);

        // user 2 borrows 50 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 50
        );
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 1 transfers 25 aToken to user 2
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let transfer_amount = convert_to_currency_decimals(a_token_address, 25);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        let user2_balance_before =
            a_token_factory::balance_of(user2_address, a_token_address);
        let user2_debt_before =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );

        // user 2 repays half of the debt
        let repay_amount = convert_to_currency_decimals(underlying_u1_token_address, 25);
        borrow_logic::repay_with_a_tokens(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2 // variable interest rate mode
        );

        // check emitted events
        let emitted_repay_events = emitted_events<borrow_logic::Repay>();
        assert!(vector::length(&emitted_repay_events) == 1, TEST_SUCCESS);

        // check user 2 balances
        let user2_balance_after =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(
            user2_balance_after == user2_balance_before - repay_amount,
            TEST_SUCCESS
        );

        let user2_debt_after =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(
            user2_debt_after == user2_debt_before - repay_amount,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // User 1 deposits 100 U_1, user 2 deposits 100 U_2, borrows 50 U_1
    // User 2 receives 25 aToken from user 1, use all aToken to repay debt
    fun test_repay_with_a_tokens_with_all_atoken_to_repay_debt(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 10 APT to the user1_address and user2_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 100 U_1 for user 1
        let mint_amount = convert_to_currency_decimals(underlying_u1_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 100 U_1
        let supply_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 100
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));
        // mint 100 U_2 for user 2
        let mint_amount = convert_to_currency_decimals(underlying_u2_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 100 U_2
        let supply_amount = convert_to_currency_decimals(
            underlying_u2_token_address, 100
        );
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::fast_forward_seconds(1000);

        // user 2 borrows 50 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 50
        );
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 1 transfers 25 aToken to user 2
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let transfer_amount = convert_to_currency_decimals(a_token_address, 25);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        let user2_balance_before =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance_before == transfer_amount, TEST_SUCCESS);

        let user2_debt_before =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );

        // user 2 repays half of the debt
        let repay_amount = math_utils::u256_max();
        borrow_logic::repay_with_a_tokens(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2 // variable interest rate mode
        );

        // check emitted events
        let emitted_repay_events = emitted_events<borrow_logic::Repay>();
        assert!(vector::length(&emitted_repay_events) == 1, TEST_SUCCESS);

        // check user 2 balances
        let user2_balance_after =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance_after == 0, TEST_SUCCESS);

        let user2_debt_after =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(
            user2_debt_after == user2_debt_before - transfer_amount,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // User 1 deposits 100 U_1, user 2 deposits 100 U_2, borrows 50 U_1
    // User 2 receives 50 aToken from user 1, repay all debt
    fun test_repay_with_a_tokens_with_repay_all_debt(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 100 U_1 for user 1
        let mint_amount = convert_to_currency_decimals(underlying_u1_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 100 U_1
        let supply_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 100
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // mint 10 APT to the user1_address and user2_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 100 U_2 for user 2
        let mint_amount = convert_to_currency_decimals(underlying_u2_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 100 U_2
        let supply_amount = convert_to_currency_decimals(
            underlying_u2_token_address, 100
        );
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::fast_forward_seconds(1000);

        // user 2 borrows 50 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 50
        );
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 1 transfers 25 aToken to user 2
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let transfer_amount = convert_to_currency_decimals(a_token_address, 50);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        let user2_balance_before =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance_before == transfer_amount, TEST_SUCCESS);

        let user2_debt_before =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );

        // user 2 repays half of the debt
        let repay_amount = math_utils::u256_max();
        borrow_logic::repay_with_a_tokens(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2 // variable interest rate mode
        );

        // check emitted events
        let emitted_repay_events = emitted_events<borrow_logic::Repay>();
        assert!(vector::length(&emitted_repay_events) == 1, TEST_SUCCESS);

        // check user 2 balances
        let user2_balance_after =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(
            user2_balance_after == user2_balance_before - user2_debt_before,
            TEST_SUCCESS
        );

        let user2_debt_after =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(user2_debt_after == 0, TEST_SUCCESS);

        // Check interest rates after repaying with aTokens
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let current_liquidity_rate =
            pool::get_reserve_current_liquidity_rate(reserve_data);
        let current_variable_borrow_rate =
            pool::get_reserve_current_variable_borrow_rate(reserve_data);

        let unbacked = 0;
        let liquidity_added = 0;
        let liquidity_taken = 0;
        let total_variable_debt =
            variable_debt_token_factory::total_supply(variable_debt_token_address);
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_config_map);
        let reserve = underlying_u1_token_address;
        // The underlying token balance corresponding to the aToken
        let a_token_underlying_balance =
            (
                fungible_asset_manager::balance_of(
                    a_token_factory::get_token_account_address(a_token_address),
                    underlying_u1_token_address
                ) as u256
            );

        let (cacl_current_liquidity_rate, cacl_current_variable_borrow_rate) =
            default_reserve_interest_rate_strategy::calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            );

        assert!(
            (current_liquidity_rate as u256) == cacl_current_liquidity_rate, TEST_SUCCESS
        );
        assert!(
            (current_variable_borrow_rate as u256) == cacl_current_variable_borrow_rate,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // User 1 deposits 100 U_1, user 2 deposits 100 U_2, borrows 50 U_1
    // User 2 receives 60 aToken from user 1, user2 collateral state is false
    fun test_repay_with_a_tokens_with_user_collateral_state_is_false(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 100 U_1 for user 1
        let mint_amount = convert_to_currency_decimals(underlying_u1_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 100 U_1
        let supply_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 100
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            supply_amount,
            user1_address,
            0
        );

        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // mint 10 APT to the user1_address and user2_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 100 U_2 for user 2
        let mint_amount = convert_to_currency_decimals(underlying_u2_token_address, 100);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 100 U_2
        let supply_amount = convert_to_currency_decimals(
            underlying_u2_token_address, 100
        );
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            supply_amount,
            user2_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::fast_forward_seconds(1000);

        // user 2 borrows 50 U_1
        let borrow_amount = convert_to_currency_decimals(
            underlying_u1_token_address, 50
        );
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2, // variable interest rate mode
            0, // referral
            user2_address
        );

        // user 1 transfers 25 aToken to user 2
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        let transfer_amount = convert_to_currency_decimals(a_token_address, 60);
        pool_token_logic::transfer(
            user1,
            user2_address,
            transfer_amount,
            a_token_address
        );

        let user2_balance_before =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(user2_balance_before == transfer_amount, TEST_SUCCESS);

        let user2_debt_before =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );

        // set user2 collateral state to false
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u1_token_address, false
        );

        // user 2 repays half of the debt
        let repay_amount = math_utils::u256_max();
        borrow_logic::repay_with_a_tokens(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2 // variable interest rate mode
        );

        // check emitted events
        let emitted_repay_events = emitted_events<borrow_logic::Repay>();
        assert!(vector::length(&emitted_repay_events) == 1, TEST_SUCCESS);

        // check user 2 balances
        let user2_balance_after =
            a_token_factory::balance_of(user2_address, a_token_address);
        assert!(
            user2_balance_after == user2_balance_before - user2_debt_before,
            TEST_SUCCESS
        );

        let user2_debt_after =
            variable_debt_token_factory::balance_of(
                user2_address, variable_debt_token_address
            );
        assert!(user2_debt_after == 0, TEST_SUCCESS);

        // Check interest rates after repaying with aTokens
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);
        let current_liquidity_rate =
            pool::get_reserve_current_liquidity_rate(reserve_data);
        let current_variable_borrow_rate =
            pool::get_reserve_current_variable_borrow_rate(reserve_data);

        let unbacked = 0;
        let liquidity_added = 0;
        let liquidity_taken = 0;
        let total_variable_debt =
            variable_debt_token_factory::total_supply(variable_debt_token_address);
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_config_map);
        let reserve = underlying_u1_token_address;
        // The underlying token balance corresponding to the aToken
        let a_token_underlying_balance =
            (
                fungible_asset_manager::balance_of(
                    a_token_factory::get_token_account_address(a_token_address),
                    underlying_u1_token_address
                ) as u256
            );

        let (cacl_current_liquidity_rate, cacl_current_variable_borrow_rate) =
            default_reserve_interest_rate_strategy::calculate_interest_rates(
                unbacked,
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_factor,
                reserve,
                a_token_underlying_balance
            );

        assert!(
            (current_liquidity_rate as u256) == cacl_current_liquidity_rate, TEST_SUCCESS
        );
        assert!(
            (current_variable_borrow_rate as u256) == cacl_current_variable_borrow_rate,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // @notice Tests that isolation mode debt ceiling uses ceiling division for accurate debt calculation
    // @dev This test verifies that small borrow amounts are properly counted using ceiling division
    //      and validates the total debt calculation matches the expected formula
    fun test_isolation_mode_debt_ceiling_rounding_fix(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // Set U_2 in isolation mode with debt ceiling = 100 debt ceiling units
        // This corresponds to 1 unit of borrowing in the debt ceiling calculation
        let debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u2_token_address,
            debt_ceiling
        );

        // mint APT to user1 and user2
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 1000 U_1 for user 1 (liquidity provider)
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            mint_u1_amount,
            user1_address,
            0
        );

        // mint 1000 U_2 for user 2 (collateral for isolation mode)
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            mint_u2_amount,
            user2_address,
            0
        );

        // Enable U_2 as collateral for user 2
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset prices
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set U_1 as borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // First borrow: 0.5 units
        let first_small_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) / 2;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            first_small_borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify first borrow debt calculation
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 50, TEST_SUCCESS);

        // Second borrow: 0.33 units
        let second_small_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) / 3;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            second_small_borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify total debt calculation matches expected formula
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);

        // Calculate expected total debt using ceiling division formula
        let u1_decimals =
            (fungible_asset_manager::decimals(underlying_u1_token_address) as u256);
        let difference_decimals = u1_decimals
            - reserve_config::get_debt_ceiling_decimals();
        let real_decimals = math_utils::pow(10, difference_decimals);
        let expected_total_debt =
            math_utils::ceil_div(first_small_borrow_amount, real_decimals)
                + math_utils::ceil_div(second_small_borrow_amount, real_decimals);

        assert!((isolation_mode_total_debt as u256) == expected_total_debt, TEST_SUCCESS)
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // @notice Tests that isolation mode debt ceiling properly rejects borrows when ceiling is exceeded
    // @dev This test verifies that ceiling division correctly calculates debt and rejects when limit is reached
    #[expected_failure(abort_code = 53, location = aave_pool::validation_logic)]
    fun test_isolation_mode_debt_ceiling_rejection(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // Set U_2 in isolation mode with debt ceiling = 100 debt ceiling units
        // This corresponds to 1 unit of borrowing in the debt ceiling calculation
        let debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u2_token_address,
            debt_ceiling
        );

        // mint APT to user1 and user2
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 1000 U_1 for user 1 (liquidity provider)
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            mint_u1_amount,
            user1_address,
            0
        );

        // mint 1000 U_2 for user 2 (collateral for isolation mode)
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            mint_u2_amount,
            user2_address,
            0
        );

        // Enable U_2 as collateral for user 2
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset prices
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set U_1 as borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // First borrow: 0.4 units (40 debt ceiling units)
        let first_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) * 4 / 10;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            first_borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify first borrow debt calculation
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 40, TEST_SUCCESS);

        // Second borrow: 0.4 units (40 debt ceiling units)
        let second_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) * 4 / 10;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            second_borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify second borrow debt calculation
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 80, TEST_SUCCESS);

        // Third borrow: 0.3 units (30 debt ceiling units) - should fail because 40 + 40 + 30 = 110 > 100
        let third_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) * 3 / 10;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            third_borrow_amount,
            2,
            0,
            user2_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // @notice Tests that isolation mode debt ceiling uses consistent ceiling division for both borrow and repay
    // @dev This test verifies that small amounts are handled consistently to prevent debt ceiling bypass
    //      while maintaining predictable behavior for users
    fun test_isolation_mode_debt_ceiling_consistency(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // Set U_2 in isolation mode with debt ceiling = 100 debt ceiling units
        let debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u2_token_address,
            debt_ceiling
        );

        // mint APT to user1 and user2
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 1000 U_1 for user 1 (liquidity provider)
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            mint_u1_amount,
            user1_address,
            0
        );

        // mint 1000 U_2 for user 2 (collateral for isolation mode)
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            mint_u2_amount,
            user2_address,
            0
        );

        // Enable U_2 as collateral for user 2
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset prices
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set U_1 as borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // Test 1: Small borrow amount (0.33 units) - should increment debt by 1 unit
        let small_borrow_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) / 3;
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            small_borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify debt calculation
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 34, TEST_SUCCESS);

        // Mint U_1 to user2 for repayment
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (small_borrow_amount as u64),
            underlying_u1_token_address
        );

        // Test 2: Repay the same small amount - should decrement debt by 1 unit
        borrow_logic::repay(
            user2,
            underlying_u1_token_address,
            small_borrow_amount,
            2,
            user2_address
        );

        // Verify debt is back to zero (consistent rounding)
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 0, TEST_SUCCESS);

        // Test 3: Multiple small operations to verify consistency
        let tiny_amount = convert_to_currency_decimals(underlying_u1_token_address, 1)
            / 10; // 0.1 units

        // Borrow 10 times 0.1 units
        let i = 0;
        while (i < 10) {
            borrow_logic::borrow(
                user2,
                underlying_u1_token_address,
                tiny_amount,
                2,
                0,
                user2_address
            );
            i = i + 1;
        };

        // Verify total debt (10 * 0.1 = 1 unit, but each 0.1 rounds up to 1 debt unit)
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 100, TEST_SUCCESS); // 10 * 10 = 100 debt units

        // Mint enough U_1 for repayment
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (tiny_amount * 10 as u64),
            underlying_u1_token_address
        );

        // Repay 10 times 0.1 units
        let i = 0;
        while (i < 10) {
            borrow_logic::repay(
                user2,
                underlying_u1_token_address,
                tiny_amount,
                2,
                user2_address
            );
            i = i + 1;
        };

        // Verify debt is back to zero (consistent rounding)
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 0, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x041,
            user2 = @0x042
        )
    ]
    // @notice Tests that isolation mode debt ceiling uses ceiling division for accurate debt calculation during repayment
    // @dev This test verifies that small repay amounts are properly counted using ceiling division
    //      and validates the total debt reduction matches the expected formula
    fun test_isolation_mode_debt_ceiling_repayment_rounding_fix(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let underlying_u2_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_2"));

        // Set U_2 in isolation mode with debt ceiling = 100 debt ceiling units
        let debt_ceiling = 100;
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u2_token_address,
            debt_ceiling
        );

        // mint APT to user1 and user2
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, 1_000_000_000
        );
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user2_address, 1_000_000_000
        );

        // mint 1000 U_1 for user 1 (liquidity provider)
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // user 1 supplies 1000 U_1
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            mint_u1_amount,
            user1_address,
            0
        );

        // mint 1000 U_2 for user 2 (collateral for isolation mode)
        let mint_u2_amount =
            convert_to_currency_decimals(underlying_u2_token_address, 1000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u2_amount as u64),
            underlying_u2_token_address
        );

        // user 2 supplies 1000 U_2
        supply_logic::supply(
            user2,
            underlying_u2_token_address,
            mint_u2_amount,
            user2_address,
            0
        );

        // Enable U_2 as collateral for user 2
        supply_logic::set_user_use_reserve_as_collateral(
            user2, underlying_u2_token_address, true
        );

        // set asset prices
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u1_token_address,
            100
        );

        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_u2_token_address,
            100
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // set U_1 as borrowable in isolation
        pool_configurator::set_borrowable_in_isolation(
            aave_pool, underlying_u1_token_address, true
        );

        // Borrow 1 unit to establish isolation mode debt
        let borrow_amount = convert_to_currency_decimals(underlying_u1_token_address, 1);
        borrow_logic::borrow(
            user2,
            underlying_u1_token_address,
            borrow_amount,
            2,
            0,
            user2_address
        );

        // Verify initial debt calculation
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 100, TEST_SUCCESS);

        // Mint U_1 to user2 for repayment
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (borrow_amount as u64),
            underlying_u1_token_address
        );

        // Repay 0.5 units (should reduce debt by 50 units using ceiling division)
        let repay_amount = convert_to_currency_decimals(underlying_u1_token_address, 1)
            / 2;
        borrow_logic::repay(
            user2,
            underlying_u1_token_address,
            repay_amount,
            2,
            user2_address
        );

        // Verify debt reduction using ceiling division
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);
        assert!(isolation_mode_total_debt == 50, TEST_SUCCESS);

        // Repay another 0.33 units (should reduce debt by 33 units using ceiling division)
        let second_repay_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1) / 3;
        borrow_logic::repay(
            user2,
            underlying_u1_token_address,
            second_repay_amount,
            2,
            user2_address
        );

        // Verify final debt calculation matches expected formula
        let reserve_data = pool::get_reserve_data(underlying_u2_token_address);
        let isolation_mode_total_debt =
            pool::get_reserve_isolation_mode_total_debt(reserve_data);

        // Calculate expected remaining debt using ceiling division formula
        let u1_decimals =
            (fungible_asset_manager::decimals(underlying_u1_token_address) as u256);
        let difference_decimals = u1_decimals
            - reserve_config::get_debt_ceiling_decimals();
        let real_decimals = math_utils::pow(10, difference_decimals);
        let expected_debt_reduction =
            math_utils::ceil_div(repay_amount, real_decimals)
                + math_utils::ceil_div(second_repay_amount, real_decimals);
        let expected_remaining_debt = 100 - expected_debt_reduction;

        assert!(
            (isolation_mode_total_debt as u256) == expected_remaining_debt, TEST_SUCCESS
        )
    }
}
