#[test_only]
module aave_pool::variable_debt_token_factory_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option;
    use std::signer::Self;
    use std::string::utf8;
    use std::vector::Self;
    use aptos_framework::event::emitted_events;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Self;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aave_acl::acl_manage::Self;
    use aave_math::wad_ray_math;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::rewards_controller;
    use aave_pool::token_base::{Burn, Mint, Transfer};
    use aave_pool::variable_debt_token_factory::Self;

    const REWARDS_CONTROLLER_NAME: vector<u8> = b"REWARDS_CONTROLLER_FOR_TESTING";

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[test(aave_pool = @aave_pool, variable_tokens_admin = @aave_pool, aave_acl = @aave_acl)]
    fun test_variable_token_initialization(
        aave_pool: &signer, variable_tokens_admin: &signer, aave_acl: &signer
    ) {
        // init debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        let variable_tokens_admin_address = signer::address_of(variable_tokens_admin);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, variable_tokens_admin_address);

        // create variable tokens
        let name = utf8(b"TEST_VAR_TOKEN_1");
        let symbol = utf8(b"VAR1");
        let decimals = 6;
        let underlying_asset_address = @0x033;
        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::none(),
            underlying_asset_address
        );
        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
        let variable_token_address = variable_debt_token_factory::token_address(symbol);
        let variable_token_metadata = variable_debt_token_factory::asset_metadata(
            symbol
        );
        assert!(
            object::address_to_object<Metadata>(variable_token_address)
                == variable_token_metadata,
            TEST_SUCCESS
        );

        assert!(
            variable_debt_token_factory::get_underlying_asset_address(
                variable_token_address
            ) == underlying_asset_address,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::get_previous_index(
                variable_tokens_admin_address, variable_token_address
            ) == 0,
            TEST_SUCCESS
        );
        let (user_scaled_balance, scaled_total_supply) =
            variable_debt_token_factory::get_scaled_user_balance_and_supply(
                variable_tokens_admin_address, variable_token_address
            );
        assert!(user_scaled_balance == 0, TEST_SUCCESS);
        assert!(scaled_total_supply == 0, TEST_SUCCESS);

        assert!(
            variable_debt_token_factory::scaled_balance_of(
                variable_tokens_admin_address, variable_token_address
            ) == 0,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::scaled_total_supply(variable_token_address)
                == 0,
            TEST_SUCCESS
        );

        assert!(
            variable_debt_token_factory::balance_of(
                variable_tokens_admin_address, variable_token_address
            ) == 0,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::total_supply(variable_token_address) == 0,
            TEST_SUCCESS
        );

        assert!(
            variable_debt_token_factory::decimals(variable_token_address) == decimals,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::symbol(variable_token_address) == symbol,
            TEST_SUCCESS
        );
        assert!(
            variable_debt_token_factory::name(variable_token_address) == name,
            TEST_SUCCESS
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            variable_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            token_receiver = @0x42
        )
    ]
    fun test_variable_token_mint_burn(
        aave_pool: &signer,
        variable_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        token_receiver: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(variable_tokens_admin)
        );

        // create var tokens
        let name = utf8(b"TEST_VAR_TOKEN_1");
        let symbol = utf8(b"VAR1");
        let decimals = 6;
        let underlying_asset_address = @0x033;
        let var_token_address =
            variable_debt_token_factory::create_token(
                variable_tokens_admin,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address
            );
        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // ============= MINT ============== //
        let amount_to_mint: u256 = 100;
        let reserve_index: u256 = 1 * wad_ray_math::ray();
        let amount_to_mint_scaled = wad_ray_math::ray_div(amount_to_mint, reserve_index);

        variable_debt_token_factory::mint(
            signer::address_of(token_receiver),
            signer::address_of(token_receiver),
            amount_to_mint,
            reserve_index,
            var_token_address
        );

        // assert a token supply
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == amount_to_mint_scaled,
            TEST_SUCCESS
        );

        // assert var_tokens receiver balance
        let var_token_amount_scaled = wad_ray_math::ray_div(
            amount_to_mint, reserve_index
        );
        assert!(
            variable_debt_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), var_token_address
            ) == var_token_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 1, TEST_SUCCESS);
        let emitted_mint_events = emitted_events<Mint>();
        assert!(vector::length(&emitted_mint_events) == 1, TEST_SUCCESS);

        // ============= BURN ============== //
        // now burn the variable tokens
        let amount_to_burn = amount_to_mint / 2;
        variable_debt_token_factory::burn(
            signer::address_of(token_receiver),
            amount_to_burn,
            reserve_index,
            var_token_address
        );

        // assert var token supply
        let expected_var_token_scaled_total_supply =
            wad_ray_math::ray_div(amount_to_mint - amount_to_burn, reserve_index);
        assert!(
            variable_debt_token_factory::scaled_total_supply(var_token_address)
                == expected_var_token_scaled_total_supply,
            TEST_SUCCESS
        );

        // assert var_tokens receiver balance
        let var_token_amount_scaled = wad_ray_math::ray_div(
            amount_to_burn, reserve_index
        );
        assert!(
            variable_debt_token_factory::scaled_balance_of(
                signer::address_of(token_receiver), var_token_address
            ) == var_token_amount_scaled,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_transfer_events = emitted_events<Transfer>();
        assert!(vector::length(&emitted_transfer_events) == 2, TEST_SUCCESS);
        let emitted_burn_events = emitted_events<Burn>();
        assert!(vector::length(&emitted_burn_events) == 1, TEST_SUCCESS);
    }

    //  =======================  Test exceptions  =======================
    #[test(user1 = @0x41)]
    #[expected_failure(abort_code = 1401, location = aave_pool::token_base)]
    fun test_init_module_with_not_pool_owner(user1: &signer) {
        variable_debt_token_factory::test_init_module(user1);
    }

    #[test(aave_pool = @aave_pool)]
    #[expected_failure(abort_code = 1502, location = aave_pool::variable_debt_token_factory)]
    fun test_assert_token_exists_with_token_not_exist(
        aave_pool: &signer
    ) {
        variable_debt_token_factory::test_init_module(aave_pool);
        variable_debt_token_factory::assert_token_exists_for_testing(@0x41);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            user1 = @0x41
        )
    ]
    #[expected_failure(abort_code = 5, location = aave_pool::variable_debt_token_factory)]
    fun test_create_token_with_caller_not_asset_listing_or_pool_admin(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        user1: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init variable debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        // init acl module
        acl_manage::test_init_module(aave_acl);

        let user1_address = signer::address_of(user1);
        if (acl_manage::is_asset_listing_admin(user1_address)) {
            acl_manage::remove_asset_listing_admin(aave_acl, user1_address);
        };
        if (acl_manage::is_pool_admin(user1_address)) {
            acl_manage::remove_pool_admin(aave_acl, user1_address);
        };

        // create variable debt token
        let name = utf8(b"TEST_V_TOKEN_6");
        let symbol = utf8(b"V6");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        variable_debt_token_factory::create_token(
            user1,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::none(),
            underlying_asset_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            caller = @0x41
        )
    ]
    #[expected_failure(abort_code = 1209, location = aave_pool::variable_debt_token_factory)]
    fun test_mint_when_caller_equal_on_behalf_of(
        aave_pool: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        caller: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        // init variable debt token
        variable_debt_token_factory::test_init_module(aave_pool);

        // init acl module
        acl_manage::test_init_module(aave_acl);

        let caller_address = signer::address_of(caller);
        // add pool admin for caller
        acl_manage::add_pool_admin(aave_acl, caller_address);

        // create variable debt token
        let name = utf8(b"TEST_V_TOKEN_6");
        let symbol = utf8(b"V6");
        let decimals = 3;
        let underlying_asset_address = @0x033;
        let var_token_address =
            variable_debt_token_factory::create_token(
                caller,
                name,
                symbol,
                decimals,
                utf8(b""),
                utf8(b""),
                option::none(),
                underlying_asset_address
            );

        let on_behalf_of = @0x42;
        variable_debt_token_factory::mint(
            caller_address,
            on_behalf_of,
            1000000,
            1 * wad_ray_math::ray(),
            var_token_address
        );
    }

    #[
        test(
            aave_pool = @aave_pool,
            variable_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1502, location = aave_pool::variable_debt_token_factory)]
    fun test_token_address_with_owner_is_same_but_symbol_is_different(
        aave_pool: &signer,
        variable_tokens_admin: &signer,
        aave_acl: &signer,
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

        // init a token
        variable_debt_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(
            aave_acl, signer::address_of(variable_tokens_admin)
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
        let name = utf8(b"TEST_V_TOKEN_2");
        let symbol = utf8(b"V2");
        let decimals = 8;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address
        );

        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        let new_symbol = utf8(b"A3");

        variable_debt_token_factory::token_address(new_symbol);
    }

    #[
        test(
            aave_pool = @aave_pool,
            variable_tokens_admin = @aave_pool,
            aave_acl = @aave_acl,
            aave_std = @std,
            aptos_framework = @0x1,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    #[expected_failure(abort_code = 1501, location = aave_pool::variable_debt_token_factory)]
    fun test_token_address_with_owner_and_symbol_have_two_identical(
        aave_pool: &signer,
        variable_tokens_admin: &signer,
        aave_acl: &signer,
        aave_std: &signer,
        aptos_framework: &signer,
        underlying_tokens_admin: &signer
    ) {
        // start the timer
        set_time_has_started_for_testing(aptos_framework);

        // add the test events feature flag
        change_feature_flags_for_testing(aave_std, vector[26], vector[]);

        let variable_tokens_admin_address = signer::address_of(variable_tokens_admin);

        // init mock underlying token factory module
        mock_underlying_token_factory::test_init_module(underlying_tokens_admin);

        // init a token
        variable_debt_token_factory::test_init_module(aave_pool);

        // set asset listing admin
        acl_manage::test_init_module(aave_acl);
        acl_manage::add_asset_listing_admin(aave_acl, variable_tokens_admin_address);

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
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);

        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address
        );
        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);

        // create a_tokens again
        let name = utf8(b"TEST_A_TOKEN_3");
        let symbol = utf8(b"A2");
        let decimals = 8;
        let incentives_controller_address =
            rewards_controller::rewards_controller_address(REWARDS_CONTROLLER_NAME);
        let underlying_asset_address = @0x045;
        variable_debt_token_factory::create_token(
            variable_tokens_admin,
            name,
            symbol,
            decimals,
            utf8(b""),
            utf8(b""),
            option::some(incentives_controller_address),
            underlying_asset_address
        );

        // check emitted events
        let emitted_events = emitted_events<variable_debt_token_factory::Initialized>();
        // make sure event of type was emitted
        assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);

        variable_debt_token_factory::token_address(symbol);
    }
}
