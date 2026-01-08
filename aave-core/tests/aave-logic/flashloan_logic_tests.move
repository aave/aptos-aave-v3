#[test_only]
module aave_pool::flashloan_logic_tests {
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp;
    use aave_acl::acl_manage;
    use aave_config::user_config;
    use aave_math::math_utils;
    use aave_math::math_utils::get_percentage_factor;
    use aave_math::wad_ray_math;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::borrow_logic;
    use aave_pool::token_helper::{
        init_reserves_with_oracle,
        convert_to_currency_decimals
    };
    use aave_pool::token_helper;
    use aave_pool::a_token_factory::Self;
    use aave_pool::flashloan_logic::{
        Self,
        get_complex_flashloan_receipt_sender,
        get_complex_flashloan_receipt_receiver,
        get_complex_flashloan_receipt_index,
        get_complex_flashloan_current_asset,
        get_complex_flashloan_current_amount,
        get_complex_flashloan_total_premium,
        get_complex_flashloan_premium_total,
        get_complex_flashloan_premium_to_protocol,
        get_complex_flashloan_referral_code,
        get_complex_flashloan_interest_rate_mode,
        get_complex_flashloan_on_behalf_of,
        get_simple_flashloan_receipt_sender,
        get_simple_flashloan_receipt_receiver,
        get_simple_flashloan_receipt_index,
        get_simple_flashloan_current_amount,
        get_simple_flashloan_total_premium,
        get_simple_flashloan_premium_total,
        get_simple_flashloan_premium_to_protocol,
        get_simple_flashloan_referral_code,
        get_simple_flashloan_on_behalf_of,
        get_simple_flashloan_current_asset
    };
    use aave_mock_underlyings::mock_underlying_token_factory::Self;
    use aave_pool::pool;
    use aave_pool::pool_tests::create_user_config_for_reserve;
    use aave_pool::supply_logic::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// User takes and repays a single asset flashloan
    fun simple_flashloan_same_payer_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
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

        let flashloan_user_address = signer::address_of(flashloan_user);
        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            flashloan_user_address,
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = flashloan_user_address;
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

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = flashloan_user_address;
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
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

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                flashloan_user,
                flashloan_user_address,
                underlying_token_address,
                (flashloan_amount as u256),
                0 // referral code
            );

        // check getter
        assert!(
            get_simple_flashloan_receipt_sender(&flashloan_receipt)
                == flashloan_user_address,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_receipt_receiver(&flashloan_receipt)
                == flashloan_user_address,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_receipt_index(&flashloan_receipt) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_current_asset(&flashloan_receipt)
                == underlying_token_address,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_current_amount(&flashloan_receipt)
                == (flashloan_amount as u256),
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_total_premium(&flashloan_receipt)
                == math_utils::percent_mul(
                    (flashloan_amount as u256), flashloan_premium_total
                ),
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_premium_total(&flashloan_receipt)
                == flashloan_premium_total,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_premium_to_protocol(&flashloan_receipt)
                == flashloan_premium_to_protocol,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_referral_code(&flashloan_receipt) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_simple_flashloan_on_behalf_of(&flashloan_receipt)
                == flashloan_user_address,
            TEST_SUCCESS
        );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(flashloan_user, flashloan_receipt);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @std,
            flashloan_payer = @0x042,
            flashloan_receiver = @0x043,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// User takes a flashloan which is received by someone else. Either user or taker then repays a single asset flashloan
    fun simple_flashloan_different_payer_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_payer: &signer,
        flashloan_receiver: &signer,
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

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user configs for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_payer),
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        create_user_config_for_reserve(
            signer::address_of(flashloan_receiver),
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for flashloan payer and receiver
        // mint 100 underlying tokens for flashloan payer and receiver
        let mint_amount: u64 = 100;
        let users = vector[
            signer::address_of(flashloan_payer),
            signer::address_of(flashloan_receiver)
        ];
        for (i in 0..vector::length(&users)) {
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                *vector::borrow(&users, i),
                mint_amount,
                underlying_token_address
            );
            let initial_user_balance =
                mock_underlying_token_factory::balance_of(
                    *vector::borrow(&users, i), underlying_token_address
                );
            // assert user balance of underlying
            assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
        };

        // ----> flashloan payer supplies
        // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_payer);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_payer,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check flashloan payer balance of underlying
        let initial_payer_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            initial_payer_balance == mint_amount - supplied_amount, TEST_SUCCESS
        );
        // > check flashloan payer a_token balance after supply
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(flashloan_payer), a_token_address
            );
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (pool::get_reserve_liquidity_index(reserve_data) as u256)
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        let initial_receiver_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );

        // ----> flashloan payer takes a flashloan but receiver is different
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                flashloan_payer,
                signer::address_of(flashloan_receiver), // now the receiver expects to receive the flashloan
                underlying_token_address,
                (flashloan_amount as u256),
                0 // referral code
            );

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance,
            TEST_SUCCESS
        ); // same balance as before

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance + flashloan_amount,
            TEST_SUCCESS
        ); // increased balance due to flashloan

        // ----> receiver repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(flashloan_receiver, flashloan_receipt);

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance,
            TEST_SUCCESS
        );

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// User takes and repays a single asset flashloan
    fun complex_flashloan_same_payer_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
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

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_user),
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = signer::address_of(flashloan_user);
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

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_user);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
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

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_user,
                signer::address_of(flashloan_user),
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                signer::address_of(flashloan_user),
                0 // referral code
            );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_user), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// User takes and repays a single asset flashloan being authorized
    fun complex_flashloan_same_payer_receiver_authorized(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
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

        let flashloan_user_address = signer::address_of(flashloan_user);
        // add flashloan borrower for flashloan_user
        acl_manage::add_flash_borrower(aave_role_super_admin, flashloan_user_address);

        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            flashloan_user_address,
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_receiver_address = flashloan_user_address;
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

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = flashloan_user_address;
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
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

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_user,
                flashloan_user_address,
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                flashloan_user_address,
                0 // referral code
            );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        let flashloan_paid_premium = 0; // because the user is authorized flash borrower
        assert!(
            flashloan_taken_underlying_balance
                == supplier_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @std,
            flashloan_payer = @0x042,
            flashloan_receiver = @0x043,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// User takes a complex flashloan which is received by someone else. Either user or taker then repays the complex flashloan
    fun complex_flashloan_different_payer_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_payer: &signer,
        flashloan_receiver: &signer,
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

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user configs for reserve index
        create_user_config_for_reserve(
            signer::address_of(flashloan_payer),
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        create_user_config_for_reserve(
            signer::address_of(flashloan_receiver),
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for flashloan payer and receiver
        // mint 100 underlying tokens for flashloan payer and receiver
        let mint_amount: u64 = 100;
        let users = vector[
            signer::address_of(flashloan_payer),
            signer::address_of(flashloan_receiver)
        ];
        for (i in 0..vector::length(&users)) {
            mock_underlying_token_factory::mint(
                underlying_tokens_admin,
                *vector::borrow(&users, i),
                mint_amount,
                underlying_token_address
            );
            let initial_user_balance =
                mock_underlying_token_factory::balance_of(
                    *vector::borrow(&users, i), underlying_token_address
                );
            // assert user balance of underlying
            assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
        };

        // ----> flashloan payer supplies
        // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
        let supply_receiver_address = signer::address_of(flashloan_payer);
        let supplied_amount: u64 = 50;
        supply_logic::supply(
            flashloan_payer,
            underlying_token_address,
            (supplied_amount as u256),
            supply_receiver_address,
            0
        );

        // > check flashloan payer balance of underlying
        let initial_payer_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            initial_payer_balance == mint_amount - supplied_amount, TEST_SUCCESS
        );
        // > check flashloan payer a_token balance after supply
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let supplier_a_token_balance =
            a_token_factory::scaled_balance_of(
                signer::address_of(flashloan_payer), a_token_address
            );
        let supplied_amount_scaled =
            wad_ray_math::ray_div(
                (supplied_amount as u256),
                (pool::get_reserve_liquidity_index(reserve_data) as u256)
            );
        assert!(supplier_a_token_balance == supplied_amount_scaled, TEST_SUCCESS);

        let initial_receiver_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );

        // ----> flashloan payer takes a flashloan but receiver is different
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_payer,
                signer::address_of(flashloan_receiver),
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_none()], // interest rate modes
                signer::address_of(flashloan_payer), // on behalf of
                0 // referral code
            );

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance,
            TEST_SUCCESS
        ); // same balance as before

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance + flashloan_amount,
            TEST_SUCCESS
        ); // increased balance due to flashloan

        // ----> receiver repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_receiver, flashloan_receipts);

        // check intermediate underlying balance for flashloan payer
        let flashloan_payer_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_payer), underlying_token_address
            );
        assert!(
            flashloan_payer_underlying_balance == initial_payer_balance,
            TEST_SUCCESS
        );

        // check intermediate underlying balance for flashloan receiver
        let flashloan_receiver_underlying_balance =
            mock_underlying_token_factory::balance_of(
                signer::address_of(flashloan_receiver), underlying_token_address
            );
        let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
        assert!(
            flashloan_receiver_underlying_balance
                == initial_receiver_balance - flashloan_paid_premium,
            TEST_SUCCESS
        );

        // check emitted events
        let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_oracle = @aave_oracle,
            data_feeds = @data_feeds,
            platform = @platform,
            aptos_std = @aptos_std,
            flashloan_user = @0x042,
            underlying_tokens_admin = @aave_mock_underlyings
        )
    ]
    /// Borrowing with a variable rate
    fun complex_flashloan_by_borrowing_with_variable_rate(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_oracle: &signer,
        data_feeds: &signer,
        platform: &signer,
        aptos_std: &signer,
        flashloan_user: &signer,
        underlying_tokens_admin: &signer
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

        let flashloan_user_address = signer::address_of(flashloan_user);
        // get one underlying asset data
        let underlying_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_0"));

        // mint 10 APT to the flashloan_user_address
        aptos_framework::aptos_coin_tests::mint_apt_fa_to_primary_fungible_store_for_test(
            flashloan_user_address, 1_000_000_000
        );

        // set asset price for U_0
        token_helper::set_asset_price(
            aave_role_super_admin,
            aave_oracle,
            underlying_token_address,
            10
        );

        // get the reserve config for it
        let reserve_data = pool::get_reserve_data(underlying_token_address);

        // set flashloan premium
        let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
        let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
        pool::set_flashloan_premiums_test(
            (flashloan_premium_total as u128),
            (flashloan_premium_to_protocol as u128)
        );

        // init user config for reserve index
        create_user_config_for_reserve(
            flashloan_user_address,
            (pool::get_reserve_id(reserve_data) as u256),
            option::some(false),
            option::some(true)
        );

        // ----> mint underlying for the flashloan user
        // mint 100 underlying tokens for the flashloan user
        let mint_amount =
            (convert_to_currency_decimals(underlying_token_address, 100) as u64);
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            flashloan_user_address,
            mint_amount,
            underlying_token_address
        );
        let initial_user_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        // assert user balance of underlying
        assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
        // assert underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some((mint_amount as u128)),
            TEST_SUCCESS
        );

        // ----> flashloan user supplies
        // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
        // flashloan_user supplies 50 underlying tokens
        let supplied_amount: u64 =
            (convert_to_currency_decimals(underlying_token_address, 50) as u64);
        supply_logic::supply(
            flashloan_user,
            underlying_token_address,
            (supplied_amount as u256),
            flashloan_user_address,
            0
        );

        // > check emitted events
        let emitted_supply_events = emitted_events<supply_logic::Supply>();
        assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);

        // > check flashloan user (supplier) balance of underlying
        let supplier_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            supplier_balance == initial_user_balance - supplied_amount,
            TEST_SUCCESS
        );
        // > check underlying supply
        assert!(
            mock_underlying_token_factory::supply(underlying_token_address)
                == option::some((mint_amount as u128)),
            TEST_SUCCESS
        );
        // set global time
        timestamp::update_global_time_for_test_secs(1000);

        // ----> flashloan user takes a flashloan
        let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                flashloan_user,
                flashloan_user_address,
                vector[underlying_token_address],
                vector[(flashloan_amount as u256)],
                vector[user_config::get_interest_rate_mode_variable()], // interest rate modes
                flashloan_user_address,
                0 // referral code
            );

        // check getter
        let flashloan_frist_receipts = vector::borrow(&flashloan_receipts, 0);
        assert!(
            get_complex_flashloan_receipt_sender(flashloan_frist_receipts)
                == flashloan_user_address,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_receipt_receiver(flashloan_frist_receipts)
                == flashloan_user_address,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_receipt_index(flashloan_frist_receipts) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_current_asset(flashloan_frist_receipts)
                == underlying_token_address,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_current_amount(flashloan_frist_receipts)
                == (flashloan_amount as u256),
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_total_premium(flashloan_frist_receipts) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_premium_total(flashloan_frist_receipts)
                == flashloan_premium_total,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_premium_to_protocol(flashloan_frist_receipts)
                == flashloan_premium_to_protocol,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_referral_code(flashloan_frist_receipts) == 0,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_interest_rate_mode(flashloan_frist_receipts) == 2,
            TEST_SUCCESS
        );
        assert!(
            get_complex_flashloan_on_behalf_of(flashloan_frist_receipts)
                == flashloan_user_address,
            TEST_SUCCESS
        );

        // check intermediate underlying balance
        let flashloan_taker_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );
        assert!(
            flashloan_taker_underlying_balance == supplier_balance + flashloan_amount,
            TEST_SUCCESS
        );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts);

        // check emitted events
        let emitted_borrow_events = emitted_events<borrow_logic::Borrow>();
        assert!(vector::length(&emitted_borrow_events) == 1, TEST_SUCCESS);

        let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
        assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);

        // check intermediate underlying balance for flashloan user
        let flashloan_taken_underlying_balance =
            mock_underlying_token_factory::balance_of(
                flashloan_user_address, underlying_token_address
            );

        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let a_token_balance =
            a_token_factory::scaled_balance_of(flashloan_user_address, a_token_address);
        let variable_debt_token_balance =
            variable_debt_token_factory::scaled_balance_of(
                flashloan_user_address, variable_debt_token_address
            );
        assert!(
            (flashloan_taken_underlying_balance as u256)
                == a_token_balance + variable_debt_token_balance,
            TEST_SUCCESS
        );
    }
}
