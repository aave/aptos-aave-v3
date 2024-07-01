#[test_only]
module aave_pool::emode_logic_tests {
    use std::features::change_feature_flags_for_testing;
    use std::option::Self;
    use std::signer;
    use std::string::utf8;
    use std::vector;
    use aptos_framework::event::emitted_events;

    use aave_mock_oracle::oracle::test_init_oracle;

    use aave_pool::emode_logic::{
        configure_emode_category,
        get_emode_category_data,
        get_emode_category_liquidation_bonus,
        get_emode_category_liquidation_threshold,
        get_emode_category_price_source,
        get_emode_configuration,
        get_user_emode,
        init_emode,
        is_in_emode_category,
        set_user_emode,
        UserEModeSet,
    };
    use aave_pool::pool::test_init_pool;
    use aave_pool::pool_tests::{create_reserve_with_config, create_user_config_for_reserve};

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;
//
//     #[test(pool = @aave_pool,)]
//     #[expected_failure(abort_code = 16)]
//     fun zero_emode_id_failure(pool: &signer) {
//         // init the emode
//         init_emode(pool);
//
//         // configure an illegal emode category
//         let id: u8 = 0;
//         let ltv: u16 = 100;
//         let liquidation_threshold: u16 = 200;
//         let liquidation_bonus: u16 = 300;
//         let price_source: address = @0x01;
//         let label = utf8(b"MODE1");
//         configure_emode_category(id, ltv, liquidation_threshold, liquidation_bonus,
//             price_source, label);
//     }
//
//     #[test(pool = @aave_pool,)]
//     fun get_nonexisting_emode_category(pool: &signer) {
//         // init the emode
//         init_emode(pool);
//
//         // get an non-existing emode category
//         let id: u8 = 3;
//         let (ltv, liquidation_threshold, emode_asset_price) = get_emode_configuration(id);
//         assert!(ltv == 0, TEST_SUCCESS);
//         assert!(liquidation_threshold == 0, TEST_SUCCESS);
//         assert!(emode_asset_price == 0, TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, mock_oracle = @aave_mock_oracle,)]
//     fun test_emode_config(pool: &signer, mock_oracle: &signer,) {
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init the emode
//         init_emode(pool);
//
//         // configure and assert two emode categories
//         let id1: u8 = 1;
//         let ltv1: u16 = 100;
//         let liquidation_threshold1: u16 = 200;
//         let liquidation_bonus1: u16 = 300;
//         let price_source1: address = @0x01;
//         let label1 = utf8(b"MODE1");
//         configure_emode_category(id1,
//             ltv1,
//             liquidation_threshold1,
//             liquidation_bonus1,
//             price_source1,
//             label1);
//         let emode_data1 = get_emode_category_data(id1);
//         assert!(get_emode_category_liquidation_bonus(&emode_data1)
//             == liquidation_bonus1, TEST_SUCCESS);
//         assert!(get_emode_category_liquidation_threshold(&emode_data1)
//             == liquidation_threshold1,
//             TEST_SUCCESS);
//         assert!(get_emode_category_price_source(&emode_data1) == price_source1, TEST_SUCCESS);
//         let (ltv, liquidation_threshold, _emode_asset_price) = get_emode_configuration(id1);
//         assert!(ltv == (ltv1 as u256), TEST_SUCCESS);
//         assert!(liquidation_threshold == (liquidation_threshold1 as u256), TEST_SUCCESS);
//
//         let id2: u8 = 2;
//         let ltv2: u16 = 101;
//         let liquidation_threshold2: u16 = 201;
//         let liquidation_bonus2: u16 = 301;
//         let price_source2: address = @0x02;
//         let label2 = utf8(b"MODE2");
//         configure_emode_category(id2,
//             ltv2,
//             liquidation_threshold2,
//             liquidation_bonus2,
//             price_source2,
//             label2);
//         let emode_data2 = get_emode_category_data(id2);
//         assert!(get_emode_category_liquidation_bonus(&emode_data2)
//             == liquidation_bonus2, TEST_SUCCESS);
//         assert!(get_emode_category_liquidation_threshold(&emode_data2)
//             == liquidation_threshold2,
//             TEST_SUCCESS);
//         assert!(get_emode_category_price_source(&emode_data2) == price_source2, TEST_SUCCESS);
//         let (ltv, liquidation_threshold, _emode_asset_price) = get_emode_configuration(id2);
//         assert!(ltv == (ltv2 as u256), TEST_SUCCESS);
//         assert!(liquidation_threshold == (liquidation_threshold2 as u256), TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, mock_oracle = @aave_mock_oracle, user = @0x01, aave_std = @std,)]
//     fun test_legitimate_user_emode(
//         pool: &signer, mock_oracle: &signer, user: &signer, aave_std: &signer,
//     ) {
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init the emode
//         init_emode(pool);
//         // define an emode cat for reserve and user
//         let emode_cat_id1: u8 = 1;
//         // configure an emode category
//         let ltv1: u16 = 100;
//         let liquidation_threshold1: u16 = 200;
//         let liquidation_bonus1: u16 = 300;
//         let price_source1: address = @0x01;
//         let label1 = utf8(b"MODE1");
//         configure_emode_category(emode_cat_id1,
//             ltv1,
//             liquidation_threshold1,
//             liquidation_bonus1,
//             price_source1,
//             label1);
//
//         // init a reserve
//         test_init_pool(pool);
//
//         let underlying_asset_decimals = 2;
//         let a_token_tmpl = @0x011;
//         let variable_debt_token_addr = @0x013;
//         let underlying_asset_addr = @0x015;
//
//         let reserve_index =
//             create_reserve_with_config(underlying_asset_decimals,
//                 a_token_tmpl,
//                 variable_debt_token_addr,
//                 underlying_asset_addr,
//                 option::none(), // ltv
//                 option::none(), // liq threshold
//                 option::none(), // liq bonus
//                 option::some(2), //decimals
//                 option::some(true), //active
//                 option::some(false), //frozen
//                 option::some(false), // paused
//                 option::some(true), // borrowable_in_isolation
//                 option::some(true), // siloed_borrowing
//                 option::some(true), // borrowing_enabled
//                 option::none(), // reserve_factor
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
//         create_user_config_for_reserve(signer::address_of(user), reserve_index,
//             option::some(true), option::some(true));
//
//         // set user emode
//         set_user_emode(user, emode_cat_id1);
//
//         // get and assert user emode
//         let user_emode = get_user_emode(signer::address_of(user));
//         assert!(user_emode == (emode_cat_id1 as u256), TEST_SUCCESS);
//
//         assert!(is_in_emode_category(user_emode, (emode_cat_id1 as u256)), TEST_SUCCESS);
//         assert!(!is_in_emode_category(user_emode, (2 as u256)), TEST_SUCCESS);
//
//         // check emitted events
//         let emitted_events = emitted_events<UserEModeSet>();
//         // make sure event of type was emitted
//         assert!(vector::length(&emitted_events) == 1, TEST_SUCCESS);
//     }
//
//     #[test(pool = @aave_pool, mock_oracle = @aave_mock_oracle, user = @0x01, aave_std = @std,)]
//     #[expected_failure(abort_code = 58)]
//     fun test_user_emode_with_0_reserve(
//         pool: &signer, mock_oracle: &signer, user: &signer, aave_std: &signer,
//     ) {
//         // add the test events feature flag
//         change_feature_flags_for_testing(aave_std, vector[26], vector[]);
//
//         // init oracle
//         test_init_oracle(mock_oracle);
//
//         // init the emode
//         init_emode(pool);
//         // define an emode cat for reserve and user
//         let emode_cat_id1: u8 = 1;
//         // configure an emode category
//         let ltv1: u16 = 100;
//         let liquidation_threshold1: u16 = 200;
//         let liquidation_bonus1: u16 = 300;
//         let price_source1: address = @0x01;
//         let label1 = utf8(b"MODE1");
//         configure_emode_category(emode_cat_id1,
//             ltv1,
//             liquidation_threshold1,
//             liquidation_bonus1,
//             price_source1,
//             label1);
//
//         // init a reserve with 0 emod category
//         test_init_pool(pool);
//
//         let underlying_asset_decimals = 2;
//         let a_token_tmpl = @0x011;
//         let variable_debt_token_addr = @0x013;
//         let underlying_asset_addr = @0x015;
//         let reserve_index =
//             create_reserve_with_config(underlying_asset_decimals,
//                 a_token_tmpl,
//                 variable_debt_token_addr,
//                 underlying_asset_addr,
//                 option::none(), // ltv
//                 option::none(), // liq threshold
//                 option::none(), // liq bonus
//                 option::some(2), //decimals
//                 option::some(true), //active
//                 option::some(false), //frozen
//                 option::some(false), // paused
//                 option::some(true), // borrowable_in_isolation
//                 option::some(true), // siloed_borrowing
//                 option::some(true), // borrowing_enabled
//                 option::none(), // reserve_factor
//                 option::none(), // borrow_cap
//                 option::none(), // supply_cap
//                 option::none(), // debt_ceiling
//                 option::none(), // liquidation_protocol_fee
//                 option::none(), // unbacked_mint_cap
//                 option::none(), // e_mode_category
//                 option::some(true), // flash_loan_enabled
//             );
//
//         // init user config for reserve index
//         create_user_config_for_reserve(signer::address_of(user), reserve_index,
//             option::some(true), option::some(true));
//
//         // set user emode
//         set_user_emode(user, 2);
//     }
}
