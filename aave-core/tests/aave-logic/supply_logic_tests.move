#[test_only]
module aave_pool::supply_logic_tests {
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_std::debug::print;
    use aptos_framework::account;
    use aptos_framework::aptos_coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_pool::pool_data_provider;
    use aave_pool::token_helper::convert_to_currency_decimals;
    use aave_pool::pool_token_logic;
    use aave_pool::pool;
    use aave_pool::token_helper;
    use aave_pool::pool_fee_manager;
    use aave_pool::a_token_factory::Self;
    use aave_pool::emode_logic::{Self, configure_emode_category};
    use aave_pool::pool::{get_reserve_data, get_reserve_id, get_reserve_liquidity_index};
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::coin_migrator;
    use aave_pool::pool_configurator;
    use aave_pool::pool_tests::create_user_config_for_reserve;
    use aave_pool::supply_logic::Self;
    use aave_pool::events::Self;

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
    fun test_supply_partial_withdraw(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        supply_user: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(supply_user),
            (get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // =============== MINT UNDERLYING FOR USER ================= //
        // mint 100 underlying tokens for the user
        let mint_receiver_address = signer::address_of(supply_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // =============== USER SUPPLY ================= //
        // user supplies the underlying token
        let supply_receiver_address = signer::address_of(supply_user);
        let supplied_amount: u64 = 10;
        supply_logic::supply(
            supply_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
        // > check supplier balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );
        // > check a_token underlying balance
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let atoken_acocunt_address =
            a_token_factory::get_token_account_address(a_token_address);
        let underlying_atoken_acocunt_balance =
            mock_underlying_token_factory::balance_of(
                atoken_acocunt_address, underlying_token_address
            );
        assert!(underlying_atoken_acocunt_balance == supplied_amount, TEST_SUCCESS);

        // > check user a_token balance after supply
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (get_reserve_liquidity_index(reserve_data) as u256)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(supply_user), a_token_address
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        // mint 1 APT to the supply_user
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            signer::address_of(supply_user), mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(signer::address_of(supply_user))
                == mint_apt_amount,
            TEST_SUCCESS
        );

        // =============== USER WITHDRAWS ================= //
        // user withdraws a small amount of the supplied amount
        let amount_to_withdraw = 4;
        supply_logic::withdraw(
            supply_user,
            underlying_token_address,
            (amount_to_withdraw as u256),
            supply_receiver_address
        );

        // > check a_token balance of underlying
        let atoken_acocunt_balance =
            mock_underlying_token_factory::balance_of(
                atoken_acocunt_address, underlying_token_address
            );
        assert!(
            atoken_acocunt_balance == supplied_amount - amount_to_withdraw,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // > check user a_token balance after withdrawal
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount - amount_to_withdraw as u256),
                (get_reserve_liquidity_index(reserve_data) as u256)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(supply_user), a_token_address
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        // > check users underlying tokens balance
        let supplier_underlying_balance_after_withdraw =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_underlying_balance_after_withdraw
                == initial_user_balance - supplied_amount + amount_to_withdraw,
            TEST_SUCCESS
        );

        assert!(
            coin::balance<AptosCoin>(signer::address_of(supply_user))
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_token_address),
            TEST_SUCCESS
        );

        // > check emitted events
        let emitted_withdraw_events = emitted_events<supply_logic::Withdraw>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
        let emitted_reserve_collecteral_disabled_events =
            emitted_events<events::ReserveUsedAsCollateralDisabled>();
        assert!(
            vector::length(&emitted_reserve_collecteral_disabled_events) == 0,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            supply_user = @0x042,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// Reserve allows borrowing and being used as collateral.
    /// User config allows borrowing and collateral.
    /// User supplies and withdraws the entire amount
    fun test_supply_full_collateral_withdraw(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        supply_user: &signer,
        underlying_tokens_admin: &signer
    ) {
        token_helper::init_reserves_with_oracle(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );

        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 8800;
        let liquidation_threshold: u16 = 9800;
        let liquidation_bonus: u16 = 11000;
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // set underlying emode category
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_token_address, emode_cat_id
        );

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(supply_user),
            (get_reserve_id(reserve_data) as u256),
            option::some(true),
            option::some(true)
        );

        // set asset price
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_token_address,
            10
        );

        // =============== MINT UNDERLYING FOR USER ================= //
        // set user emode
        emode_logic::set_user_emode(supply_user, emode_cat_id);

        // mint 100 underlying tokens for the user
        let mint_receiver_address = signer::address_of(supply_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // =============== USER SUPPLY ================= //
        // user supplies the underlying token
        let supply_receiver_address = signer::address_of(supply_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            supply_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
        // > check supplier balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );
        // > check underlying balance of atoken
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let atoken_account_address =
            a_token_factory::get_token_account_address(a_token_address);
        let underlying_acocunt_balance =
            mock_underlying_token_factory::balance_of(
                atoken_account_address, underlying_token_address
            );
        assert!(underlying_acocunt_balance == supplied_amount, TEST_SUCCESS);

        // > check user a_token balance after supply
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (get_reserve_liquidity_index(reserve_data) as u256)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(supply_user), a_token_address
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        // mint 1 APT to the supply_user
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            signer::address_of(supply_user), mint_apt_amount
        );
        assert!(
            coin::balance<AptosCoin>(signer::address_of(supply_user))
                == mint_apt_amount,
            TEST_SUCCESS
        );

        // =============== USER WITHDRAWS ================= //
        // user withdraws his entire supply
        let amount_to_withdraw = 50;
        supply_logic::withdraw(
            supply_user,
            underlying_token_address,
            (amount_to_withdraw as u256),
            supply_receiver_address
        );

        // > check underlying balance of a_token account
        let atoken_acocunt_balance =
            mock_underlying_token_factory::balance_of(
                atoken_account_address, underlying_token_address
            );
        assert!(atoken_acocunt_balance == 0, TEST_SUCCESS);

        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // > check user a_token balance after withdrawal
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(supply_user), a_token_address
            );
        assert!(supplier_a_token_balance == 0, TEST_SUCCESS);

        // > check users underlying tokens balance
        let supplier_underlying_balance_after_withdraw =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_underlying_balance_after_withdraw
                == initial_user_balance - supplied_amount + amount_to_withdraw,
            TEST_SUCCESS
        );

        assert!(
            coin::balance<AptosCoin>(signer::address_of(supply_user))
                == mint_apt_amount
                    - pool_fee_manager::get_apt_fee(underlying_token_address),
            TEST_SUCCESS
        );

        // > check emitted events
        let emitted_withdraw_events = emitted_events<supply_logic::Withdraw>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
        let emitted_reserve_collecteral_disabled_events =
            emitted_events<events::ReserveUsedAsCollateralDisabled>();
        assert!(
            vector::length(&emitted_reserve_collecteral_disabled_events) == 1,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            underlying_tokens_admin = @aave_mock_underlyings,
            supply_user = @0x042
        )
    ]
    /// Reserve allows borrowing and being used as collateral.
    /// User config allows borrowing and collateral.
    /// User supplies and withdraws the entire amount
    /// with ltv and no debt ceiling, and not using as collateral already
    fun test_supply_use_as_collateral(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        underlying_tokens_admin: &signer,
        supply_user: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            underlying_tokens_admin
        );

        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));

        // define an emode cat for reserve and user
        let emode_cat_id: u8 = 1;
        // configure an emode category
        let ltv: u16 = 8500;
        let liquidation_threshold: u16 = 9000;
        let liquidation_bonus: u16 = 10500;
        let label = utf8(b"MODE1");
        configure_emode_category(
            emode_cat_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        // set underlying emode category
        pool_configurator::set_asset_emode_category(
            aave_pool, underlying_token_address, emode_cat_id
        );

        // get the reserve config for it
        let reserve_data = get_reserve_data(underlying_token_address);

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(supply_user),
            (get_reserve_id(reserve_data) as u256),
            option::some(true),
            option::some(false) // NOTE: not using any as collateral already
        );

        // =============== MINT UNDERLYING FOR USER ================= //
        // mint 100 underlying tokens for the user
        let mint_receiver_address = signer::address_of(supply_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // =============== USER SUPPLY ================= //
        // user supplies the underlying token
        let supply_receiver_address = signer::address_of(supply_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            supply_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
        let emitted_reserve_used_as_collateral_events =
            emitted_events<events::ReserveUsedAsCollateralEnabled>();
        assert!(
            vector::length(&emitted_reserve_used_as_collateral_events) == 0,
            TEST_SUCCESS
        );
        // > check supplier balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );
        // > check a_token balance of underlying
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let atoken_account_address =
            a_token_factory::get_token_account_address(a_token_address);
        let atoken_acocunt_balance =
            mock_underlying_token_factory::balance_of(
                atoken_account_address, underlying_token_address
            );
        assert!(atoken_acocunt_balance == supplied_amount, TEST_SUCCESS);
        // > check user a_token balance after supply
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (get_reserve_liquidity_index(reserve_data) as u256)
            );
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(supply_user), a_token_address
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aptos_std = @aptos_std,
            underlying_tokens_admin = @aave_mock_underlyings,
            supply_user = @0x042
        )
    ]
    fun test_supply_with_reserve_factor_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        underlying_tokens_admin: &signer,
        supply_user: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            underlying_tokens_admin
        );

        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));

        // =============== MINT UNDERLYING FOR USER ================= //
        // mint 100 underlying tokens for the user
        let mint_receiver_address = signer::address_of(supply_user);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            mint_receiver_address,
            100,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == 100, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );

        // set reserve factor to 0
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_token_address);
        reserve_config::set_reserve_factor(&mut reserve_config_map, 0);
        pool::test_set_reserve_configuration(
            underlying_token_address, reserve_config_map
        );
        assert!(
            reserve_config::get_reserve_factor(&reserve_config_map) == 0, TEST_SUCCESS
        );

        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // =============== USER SUPPLY ================= //
        // user supplies the underlying token
        let supply_receiver_address = signer::address_of(supply_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            supply_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
        let emitted_reserve_used_as_collateral_events =
            emitted_events<events::ReserveUsedAsCollateralEnabled>();
        assert!(
            vector::length(&emitted_reserve_used_as_collateral_events) == 0,
            TEST_SUCCESS
        );
        // > check supplier balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                mint_receiver_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some(100),
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41,
            user2 = @0x42
        )
    ]
    // User 2 supply 100 U_0, transfers to user 1. Checks that U_0 is activated as collateral for user 1
    fun test_supply_with_user2_transfer_user1_100_u0(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer,
        user2: &signer
    ) {
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // User 2 mint 100000000 U_0.
        let mint_u0_amount =
            convert_to_currency_decimals(underlying_u0_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user2_address,
            (mint_u0_amount as u64),
            underlying_u0_token_address
        );

        // User 2 supply 100 U_0. Checks that U_0 is not activated as collateral.
        supply_logic::supply(
            user2,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 100),
            user2_address,
            0
        );

        // User 2 transfers 100 U_0 to user 1
        let reserve_data = pool::get_reserve_data(underlying_u0_token_address);
        let a_token_u0_address = pool::get_reserve_a_token_address(reserve_data);
        pool_token_logic::transfer(
            user2,
            user1_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1),
            a_token_u0_address
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u0_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // User 1 deposit U_1, then tries to use U_1 isolation emode
    fun test_supply_with_u1_isolation_emode(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 100 underlying tokens for user1
        let user1_address = signer::address_of(user1);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 100) as u64),
            underlying_u1_token_address
        );

        //  set debt ceiling for U_1
        let new_debt_ceiling = 10000;
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u1_token_address,
            new_debt_ceiling
        );

        // User1 supply 100 underlying tokens to aave_pool
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // User 1 deposit U_1, set u1 ltv is zero
    fun test_supply_with_u1_ltv_is_zreo(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 100 underlying tokens for user1
        let user1_address = signer::address_of(user1);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 100) as u64),
            underlying_u1_token_address
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        reserve_config::set_ltv(&mut reserve_config_map, 0);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // User1 supply 100 underlying tokens to aave_pool
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // User 1 deposit U_0 and U_1, then tries to use U_1 enable collateral
    fun test_supply_with_u1_isolation_emode_and_u1_enable_collateral(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u0_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // User 1 mint 100000000 U_0.
        let mint_u0_amount =
            convert_to_currency_decimals(underlying_u0_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u0_amount as u64),
            underlying_u0_token_address
        );

        // User 1 supply 1 U_0. Checks that U_0 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u0_token_address,
            convert_to_currency_decimals(underlying_u0_token_address, 1),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u0_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // User 1 mint 100000000 U_1.
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // set debt ceiling for U_1
        let ceilingAmount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000);
        pool_configurator::set_debt_ceiling(
            aave_pool,
            underlying_u1_token_address,
            ceilingAmount
        );

        // User 1 supply 1 U_1. Checks that U_1 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // set debt ceiling for U_1
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let ceilingAmount = 0;
        reserve_config::set_debt_ceiling(&mut reserve_config_map, ceilingAmount);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // User 1 tries to use U_1 as collateral
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // test withdraw when amount equal to max u256 and asset disable collateral
    fun test_withdraw_when_amount_equal_max_u256_and_asset_disable_collateral(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 1 APT to the user1_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, mint_apt_amount
        );

        // user 1 deposits
        let supply_amount = 100;
        // user 1 supplies U_1 tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            supply_amount,
            underlying_u1_token_address
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            (supply_amount as u256),
            user1_address,
            0
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // disable collateral U_1 for user 1
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // user 1 withdraws
        supply_logic::withdraw(
            user1,
            underlying_u1_token_address,
            math_utils::get_u256_max_for_testing(),
            user1_address
        );

        // check user balance of U_1
        let user_balance =
            mock_underlying_token_factory::balance_of(
                user1_address, underlying_u1_token_address
            );
        assert!(user_balance == supply_amount, TEST_SUCCESS);

        // check underlying supply
        let underlying_supply =
            mock_underlying_token_factory::supply(underlying_u1_token_address);
        assert!(underlying_supply == option::some(100), TEST_SUCCESS);

        // check a_token balance of U_1
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let a_token_balance = a_token_factory::balance_of(
            user1_address, a_token_address
        );
        assert!(a_token_balance == 0, TEST_SUCCESS);

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // test withdraw when amount equal to max u256 and burn all a_token
    fun test_withdraw_when_amount_equal_max_u256_and_burn_all_a_token(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        // create test accounts
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1 APT to the user1_address
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            user1_address, mint_apt_amount
        );

        // user 1 deposits
        let supply_amount = 100;
        // user 1 supplies U_1 tokens
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            supply_amount,
            underlying_u1_token_address
        );
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            (supply_amount as u256),
            user1_address,
            0
        );

        // user 1 withdraws
        supply_logic::withdraw(
            user1,
            underlying_u1_token_address,
            math_utils::get_u256_max_for_testing(),
            user1_address
        );

        // check user balance of U_1
        let user_balance =
            mock_underlying_token_factory::balance_of(
                user1_address, underlying_u1_token_address
            );
        assert!(user_balance == supply_amount, TEST_SUCCESS);

        // check underlying supply
        let underlying_supply =
            mock_underlying_token_factory::supply(underlying_u1_token_address);
        assert!(underlying_supply == option::some(100), TEST_SUCCESS);

        // check a_token balance of U_1
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let a_token_balance = a_token_factory::balance_of(
            user1_address, a_token_address
        );
        assert!(a_token_balance == 0, TEST_SUCCESS);

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    fun test_set_user_use_reserve_as_collateral_when_disable_collateral_after_deposit(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // User 1 mint 100000000 U_1.
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // User 1 supply 100 U_1. Checks that U_1 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            user1_address,
            0
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // disable collateral for user 1
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    fun test_set_user_use_reserve_as_collateral_when_u1_enable_collateral_again(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // User 1 mint 100000000 U_1.
        let mint_u1_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u1_amount as u64),
            underlying_u1_token_address
        );

        // User 1 supply 100 U_1. Checks that U_1 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 100),
            user1_address,
            0
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );
        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // case1: enable collateral for user 1 again, use_as_collateral == is_collateral == true
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);

        // case2: disable collateral for user 1
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);

        // disable collateral for user 1 again, use_as_collateral == is_collateral == false
        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );
        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            user1 = @0x41
        )
    ]
    // Allow `validate_set_use_reserve_as_collateral` to succeed if:
    // 1. collateral is currently enabled,
    // 2. user balance is 0,
    // 3. user wants to disable collateral.
    // This handles rounding errors or logic failures that may leave stale collateral flags.
    fun test_set_user_use_reserve_as_collateral_when_user_balance_is_zero_and_collateral_is_true(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        let user1_address = signer::address_of(user1);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));
        // User 1 mint 100000000 U_0.
        let mint_u0_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 10000000);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (mint_u0_amount as u64),
            underlying_u1_token_address
        );

        // User 1 supply 1 U_0. Checks that U_0 is not activated as collateral.
        supply_logic::supply(
            user1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1),
            user1_address,
            0
        );

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, true
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == true, TEST_SUCCESS);

        // set liquidity_index is 0
        pool::set_reserve_liquidity_index_for_testing(underlying_u1_token_address, 0);
        timestamp::fast_forward_seconds(100);

        supply_logic::set_user_use_reserve_as_collateral(
            user1, underlying_u1_token_address, false
        );

        let (_, _, _, _, usage_as_collateral_enabled) =
            pool_data_provider::get_user_reserve_data(
                underlying_u1_token_address, user1_address
            );

        assert!(usage_as_collateral_enabled == false, TEST_SUCCESS);
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
            supply_user = @0x042
        )
    ]
    /// User directly supplies an APT coin which is atomically wrapped into an FA and deposited
    fun test_supply_coin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aptos_std: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        underlying_tokens_admin: &signer,
        supply_user: &signer
    ) {
        // init fa reserves with oracle and wrapped coins as a reserve
        token_helper::init_reserves_with_oracle_and_wrapped_coins(
            aave_pool,
            aave_role_super_admin,
            aptos_std,
            aave_oracle,
            data_feeds,
            platform,
            underlying_tokens_admin,
            aave_pool
        );
        // set the supplier account to be test account
        account::create_account_for_test(signer::address_of(supply_user));

        // register the supplier as a coins receiver
        coin::register<aptos_coin::AptosCoin>(supply_user);

        // get the reserve config for it
        let underlying_token_address =
            coin_migrator::get_fa_address<aptos_coin::AptosCoin>();
        let reserve_data = get_reserve_data(underlying_token_address);

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(supply_user),
            (get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // =============== MINT APT COINS TO USER ================= //
        assert!(
            coin::balance<aptos_coin::AptosCoin>(signer::address_of(supply_user)) == 0,
            TEST_SUCCESS
        );
        let supplier_init_balance = 100;
        let coins =
            coin::withdraw<aptos_coin::AptosCoin>(aptos_std, supplier_init_balance);
        coin::deposit(signer::address_of(supply_user), coins);
        assert!(
            coin::balance<aptos_coin::AptosCoin>(signer::address_of(supply_user))
                == supplier_init_balance,
            TEST_SUCCESS
        );

        // =============== USER SUPPLIES THE COIN DIRECTLY ================= //
        // user supplies his coin token
        let supply_receiver_address = signer::address_of(supply_user);
        let supplied_amount: u64 = 10;
        print(
            &coin::balance<aptos_coin::AptosCoin>(signer::address_of(supply_user))
        );
        supply_logic::supply_coin<aptos_coin::AptosCoin>(
            supply_user,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check supplier balance of coins
        let supplier_end_balance =
            coin::balance<aptos_coin::AptosCoin>(signer::address_of(supply_user));
        assert!(
            supplier_end_balance == supplier_init_balance - supplied_amount,
            TEST_SUCCESS
        );

        // mint 1 APT to the supply_user
        let mint_apt_amount = 100000000;
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            signer::address_of(supply_user), mint_apt_amount
        );

        // =============== USER WITHDRAWS ================= //
        // user withdraws a small amount of the supplied amount
        let amount_to_withdraw = 4;
        supply_logic::withdraw(
            supply_user,
            underlying_token_address,
            (amount_to_withdraw as u256),
            supply_receiver_address
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<supply_logic::Withdraw>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
        let emitted_reserve_collecteral_disabled_events =
            emitted_events<events::ReserveUsedAsCollateralDisabled>();
        assert!(
            vector::length(&emitted_reserve_collecteral_disabled_events) == 0,
            TEST_SUCCESS
        );
    }
}
