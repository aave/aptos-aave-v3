module aave_pool::emode_logic {
    use std::signer;
    use std::string;
    use std::string::String;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;

    use aave_config::error;
    use aave_mock_oracle::oracle;

    use aave_pool::pool;
    use aave_pool::pool_validation;

    friend aave_pool::pool_configurator;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;

    #[test_only]
    friend aave_pool::emode_logic_tests;
    #[test_only]
    friend aave_pool::supply_logic_tests;
    #[test_only]
    friend aave_pool::borrow_logic_tests;

    const EMPTY_STRING: vector<u8> = b"";

    #[event]
    struct UserEModeSet has store, drop {
        user: address,
        category_id: u8,
    }

    struct EModeCategory has store, copy, drop {
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        price_source: address,
        label: String,
    }

    // List of eMode categories as a map (eModeCategoryId => eModeCategory).
    struct EModeCategoryList has key {
        value: SmartTable<u8, EModeCategory>,
    }

    struct UsersEmodeCategory has key, store {
        value: SmartTable<address, u8>,
    }

    public(friend) fun init_emode(account: &signer) {
        assert!((signer::address_of(account) == @aave_pool),
            error::get_ecaller_not_pool_admin());
        move_to(account, EModeCategoryList { value: smart_table::new<u8, EModeCategory>(), });
        move_to(account, UsersEmodeCategory { value: smart_table::new<address, u8>(), })
    }

    public entry fun set_user_emode(account: &signer, category_id: u8) acquires UsersEmodeCategory, EModeCategoryList {
        //  validate set user emode
        let account_address = signer::address_of(account);
        let user_config_map = pool::get_user_configuration(account_address);
        let reserves_count = pool::get_reserves_count();
        let emode_configuration = get_emode_category_data(category_id);
        pool_validation::validate_set_user_emode(&user_config_map, reserves_count,
            category_id, emode_configuration.liquidation_threshold);

        let prev_category_id = get_user_emode(account_address);
        let user_emode_category = borrow_global_mut<UsersEmodeCategory>(@aave_pool);
        smart_table::upsert(&mut user_emode_category.value, account_address, category_id);
        let (emode_ltv, emode_liq_threshold, emode_asset_price) = get_emode_configuration(
            category_id);
        if (prev_category_id != 0) {
            pool_validation::validate_health_factor(reserves_count,
                &user_config_map,
                account_address,
                category_id,
                emode_ltv,
                emode_liq_threshold,
                emode_asset_price);
        };
        event::emit(UserEModeSet { user: account_address, category_id });
    }

    #[view]
    public fun get_user_emode(user: address): u256 acquires UsersEmodeCategory {
        let user_emode_category = borrow_global<UsersEmodeCategory>(@aave_pool);
        if (!smart_table::contains(&user_emode_category.value, user)) {
            return 0
        };
        let user_emode = smart_table::borrow(&user_emode_category.value, user);
        (*user_emode as u256)
    }

    public fun get_emode_e_mode_price_source(user_emode_category: u8): address acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return @0x0
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.price_source
    }

    public fun get_emode_configuration(user_emode_category: u8): (u256, u256, u256) acquires EModeCategoryList {
        let emode_asset_price = 0;
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return (0, 0, emode_asset_price)
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        let emode_price_source = emode_category.price_source;
        if (emode_price_source != @0x0) {
            emode_asset_price = oracle::get_asset_price(emode_price_source);
        };
        return ((emode_category.ltv as u256), (emode_category.liquidation_threshold as u256),
            emode_asset_price)
    }

    public fun get_emode_e_mode_label(user_emode_category: u8): String acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return string::utf8(EMPTY_STRING)
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.label
    }

    public fun get_emode_e_mode_liquidation_bonus(user_emode_category: u8): u16 acquires EModeCategoryList {
        let emode_category_list = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_list.value, user_emode_category)) {
            return 0
        };
        let emode_category =
            smart_table::borrow(&emode_category_list.value, user_emode_category);
        emode_category.liquidation_bonus
    }

    public(friend) fun configure_emode_category(
        id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        price_source: address,
        label: String
    ) acquires EModeCategoryList {
        assert!(id != 0, error::get_eemode_category_reserved());
        let emode_category_list = borrow_global_mut<EModeCategoryList>(@aave_pool);
        smart_table::upsert(&mut emode_category_list.value,
            id,
            EModeCategory {
                ltv,
                liquidation_threshold,
                liquidation_bonus,
                price_source,
                label,
            });
    }

    public fun is_in_emode_category(
        emode_user_category: u256, emode_assert_category: u256
    ): bool {
        emode_user_category != 0 && emode_assert_category == emode_user_category
    }

    #[view]
    public fun get_emode_category_data(id: u8): EModeCategory acquires EModeCategoryList {
        let emode_category_data = borrow_global<EModeCategoryList>(@aave_pool);
        if (!smart_table::contains(&emode_category_data.value, id)) {
            return EModeCategory {
                ltv: 0,
                liquidation_threshold: 0,
                liquidation_bonus: 0,
                // each eMode category may or may not have a custom oracle to override the individual assets price oracles
                price_source: @0x0,
                label: string::utf8(b""),
            }
        };

        *smart_table::borrow<u8, EModeCategory>(&emode_category_data.value, id)
    }

    public fun get_emode_category_ltv(emode_category: &EModeCategory): u16 {
        emode_category.ltv
    }

    public fun get_emode_category_liquidation_threshold(
        emode_category: &EModeCategory
    ): u16 {
        emode_category.liquidation_threshold
    }

    public fun get_emode_category_liquidation_bonus(
        emode_category: &EModeCategory
    ): u16 {
        emode_category.liquidation_bonus
    }

    public fun get_emode_category_price_source(
        emode_category: &EModeCategory
    ): address {
        emode_category.price_source
    }

    public fun get_emode_category_label(emode_category: &EModeCategory): String {
        emode_category.label
    }
}
