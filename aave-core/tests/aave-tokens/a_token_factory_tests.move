#[test_only]
module aave_pool::a_token_factory_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::signer;
    use std::string::utf8;
    use std::vector::Self;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage::{Self, test_init_module};
    use aave_math::wad_ray_math;
    use aave_pool::pool;
    use aave_pool::token_helper;
    use aave_pool::fungible_asset_manager;
    use aave_pool::events::BalanceTransfer;
    use aave_pool::rewards_controller;

    use aave_pool::a_token_factory::Self;
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::token_base::{Burn, Mint, Transfer};

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_atoken_initialization(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        let a_tokens_admin_address = signer::address_of(a_tokens_admin);
        // create a tokens admin account
        account::create_account_for_test(a_tokens_admin_address);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, a_tokens_admin_address);

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_1");
        let symbol = utf8(b"A1");
        let decimals = 6;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address,
                treasury_address
            );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(a_token_factory::decimals(a_token_address) == decimals, TEST_SUCCESS);
        assert!(a_token_factory::symbol(a_token_address) == symbol, TEST_SUCCESS);
        assert!(a_token_factory::name(a_token_address) == name, TEST_SUCCESS);
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_previous_index(a_tokens_admin_address, a_token_address)
                == 0,
            TEST_SUCCESS
        );
        let (user_scaled_balance, scaled_total_supply) =
            a_token_factory::get_scaled_user_balance_and_supply(
                a_tokens_admin_address, a_token_address
            );
        assert!(user_scaled_balance == 0, TEST_SUCCESS);
        assert!(scaled_total_supply == 0, TEST_SUCCESS);

        assert!(
            a_token_factory::scaled_balance_of(a_tokens_admin_address, a_token_address)
                == 0,
            TEST_SUCCESS
        );
        assert!(a_token_factory::scaled_total_supply(a_token_address) == 0, TEST_SUCCESS);

        assert!(
            a_token_factory::balance_of(a_tokens_admin_address, a_token_address) == 0,
            TEST_SUCCESS
        );
        assert!(a_token_factory::total_supply(a_token_address) == 0, TEST_SUCCESS);

        let a_token_metadata = a_token_factory::asset_metadata(symbol);
        assert!(
            a_token_factory::asset_metadata(symbol) == a_token_metadata,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_atoken_mint_burn_transfer(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 6;
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
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 6;
        let treasury_address = @0x034;

        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address,
                treasury_address
            );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // mint resource_account
        let amount_to_mint: u256 = 100;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            (amount_to_mint as u64),
            underlying_asset_address
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // get atoken scaled amount
        let atoken_amount_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= BURN ATOKENS ============== //
        // now burn the atokens
        let amount_to_burn = amount_to_mint / 2;

        // burn
        a_token_factory::burn(
            signer::address_of(token_receiver),
            signer::address_of(token_receiver),
            amount_to_burn,
            reserve_index,
            a_token_address
        );

        let remaining_amount = amount_to_mint - amount_to_burn;
        let remaining_amount_scaled =
            wad_ray_math::ray_div(remaining_amount, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == remaining_amount_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == remaining_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
        let emitted_burn_events = emitted_events<Burn>();
        assert!(vector::length(&emitted_burn_events) == 1, TEST_SUCCESS);

        // ============= TRANSFER ATOKENS ============== //
        let transfer_receiver = @0x45;
        let transfer_amount: u256 = 20;
        let transfer_receiver_amount_scaled =
            wad_ray_math::ray_div(transfer_amount, reserve_index);

        // assert transfer receiver
        a_token_factory::transfer_on_liquidation(
            signer::address_of(token_receiver),
            transfer_receiver,
            20,
            reserve_index,
            a_token_address,
            false
        );
        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == transfer_receiver_amount_scaled,
            TEST_SUCCESS
        );

        // assert token sender
        let transfer_sender_scaled_balance =
            wad_ray_math::ray_div(amount_to_burn - transfer_amount, reserve_index);
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == transfer_sender_scaled_balance,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 3, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_atoken_mint_with_incentives_controller(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 8;
        let max_supply = 100000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x034;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::some(incentives_controller_address),
                underlying_asset_address,
                treasury_address
            );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 1000;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        // first mint is true
        let first_mint =
            a_token_factory::mint(
                signer::address_of(caller),
                signer::address_of(token_receiver),
                amount_to_mint,
                reserve_index,
                a_token_address
            );
        assert!(first_mint, TEST_SUCCESS);

        // get atoken scaled amount
        let atoken_amount_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let transfer_emitted_events = emitted_events<Transfer>();
        assert!(vector::length(&transfer_emitted_events) == 1, TEST_SUCCESS);
        let mint_emitted_events = emitted_events<Mint>();
        assert!(vector::length(&mint_emitted_events) == 1, TEST_SUCCESS);

        // mint a tokens for token_receiver again
        let amount_to_mint: u256 = 1000;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        // second mint is false
        let second_mint =
            a_token_factory::mint(
                signer::address_of(caller),
                signer::address_of(token_receiver),
                amount_to_mint,
                reserve_index,
                a_token_address
            );
        assert!(!second_mint, TEST_SUCCESS);

        // get atoken scaled amount
        let atoken_amount_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == atoken_amount_scaled * 2,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == atoken_amount_scaled * 2,
            TEST_SUCCESS
        );

        // check emitted events
        let transfer_emitted_events = emitted_events<Transfer>();
        assert!(vector::length(&transfer_emitted_events) == 2, TEST_SUCCESS);

        let mint_emitted__events = emitted_events<Mint>();
        assert!(vector::length(&mint_emitted__events) == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_atoken_burn_with_incentives_controller(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_2");
        let symbol = utf8(b"T2");
        let decimals = 8;
        let max_supply = 100000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);
        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x034;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        // create a_tokens with incentives controller
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::some(incentives_controller_address),
                underlying_asset_address,
                treasury_address
            );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 20000;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        // first mint is true
        let first_mint =
            a_token_factory::mint(
                signer::address_of(caller),
                signer::address_of(token_receiver),
                amount_to_mint,
                reserve_index,
                a_token_address
            );
        assert!(first_mint, TEST_SUCCESS);

        // get a token scaled amount
        let atoken_amount_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // assert a token receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == atoken_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= BURN ATOKENS ============== //
        // mint 20000 underlying token for resource_account
        let resource_account_address =
            a_token_factory::get_token_account_address(a_token_address);
        let amount_to_mint: u256 = 20000;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            resource_account_address,
            (amount_to_mint as u64),
            underlying_asset_address
        );

        // assert resource_account_address balance
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    resource_account_address, underlying_asset_address
                ) as u256
            ) == amount_to_mint,
            TEST_SUCCESS
        );

        // now burn the atokens for token_receiver
        let amount_to_burn = amount_to_mint / 2;
        let new_reserve_index = 6 * wad_ray_math::ray();
        // Burn 10000 aTokens from the `token_receiver` account and transfer an equivalent 10000 underlying tokens back to `token_receiver`.
        // Update the reserve index where `balance_increase` is greater than `amount_to_burn`.
        a_token_factory::burn(
            signer::address_of(token_receiver),
            resource_account_address,
            amount_to_burn,
            new_reserve_index,
            a_token_address
        );

        let remaining_amount = amount_to_mint - amount_to_burn;
        let remaining_amount_scaled =
            wad_ray_math::ray_div(remaining_amount, new_reserve_index);

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint - remaining_amount_scaled,
            TEST_SUCCESS
        );

        // assert a token receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint - remaining_amount_scaled,
            TEST_SUCCESS
        );

        // assert underlying token receiver balance
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    signer::address_of(token_receiver), underlying_asset_address
                ) as u256
            ) == 0,
            TEST_SUCCESS
        );

        // check emitted events
        let transfer_emitted_events = emitted_events<Transfer>();
        assert!(vector::length(&transfer_emitted_events) == 2, TEST_SUCCESS);
        let mint_emitted_events = emitted_events<Mint>();
        assert!(vector::length(&mint_emitted_events) == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41
        )
    ]
    fun test_atoken_transfer_on_liquidation(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );
        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_3");
        let symbol = utf8(b"A3");
        let decimals = 6;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address,
                treasury_address
            );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= TRANSFER ATOKENS ON LIQUIDATION ============== //
        let transfer_receiver = @0x45;
        let transfer_amount: u256 = 20;
        let transfer_receiver_amount_scaled =
            wad_ray_math::ray_div(transfer_amount, reserve_index);
        // assert transfer receiver
        a_token_factory::transfer_on_liquidation(
            signer::address_of(token_receiver),
            transfer_receiver,
            transfer_amount,
            reserve_index,
            a_token_address,
            false
        );
        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == transfer_receiver_amount_scaled,
            TEST_SUCCESS
        );

        // assert token sender
        let transfer_sender_scaled_balance =
            wad_ray_math::ray_div(amount_to_mint - transfer_amount, reserve_index);
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == transfer_sender_scaled_balance,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42,
            caller = @0x41
        )
    ]
    fun test_atoken_transfer_on_liquidation_with_incentives_controller(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );
        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_3");
        let symbol = utf8(b"A3");
        let decimals = 8;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;

        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);
        let rewards_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::some(rewards_controller_address),
                underlying_asset_address,
                treasury_address
            );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // check addresses
        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= MINT ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // assert a token supply
        assert!(
            a_token_factory::scaled_total_supply(a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // assert a_tokens receiver balance
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= TRANSFER ATOKENS ON LIQUIDATION ============== //
        let transfer_receiver = @0x45;
        let transfer_amount: u256 = 20;
        let new_reserve_index = 4 * wad_ray_math::ray();
        let transfer_receiver_amount_scaled =
            wad_ray_math::ray_div(transfer_amount, new_reserve_index);

        // mint 100 aTokens for transfer_receiver
        a_token_factory::mint(
            signer::address_of(caller),
            transfer_receiver,
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // case1: The sender is not equal to the recipient
        // transfer a token from token_receiver to transfer_receiver
        // transfer_receiver have 100 aTokens
        // transfer_receiver will receive 5 aTokens
        a_token_factory::transfer_on_liquidation(
            signer::address_of(token_receiver),
            transfer_receiver,
            transfer_amount,
            new_reserve_index,
            a_token_address,
            false
        );

        // check emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        assert!(vector::length(&balance_transfer_emitted_events) == 1, TEST_SUCCESS);
        let transfer_emitted_events = emitted_events<Transfer>();
        assert!(vector::length(&transfer_emitted_events) == 5, TEST_SUCCESS);
        let mint_emitted_events = emitted_events<Mint>();
        assert!(vector::length(&mint_emitted_events) == 4, TEST_SUCCESS);

        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == transfer_receiver_amount_scaled + amount_to_mint,
            TEST_SUCCESS
        );

        // assert token sender
        let transfer_sender_scaled_balance =
            amount_to_mint - transfer_receiver_amount_scaled;
        assert!(
            a_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), a_token_address
            ) == transfer_sender_scaled_balance,
            TEST_SUCCESS
        );

        // case2: The sender is equal to the recipient
        // transfer a token from transfer_receiver to transfer_receiver
        // transfer_receiver have 105 aTokens
        // The sender is equal to the recipient
        // The balance is first reduced and then increased
        // The balance remains unchanged in the end
        let new_transfer_amount = 50;
        a_token_factory::transfer_on_liquidation(
            transfer_receiver,
            transfer_receiver,
            new_transfer_amount,
            new_reserve_index,
            a_token_address,
            false
        );

        // check emitted events
        let balance_transfer_emitted_events = emitted_events<BalanceTransfer>();
        assert!(vector::length(&balance_transfer_emitted_events) == 2, TEST_SUCCESS);
        let transfer_emitted_events = emitted_events<Transfer>();
        assert!(vector::length(&transfer_emitted_events) == 6, TEST_SUCCESS);
        let mint_emitted_events = emitted_events<Mint>();
        assert!(vector::length(&mint_emitted_events) == 4, TEST_SUCCESS);

        assert!(
            a_token_factory::scaled_balance_of(transfer_receiver, a_token_address)
                == amount_to_mint + transfer_receiver_amount_scaled,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1
        )
    ]
    fun test_atoken_mint_to_treasury(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_4");
        let symbol = utf8(b"A4");
        let decimals = 6;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address,
                treasury_address
            );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // ============= MINT TO TREASURY ============== //
        // case1: amount_to_mint = 0
        let amount_to_mint: u256 = 0;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // mint to treasury
        a_token_factory::mint_to_treasury(
            amount_to_mint, reserve_index, a_token_address
        );

        // check balances
        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // case2: amount_to_mint = 100
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        // mint to treasury
        a_token_factory::mint_to_treasury(
            amount_to_mint, reserve_index, a_token_address
        );

        // check balances
        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        assert!(
            a_token_factory::scaled_balance_of(treasury_address, a_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_atoken_transfer_underlying_to(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // create underlying token
        let underlying_token_name = utf8(b"TOKEN_5");
        let underlying_token_symbol = utf8(b"T5");
        let underlying_token_decimals = 3;
        let underlying_token_max_supply = 10000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            underlying_token_max_supply,
            underlying_token_name,
            underlying_token_symbol,
            underlying_token_decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_token_address =
            mock_underlying_token_factory::token_address(underlying_token_symbol);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a tokens
        let name = utf8(b"TEST_A_TOKEN_6");
        let symbol = utf8(b"A6");
        let decimals = 6;
        let treasury_address = @0x034;
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_token_address,
                treasury_address
            );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // =============== MINT UNDERLYING FOR ACCOUNT ================= //
        // mint 100 underlying tokens for some address
        let underlying_amount: u256 = 100;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            (underlying_amount as u64),
            underlying_token_address
        );

        // ============= TRANSFER THE UNDERLYING TIED TO THE ATOKENS ACCOUNT TO ANOTHER ACCOUNT ============== //
        let underlying_receiver_address = @0x7;
        let transfer_amount: u256 = 40;
        a_token_factory::transfer_underlying_to(
            underlying_receiver_address, transfer_amount, a_token_address
        );

        // check the receiver balance
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    underlying_receiver_address, underlying_token_address
                ) as u256
            ) == transfer_amount,
            TEST_SUCCESS
        );

        // check the underlying account
        assert!(
            (
                mock_underlying_token_factory::balance_of(
                    a_token_factory::get_token_account_address(a_token_address),
                    underlying_token_address
                ) as u256
            ) == underlying_amount - transfer_amount,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            rescue_receiver = @0x42,
            caller = @0x41,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    fun test_atoken_rescue(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        rescue_receiver: &signer,
        caller: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init the acl module and make aave_pool the asset listing/pool admin
        test_init_module(aave_role_super_admin);
        acl_manage::add_asset_listing_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN");
        let symbol = utf8(b"A");
        let decimals = 6;
        let treasury_address = @0x034;
        let underlying_asset_address = @0x033;
        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address,
                treasury_address
            );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();

        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        // check addresses
        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= RESCUE TRANSFER ATOKENS ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let _amount_to_mint_scaled = wad_ray_math::ray_div(
            amount_to_mint, reserve_index
        );

        let rescue_amount: u256 = 20;
        let _rescue_amount_scaled = wad_ray_math::ray_div(rescue_amount, reserve_index);

        // mint some tokens to the pool
        a_token_factory::mint(
            signer::address_of(caller),
            signer::address_of(aave_pool),
            amount_to_mint,
            reserve_index,
            a_token_address
        );

        // check events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // Create a new token
        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 6;
        let max_supply = 10000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        // Transfer some tokens to the resource account
        let new_underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);
        let mint_amount = 1000000;
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            a_token_factory::get_token_account_address(a_token_address),
            mint_amount,
            new_underlying_asset_address
        );
        // The user's balance before rescue is 0
        let rescue_receiver_address = signer::address_of(rescue_receiver);
        assert!(
            fungible_asset_manager::balance_of(
                rescue_receiver_address, new_underlying_asset_address
            ) == 0,
            TEST_SUCCESS
        );

        // do rescue transfer. Singer is pool admin = aave_pool
        a_token_factory::rescue_tokens(
            aave_pool,
            new_underlying_asset_address,
            rescue_receiver_address,
            (mint_amount as u256),
            a_token_address
        );
        // The user's balance after rescue is 1000000
        // assert rescue receiver balance
        assert!(
            fungible_asset_manager::balance_of(
                rescue_receiver_address, new_underlying_asset_address
            ) == mint_amount,
            TEST_SUCCESS
        );
    }

    //  =======================  Test exceptions  =======================
    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::token_base)]
    fun test_init_module_with_not_pool_owner(user1: &signer) {
        a_token_factory::test_init_module(user1);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            user1 = @0x41
        )
    ]
    #[expected_failure(abort_code = 5, location = aave_pool::a_token_factory)]
    fun test_create_token_with_caller_not_asset_listing_and_pool_admin(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // init acl module
        acl_manage::test_init_module(aave_acl);

        let user1_address = signer::address_of(user1);
        if (acl_manage::is_asset_listing_admin(user1_address)) {
            acl_manage::remove_asset_listing_admin(aave_acl, user1_address);
        };
        if (acl_manage::is_pool_admin(user1_address)) {
            acl_manage::remove_pool_admin(aave_acl, user1_address);
        };

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_6");
        let symbol = utf8(b"A6");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        let treasury_address = @0x034;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::none(),
            underlying_asset_address,
            treasury_address
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_assert_token_exists_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::assert_token_exists_for_testing(@0x41);
    }

    #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_rescue_tokens_with_token_not_exist(
        aave_pool: &signer, aave_role_super_admin: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        acl_manage::test_init_module(aave_role_super_admin);
        // add pool admin
        acl_manage::add_pool_admin(
            aave_role_super_admin, signer::address_of(aave_pool)
        );

        // rescue tokens with token not exist
        a_token_factory::rescue_tokens(aave_pool, @0x32, @0x43, 10000, @0x11);
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
    #[expected_failure(abort_code = 85, location = aave_pool::a_token_factory)]
    fun test_atoken_rescue_when_underlying_token_equal_rescue_token(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        account::create_account_for_test(user1_address);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        // do rescue transfer. aave_pool is pool admin
        a_token_factory::rescue_tokens(
            aave_pool,
            underlying_u1_token_address,
            user1_address,
            100,
            a_token_address
        );
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
    #[expected_failure(abort_code = 1, location = aave_pool::token_base)]
    fun test_atoken_rescue_when_caller_not_pool_admin(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        let user1_address = signer::address_of(user1);
        account::create_account_for_test(user1_address);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        // do rescue transfer. user1 is not pool admin
        a_token_factory::rescue_tokens(
            user1,
            underlying_u1_token_address,
            user1_address,
            100,
            a_token_address
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_mint_a_token_with_token_not_exist(aave_pool: &signer) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::mint(@0x41, @0x42, 100, 1 * wad_ray_math::ray(), @0x11);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 24, location = aave_pool::token_base)]
    fun test_mint_a_token_with_mint_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        // mint a token with mint amount = 0
        a_token_factory::mint(
            @0x41,
            @0x42,
            0,
            1 * wad_ray_math::ray(),
            a_token_address
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_burn_a_token_with_token_not_exist(aave_pool: &signer) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::burn(@0x41, @0x42, 100, 1 * wad_ray_math::ray(), @0x11);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 25, location = aave_pool::token_base)]
    fun test_burn_a_token_with_burn_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aave_std);

        token_helper::init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_data = pool::get_reserve_data(underlying_u1_token_address);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);

        // burn a token with amount = 0
        a_token_factory::burn(
            @0x41,
            @0x42,
            0,
            1 * wad_ray_math::ray(),
            a_token_address
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_mint_to_treasury_with_token_not_exist(aave_pool: &signer) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::mint_to_treasury(100, 1 * wad_ray_math::ray(), @0x22);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_transfer_underlying_to_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::transfer_underlying_to(@0x55, 200, @0x22);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_transfer_on_liquidation_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::transfer_on_liquidation(
            @0x55,
            @0x66,
            100,
            1 * wad_ray_math::ray(),
            @0x22,
            false
        );
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_get_token_account_address_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::get_token_account_address(@0x22);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_get_reserve_treasury_address_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::get_reserve_treasury_address(@0x23);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_get_underlying_asset_address_with_token_not_exist(
        aave_pool: &signer
    ) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::get_underlying_asset_address(@0x24);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_drop_token_with_token_not_exist(aave_pool: &signer) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::drop_token(@0x24);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_drop_token_with_token_exists(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 8;
        let max_supply = 100000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x034;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        let a_token_address =
            a_token_factory::create_token(
                a_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::some(incentives_controller_address),
                underlying_asset_address,
                treasury_address
            );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let resource_account = account::create_resource_address(&a_token_address, b"");

        assert!(
            a_token_factory::get_underlying_asset_address(a_token_address)
                == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_reserve_treasury_address(a_token_address)
                == treasury_address,
            TEST_SUCCESS
        );
        assert!(
            a_token_factory::get_token_account_address(a_token_address)
                == resource_account,
            TEST_SUCCESS
        );

        // ============= DROP ATOKEN ============== //
        // assert token exists before drop token
        a_token_factory::assert_token_exists_for_testing(a_token_address);

        a_token_factory::drop_token(a_token_address);

        // assert token does not exist after drop token
        a_token_factory::assert_token_exists_for_testing(a_token_address);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_token_address_with_token_not_exist(aave_pool: &signer) {
        a_token_factory::test_init_module(aave_pool);
        a_token_factory::token_address(utf8(b"aDai"));
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1502, location = aave_pool::a_token_factory)]
    fun test_token_address_with_owner_is_same_but_symbol_is_different(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // create a tokens admin account
        account::create_account_for_test(signer::address_of(a_tokens_admin));

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(a_tokens_admin)
        );

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 8;
        let max_supply = 100000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x034;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address,
            treasury_address
        );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let new_symbol = utf8(b"A3");

        a_token_factory::token_address(new_symbol);
    }

    #[
        test(
            aave_pool = @aave_pool,
            a_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1501, location = aave_pool::a_token_factory)]
    fun test_token_address_with_owner_and_symbol_have_two_identical(
        aave_pool: &signer,
        a_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        let a_tokens_admin_address = signer::address_of(a_tokens_admin);
        // create a tokens admin account
        account::create_account_for_test(a_tokens_admin_address);

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        a_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, a_tokens_admin_address);

        let name = utf8(b"TOKEN_1");
        let symbol = utf8(b"T1");
        let decimals = 8;
        let max_supply = 100000000;
        mock_underlying_token_factory::create_token(
            underlying_tokens_admin,
            max_supply,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b"")
        );
        let underlying_asset_address =
            mock_underlying_token_factory::token_address(symbol);

        // init the incentives controller
        rewards_controller::test_initialize(aave_pool, REWARDS_CONTROLLER_NAME);

        // create a_tokens
        let name = utf8(b"TEST_A_TOKEN_2");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x034;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address,
            treasury_address
        );
        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // create a_tokens again
        let name = utf8(b"TEST_A_TOKEN_3");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let treasury_address = @0x044;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let underlying_asset_address = @0x045;
        a_token_factory::create_token(
            a_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address,
            treasury_address
        );

        // check emitted events
        let emitted_events = emitted_events<a_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        a_token_factory::token_address(symbol);
    }
}
