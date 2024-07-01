#[test_only]
module aave_pool::supply_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::event::emitted_events;
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    use aave_acl::acl_manage::{Self, test_init_module};
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle::test_init_oracle;

    use aave_pool::a_token_factory::Self;
    use aave_pool::default_reserve_interest_rate_strategy::Self;
    use aave_pool::emode_logic::Self;
    use aave_pool::pool_configurator::test_init_module as pool_config_init_reserves;
    use aave_pool::pool_tests::{create_reserve_with_config, create_user_config_for_reserve};
    use aave_pool::supply_logic::Self;
    use aave_pool::token_base::Self;
    use aave_pool::underlying_token_factory::Self;
    use aave_pool::variable_token_factory::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, supply_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
//     /// Reserve allows borrowing and being used as collateral.
//     /// User config allows only borrowing for the reserve.
//     /// User supplies and withdraws parts of the supplied amount
//     fun test_supply_partial_withdraw(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         mock_oracle: &signer,
//         aave_std: &signer,
//         supply_user: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         underlying_tokens_admin: &signer,
//         aptos_framework: &signer,
//         collector_account: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init pool conigutrator and pool modules
//         pool_config_init_reserves(pool);
//
//         // init underlying tokens
//         underlying_token_factory::test_init_module(aave_pool);
//         let underlying_token_name = utf8(b"TOKEN_1");
//         let underlying_token_symbol = utf8(b"T1");
//         let underlying_token_decimals = 3;
//         let underlying_token_max_supply = 10000;
//         underlying_token_factory::create_token(underlying_tokens_admin,
//             underlying_token_max_supply,
//             underlying_token_name,
//             underlying_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),);
//         let underlying_token_address = underlying_token_factory::token_address(
//             underlying_token_symbol);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//
//         //create a tokens
//         let a_token_symbol = utf8(b"A1");
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             a_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_token_address, // underlying asset address
//             signer::address_of(collector_account), // treasury address
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // init and add a single reserve to the pool
//         let reserve_index =
//             create_reserve_with_config((underlying_token_decimals as u256),
//                 a_token_address,
//                 variable_token_address,
//                 underlying_token_address,
//                 option::none(), // ltv
//                 option::none(), // liq threshold
//                 option::none(), // liq bonus
//                 option::some((underlying_token_decimals as u256)), //decimals
//                 option::some(true), //active
//                 option::some(false), //frozen
//                 option::some(false), // paused
//                 option::some(true), // borrowable_in_isolation
//                 option::some(true), // siloed_borrowing
//                 option::some(true), // borrowing_enabled
//                 option::none(), // reserve_factor*
//                 option::none(), // borrow_cap
//                 option::none(), // supply_cap
//                 option::none(), // debt_ceiling
//                 option::none(), // liquidation_protocol_fee
//                 option::none(), // unbacked_mint_cap
//                 option::some((0 as u256)), // e_mode_category
//                 option::some(true), // flash_loan_enabled
//             );
//
//         // init the default interest rate strategy for the underlying_token_address
//         let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
//         let base_variable_borrow_rate: u256 = 0;
//         let variable_rate_slope1: u256 = 0;
//         let variable_rate_slope2: u256 = 0;
//         default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
//             underlying_token_address,
//             optimal_usage_ratio,
//             base_variable_borrow_rate,
//             variable_rate_slope1,
//             variable_rate_slope2,);
//
//         // init user config for reserve index
//         create_user_config_for_reserve(signer::address_of(supply_user), reserve_index,
//             option::some(false), option::some(true));
//
//         // =============== MINT UNDERLYING FOR USER ================= //
//         // mint 100 underlying tokens for the user
//         let mint_receiver_address = signer::address_of(supply_user);
//         underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
//             underlying_token_address);
//         let initial_user_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         // assert user balance of underlying
//         assert!(initial_user_balance == 100, TEST_SUCCESS);
//         // assert underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//
//         // =============== USER SUPPLY ================= //
//         // user supplies the underlying token
//         let supply_receiver_address = signer::address_of(supply_user);
//         let supplied_amount: u64 = 10;
//         supply_logic::supply(supply_user,
//             underlying_token_address,
//             (supplied_amount as u256),
//             supply_receiver_address,
//             0);
//
//         // > check emitted events
//         let emitted_supply_events = emitted_events<supply_logic::Supply>();
//         assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
//         // > check supplier balance of underlying
//         let supplier_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
//         // > check underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//         // > check a_token underlying balance
//         let atoken_acocunt_address = a_token_factory::get_token_account_address(
//             a_token_address);
//         let underlying_acocunt_balance =
//             underlying_token_factory::balance_of(atoken_acocunt_address,
//                 underlying_token_address);
//         assert!(underlying_acocunt_balance == supplied_amount, TEST_SUCCESS);
//         // > check user a_token balance after supply
//         let supplier_a_token_balance =
//             a_token_factory::balance_of(signer::address_of(supply_user), a_token_address);
//         assert!(supplier_a_token_balance == (supplied_amount as u256), TEST_SUCCESS);
//
//         // =============== USER WITHDRAWS ================= //
//         // user withdraws a small amount of the supplied amount
//         let amount_to_withdraw = 4;
//         supply_logic::withdraw(supply_user, underlying_token_address, (amount_to_withdraw as u256),
//             supply_receiver_address);
//
//         // > check a_token balance of underlying
//         let atoken_acocunt_balance =
//             underlying_token_factory::balance_of(atoken_acocunt_address,
//                 underlying_token_address);
//         assert!(atoken_acocunt_balance == supplied_amount - amount_to_withdraw, TEST_SUCCESS);
//         // > check underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//         // > check user a_token balance after withdrawal
//         let supplier_a_token_balance =
//             a_token_factory::balance_of(signer::address_of(supply_user), a_token_address);
//         assert!(supplier_a_token_balance
//             == ((supplied_amount - amount_to_withdraw) as u256), TEST_SUCCESS);
//         // > check users underlying tokens balance
//         let supplier_underlying_balance_after_withdraw =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         assert!(supplier_underlying_balance_after_withdraw
//             == initial_user_balance - supplied_amount + amount_to_withdraw,
//             TEST_SUCCESS);
//         // > check emitted events
//         let emitted_withdraw_events = emitted_events<supply_logic::Withdraw>();
//         assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
//         let emitted_reserve_collecteral_disabled_events = emitted_events<supply_logic::ReserveUsedAsCollateralDisabled>();
//         assert!(vector::length(&emitted_reserve_collecteral_disabled_events) == 0,
//             TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, supply_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
//     /// Reserve allows borrowing and being used as collateral.
//     /// User config allows borrowing and collateral.
//     /// User supplies and withdraws the entire amount
//     fun test_supply_full_collateral_withdraw(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         mock_oracle: &signer,
//         aave_std: &signer,
//         supply_user: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         underlying_tokens_admin: &signer,
//         aptos_framework: &signer,
//         collector_account: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init pool conigutrator and pool modules
//         pool_config_init_reserves(pool);
//
//         // define an emode cat for reserve and user
//         let emode_cat_id1: u8 = 1;
//         // configure an emode category
//         let ltv1: u16 = 10000;
//         let liquidation_threshold1: u16 = 10000;
//         let liquidation_bonus1: u16 = 0;
//         let price_source1: address = @0x01;
//         let label1 = utf8(b"MODE1");
//         emode_logic::configure_emode_category(emode_cat_id1,
//             ltv1,
//             liquidation_threshold1,
//             liquidation_bonus1,
//             price_source1,
//             label1);
//
//         // init underlying tokens
//         underlying_token_factory::test_init_module(aave_pool);
//         let underlying_token_name = utf8(b"TOKEN_1");
//         let underlying_token_symbol = utf8(b"T1");
//         let underlying_token_decimals = 3;
//         let underlying_token_max_supply = 10000;
//         underlying_token_factory::create_token(underlying_tokens_admin,
//             underlying_token_max_supply,
//             underlying_token_name,
//             underlying_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),);
//         let underlying_token_address = underlying_token_factory::token_address(
//             underlying_token_symbol);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//
//         //create a tokens
//         let a_token_symbol = utf8(b"A1");
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             a_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_token_address, // underlying asset address
//             signer::address_of(collector_account), // treasury address
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // init the default interest rate strategy for the underlying_token_address
//         let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
//         let base_variable_borrow_rate: u256 = 0;
//         let variable_rate_slope1: u256 = 0;
//         let variable_rate_slope2: u256 = 0;
//         default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
//             underlying_token_address,
//             optimal_usage_ratio,
//             base_variable_borrow_rate,
//             variable_rate_slope1,
//             variable_rate_slope2,);
//
//         // init and add a single reserve to the pool
//         let reserve_index =
//             create_reserve_with_config((underlying_token_decimals as u256),
//                 a_token_address,
//                 variable_token_address,
//                 underlying_token_address,
//                 option::none(), // ltv
//                 option::none(), // liq threshold
//                 option::none(), // liq bonus
//                 option::some((underlying_token_decimals as u256)), //decimals
//                 option::some(true), //active
//                 option::some(false), //frozen
//                 option::some(false), // paused
//                 option::some(true), // borrowable_in_isolation
//                 option::some(true), // siloed_borrowing
//                 option::some(true), // borrowing_enabled
//                 option::none(), // reserve_factor*
//                 option::none(), // borrow_cap
//                 option::none(), // supply_cap
//                 option::none(), // debt_ceiling
//                 option::none(), // liquidation_protocol_fee
//                 option::none(), // unbacked_mint_cap
//                 option::some((emode_cat_id1 as u256)), // e_mode_category
//                 option::some(true), // flash_loan_enabled
//             );
//
//         // init user config for reserve index
//         create_user_config_for_reserve(signer::address_of(supply_user), reserve_index,
//             option::some(true), option::some(true));
//
//         // set user emode
//         emode_logic::set_user_emode(supply_user, emode_cat_id1);
//
//         // =============== MINT UNDERLYING FOR USER ================= //
//         // mint 100 underlying tokens for the user
//         let mint_receiver_address = signer::address_of(supply_user);
//         underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
//             underlying_token_address);
//         let initial_user_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         // assert user balance of underlying
//         assert!(initial_user_balance == 100, TEST_SUCCESS);
//         // asser underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//
//         // =============== USER SUPPLY ================= //
//         // user supplies the underlying token
//         let supply_receiver_address = signer::address_of(supply_user);
//         let supplied_amount: u64 = 50;
//         supply_logic::supply(supply_user,
//             underlying_token_address,
//             (supplied_amount as u256),
//             supply_receiver_address,
//             0);
//
//         // > check emitted events
//         let emitted_supply_events = emitted_events<supply_logic::Supply>();
//         assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
//         // > check supplier balance of underlying
//         let supplier_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
//         // > check underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//         // > check underlying balance of atoken
//         let atoken_account_address = a_token_factory::get_token_account_address(
//             a_token_address);
//         let underlying_acocunt_balance =
//             underlying_token_factory::balance_of(atoken_account_address,
//                 underlying_token_address);
//         assert!(underlying_acocunt_balance == supplied_amount, TEST_SUCCESS);
//         // > check user a_token balance after supply
//         let supplier_a_token_balance =
//             a_token_factory::balance_of(signer::address_of(supply_user), a_token_address);
//         assert!(supplier_a_token_balance == (supplied_amount as u256), TEST_SUCCESS);
//
//         // =============== USER WITHDRAWS ================= //
//         // user withdraws his entire supply
//         let amount_to_withdraw = 50;
//         supply_logic::withdraw(supply_user, underlying_token_address, (amount_to_withdraw as u256),
//             supply_receiver_address);
//
//         // > check underlying balance of a_token account
//         let atoken_acocunt_balance =
//             underlying_token_factory::balance_of(atoken_account_address,
//                 underlying_token_address);
//         assert!(atoken_acocunt_balance == 0, TEST_SUCCESS);
//         // > check underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//         // > check user a_token balance after withdrawal
//         let supplier_a_token_balance =
//             a_token_factory::balance_of(signer::address_of(supply_user), a_token_address);
//         assert!(supplier_a_token_balance == 0, TEST_SUCCESS);
//         // > check users underlying tokens balance
//         let supplier_underlying_balance_after_withdraw =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         assert!(supplier_underlying_balance_after_withdraw
//             == initial_user_balance - supplied_amount + amount_to_withdraw,
//             TEST_SUCCESS);
//         // > check emitted events
//         let emitted_withdraw_events = emitted_events<supply_logic::Withdraw>();
//         assert!(vector::length(&emitted_withdraw_events) == 1, TEST_SUCCESS);
//         let emitted_reserve_collecteral_disabled_events = emitted_events<supply_logic::ReserveUsedAsCollateralDisabled>();
//         assert!(vector::length(&emitted_reserve_collecteral_disabled_events) == 1,
//             TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, mock_oracle = @aave_mock_oracle, aave_std = @std, supply_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55,)]
//     /// Reserve allows borrowing and being used as collateral.
//     /// User config allows borrowing and collateral.
//     /// User supplies and withdraws the entire amount
//     /// with ltv and no debt ceiling, and not using as collateral already
//     fun test_supply_use_as_collateral(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         mock_oracle: &signer,
//         aave_std: &signer,
//         supply_user: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         underlying_tokens_admin: &signer,
//         aptos_framework: &signer,
//         collector_account: &signer,
//     ) {
//         // start the timer
//         set_time_has_started_for_testing(aptos_framework);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init pool conigutrator and pool modules
//         pool_config_init_reserves(pool);
//
//         // init underlying tokens
//         underlying_token_factory::test_init_module(aave_pool);
//         let underlying_token_name = utf8(b"TOKEN_1");
//         let underlying_token_symbol = utf8(b"T1");
//         let underlying_token_decimals = 3;
//         let underlying_token_max_supply = 10000;
//         underlying_token_factory::create_token(underlying_tokens_admin,
//             underlying_token_max_supply,
//             underlying_token_name,
//             underlying_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),);
//         let underlying_token_address = underlying_token_factory::token_address(
//             underlying_token_symbol);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//
//         //create a tokens
//         let a_token_symbol = utf8(b"A1");
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             a_token_symbol,
//             underlying_token_decimals,
//             utf8(b""),
//             utf8(b""),
//             underlying_token_address, // underlying asset address
//             signer::address_of(collector_account), // treasury address
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // init the default interest rate strategy for the underlying_token_address
//         let optimal_usage_ratio: u256 = wad_ray_math::get_half_ray_for_testing();
//         let base_variable_borrow_rate: u256 = 0;
//         let variable_rate_slope1: u256 = 0;
//         let variable_rate_slope2: u256 = 0;
//         default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(pool,
//             underlying_token_address,
//             optimal_usage_ratio,
//             base_variable_borrow_rate,
//             variable_rate_slope1,
//             variable_rate_slope2,);
//
//         // init and add a single reserve to the pool
//         let reserve_index =
//             create_reserve_with_config((underlying_token_decimals as u256),
//                 a_token_address,
//                 variable_token_address,
//                 underlying_token_address,
//                 option::some(5000), // NOTE: set ltv
//                 option::none(), // liq threshold
//                 option::none(), // liq bonus
//                 option::some((underlying_token_decimals as u256)), //decimals
//                 option::some(true), //active
//                 option::some(false), //frozen
//                 option::some(false), // paused
//                 option::some(true), // borrowable_in_isolation
//                 option::some(true), // siloed_borrowing
//                 option::some(true), // borrowing_enabled
//                 option::none(), // reserve_factor*
//                 option::none(), // borrow_cap
//                 option::none(), // supply_cap
//                 option::some(0), // NOTE: set no debt_ceiling
//                 option::none(), // liquidation_protocol_fee
//                 option::none(), // unbacked_mint_cap
//                 option::some((0 as u256)), // e_mode_category
//                 option::some(true), // flash_loan_enabled
//             );
//
//         // init user config for reserve index
//         create_user_config_for_reserve(signer::address_of(supply_user), reserve_index,
//             option::some(true), option::some(false) // NOTE: not using any as collateral already
//         );
//
//         // =============== MINT UNDERLYING FOR USER ================= //
//         // mint 100 underlying tokens for the user
//         let mint_receiver_address = signer::address_of(supply_user);
//         underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
//             underlying_token_address);
//         let initial_user_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         // assert user balance of underlying
//         assert!(initial_user_balance == 100, TEST_SUCCESS);
//         // asser underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//
//         // =============== USER SUPPLY ================= //
//         // user supplies the underlying token
//         let supply_receiver_address = signer::address_of(supply_user);
//         let supplied_amount: u64 = 50;
//         supply_logic::supply(supply_user,
//             underlying_token_address,
//             (supplied_amount as u256),
//             supply_receiver_address,
//             0);
//
//         // > check emitted events
//         let emitted_supply_events = emitted_events<supply_logic::Supply>();
//         assert!(vector::length(&emitted_supply_events) == 1, TEST_SUCCESS);
//         let emitted_reserve_used_as_collateral_events = emitted_events<supply_logic::ReserveUsedAsCollateralEnabled>();
//         assert!(vector::length(&emitted_reserve_used_as_collateral_events) == 1,
//             TEST_SUCCESS);
//         // > check supplier balance of underlying
//         let supplier_balance =
//             underlying_token_factory::balance_of(mint_receiver_address,
//                 underlying_token_address);
//         assert!(supplier_balance == initial_user_balance - supplied_amount, TEST_SUCCESS);
//         // > check underlying supply
//         assert!(underlying_token_factory::supply(underlying_token_address)
//             == option::some(100),
//             TEST_SUCCESS);
//         // > check a_token balance of underlying
//         let atoken_account_address = a_token_factory::get_token_account_address(
//             a_token_address);
//         let atoken_acocunt_balance =
//             underlying_token_factory::balance_of(atoken_account_address,
//                 underlying_token_address);
//         assert!(atoken_acocunt_balance == supplied_amount, TEST_SUCCESS);
//         // > check user a_token balance after supply
//         let supplier_a_token_balance =
//             a_token_factory::balance_of(signer::address_of(supply_user), a_token_address);
//         assert!(supplier_a_token_balance == (supplied_amount as u256), TEST_SUCCESS);
//     }
}
