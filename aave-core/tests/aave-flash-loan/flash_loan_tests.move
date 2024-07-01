#[test_only]
module aave_pool::flashloan_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aptos_framework::account;
    use aave_acl::acl_manage::{Self, test_init_module};
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle::test_init_oracle;
    use aave_pool::default_reserve_interest_rate_strategy::Self;
    use aave_pool::pool_configurator::test_init_module as pool_config_init_reserves;
    use aave_pool::pool_tests::{create_reserve_with_config, create_user_config_for_reserve};
    use aave_pool::a_token_factory::Self;
    use aave_pool::token_base::Self;
    use aave_pool::underlying_token_factory::Self;
    use aave_pool::variable_token_factory::Self;
    use aave_pool::supply_logic::Self;
    use aave_pool::flashloan_logic::{Self};
    use aave_math::math_utils::get_percentage_factor;
    use aave_config::user as user_config;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, flashloan_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
    // /// User takes and repays a single asset flashloan
    // fun simple_flashloan_same_payer_receiver(
    //     pool: &signer,
    //     aave_role_super_admin: &signer,
    //     mock_oracle: &signer,
    //     aave_std: &signer,
    //     flashloan_user: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aptos_framework: &signer,
    //     collector_account: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init oracle
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool conigutrator and pool modules
    //     pool_config_init_reserves(pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(pool);
    //     let underlying_token_name = utf8(b"TOKEN_1");
    //     let underlying_token_symbol = utf8(b"T1");
    //     let underlying_token_decimals = 3;
    //     let underlying_token_max_supply = 10000;
    //     underlying_token_factory::create_token(underlying_tokens_admin,
    //         underlying_token_max_supply,
    //         underlying_token_name,
    //         underlying_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),);
    //     let underlying_token_address = underlying_token_factory::token_address(
    //         underlying_token_symbol);
    //
    //     // init token base for tokens
    //     token_base::test_init_module(pool);
    //
    //     // create variable tokens
    //     variable_token_factory::create_token(variable_tokens_admin,
    //         utf8(b"TEST_VAR_TOKEN_1"),
    //         utf8(b"VAR1"),
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         @0x033, // take random
    //     );
    //     let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
    //
    //     //create a tokens
    //     let a_token_symbol = utf8(b"A1");
    //     a_token_factory::create_token(a_tokens_admin,
    //         utf8(b"TEST_A_TOKEN_1"),
    //         a_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         underlying_token_address, // underlying asset address
    //         signer::address_of(collector_account), // treasury address
    //     );
    //     let a_token_address = a_token_factory::token_address(utf8(b"A1"));
    //
    //     // init and add a single reserve to the pool
    //     let reserve_index =
    //         create_reserve_with_config((underlying_token_decimals as u256),
    //             a_token_address,
    //             variable_token_address,
    //             underlying_token_address,
    //             option::none(), // ltv
    //             option::none(), // liq threshold
    //             option::none(), // liq bonus
    //             option::some((underlying_token_decimals as u256)), //decimals
    //             option::some(true), //active
    //             option::some(false), //frozen
    //             option::some(false), // paused
    //             option::some(true), // borrowable_in_isolation
    //             option::some(true), // siloed_borrowing
    //             option::some(true), // borrowing_enabled
    //             option::none(), // reserve_factor*
    //             option::none(), // borrow_cap
    //             option::none(), // supply_cap
    //             option::none(), // debt_ceiling
    //             option::none(), // liquidation_protocol_fee
    //             option::none(), // unbacked_mint_cap
    //             option::some((0 as u256)), // e_mode_category
    //             option::some(true), // flash_loan_enabled
    //         );
    //
    //     // init the default interest rate strategy for the underlying_token_address
    //     let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
    //     let base_variable_borrow_rate: u256 = 0;
    //     let variable_rate_slope1: u256 = 0;
    //     let variable_rate_slope2: u256 = 0;
    //     default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
    //         underlying_token_address,
    //         optimal_usage_ratio,
    //         base_variable_borrow_rate,
    //         variable_rate_slope1,
    //         variable_rate_slope2,);
    //
    //     // init user config for reserve index
    //     create_user_config_for_reserve(signer::address_of(flashloan_user), reserve_index,
    //         option::some(false), option::some(true));
    //
    //     // ----> mint underlying for the flashloan user
    //     // mint 100 underlying tokens for the flashloan user
    //     let mint_receiver_address = signer::address_of(flashloan_user);
    //     underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
    //         underlying_token_address);
    //     let initial_user_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     // assert user balance of underlying
    //     assert!(initial_user_balance == 100, TEST_SUCCESS);
    //     // assert underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user supplies
    //     // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
    //     let supply_receiver_address = signer::address_of(flashloan_user);
    //     let supplied_amount: u64 = 50;
    //     supply_logic::supply(flashloan_user,
    //         underlying_token_address,
    //         (supplied_amount as u256),
    //         supply_receiver_address,
    //         0);
    //
    //     // > check emitted events
    //     let emitted_supply_events = emitted_events<supply_logic::Supply>();
    //     assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
    //
    //     // > check flashloan user (supplier) balance of underlying
    //     let supplier_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
    //     // > check underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user takes a flashloan
    //     let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
    //     let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
    //     let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
    //     let flashloan_receipt =
    //         flashloan_logic::flash_loan_simple(flashloan_user,
    //             signer::address_of(flashloan_user),
    //             underlying_token_address,
    //             (flashloan_amount as u256),
    //             0, // referal code
    //             );
    //
    //     // check intermediate underlying balance
    //     let flashloan_taker_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     assert!(flashloan_taker_underlying_balance
    //         == supplier_balance + flashloan_amount, TEST_SUCCESS);
    //
    //     // ----> flashloan user repays flashloan + premium
    //     flashloan_logic::pay_flash_loan_simple(flashloan_user, flashloan_receipt,);
    //
    //     // check intermediate underlying balance for flashloan user
    //     let flashloan_taken_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
    //     assert!(flashloan_taken_underlying_balance
    //         == supplier_balance - flashloan_paid_premium, TEST_SUCCESS);
    //
    //     // check emitted events
    //     let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
    //     assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, flashloan_payer = @0x042, flashloan_receiver = @0x043, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
    // /// User takes a flashloan which is received by someone else. Either user or taker then repays a single asset flashloan
    // fun simple_flashloan_different_payer_receiver(
    //     pool: &signer,
    //     aave_role_super_admin: &signer,
    //     mock_oracle: &signer,
    //     aave_std: &signer,
    //     flashloan_payer: &signer,
    //     flashloan_receiver: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aptos_framework: &signer,
    //     collector_account: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init oracle
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool conigutrator and pool modules
    //     pool_config_init_reserves(pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(pool);
    //     let underlying_token_name = utf8(b"TOKEN_1");
    //     let underlying_token_symbol = utf8(b"T1");
    //     let underlying_token_decimals = 3;
    //     let underlying_token_max_supply = 10000;
    //     underlying_token_factory::create_token(underlying_tokens_admin,
    //         underlying_token_max_supply,
    //         underlying_token_name,
    //         underlying_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),);
    //     let underlying_token_address = underlying_token_factory::token_address(
    //         underlying_token_symbol);
    //
    //     // init token base for tokens
    //     token_base::test_init_module(pool);
    //
    //     // create variable tokens
    //     variable_token_factory::create_token(variable_tokens_admin,
    //         utf8(b"TEST_VAR_TOKEN_1"),
    //         utf8(b"VAR1"),
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         @0x033, // take random
    //     );
    //     let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
    //
    //     //create a tokens
    //     let a_token_symbol = utf8(b"A1");
    //     a_token_factory::create_token(a_tokens_admin,
    //         utf8(b"TEST_A_TOKEN_1"),
    //         a_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         underlying_token_address, // underlying asset address
    //         signer::address_of(collector_account), // treasury address
    //     );
    //     let a_token_address = a_token_factory::token_address(utf8(b"A1"));
    //
    //     // init and add a single reserve to the pool
    //     let reserve_index =
    //         create_reserve_with_config((underlying_token_decimals as u256),
    //             a_token_address,
    //             variable_token_address,
    //             underlying_token_address,
    //             option::none(), // ltv
    //             option::none(), // liq threshold
    //             option::none(), // liq bonus
    //             option::some((underlying_token_decimals as u256)), //decimals
    //             option::some(true), //active
    //             option::some(false), //frozen
    //             option::some(false), // paused
    //             option::some(true), // borrowable_in_isolation
    //             option::some(true), // siloed_borrowing
    //             option::some(true), // borrowing_enabled
    //             option::none(), // reserve_factor*
    //             option::none(), // borrow_cap
    //             option::none(), // supply_cap
    //             option::none(), // debt_ceiling
    //             option::none(), // liquidation_protocol_fee
    //             option::none(), // unbacked_mint_cap
    //             option::some((0 as u256)), // e_mode_category
    //             option::some(true), // flash_loan_enabled
    //         );
    //
    //     // init the default interest rate strategy for the underlying_token_address
    //     let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
    //     let base_variable_borrow_rate: u256 = 0;
    //     let variable_rate_slope1: u256 = 0;
    //     let variable_rate_slope2: u256 = 0;
    //     default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
    //         underlying_token_address,
    //         optimal_usage_ratio,
    //         base_variable_borrow_rate,
    //         variable_rate_slope1,
    //         variable_rate_slope2,);
    //
    //     // init user configs for reserve index
    //     create_user_config_for_reserve(signer::address_of(flashloan_payer), reserve_index,
    //         option::some(false), option::some(true));
    //
    //     create_user_config_for_reserve(signer::address_of(flashloan_receiver),
    //         reserve_index,
    //         option::some(false),
    //         option::some(true));
    //
    //     // ----> mint underlying for flashloan payer and receiver
    //     // mint 100 underlying tokens for flashloan payer and receiver
    //     let mint_amount: u64 = 100;
    //     let users = vector[
    //         signer::address_of(flashloan_payer),
    //         signer::address_of(flashloan_receiver)];
    //     for (i in 0..vector::length(&users)) {
    //         underlying_token_factory::mint(underlying_tokens_admin,
    //             *vector::borrow(&users, i),
    //             mint_amount,
    //             underlying_token_address);
    //         let initial_user_balance =
    //             underlying_token_factory::balance_of(*vector::borrow(&users, i),
    //                 underlying_token_address);
    //         // assert user balance of underlying
    //         assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
    //     };
    //
    //     // ----> flashloan payer supplies
    //     // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
    //     let supply_receiver_address = signer::address_of(flashloan_payer);
    //     let supplied_amount: u64 = 50;
    //     supply_logic::supply(flashloan_payer,
    //         underlying_token_address,
    //         (supplied_amount as u256),
    //         supply_receiver_address,
    //         0);
    //
    //     // > check flashloan payer balance of underlying
    //     let initial_payer_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(initial_payer_balance == mint_amount - supplied_amount, TEST_SUCCESS);
    //     // > check flashloan payer a_token balance after supply
    //     let supplier_a_token_balance =
    //         a_token_factory::balance_of(signer::address_of(flashloan_payer), a_token_address);
    //     assert!(supplier_a_token_balance == (supplied_amount as u256), TEST_SUCCESS);
    //
    //     let initial_receiver_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //
    //     // ----> flashloan payer takes a flashloan but receiver is different
    //     let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
    //     let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
    //     let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
    //     let flashloan_receipt =
    //         flashloan_logic::flash_loan_simple(flashloan_payer,
    //             signer::address_of(flashloan_receiver), // now the receiver expects to receive the flashloan
    //             underlying_token_address,
    //             (flashloan_amount as u256),
    //             0, // referal code
    //         );
    //
    //     // check intermediate underlying balance for flashloan payer
    //     let flashloan_payer_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS); // same balance as before
    //
    //     // check intermediate underlying balance for flashloan receiver
    //     let flashloan_receiver_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //     assert!(flashloan_receiver_underlying_balance
    //         == initial_receiver_balance + flashloan_amount,
    //         TEST_SUCCESS); // increased balance due to flashloan
    //
    //     // ----> receiver repays flashloan + premium
    //     flashloan_logic::pay_flash_loan_simple(flashloan_receiver, flashloan_receipt,);
    //
    //     // check intermediate underlying balance for flashloan payer
    //     let flashloan_payer_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS);
    //
    //     // check intermediate underlying balance for flashloan receiver
    //     let flashloan_receiver_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //     let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
    //     assert!(flashloan_receiver_underlying_balance
    //         == initial_receiver_balance - flashloan_paid_premium,
    //         TEST_SUCCESS);
    //
    //     // check emitted events
    //     let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
    //     assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, flashloan_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
    // /// User takes and repays a single asset flashloan
    // fun complex_flashloan_same_payer_receiver(
    //     pool: &signer,
    //     aave_role_super_admin: &signer,
    //     mock_oracle: &signer,
    //     aave_std: &signer,
    //     flashloan_user: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aptos_framework: &signer,
    //     collector_account: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init oracle
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool conigutrator and pool modules
    //     pool_config_init_reserves(pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(pool);
    //     let underlying_token_name = utf8(b"TOKEN_1");
    //     let underlying_token_symbol = utf8(b"T1");
    //     let underlying_token_decimals = 3;
    //     let underlying_token_max_supply = 10000;
    //     underlying_token_factory::create_token(underlying_tokens_admin,
    //         underlying_token_max_supply,
    //         underlying_token_name,
    //         underlying_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),);
    //     let underlying_token_address = underlying_token_factory::token_address(
    //         underlying_token_symbol);
    //
    //     // init token base for tokens
    //     token_base::test_init_module(pool);
    //
    //     // create variable tokens
    //     variable_token_factory::create_token(variable_tokens_admin,
    //         utf8(b"TEST_VAR_TOKEN_1"),
    //         utf8(b"VAR1"),
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         @0x033, // take random
    //     );
    //     let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
    //
    //     //create a tokens
    //     let a_token_symbol = utf8(b"A1");
    //     a_token_factory::create_token(a_tokens_admin,
    //         utf8(b"TEST_A_TOKEN_1"),
    //         a_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         underlying_token_address, // underlying asset address
    //         signer::address_of(collector_account), // treasury address
    //     );
    //     let a_token_address = a_token_factory::token_address(utf8(b"A1"));
    //
    //     // init and add a single reserve to the pool
    //     let reserve_index =
    //         create_reserve_with_config((underlying_token_decimals as u256),
    //             a_token_address,
    //             variable_token_address,
    //             underlying_token_address,
    //             option::none(), // ltv
    //             option::none(), // liq threshold
    //             option::none(), // liq bonus
    //             option::some((underlying_token_decimals as u256)), //decimals
    //             option::some(true), //active
    //             option::some(false), //frozen
    //             option::some(false), // paused
    //             option::some(true), // borrowable_in_isolation
    //             option::some(true), // siloed_borrowing
    //             option::some(true), // borrowing_enabled
    //             option::none(), // reserve_factor*
    //             option::none(), // borrow_cap
    //             option::none(), // supply_cap
    //             option::none(), // debt_ceiling
    //             option::none(), // liquidation_protocol_fee
    //             option::none(), // unbacked_mint_cap
    //             option::some((0 as u256)), // e_mode_category
    //             option::some(true), // flash_loan_enabled
    //         );
    //
    //     // init the default interest rate strategy for the underlying_token_address
    //     let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
    //     let base_variable_borrow_rate: u256 = 0;
    //     let variable_rate_slope1: u256 = 0;
    //     let variable_rate_slope2: u256 = 0;
    //     default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
    //         underlying_token_address,
    //         optimal_usage_ratio,
    //         base_variable_borrow_rate,
    //         variable_rate_slope1,
    //         variable_rate_slope2,);
    //
    //     // init user config for reserve index
    //     create_user_config_for_reserve(signer::address_of(flashloan_user), reserve_index,
    //         option::some(false), option::some(true));
    //
    //     // ----> mint underlying for the flashloan user
    //     // mint 100 underlying tokens for the flashloan user
    //     let mint_receiver_address = signer::address_of(flashloan_user);
    //     underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
    //         underlying_token_address);
    //     let initial_user_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     // assert user balance of underlying
    //     assert!(initial_user_balance == 100, TEST_SUCCESS);
    //     // assert underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user supplies
    //     // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
    //     let supply_receiver_address = signer::address_of(flashloan_user);
    //     let supplied_amount: u64 = 50;
    //     supply_logic::supply(flashloan_user,
    //         underlying_token_address,
    //         (supplied_amount as u256),
    //         supply_receiver_address,
    //         0);
    //
    //     // > check emitted events
    //     let emitted_supply_events = emitted_events<supply_logic::Supply>();
    //     assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
    //
    //     // > check flashloan user (supplier) balance of underlying
    //     let supplier_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
    //     // > check underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user takes a flashloan
    //     let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
    //     let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
    //     let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
    //     let flashloan_receipts =
    //         flashloan_logic::flash_loan_simple(flashloan_user,
    //             signer::address_of(flashloan_user),
    //             vector[underlying_token_address],
    //             vector[(flashloan_amount as u256)],
    //             vector[user_config::get_interest_rate_mode_none()], // interest rate modes
    //             signer::address_of(flashloan_user), // on behalf of
    //             0, // referal code
    //             flashloan_premium_to_protocol,
    //             flashloan_premium_total,
    //             false, // is_authorized_flash_borrower
    //         );
    //
    //     // check intermediate underlying balance
    //     let flashloan_taker_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     assert!(flashloan_taker_underlying_balance
    //         == supplier_balance + flashloan_amount, TEST_SUCCESS);
    //
    //     // ----> flashloan user repays flashloan + premium
    //     flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts,);
    //
    //     // check intermediate underlying balance for flashloan user
    //     let flashloan_taken_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
    //     assert!(flashloan_taken_underlying_balance
    //         == supplier_balance - flashloan_paid_premium, TEST_SUCCESS);
    //
    //     // check emitted events
    //     let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
    //     assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, flashloan_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
    // /// User takes and repays a single asset flashloan
    // fun complex_flashloan_same_payer_receiver_authorized(
    //     pool: &signer,
    //     aave_role_super_admin: &signer,
    //     mock_oracle: &signer,
    //     aave_std: &signer,
    //     flashloan_user: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aptos_framework: &signer,
    //     collector_account: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init oracle
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool conigutrator and pool modules
    //     pool_config_init_reserves(pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(pool);
    //     let underlying_token_name = utf8(b"TOKEN_1");
    //     let underlying_token_symbol = utf8(b"T1");
    //     let underlying_token_decimals = 3;
    //     let underlying_token_max_supply = 10000;
    //     underlying_token_factory::create_token(underlying_tokens_admin,
    //         underlying_token_max_supply,
    //         underlying_token_name,
    //         underlying_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),);
    //     let underlying_token_address = underlying_token_factory::token_address(
    //         underlying_token_symbol);
    //
    //     // init token base for tokens
    //     token_base::test_init_module(pool);
    //
    //     // create variable tokens
    //     variable_token_factory::create_token(variable_tokens_admin,
    //         utf8(b"TEST_VAR_TOKEN_1"),
    //         utf8(b"VAR1"),
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         @0x033, // take random
    //     );
    //     let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
    //
    //     //create a tokens
    //     let a_token_symbol = utf8(b"A1");
    //     a_token_factory::create_token(a_tokens_admin,
    //         utf8(b"TEST_A_TOKEN_1"),
    //         a_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         underlying_token_address, // underlying asset address
    //         signer::address_of(collector_account), // treasury address
    //     );
    //     let a_token_address = a_token_factory::token_address(utf8(b"A1"));
    //
    //     // init and add a single reserve to the pool
    //     let reserve_index =
    //         create_reserve_with_config((underlying_token_decimals as u256),
    //             a_token_address,
    //             variable_token_address,
    //             underlying_token_address,
    //             option::none(), // ltv
    //             option::none(), // liq threshold
    //             option::none(), // liq bonus
    //             option::some((underlying_token_decimals as u256)), //decimals
    //             option::some(true), //active
    //             option::some(false), //frozen
    //             option::some(false), // paused
    //             option::some(true), // borrowable_in_isolation
    //             option::some(true), // siloed_borrowing
    //             option::some(true), // borrowing_enabled
    //             option::none(), // reserve_factor*
    //             option::none(), // borrow_cap
    //             option::none(), // supply_cap
    //             option::none(), // debt_ceiling
    //             option::none(), // liquidation_protocol_fee
    //             option::none(), // unbacked_mint_cap
    //             option::some((0 as u256)), // e_mode_category
    //             option::some(true), // flash_loan_enabled
    //         );
    //
    //     // init the default interest rate strategy for the underlying_token_address
    //     let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
    //     let base_variable_borrow_rate: u256 = 0;
    //     let variable_rate_slope1: u256 = 0;
    //     let variable_rate_slope2: u256 = 0;
    //     default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
    //         underlying_token_address,
    //         optimal_usage_ratio,
    //         base_variable_borrow_rate,
    //         variable_rate_slope1,
    //         variable_rate_slope2,);
    //
    //     // init user config for reserve index
    //     create_user_config_for_reserve(signer::address_of(flashloan_user), reserve_index,
    //         option::some(false), option::some(true));
    //
    //     // ----> mint underlying for the flashloan user
    //     // mint 100 underlying tokens for the flashloan user
    //     let mint_receiver_address = signer::address_of(flashloan_user);
    //     underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
    //         underlying_token_address);
    //     let initial_user_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     // assert user balance of underlying
    //     assert!(initial_user_balance == 100, TEST_SUCCESS);
    //     // assert underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user supplies
    //     // flashloan user supplies the underlying token to fill the pool before attempting to take a flashloan
    //     let supply_receiver_address = signer::address_of(flashloan_user);
    //     let supplied_amount: u64 = 50;
    //     supply_logic::supply(flashloan_user,
    //         underlying_token_address,
    //         (supplied_amount as u256),
    //         supply_receiver_address,
    //         0);
    //
    //     // > check emitted events
    //     let emitted_supply_events = emitted_events<supply_logic::Supply>();
    //     assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
    //
    //     // > check flashloan user (supplier) balance of underlying
    //     let supplier_balance =
    //         underlying_token_factory::balance_of(mint_receiver_address,
    //             underlying_token_address);
    //     assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
    //     // > check underlying supply
    //     assert!(underlying_token_factory::supply(underlying_token_address)
    //         == option::some(100),
    //         TEST_SUCCESS);
    //
    //     // ----> flashloan user takes a flashloan
    //     let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
    //     let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
    //     let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
    //     let flashloan_receipts =
    //         flashloan_logic::flashloan(flashloan_user,
    //             signer::address_of(flashloan_user),
    //             vector[underlying_token_address],
    //             vector[(flashloan_amount as u256)],
    //             vector[user_config::get_interest_rate_mode_none()], // interest rate modes
    //             signer::address_of(flashloan_user), // on behalf of
    //             0, // referal code
    //         );
    //
    //     // check intermediate underlying balance
    //     let flashloan_taker_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     assert!(flashloan_taker_underlying_balance
    //         == supplier_balance + flashloan_amount, TEST_SUCCESS);
    //
    //     // ----> flashloan user repays flashloan + premium
    //     flashloan_logic::pay_flash_loan_complex(flashloan_user, flashloan_receipts,);
    //
    //     // check intermediate underlying balance for flashloan user
    //     let flashloan_taken_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_user),
    //             underlying_token_address);
    //     let flashloan_paid_premium = 0; // because the user is authorized flash borrower
    //     assert!(flashloan_taken_underlying_balance
    //         == supplier_balance - flashloan_paid_premium, TEST_SUCCESS);
    //
    //     // check emitted events
    //     let emitted_flashloan_events = emitted_events<flashloan_logic::FlashLoan>();
    //     assert!(vector::length(&emitted_flashloan_events) == 1, TEST_SUCCESS);
    // }
    //
    // #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, flashloan_payer = @0x042, flashloan_receiver = @0x043, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
    // /// User takes a complex flashloan which is received by someone else. Either user or taker then repays the complex flashloan
    // fun complex_flashloan_different_payer_receiver(
    //     pool: &signer,
    //     aave_role_super_admin: &signer,
    //     mock_oracle: &signer,
    //     aave_std: &signer,
    //     flashloan_payer: &signer,
    //     flashloan_receiver: &signer,
    //     variable_tokens_admin: &signer,
    //     a_tokens_admin: &signer,
    //     underlying_tokens_admin: &signer,
    //     aptos_framework: &signer,
    //     collector_account: &signer,
    // ) {
    //     // start the timer
    //     set_time_has_started_for_testing(aptos_framework);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // create a tokens admin account
    //     account::create_account_for_test(signer::address_of(a_tokens_admin));
    //
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init oracle
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool conigutrator and pool modules
    //     pool_config_init_reserves(pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(pool);
    //     let underlying_token_name = utf8(b"TOKEN_1");
    //     let underlying_token_symbol = utf8(b"T1");
    //     let underlying_token_decimals = 3;
    //     let underlying_token_max_supply = 10000;
    //     underlying_token_factory::create_token(underlying_tokens_admin,
    //         underlying_token_max_supply,
    //         underlying_token_name,
    //         underlying_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),);
    //     let underlying_token_address = underlying_token_factory::token_address(
    //         underlying_token_symbol);
    //
    //     // init token base for tokens
    //     token_base::test_init_module(pool);
    //
    //     // create variable tokens
    //     variable_token_factory::create_token(variable_tokens_admin,
    //         utf8(b"TEST_VAR_TOKEN_1"),
    //         utf8(b"VAR1"),
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         @0x033, // take random
    //     );
    //     let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
    //
    //     //create a tokens
    //     let a_token_symbol = utf8(b"A1");
    //     a_token_factory::create_token(a_tokens_admin,
    //         utf8(b"TEST_A_TOKEN_1"),
    //         a_token_symbol,
    //         underlying_token_decimals,
    //         utf8(b""),
    //         utf8(b""),
    //         underlying_token_address, // underlying asset address
    //         signer::address_of(collector_account), // treasury address
    //     );
    //     let a_token_address = a_token_factory::token_address(utf8(b"A1"));
    //
    //     // init and add a single reserve to the pool
    //     let reserve_index =
    //         create_reserve_with_config((underlying_token_decimals as u256),
    //             a_token_address,
    //             variable_token_address,
    //             underlying_token_address,
    //             option::none(), // ltv
    //             option::none(), // liq threshold
    //             option::none(), // liq bonus
    //             option::some((underlying_token_decimals as u256)), //decimals
    //             option::some(true), //active
    //             option::some(false), //frozen
    //             option::some(false), // paused
    //             option::some(true), // borrowable_in_isolation
    //             option::some(true), // siloed_borrowing
    //             option::some(true), // borrowing_enabled
    //             option::none(), // reserve_factor*
    //             option::none(), // borrow_cap
    //             option::none(), // supply_cap
    //             option::none(), // debt_ceiling
    //             option::none(), // liquidation_protocol_fee
    //             option::none(), // unbacked_mint_cap
    //             option::some((0 as u256)), // e_mode_category
    //             option::some(true), // flash_loan_enabled
    //         );
    //
    //     // init the default interest rate strategy for the underlying_token_address
    //     let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
    //     let base_variable_borrow_rate: u256 = 0;
    //     let variable_rate_slope1: u256 = 0;
    //     let variable_rate_slope2: u256 = 0;
    //     default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
    //         underlying_token_address,
    //         optimal_usage_ratio,
    //         base_variable_borrow_rate,
    //         variable_rate_slope1,
    //         variable_rate_slope2,);
    //
    //     // init user configs for reserve index
    //     create_user_config_for_reserve(signer::address_of(flashloan_payer), reserve_index,
    //         option::some(false), option::some(true));
    //
    //     create_user_config_for_reserve(signer::address_of(flashloan_receiver),
    //         reserve_index,
    //         option::some(false),
    //         option::some(true));
    //
    //     // ----> mint underlying for flashloan payer and receiver
    //     // mint 100 underlying tokens for flashloan payer and receiver
    //     let mint_amount: u64 = 100;
    //     let users = vector[
    //         signer::address_of(flashloan_payer),
    //         signer::address_of(flashloan_receiver)];
    //     for (i in 0..vector::length(&users)) {
    //         underlying_token_factory::mint(underlying_tokens_admin,
    //             *vector::borrow(&users, i),
    //             mint_amount,
    //             underlying_token_address);
    //         let initial_user_balance =
    //             underlying_token_factory::balance_of(*vector::borrow(&users, i),
    //                 underlying_token_address);
    //         // assert user balance of underlying
    //         assert!(initial_user_balance == mint_amount, TEST_SUCCESS);
    //     };
    //
    //     // ----> flashloan payer supplies
    //     // flashloan payer supplies the underlying token to fill the pool before attempting to take a flashloan
    //     let supply_receiver_address = signer::address_of(flashloan_payer);
    //     let supplied_amount: u64 = 50;
    //     supply_logic::supply(flashloan_payer,
    //         underlying_token_address,
    //         (supplied_amount as u256),
    //         supply_receiver_address,
    //         0);
    //
    //     // > check flashloan payer balance of underlying
    //     let initial_payer_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(initial_payer_balance == mint_amount - supplied_amount, TEST_SUCCESS);
    //     // > check flashloan payer a_token balance after supply
    //     let supplier_a_token_balance =
    //         a_token_factory::balance_of(signer::address_of(flashloan_payer), a_token_address);
    //     assert!(supplier_a_token_balance == (supplied_amount as u256), TEST_SUCCESS);
    //
    //     let initial_receiver_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //
    //     // ----> flashloan payer takes a flashloan but receiver is different
    //     let flashloan_premium_total = get_percentage_factor() / 10; // 100/10 = 10%
    //     let flashloan_premium_to_protocol = get_percentage_factor() / 20; // 100/20 = 5%
    //     let flashloan_amount = supplied_amount / 2; // half of the pool = 50/2 = 25
    //     let flashloan_receipts =
    //         flashloan_logic::flashloan(flashloan_payer,
    //             signer::address_of(flashloan_receiver),
    //             vector[underlying_token_address],
    //             vector[(flashloan_amount as u256)],
    //             vector[user_config::get_interest_rate_mode_none()], // interest rate modes
    //             signer::address_of(flashloan_payer), // on behalf of
    //             0, // referal code
    //         );
    //
    //     // check intermediate underlying balance for flashloan payer
    //     let flashloan_payer_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS); // same balance as before
    //
    //     // check intermediate underlying balance for flashloan receiver
    //     let flashloan_receiver_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //     assert!(flashloan_receiver_underlying_balance
    //         == initial_receiver_balance + flashloan_amount,
    //         TEST_SUCCESS); // increased balance due to flashloan
    //
    //     // ----> receiver repays flashloan + premium
    //     flashloan_logic::pay_flash_loan_complex(flashloan_receiver, flashloan_receipts,);
    //
    //     // check intermediate underlying balance for flashloan payer
    //     let flashloan_payer_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_payer),
    //             underlying_token_address);
    //     assert!(flashloan_payer_underlying_balance == initial_payer_balance, TEST_SUCCESS);
    //
    //     // check intermediate underlying balance for flashloan receiver
    //     let flashloan_receiver_underlying_balance =
    //         underlying_token_factory::balance_of(signer::address_of(flashloan_receiver),
    //             underlying_token_address);
    //     let flashloan_paid_premium = 3; // 10% * 25 = 2.5 = 3
    //     assert!(flashloan_receiver_underlying_balance
    //         == initial_receiver_balance - flashloan_paid_premium,
    //         TEST_SUCCESS);
    //
    //     // check emitted events
    //     let emitted_withdraw_events = emitted_events<flashloan_logic::FlashLoan>();
    //     assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
    // }
}