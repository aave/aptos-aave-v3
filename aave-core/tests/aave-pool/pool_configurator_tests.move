#[test_only]
module aave_pool::pool_configurator_tests {
    use std::features::change_feature_flags_for_testing;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;
    use aptos_framework::account;
    use aave_acl::acl_manage;
    use aave_acl::acl_manage::test_init_module;
    use aave_mock_oracle::oracle::test_init_oracle;
    use aave_pool::a_token_factory::Self;
    use aave_pool::token_base;
    use aave_pool::variable_token_factory::Self;
    use aave_pool::underlying_token_factory::{Self};

    use aave_pool::pool::{get_reserves_count, ReserveInitialized};
    use aave_pool::pool_configurator::Self;

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

    // #[test(aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle,)]
    // fun test_add_reserves(
    //     aave_pool: &signer,
    //     aave_role_super_admin: &signer,
    //     aave_std: &signer,
    //     mock_oracle: &signer,
    // ) {
    //     // init the acl module and make aave_pool the asset listing/pool admin
    //     acl_manage::test_init_module(aave_role_super_admin);
    //     acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
    //     acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
    //
    //     // init token base
    //     token_base::test_init_module(aave_pool);
    //
    //     // init underlying tokens
    //     underlying_token_factory::test_init_module(aave_pool);
    //
    //     // add the test events feature flag
    //     change_feature_flags_for_testing(aave_std, vector[26], vector[]);
    //
    //     // init oracle module
    //     test_init_oracle(mock_oracle);
    //
    //     // init pool_configurator & reserves module
    //     pool_configurator::test_init_module(aave_pool);
    //
    //     assert!(pool_configurator::get_revision() == 1, TEST_SUCCESS);
    //
    //     // init input data for creating pool reserves
    //     let treasuries = vector[@0x011, @0x012];
    //
    //     let underlying_asset = vector[@0x061, @0x062];
    //     let underlying_asset_decimals = vector[2, 3];
    //
    //     let a_token_names = vector[utf8(b"TEST_A_TOKEN_1"), utf8(b"TEST_A_TOKEN_2")];
    //     let a_token_symbols = vector[utf8(b"A1"), utf8(b"A2")];
    //
    //     let variable_debt_token_names = vector[utf8(b"TEST_VAR_TOKEN_1"), utf8(b"TEST_VAR_TOKEN_2")];
    //     let variable_debt_token_symbols = vector[utf8(b"V1"), utf8(b"V2")];
    //
    //     pool_configurator::init_reserves(
    //         aave_pool,
    //         underlying_asset,
    //         underlying_asset_decimals,
    //         treasuries,
    //         a_token_names,
    //         a_token_symbols,
    //         variable_debt_token_names,
    //         variable_debt_token_symbols,
    //     );
    //     // check emitted events
    //     let emitted_events = emitted_events<ReserveInitialized>();
    //     // make sure event of type was emitted
    //     assert!(vector::length(&emitted_events) == 2, TEST_SUCCESS);
    //     // test reserves count
    //     assert!(get_reserves_count() == 2, TEST_SUCCESS);
    // }
//
//     #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle,)]
//     #[expected_failure(abort_code = 5)]
//     fun test_add_reserves_wrong_sender(
//         pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_std: &signer,
//         mock_oracle: &signer,
//     ) {
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle module
//         test_init_oracle(mock_oracle);
//
//         // init pool_configurator & reserves module
//         pool_configurator::test_init_module(pool);
//
//         let a_token_tmpl = vector[@0x011, @0x012];
//         let variable_debt_token_impl = vector[@0x031, @0x032];
//         let underlying_asset_decimals = vector[2, 3];
//         let underlying_asset = vector[@0x061, @0x062];
//
//         pool_configurator::add_reserves(mock_oracle,
//             a_token_tmpl,
//             variable_debt_token_impl,
//             underlying_asset_decimals,
//             underlying_asset,);
//     }
//
//     #[test(pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle,)]
//     #[expected_failure(abort_code = 1)]
//     fun test_drop_reserves_bad_signer(
//         pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_std: &signer,
//         mock_oracle: &signer,
//     ) {
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle module
//         test_init_oracle(mock_oracle);
//
//         // init pool_configurator & reserves module & emode
//         pool_configurator::test_init_module(pool);
//
//         let a_token_tmpl = vector[@0x011, @0x012];
//         let variable_debt_token_impl = vector[@0x031, @0x032];
//         let underlying_asset_decimals = vector[2, 3];
//         let underlying_asset = vector[@0x061, @0x062];
//
//         pool_configurator::add_reserves(pool,
//             a_token_tmpl,
//             variable_debt_token_impl,
//             underlying_asset_decimals,
//             underlying_asset,);
//
//         // drop the first reserve
//         pool_configurator::drop_reserve(mock_oracle, *vector::borrow(&underlying_asset, 0));
//     }
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens,)]
//     fun test_drop_reserves_with_0_supply(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_std: &signer,
//         mock_oracle: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//     ) {
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle module
//         test_init_oracle(mock_oracle);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init pool_configurator & reserves module & emode
//         pool_configurator::test_init_module(pool);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             2,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//
//         //create a tokens
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             utf8(b"A1"),
//             2,
//             utf8(b""),
//             utf8(b""),
//             @0x043, // take random
//             @0x044, // take random
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // create add reserves data
//         let a_token_tmpl = vector[a_token_address];
//         let variable_debt_token_impl = vector[variable_token_address];
//         let underlying_asset_decimals = vector[2];
//         let underlying_asset = vector[@0x061];
//
//         pool_configurator::add_reserves(pool,
//             a_token_tmpl,
//             variable_debt_token_impl,
//             underlying_asset_decimals,
//             underlying_asset,);
//         // test reserves count
//         assert!(get_reserves_count() == 1, TEST_SUCCESS);
//
//         // drop the first reserve
//         pool_configurator::drop_reserve(pool, *vector::borrow(&underlying_asset, 0));
//         // check emitted events
//         let emitted_events = emitted_events<pool_configurator::ReserveDropped>();
//         // make sure event of type was emitted
//         assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
//         // test reserves count
//         assert!(get_reserves_count() == 0, TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, caller = @0x41,)]
//     #[expected_failure(abort_code = 54)]
//     fun test_drop_reserves_with_nonzero_supply_variable_failure(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_std: &signer,
//         mock_oracle: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         caller: &signer,
//     ) {
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle module
//         test_init_oracle(mock_oracle);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // init pool_configurator & reserves module
//         pool_configurator::test_init_module(pool);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         let asset_decimals: u8 = 2;
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             asset_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let variable_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//         let _supply = variable_token_factory::supply(variable_token_address);
//
//         //create a tokens
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             utf8(b"A1"),
//             asset_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x043, // take random
//             @0x044, // take random
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // ============= MINT ATOKENS ============== //
//         let amount_to_mint: u256 = 100;
//         let reserve_index: u256 = 1;
//         let token_receiver = @0x03;
//         a_token_factory::mint(signer::address_of(caller),
//             token_receiver,
//             amount_to_mint,
//             reserve_index,
//             a_token_address);
//
//         // assert a token supply
//         assert!(a_token_factory::supply(a_token_address) == amount_to_mint, TEST_SUCCESS);
//
//         // add reserves data
//         let a_token_tmpl = vector[a_token_address];
//         let variable_debt_token_impl = vector[variable_token_address];
//         let underlying_asset_decimals = vector[(asset_decimals as u256)];
//         let underlying_asset = vector[@0x061];
//
//         // ============= ADD RESERVES ============== //
//         pool_configurator::add_reserves(pool,
//             a_token_tmpl,
//             variable_debt_token_impl,
//             underlying_asset_decimals,
//             underlying_asset,);
//
//         // test reserves count
//         assert!(get_reserves_count() == 1, TEST_SUCCESS);
//
//         // ============= DROP RESERVES ============== //
//         // drop the reserve
//         pool_configurator::drop_reserve(pool, *vector::borrow(&underlying_asset, 0));
//     }
//
//     #[test(pool = @aave_pool, aave_pool = @aave_pool, aave_role_super_admin = @aave_acl, aave_std = @std, mock_oracle = @aave_mock_oracle, variable_tokens_admin = @variable_tokens, a_tokens_admin = @a_tokens, caller = @0x41,)]
//     #[expected_failure(abort_code = 56)]
//     fun test_drop_reserves_with_nonzero_supply_atokens_failure(
//         pool: &signer,
//         aave_pool: &signer,
//         aave_role_super_admin: &signer,
//         aave_std: &signer,
//         mock_oracle: &signer,
//         variable_tokens_admin: &signer,
//         a_tokens_admin: &signer,
//         caller: &signer,
//     ) {
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle module
//         test_init_oracle(mock_oracle);
//
//         // create a tokens admin account
//         account::create_account_for_test(signer::address_of(a_tokens_admin));
//
//         // init the acl module and make aave_pool the asset listing/pool admin
//         test_init_module(aave_role_super_admin);
//         acl_manage::add_asset_listing_admin(aave_role_super_admin, @aave_pool);
//         acl_manage::add_pool_admin(aave_role_super_admin, @aave_pool);
//
//         // init pool_configurator & reserves module
//         pool_configurator::test_init_module(pool);
//
//         // init token base for tokens
//         token_base::test_init_module(aave_pool);
//
//         let asset_decimals: u8 = 2;
//
//         // create variable tokens
//         variable_token_factory::create_token(variable_tokens_admin,
//             utf8(b"TEST_VAR_TOKEN_1"),
//             utf8(b"VAR1"),
//             asset_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x033, // take random
//         );
//         let var_token_address = variable_token_factory::token_address(utf8(b"VAR1"));
//
//         //create a tokens
//         a_token_factory::create_token(a_tokens_admin,
//             utf8(b"TEST_A_TOKEN_1"),
//             utf8(b"A1"),
//             asset_decimals,
//             utf8(b""),
//             utf8(b""),
//             @0x043, // take random
//             @0x044, // take random
//         );
//         let a_token_address = a_token_factory::token_address(utf8(b"A1"));
//
//         // ============= MINT VAR TOKENS ============== //
//         let amount_to_mint: u256 = 100;
//         let reserve_index: u256 = 1;
//         let token_receiver = @0x03;
//         variable_token_factory::mint(signer::address_of(caller),
//             token_receiver,
//             amount_to_mint,
//             reserve_index,
//             var_token_address);
//
//         // assert a token supply
//         assert!(variable_token_factory::supply(var_token_address) == amount_to_mint,
//             TEST_SUCCESS);
//
//         // ============= ADD RESERVES ============== //
//         // add reserves data
//         let a_token_tmpl = vector[a_token_address];
//         let variable_debt_token_impl = vector[var_token_address];
//         let underlying_asset_decimals = vector[(asset_decimals as u256)];
//         let underlying_asset = vector[@0x061];
//
//         pool_configurator::add_reserves(pool,
//             a_token_tmpl,
//             variable_debt_token_impl,
//             underlying_asset_decimals,
//             underlying_asset,);
//
//         // test reserves count
//         assert!(get_reserves_count() == 1, TEST_SUCCESS);
//
//         // ============= DROP RESERVES ============== //
//         // drop the reserve
//         pool_configurator::drop_reserve(pool, *vector::borrow(&underlying_asset, 0));
//     }
}
