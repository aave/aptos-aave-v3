#[test_only]
module aave_pool::flashloan_validation_tests {

    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aave_config::reserve_config;
    use aave_pool::supply_logic;
    use aave_pool::flashloan_logic;
    use aave_mock_underlyings::mock_underlying_token_factory;
    use aave_pool::pool_configurator;
    use aave_pool::pool;
    use aave_pool::token_helper::{init_reserves, convert_to_currency_decimals};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // test flash loan signer and on_behalf_of no same
    #[expected_failure(abort_code = 1404, location = aave_pool::flashloan_logic)]
    fun test_flash_loan_signer_and_on_behalf_of_no_same(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2],
                signer::address_of(aave_pool),
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // test flash loan invalid interest_rate_mode selected
    #[expected_failure(abort_code = 33, location = aave_pool::flashloan_logic)]
    fun test_flash_loan_invalid_interest_rate_mode_selected(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let user1_address = signer::address_of(usre1);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            supplied_amount,
            user1_address,
            0
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[3],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // test pay flash loan complex flashloan_payer not equal receiver that the flashloan_receipt
    #[expected_failure(abort_code = 1406, location = aave_pool::flashloan_logic)]
    fun test_pay_flash_loan_complex_with_flashloan_payer_not_equal_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let user1_address = signer::address_of(usre1);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                @0x42,
                assets,
                amounts,
                vector[2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // test pay_flash_loan_simple flashloan_payer not equal receiver that the flashloan_receipt
    #[expected_failure(abort_code = 1406, location = aave_pool::flashloan_logic)]
    fun test_pay_flash_loan_simple_with_flashloan_payer_not_equal_receiver(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let user1_address = signer::address_of(usre1);
        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // user1 flashloan 1000 u_1 token from the pool
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                usre1,
                @0x42,
                underlying_u1_token_address,
                convert_to_currency_decimals(underlying_u1_token_address, 1000),
                0
            );

        flashloan_logic::pay_flash_loan_simple(usre1, flashloan_receipt);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with inconsistent params (revert expected)
    #[expected_failure(abort_code = 49, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_inconsistent_flashloan_params(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000, 222];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[0, 2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with duplicate asset params (revert expected)
    #[expected_failure(abort_code = 49, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_duplicate_asset_params(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // mint 1000000000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        let supplied_amount =
            convert_to_currency_decimals(underlying_u1_token_address, 1000);
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            supplied_amount,
            user1_address,
            0
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address, underlying_u1_token_address];
        let amounts = vector[100, 200];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2, 3],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with inactive reserve (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_inactive_reserve(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        reserve_config::set_active(&mut reserve_config_map, false);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with paused reserve (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_paused_reserve(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == false, TEST_SUCCESS);

        // set reserve as paused
        reserve_config::set_paused(&mut reserve_config_map, true);
        pool::test_set_reserve_configuration(
            underlying_u1_token_address, reserve_config_map
        );

        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == true, TEST_SUCCESS);

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with flashloan disabled (revert expected)
    #[expected_failure(abort_code = 91, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_flashloan_disabled(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_flashloan_enabled =
            reserve_config::get_flash_loan_enabled(&reserve_config_map);
        assert!(is_flashloan_enabled == true, TEST_SUCCESS);

        // set flashloan as disabled
        pool_configurator::set_reserve_flash_loaning(
            aave_pool, underlying_u1_token_address, false
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_flashloan_enabled =
            reserve_config::get_flash_loan_enabled(&reserve_config_map);
        assert!(is_flashloan_enabled == false, TEST_SUCCESS);

        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000000000) as u64),
            underlying_u1_token_address
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];

        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // mint 1000 u_1 token to user1
    // User1 deposit 1000 u_1 token to the pool
    // user1 flashloan 10000 u_1 token from the pool
    // validate_flashloan() the total supply of u_1 token in the pool is 1000 < 10000 (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_a_token_total_supply_lt_borrow_amount(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        // mint 1000 u_1 token to user1
        mock_underlying_token_factory::mint(
            underlying_tokens_admin,
            user1_address,
            (convert_to_currency_decimals(underlying_u1_token_address, 1000) as u64),
            underlying_u1_token_address
        );
        // supply 1000 u_1 token to the pool
        supply_logic::supply(
            usre1,
            underlying_u1_token_address,
            convert_to_currency_decimals(underlying_u1_token_address, 1000),
            user1_address,
            0
        );

        // user1 flashloan 10000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amount = convert_to_currency_decimals(underlying_u1_token_address, 10000);
        let amounts = vector[amount];

        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan_simple() with inactive reserve (revert expected)
    #[expected_failure(abort_code = 27, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_simple_with_inactive_reserve(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == true, TEST_SUCCESS);

        // set reserve as not active
        pool_configurator::set_reserve_active(
            aave_pool, underlying_u1_token_address, false
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_active = reserve_config::get_active(&reserve_config_map);
        assert!(is_active == false, TEST_SUCCESS);

        // user1 flashloan 1000 u_1 token from the pool
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                usre1,
                user1_address,
                underlying_u1_token_address,
                convert_to_currency_decimals(underlying_u1_token_address, 1000),
                0
            );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(usre1, flashloan_receipt);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan_simple() with paused reserve (revert expected)
    #[expected_failure(abort_code = 29, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_simple_with_paused_reserve(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == false, TEST_SUCCESS);

        // set reserve as paused
        pool_configurator::set_reserve_pause(
            aave_pool,
            underlying_u1_token_address,
            true,
            0
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_paused = reserve_config::get_paused(&reserve_config_map);
        assert!(is_paused == true, TEST_SUCCESS);

        // user1 flashloan 1000 u_1 token from the pool
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                usre1,
                user1_address,
                underlying_u1_token_address,
                convert_to_currency_decimals(underlying_u1_token_address, 1000),
                0
            );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(usre1, flashloan_receipt);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan_simple() with flashloan disabled (revert expected)
    #[expected_failure(abort_code = 91, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_simple_with_flashloan_disabled(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));
        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_flashloan_enabled =
            reserve_config::get_flash_loan_enabled(&reserve_config_map);
        assert!(is_flashloan_enabled == true, TEST_SUCCESS);

        // set flashloan as disabled
        pool_configurator::set_reserve_flash_loaning(
            aave_pool, underlying_u1_token_address, false
        );

        let reserve_config_map =
            pool::get_reserve_configuration(underlying_u1_token_address);
        let is_flashloan_enabled =
            reserve_config::get_flash_loan_enabled(&reserve_config_map);
        assert!(is_flashloan_enabled == false, TEST_SUCCESS);

        let user1_address = signer::address_of(usre1);

        // user1 flashloan 1000 u_1 token from the pool
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                usre1,
                user1_address,
                underlying_u1_token_address,
                convert_to_currency_decimals(underlying_u1_token_address, 1000),
                0
            );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(usre1, flashloan_receipt);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with assets are empty (revert expected)
    #[expected_failure(abort_code = 49, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_assets_are_empty(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[];
        let amounts = vector[];
        let interest_rate_modes = vector[];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                interest_rate_modes,
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with The number of assets exceeds the maximum limit
    #[expected_failure(abort_code = 49, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_assets_exceeds_maximum_limit(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[1000];
        let interest_rate_modes = vector[2];
        for (i in 0..reserve_config::get_max_reserves_count()) {
            vector::push_back(&mut assets, underlying_u1_token_address);
            vector::push_back(&mut amounts, 1000);
            vector::push_back(&mut interest_rate_modes, 2);
        };

        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                vector[0, 2],
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan() with amount is zero (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_with_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);

        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        // user1 flashloan 1000 u_1 token from the pool
        let assets = vector[underlying_u1_token_address];
        let amounts = vector[0];
        let interest_rate_modes = vector[2];
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                usre1,
                user1_address,
                assets,
                amounts,
                interest_rate_modes,
                user1_address,
                0
            );

        flashloan_logic::pay_flash_loan_complex(usre1, flashloan_receipts);
    }

    #[
        test(
            aave_pool = @aave_pool,
            aave_role_super_admin = @aave_acl,
            aave_std = @std,
            underlying_tokens_admin = @aave_mock_underlyings,
            usre1 = @0x41
        )
    ]
    // validate_flashloan_simple() with amount is zero (revert expected)
    #[expected_failure(abort_code = 26, location = aave_pool::validation_logic)]
    fun test_validate_flashloan_simple_with_amount_is_zero(
        aave_pool: &signer,
        aave_role_super_admin: &signer,
        aave_std: &signer,
        underlying_tokens_admin: &signer,
        usre1: &signer
    ) {
        let user1_address = signer::address_of(usre1);
        init_reserves(
            aave_pool,
            aave_role_super_admin,
            aave_std,
            underlying_tokens_admin
        );

        let underlying_u1_token_address =
            mock_underlying_token_factory::token_address(utf8(b"U_1"));

        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                usre1,
                user1_address,
                underlying_u1_token_address,
                0,
                0
            );

        // ----> flashloan user repays flashloan + premium
        flashloan_logic::pay_flash_loan_simple(usre1, flashloan_receipt);
    }
}
