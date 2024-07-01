#[test_only]
module aave_pool::borrow_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use aptos_framework::account;
    use aptos_framework::timestamp::set_time_has_started_for_testing;
    use aptos_framework::timestamp::{Self, fast_forward_seconds};

    use aave_acl::acl_manage::{Self, test_init_module};
    use aave_math::wad_ray_math;
    use aave_mock_oracle::oracle::test_init_oracle;
    use aave_mock_oracle::oracle_sentinel::Self;

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

//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_mock_oracle = @aave_mock_oracle, aave_std = @std, supply_user = @0x042, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, underlying_tokens_admin = @underlying_tokens, aptos_framework = @0x1, collector_account = @0x55, borrower = @0x60,)]
//     /// Reserve allows borrowing and being used as collateral.
//     /// User config allows borrowing and collateral.
//     /// User supplies and withdraws the entire amount
//     /// with ltv and no debt ceiling, and not using as collateral already
//     fun test_borrow_repay(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_mock_oracle: &signer,
//         aave_std: &signer,
//         supply_user: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         underlying_tokens_admin: &signer,
//         aptos_framework: &signer,
//         collector_account: &signer,
//         borrower: &signer,
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
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, signer::address_of(pool));
//         acl_manage::add_pool_admin(aave_role_super_admin, signer::address_of(pool));
//
//         // init the oracle incl. sentinel
//         test_init_oracle(aave_mock_oracle);
//
//         // init the oracle sentinel
//         let grace_period = (1000 as u64);
//         oracle_sentinel::set_grace_period(pool, (grace_period as u256));
//
//         // init pool configurator and pool modules
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
//                 option::some((emode_cat_id1 as u256)), // e_mode_category
//                 option::some(true), // flash_loan_enabled
//             );
//
//         // init user config for reserve index
//         create_user_config_for_reserve(signer::address_of(supply_user), reserve_index,
//             option::some(false), option::some(false));
//
//         // =============== MINT UNDERLYING FOR SUPPLIER ================= //
//         // mint 100 underlying tokens for the user
//         let mint_receiver_address = signer::address_of(supply_user);
//         underlying_token_factory::mint(underlying_tokens_admin, mint_receiver_address, 100,
//             underlying_token_address);
//
//         // =============== SUPPLIER SUPPLIES ================= //
//         // user supplies the underlying token
//         let supply_receiver_address = signer::address_of(supply_user);
//         let supplied_amount: u64 = 50;
//         supply_logic::supply(supply_user,
//             underlying_token_address,
//             (supplied_amount as u256),
//             supply_receiver_address,
//             0);
//
//         // =============== SET ORACLE ================= //
//         // set oracle to make sure borrow is allowed
//         oracle_sentinel::set_answer(pool, false, (timestamp::now_seconds() as u256));
//         fast_forward_seconds((timestamp::now_seconds() + grace_period + 1));
//         assert!(oracle_sentinel::is_borrow_allowed(), TEST_SUCCESS);
//
//         // =============== SET BORROWER EMODE ================= //
//         // set user emode
//         emode_logic::set_user_emode(borrower, emode_cat_id1);
//
//         // =============== BORROWER BORROWS ================= //
//         let _borrowed_amount = 30;
//         let _interest_rate_mode: u8 = 2;
//         // here user is expected to be in emode category of 1
//         /*
//         borrow_logic::borrow(
//             borrower,
//             underlying_token_address,
//             signer::address_of(borrower),
//             borrowed_amount,
//             interest_rate_mode,
//             0,
//             true,
//         );
//         */
//     }
}
