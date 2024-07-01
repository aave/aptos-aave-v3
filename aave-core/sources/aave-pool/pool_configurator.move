module aave_pool::pool_configurator {
    use std::signer;
    use std::string::String;
    use std::vector;
    use aptos_framework::event;

    use aave_acl::acl_manage;
    use aave_config::error as error_config;
    use aave_config::reserve as reserve_config;
    use aave_math::math_utils;

    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::emode_logic;
    use aave_pool::pool;

    const CONFIGURATOR_REVISION: u256 = 0x1;

    #[event]
    struct ReserveBorrowing has store, drop {
        asset: address,
        enabled: bool
    }

    #[event]
    struct ReserveFlashLoaning has store, drop {
        asset: address,
        enabled: bool
    }

    #[event]
    struct CollateralConfigurationChanged has store, drop {
        asset: address,
        ltv: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256
    }

    #[event]
    struct ReserveActive has store, drop {
        asset: address,
        active: bool
    }

    #[event]
    struct ReserveFrozen has store, drop {
        asset: address,
        frozen: bool
    }

    #[event]
    struct ReservePaused has store, drop {
        asset: address,
        paused: bool
    }

    #[event]
    struct ReserveDropped has store, drop {
        asset: address,
    }

    #[event]
    struct ReserveFactorChanged has store, drop {
        asset: address,
        old_reserve_factor: u256,
        new_reserve_factor: u256
    }

    #[event]
    struct BorrowCapChanged has store, drop {
        asset: address,
        old_borrow_cap: u256,
        new_borrow_cap: u256
    }

    #[event]
    struct SupplyCapChanged has store, drop {
        asset: address,
        old_supply_cap: u256,
        new_supply_cap: u256
    }

    #[event]
    struct LiquidationProtocolFeeChanged has store, drop {
        asset: address,
        old_fee: u256,
        new_fee: u256
    }

    #[event]
    struct UnbackedMintCapChanged has store, drop {
        asset: address,
        old_unbacked_mint_cap: u256,
        new_unbacked_mint_cap: u256
    }

    #[event]
    struct EModeAssetCategoryChanged has store, drop {
        asset: address,
        old_category_id: u256,
        new_category_id: u256
    }

    #[event]
    struct EModeCategoryAdded has store, drop {
        category_id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        oracle: address,
        label: String
    }

    #[event]
    struct ReserveInterestRateStrategyChanged has store, drop {
        asset: address,
        old_rate_strategy: address,
        new_rate_strategy: address
    }

    #[event]
    struct DebtCeilingChanged has store, drop {
        asset: address,
        old_debt_ceiling: u256,
        new_debt_ceiling: u256
    }

    #[event]
    struct SiloedBorrowingChanged has store, drop {
        asset: address,
        old_state: bool,
        new_state: bool
    }

    #[event]
    struct BridgeProtocolFeeUpdated has store, drop {
        old_bridge_protocol_fee: u256,
        new_bridge_protocol_fee: u256
    }

    #[event]
    struct FlashloanPremiumTotalUpdated has store, drop {
        old_flashloan_premium_total: u128,
        new_flashloan_premium_total: u128
    }

    #[event]
    struct FlashloanPremiumToProtocolUpdated has store, drop {
        old_flashloan_premium_to_protocol: u128,
        new_flashloan_premium_to_protocol: u128
    }

    #[event]
    struct BorrowableInIsolationChanged has store, drop {
        asset: address,
        borrowable: bool
    }

    #[view]
    public fun get_revision(): u256 {
        CONFIGURATOR_REVISION
    }

    #[test_only]
    public fun test_init_module(account: &signer) {
        init_module(account)
    }

    // initialize reserves
    fun init_module(account: &signer) {
        assert!((signer::address_of(account) == @aave_pool),
            error_config::get_ecaller_not_pool_admin());
        pool::init_pool(account);
        emode_logic::init_emode(account);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy(account);
    }

    // Entry function to init reserves
    public entry fun init_reserves(
        account: &signer,
        underlying_asset: vector<address>,
        underlying_asset_decimals: vector<u8>,
        treasury: vector<address>,
        a_token_name: vector<String>,
        a_token_symbol: vector<String>,
        variable_debt_token_name: vector<String>,
        variable_debt_token_symbol: vector<String>,
    ) {
        assert!(only_asset_listing_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin());
        for (i in 0..vector::length(&underlying_asset)) {
            pool::init_reserve(
                account,
                *vector::borrow(&underlying_asset, i),
                *vector::borrow(&underlying_asset_decimals, i),
                *vector::borrow(&treasury, i),
                *vector::borrow(&a_token_name, i),
                *vector::borrow(&a_token_symbol, i),
                *vector::borrow(&variable_debt_token_name, i),
                *vector::borrow(&variable_debt_token_symbol, i)
            );
        };
    }

    // Entry function to drop reserves
    public entry fun drop_reserve(account: &signer, asset: address,) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());
        // Call the `drop_reserve` function in the `pool` module
        pool::drop_reserve(asset);
        event::emit(ReserveDropped { asset });
    }

    public entry fun set_reserve_borrowing(
        account: &signer, asset: address, enabled: bool
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);
        reserve_config::set_borrowing_enabled(&mut reserve_config_map, enabled);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveBorrowing { asset, enabled })
    }

    public entry fun configure_reserve_as_collateral(
        account: &signer,
        asset: address,
        ltv: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        assert!(ltv <= liquidation_threshold, error_config::get_einvalid_reserve_params());
        let reserve_config_map = pool::get_reserve_configuration(asset);
        if (liquidation_threshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            assert!(liquidation_bonus > math_utils::get_percentage_factor(),
                error_config::get_einvalid_reserve_params());

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            assert!(math_utils::percent_mul(liquidation_threshold, liquidation_bonus) <= math_utils::get_percentage_factor(),
                error_config::get_einvalid_reserve_params());
        } else {
            assert!(liquidation_bonus == 0, error_config::get_einvalid_reserve_params());
            //if the liquidation threshold is being set to 0,
            // the reserve is being disabled as collateral. To do so,
            //we need to ensure no liquidity is supplied
            check_no_suppliers(asset);
        };

        reserve_config::set_ltv(&mut reserve_config_map, ltv);
        reserve_config::set_liquidation_threshold(&mut reserve_config_map,
            liquidation_threshold);
        reserve_config::set_liquidation_bonus(&mut reserve_config_map, liquidation_bonus);

        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(CollateralConfigurationChanged {
                asset,
                ltv,
                liquidation_threshold,
                liquidation_bonus
            })
    }

    public entry fun set_reserve_flash_loaning(
        account: &signer, asset: address, enabled: bool
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_flash_loan_enabled(&mut reserve_config_map, enabled);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveFlashLoaning { asset, enabled })
    }

    public entry fun set_reserve_active(
        account: &signer, asset: address, active: bool
    ) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());
        if (!active) {
            check_no_suppliers(asset);
        };
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_active(&mut reserve_config_map, active);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveActive { asset, active })
    }

    public entry fun set_reserve_freeze(
        account: &signer, asset: address, freeze: bool
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_frozen(&mut reserve_config_map, freeze);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveFrozen { asset, frozen: freeze })
    }

    public entry fun set_borrowable_in_isolation(
        account: &signer, asset: address, borrowable: bool
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_borrowable_in_isolation(&mut reserve_config_map, borrowable);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(BorrowableInIsolationChanged { asset, borrowable })
    }

    public entry fun set_reserve_pause(
        account: &signer, asset: address, paused: bool
    ) {
        assert!(only_pool_or_emergency_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_or_emergency_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_paused(&mut reserve_config_map, paused);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReservePaused { asset, paused })
    }

    public entry fun set_reserve_factor(
        account: &signer, asset: address, new_reserve_factor: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        assert!(new_reserve_factor <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_reserve_factor());

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_reserve_factor: u256 = reserve_config::get_reserve_factor(&reserve_config_map);

        reserve_config::set_reserve_factor(&mut reserve_config_map, new_reserve_factor);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveFactorChanged { asset, old_reserve_factor, new_reserve_factor })
    }

    public entry fun set_debt_ceiling(
        account: &signer, asset: address, new_debt_ceiling: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_debt_ceiling: u256 = reserve_config::get_debt_ceiling(&reserve_config_map);
        if (old_debt_ceiling == 0) {
            check_no_suppliers(asset);
        };
        reserve_config::set_debt_ceiling(&mut reserve_config_map, new_debt_ceiling);
        pool::set_reserve_configuration(asset, reserve_config_map);
        if (new_debt_ceiling == 0) {
            pool::reset_isolation_mode_total_debt(asset)
        };

        event::emit(DebtCeilingChanged { asset, old_debt_ceiling, new_debt_ceiling })
    }

    public entry fun set_siloed_borrowing(
        account: &signer, asset: address, new_siloed: bool
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        if (new_siloed) {
            check_no_borrowers(asset);
        };
        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_siloed: bool = reserve_config::get_siloed_borrowing(&reserve_config_map);
        reserve_config::set_siloed_borrowing(&mut reserve_config_map, new_siloed);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(SiloedBorrowingChanged { asset, old_state: old_siloed, new_state: new_siloed })
    }

    public entry fun set_borrow_cap(
        account: &signer, asset: address, new_borrow_cap: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_borrow_cap: u256 = reserve_config::get_borrow_cap(&reserve_config_map);

        reserve_config::set_borrow_cap(&mut reserve_config_map, new_borrow_cap);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(BorrowCapChanged { asset, old_borrow_cap, new_borrow_cap })
    }

    public entry fun set_supply_cap(
        account: &signer, asset: address, new_supply_cap: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_supply_cap: u256 = reserve_config::get_supply_cap(&reserve_config_map);

        reserve_config::set_supply_cap(&mut reserve_config_map, new_supply_cap);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(SupplyCapChanged { asset, old_supply_cap, new_supply_cap })
    }

    public entry fun set_liquidation_protocol_fee(
        account: &signer, asset: address, new_fee: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        assert!(new_fee <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_liquidation_protocol_fee());

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_fee: u256 =
            reserve_config::get_liquidation_protocol_fee(&reserve_config_map);

        reserve_config::set_liquidation_protocol_fee(&mut reserve_config_map, new_fee);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(LiquidationProtocolFeeChanged { asset, old_fee, new_fee })
    }

    public entry fun set_emode_category(
        account: &signer,
        category_id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        oracle: address,
        label: String
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        assert!(ltv != 0, error_config::get_einvalid_emode_category_params());

        assert!(liquidation_threshold != 0,
            error_config::get_einvalid_emode_category_params());

        // validation of the parameters: the LTV can
        // only be lower or equal than the liquidation threshold
        // (otherwise a loan against the asset would cause instantaneous liquidation)
        assert!(ltv <= liquidation_threshold,
            error_config::get_einvalid_emode_category_params());

        assert!(liquidation_bonus > (math_utils::get_percentage_factor() as u16),
            error_config::get_einvalid_emode_category_params());

        // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
        // a loan is taken there is enough collateral available to cover the liquidation bonus
        assert!(math_utils::percent_mul((liquidation_threshold as u256), (liquidation_bonus as u256))
            <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_emode_category_params());

        let reserves = pool::get_reserves_list();
        for (i in 0..vector::length(&reserves)) {
            let reserve_config_map = pool::get_reserve_configuration(*vector::borrow(&reserves, i));
            if ((category_id as u256) == reserve_config::get_emode_category(&reserve_config_map)) {
                assert!((ltv as u256) > reserve_config::get_ltv(&reserve_config_map),
                    error_config::get_einvalid_emode_category_params());
                assert!((liquidation_threshold as u256) > reserve_config::get_liquidation_threshold(&reserve_config_map),
                    error_config::get_einvalid_emode_category_params());
            };
        };

        emode_logic::configure_emode_category(category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            oracle,
            label);

        event::emit(EModeCategoryAdded {
                category_id,
                ltv,
                liquidation_threshold,
                liquidation_bonus,
                oracle,
                label
            })
    }

    public entry fun set_asset_emode_category(
        account: &signer, asset: address, new_category_id: u8
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);
        if (new_category_id != 0) {
            let emode_category = emode_logic::get_emode_category_data(new_category_id);
            let liquidation_threshold =
                emode_logic::get_emode_category_liquidation_threshold(&emode_category);
            assert!(liquidation_threshold > (reserve_config::get_liquidation_threshold(&reserve_config_map) as u16),
                error_config::get_einvalid_emode_category_assignment());
        };
        let old_category_id = reserve_config::get_emode_category(&reserve_config_map);
        reserve_config::set_emode_category(&mut reserve_config_map, (new_category_id as u256));
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(EModeAssetCategoryChanged {
                asset,
                old_category_id,
                new_category_id: (new_category_id as u256)
            })
    }

    public entry fun set_unbacked_mint_cap(
        account: &signer, asset: address, new_unbacked_mint_cap: u256
    ) {
        assert!(only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin());
        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_unbacked_mint_cap: u256 = reserve_config::get_unbacked_mint_cap(&reserve_config_map);

        reserve_config::set_unbacked_mint_cap(&mut reserve_config_map, new_unbacked_mint_cap);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(UnbackedMintCapChanged {
                asset,
                old_unbacked_mint_cap,
                new_unbacked_mint_cap
            })
    }

    public entry fun set_pool_pause(account: &signer, paused: bool) {
        assert!(only_emergency_admin(signer::address_of(account)),
            error_config::get_ecaller_not_emergency_admin());
        let reserves_address = pool::get_reserves_list();
        for (i in 0..vector::length(&reserves_address)) {
            set_reserve_pause(account, *vector::borrow(&reserves_address, i), paused);
        };
    }

    public entry fun update_bridge_protocol_fee(
        account: &signer, new_bridge_protocol_fee: u256
    ) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());

        assert!(new_bridge_protocol_fee <= math_utils::get_percentage_factor(),
            error_config::get_ebridge_protocol_fee_invalid());
        let old_bridge_protocol_fee = pool::get_bridge_protocol_fee();
        pool::set_bridge_protocol_fee(new_bridge_protocol_fee);

        event::emit(BridgeProtocolFeeUpdated {
                old_bridge_protocol_fee,
                new_bridge_protocol_fee
            });
    }

    public entry fun update_flashloan_premium_total(
        account: &signer, new_flashloan_premium_total: u128
    ) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());

        assert!(new_flashloan_premium_total <= (math_utils::get_percentage_factor() as u128),
            error_config::get_eflashloan_premium_invalid());

        let old_flashloan_premium_total = pool::get_flashloan_premium_total();
        pool::set_flashloan_premiums(new_flashloan_premium_total,
            pool::get_flashloan_premium_to_protocol());
        event::emit(FlashloanPremiumTotalUpdated {
                old_flashloan_premium_total,
                new_flashloan_premium_total
            });
    }

    public entry fun update_flashloan_premium_to_protocol(
        account: &signer, new_flashloan_premium_to_protocol: u128
    ) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());
        assert!(new_flashloan_premium_to_protocol <= (math_utils::get_percentage_factor() as u128),
            error_config::get_eflashloan_premium_invalid());
        let old_flashloan_premium_to_protocol = pool::get_flashloan_premium_to_protocol();
        pool::set_flashloan_premiums(pool::get_flashloan_premium_total(),
            new_flashloan_premium_to_protocol);
        event::emit(FlashloanPremiumToProtocolUpdated {
                old_flashloan_premium_to_protocol,
                new_flashloan_premium_to_protocol
            })
    }

    fun check_no_suppliers(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(&reserve_data);
        let reserve_accrued_to_treasury = pool::get_reserve_accrued_to_treasury(&reserve_data);
        let a_token_total_supply = pool::scale_a_token_total_supply(a_token_address);
        assert!(a_token_total_supply == 0 && reserve_accrued_to_treasury == 0,
            error_config::get_ereserve_liquidity_not_zero());
    }

    fun check_no_borrowers(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let variable_debt_token_address = pool::get_reserve_variable_debt_token_address(&reserve_data);
        let total_debt = pool::scale_variable_token_total_supply(variable_debt_token_address);
        assert!(total_debt == 0, error_config::get_ereserve_debt_not_zero())
    }

    fun only_pool_admin(account: address): bool {
        acl_manage::is_pool_admin(account)
    }

    fun only_emergency_admin(account: address): bool {
        acl_manage::is_emergency_admin(account)
    }

    fun only_pool_or_emergency_admin(account: address): bool {
        acl_manage::is_pool_admin(account) || acl_manage::is_emergency_admin(account)
    }

    fun only_asset_listing_or_pool_admins(account: address): bool {
        acl_manage::is_asset_listing_admin(account) || acl_manage::is_pool_admin(account)
    }

    fun only_risk_or_pool_admins(account: address): bool {
        acl_manage::is_risk_admin(account) || acl_manage::is_pool_admin(account)
    }

    public entry fun configure_reserves(
        account: &signer,
        asset: vector<address>,
        base_ltv: vector<u256>,
        liquidation_threshold: vector<u256>,
        liquidation_bonus: vector<u256>,
        reserve_factor: vector<u256>,
        borrow_cap: vector<u256>,
        supply_cap: vector<u256>,
        borrowing_enabled: vector<bool>,
        flash_loan_enabled: vector<bool>
    ) {
        for (i in 0..vector::length(&asset)) {
            let asset_address = *vector::borrow(&asset, i);
            let ltv = *vector::borrow(&base_ltv, i);
            let threshold = *vector::borrow(&liquidation_threshold, i);
            let bonus = *vector::borrow(&liquidation_bonus, i);
            configure_reserve_as_collateral(account, asset_address, ltv, threshold, bonus);

            let is_borrowing_enabled = *vector::borrow(&borrowing_enabled, i);
            if (is_borrowing_enabled) {
                set_reserve_borrowing(account, asset_address, true);
                set_borrow_cap(account, asset_address, *vector::borrow(&borrow_cap, i));
            };

            set_reserve_flash_loaning(account, asset_address, *vector::borrow(&flash_loan_enabled, i));
            set_supply_cap(account, asset_address, *vector::borrow(&supply_cap, i));
            set_reserve_factor(account, asset_address, *vector::borrow(&reserve_factor, i));
        }
    }
}
