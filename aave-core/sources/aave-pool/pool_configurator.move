/// @title Pool Configurator Module
/// @author Aave
/// @notice Implements functionality to configure the Aave protocol pool parameters
module aave_pool::pool_configurator {
    // imports
    use std::option::Option;
    use std::signer;
    use std::string::String;
    use std::vector;
    use aptos_std::smart_table;
    use aptos_std::smart_table::SmartTable;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_config::reserve_config;
    use aave_math::math_utils;
    use aave_pool::pool_fee_manager;
    use aave_pool::pool_logic;
    use aave_pool::variable_debt_token_factory;
    use aave_pool::a_token_factory;
    use aave_pool::pool_token_logic;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::emode_logic;
    use aave_pool::pool;

    // Structs
    /// @notice Internal module data
    struct InternalData has key {
        /// Map between an asset address and its pending ltv
        pending_ltv: SmartTable<address, u256>
    }

    // Events
    #[event]
    /// @notice Emitted when reserve interest rate strategy configuration is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param optimal_usage_ratio Optimal utilization ratio used in the interest rate calculation
    /// @param base_variable_borrow_rate Base variable borrow rate when usage rate is 0 (expressed in ray)
    /// @param variable_rate_slope1 Slope of the variable rate curve when usage <= optimal (expressed in ray)
    /// @param variable_rate_slope2 Slope of the variable rate curve when usage > optimal (expressed in ray)
    struct ReserveInterestRateDataChanged has store, drop {
        asset: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    #[event]
    /// @notice Emitted when borrowing is enabled or disabled on a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if borrowing is enabled, false otherwise
    struct ReserveBorrowing has store, drop {
        asset: address,
        enabled: bool
    }

    #[event]
    /// @notice Emitted when flashloans are enabled or disabled on a reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if flashloans are enabled, false otherwise
    struct ReserveFlashLoaning has store, drop {
        asset: address,
        enabled: bool
    }

    #[event]
    /// @notice Emitted when the collateralization risk parameters for the specified asset are updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param ltv The loan to value of the asset when used as collateral
    /// @param liquidation_threshold The threshold at which loans using this asset as collateral will be considered undercollateralized
    /// @param liquidation_bonus The bonus liquidators receive to liquidate this asset
    struct CollateralConfigurationChanged has store, drop {
        asset: address,
        ltv: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256
    }

    #[event]
    /// @notice Emitted when the pending ltv has changed during reserve freezing
    /// @param asset The address of the underlying asset of the reserve
    /// @param pending_ltv_set The pending loan to value of the asset when used as collateral
    struct PendingLtvChanged has store, drop {
        asset: address,
        pending_ltv_set: u256
    }

    #[event]
    /// @notice Emitted when a reserve is activated or deactivated
    /// @param asset The address of the underlying asset of the reserve
    /// @param active True if reserve is active, false otherwise
    struct ReserveActive has store, drop {
        asset: address,
        active: bool
    }

    #[event]
    /// @notice Emitted when a reserve is frozen or unfrozen
    /// @param asset The address of the underlying asset of the reserve
    /// @param frozen True if reserve is frozen, false otherwise
    struct ReserveFrozen has store, drop {
        asset: address,
        frozen: bool
    }

    #[event]
    /// @notice Emitted when a reserve is paused or unpaused
    /// @param asset The address of the underlying asset of the reserve
    /// @param paused True if reserve is paused, false otherwise
    struct ReservePaused has store, drop {
        asset: address,
        paused: bool
    }

    #[event]
    /// @notice Emitted when a reserve is dropped
    /// @param asset The address of the underlying asset of the reserve
    struct ReserveDropped has store, drop {
        asset: address
    }

    #[event]
    /// @notice Emitted when a reserve factor is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_reserve_factor The old reserve factor, expressed in bps
    /// @param new_reserve_factor The new reserve factor, expressed in bps
    struct ReserveFactorChanged has store, drop {
        asset: address,
        old_reserve_factor: u256,
        new_reserve_factor: u256
    }

    #[event]
    /// @notice Emitted when the borrow cap of a reserve is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_borrow_cap The old borrow cap
    /// @param new_borrow_cap The new borrow cap
    struct BorrowCapChanged has store, drop {
        asset: address,
        old_borrow_cap: u256,
        new_borrow_cap: u256
    }

    #[event]
    /// @notice Emitted when the supply cap of a reserve is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_supply_cap The old supply cap
    /// @param new_supply_cap The new supply cap
    struct SupplyCapChanged has store, drop {
        asset: address,
        old_supply_cap: u256,
        new_supply_cap: u256
    }

    #[event]
    /// @notice Emitted when the liquidation protocol fee of a reserve is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_fee The old liquidation protocol fee, expressed in bps
    /// @param new_fee The new liquidation protocol fee, expressed in bps
    struct LiquidationProtocolFeeChanged has store, drop {
        asset: address,
        old_fee: u256,
        new_fee: u256
    }

    #[event]
    /// @notice Emitted when the liquidation grace period is updated
    /// @param asset The address of the underlying asset of the reserve
    /// @param grace_period_until Timestamp until when liquidations will not be allowed post-unpause
    struct LiquidationGracePeriodChanged has store, drop {
        asset: address,
        grace_period_until: u64
    }

    #[event]
    /// @notice Emitted when the liquidation grace period is disabled
    /// @param asset The address of the underlying asset of the reserve
    struct LiquidationGracePeriodDisabled has store, drop {
        asset: address
    }

    #[event]
    /// @notice Emitted when the category of an asset in eMode is changed
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_category_id The old eMode asset category
    /// @param new_category_id The new eMode asset category
    struct EModeAssetCategoryChanged has store, drop {
        asset: address,
        old_category_id: u8,
        new_category_id: u8
    }

    #[event]
    /// @notice Emitted when a new eMode category is added
    /// @param category_id The new eMode category id
    /// @param ltv The ltv for the asset category in eMode
    /// @param liquidation_threshold The liquidationThreshold for the asset category in eMode
    /// @param liquidation_bonus The liquidationBonus for the asset category in eMode
    /// @param oracle The optional address of the price oracle specific for this category
    /// @param label A human readable identifier for the category
    struct EModeCategoryAdded has store, drop {
        category_id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        label: String
    }

    #[event]
    /// @notice Emitted when the debt ceiling of an asset is set
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_debt_ceiling The old debt ceiling
    /// @param new_debt_ceiling The new debt ceiling
    struct DebtCeilingChanged has store, drop {
        asset: address,
        old_debt_ceiling: u256,
        new_debt_ceiling: u256
    }

    #[event]
    /// @notice Emitted when the the siloed borrowing state for an asset is changed
    /// @param asset The address of the underlying asset of the reserve
    /// @param old_state The old siloed borrowing state
    /// @param new_state The new siloed borrowing state
    struct SiloedBorrowingChanged has store, drop {
        asset: address,
        old_state: bool,
        new_state: bool
    }

    #[event]
    /// @notice Emitted when the total premium on flashloans is updated
    /// @param old_flashloan_premium_total The old premium, expressed in bps
    /// @param new_flashloan_premium_total The new premium, expressed in bps
    struct FlashloanPremiumTotalUpdated has store, drop {
        old_flashloan_premium_total: u128,
        new_flashloan_premium_total: u128
    }

    #[event]
    /// @notice Emitted when the part of the premium that goes to protocol is updated
    /// @param old_flashloan_premium_to_protocol The old premium, expressed in bps
    /// @param new_flashloan_premium_to_protocol The new premium, expressed in bps
    struct FlashloanPremiumToProtocolUpdated has store, drop {
        old_flashloan_premium_to_protocol: u128,
        new_flashloan_premium_to_protocol: u128
    }

    #[event]
    /// @notice Emitted when the reserve is set as borrowable/non borrowable in isolation mode
    /// @param asset The address of the underlying asset of the reserve
    /// @param borrowable True if the reserve is borrowable in isolation, false otherwise
    struct BorrowableInIsolationChanged has store, drop {
        asset: address,
        borrowable: bool
    }

    // Public view functions
    #[view]
    /// @notice Returns the pending Loan-to-Value (LTV) ratio for the given asset
    /// @dev Reads from the `InternalData` resource but does not modify state
    /// @param asset The address of the underlying asset
    /// @return The pending LTV value as a `u256`, or 0 if not set
    public fun get_pending_ltv(asset: address): u256 acquires InternalData {
        let pending_ltv = &borrow_global<InternalData>(@aave_pool).pending_ltv;
        *smart_table::borrow_with_default(pending_ltv, asset, &0)
    }

    // Public entry functions
    /// @notice Initializes multiple reserves
    /// @param account The account signer of the caller
    /// @param underlying_asset The list of the underlying assets of the reserves
    /// @param treasury The list of the treasury addresses of the reserves
    /// @param a_token_name The list of the aToken names of the reserves
    /// @param a_token_symbol The list of the aToken symbols of the reserves
    /// @param variable_debt_token_name The list of the variable debt token names of the reserves
    /// @param variable_debt_token_symbol The list of the variable debt token symbols of the reserves
    /// @param incentives_controller The list of incentives controllers for the reserves
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    /// @dev The caller needs to be an asset listing or pool admin
    public entry fun init_reserves(
        account: &signer,
        underlying_asset: vector<address>,
        treasury: vector<address>,
        a_token_name: vector<String>,
        a_token_symbol: vector<String>,
        variable_debt_token_name: vector<String>,
        variable_debt_token_symbol: vector<String>,
        incentives_controller: vector<Option<address>>,
        optimal_usage_ratio: vector<u256>,
        base_variable_borrow_rate: vector<u256>,
        variable_rate_slope1: vector<u256>,
        variable_rate_slope2: vector<u256>
    ) {
        assert!(
            only_asset_listing_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );

        let underlying_asset_len = vector::length(&underlying_asset);
        let treasury_len = vector::length(&treasury);
        let a_token_name_len = vector::length(&a_token_name);
        let a_token_symbol_len = vector::length(&a_token_symbol);
        let var_debt_name_len = vector::length(&variable_debt_token_name);
        let var_debt_symbol_len = vector::length(&variable_debt_token_symbol);
        let var_incentives_controller_len = vector::length(&incentives_controller);
        let optimal_usage_ratio_len = vector::length(&optimal_usage_ratio);
        let base_variable_borrow_rate_len = vector::length(&base_variable_borrow_rate);
        let variable_rate_slope1_len = vector::length(&variable_rate_slope1);
        let variable_rate_slope2_len = vector::length(&variable_rate_slope2);

        assert!(
            (
                underlying_asset_len == treasury_len
                    && underlying_asset_len == a_token_name_len
                    && underlying_asset_len == a_token_symbol_len
                    && underlying_asset_len == var_debt_name_len
                    && underlying_asset_len == var_debt_symbol_len
                    && underlying_asset_len == optimal_usage_ratio_len
                    && underlying_asset_len == base_variable_borrow_rate_len
                    && underlying_asset_len == variable_rate_slope1_len
                    && underlying_asset_len == variable_rate_slope2_len
                    && underlying_asset_len == var_incentives_controller_len
            ),
            error_config::get_einconsistent_params_length()
        );

        for (i in 0..underlying_asset_len) {
            let asset = *vector::borrow(&underlying_asset, i);
            let optimal_usage_ratio = *vector::borrow(&optimal_usage_ratio, i);
            let base_variable_borrow_rate = *vector::borrow(
                &base_variable_borrow_rate, i
            );
            let variable_rate_slope1 = *vector::borrow(&variable_rate_slope1, i);
            let variable_rate_slope2 = *vector::borrow(&variable_rate_slope2, i);

            pool_token_logic::init_reserve(
                account,
                asset,
                *vector::borrow(&treasury, i),
                *vector::borrow(&incentives_controller, i),
                *vector::borrow(&a_token_name, i),
                *vector::borrow(&a_token_symbol, i),
                *vector::borrow(&variable_debt_token_name, i),
                *vector::borrow(&variable_debt_token_symbol, i),
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            );

            event::emit(
                ReserveInterestRateDataChanged {
                    asset,
                    optimal_usage_ratio,
                    base_variable_borrow_rate,
                    variable_rate_slope1,
                    variable_rate_slope2
                }
            );
        };
    }

    /// @notice Drops a reserve entirely
    /// @dev Emits the `ReserveDropped` event
    /// @param account The account signer of the caller
    /// @param asset The address of the reserve to drop
    public entry fun drop_reserve(account: &signer, asset: address) acquires InternalData {
        assert!(
            only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );
        // Call the `drop_reserve` function in the `pool_token_logic` module
        pool_token_logic::drop_reserve(asset);

        // remove any pending ltv
        let pending_ltv = &mut borrow_global_mut<InternalData>(@aave_pool).pending_ltv;
        if (smart_table::contains(pending_ltv, asset)) {
            smart_table::remove(pending_ltv, asset);
        };

        event::emit(ReserveDropped { asset });
    }

    /// @notice Configures borrowing on a reserve
    /// @dev Emits the ReserveBorrowing event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if borrowing needs to be enabled, false otherwise
    public entry fun set_reserve_borrowing(
        account: &signer, asset: address, enabled: bool
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        reserve_config::set_borrowing_enabled(&mut reserve_config_map, enabled);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveBorrowing { asset, enabled })
    }

    /// @notice Forcefully updates the interest rate strategy of the pool reserve
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param optimal_usage_ratio The optimal usage ratio, in bps
    /// @param base_variable_borrow_rate The base variable borrow rate, in bps
    /// @param variable_rate_slope1 The slope of the variable interest curve, before hitting the optimal ratio, in bps
    /// @param variable_rate_slope2 The slope of the variable interest curve, after hitting the optimal ratio, in bps
    public entry fun update_interest_rate_strategy(
        account: &signer,
        asset: address,
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        // sync indexes state
        sync_indexes_state(asset);

        // update the reserve interest rate strategy
        default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy(
            asset,
            optimal_usage_ratio,
            base_variable_borrow_rate,
            variable_rate_slope1,
            variable_rate_slope2
        );

        event::emit(
            ReserveInterestRateDataChanged {
                asset,
                optimal_usage_ratio,
                base_variable_borrow_rate,
                variable_rate_slope1,
                variable_rate_slope2
            }
        );

        // sync rates state
        sync_rates_state(asset);
    }

    /// @notice Configures the reserve collateralization parameters
    /// @dev Emits the CollateralConfigurationChanged event
    /// @dev All the values are expressed in bps. A value of 10000, results in 100.00%
    /// @dev The `liquidation_bonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param ltv The loan to value of the asset when used as collateral
    /// @param liquidation_threshold The threshold at which loans using this asset as collateral will be considered undercollateralized
    /// @param liquidation_bonus The bonus liquidators receive to liquidate this asset
    public entry fun configure_reserve_as_collateral(
        account: &signer,
        asset: address,
        ltv: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256
    ) acquires InternalData {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        // validation of the parameters: the LTV can
        // only be lower or equal than the liquidation threshold
        // (otherwise a loan against the asset would cause instantaneous liquidation)
        assert!(
            ltv <= liquidation_threshold,
            error_config::get_einvalid_reserve_params()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let emode_id = reserve_config::get_emode_category(&reserve_config_map);
        if (emode_id != 0) {
            let emode_category = emode_logic::get_emode_category_data((emode_id as u8));
            let emode_ltv = emode_logic::get_emode_category_ltv(&emode_category);
            assert!((emode_ltv as u256) > ltv, error_config::get_einvalid_reserve_params());
            let emode_liquidation_threshold =
                emode_logic::get_emode_category_liquidation_threshold(&emode_category);
            assert!(
                (emode_liquidation_threshold as u256) > liquidation_threshold,
                error_config::get_einvalid_reserve_params()
            );
        };

        if (liquidation_threshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            assert!(
                liquidation_bonus > math_utils::get_percentage_factor(),
                error_config::get_einvalid_reserve_params()
            );

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            assert!(
                math_utils::percent_mul(liquidation_threshold, liquidation_bonus)
                    <= math_utils::get_percentage_factor(),
                error_config::get_einvalid_reserve_params()
            );
        } else {
            assert!(liquidation_bonus == 0, error_config::get_einvalid_reserve_params());
            //if the liquidation threshold is being set to 0,
            // the reserve is being disabled as collateral. To do so,
            //we need to ensure no liquidity is supplied
            check_no_suppliers(asset);
        };

        let new_ltv = ltv;
        if (reserve_config::get_frozen(&reserve_config_map)) {
            let internal_data = borrow_global_mut<InternalData>(@aave_pool);
            smart_table::upsert(&mut internal_data.pending_ltv, asset, ltv);
            new_ltv = 0;
            event::emit(PendingLtvChanged { asset, pending_ltv_set: ltv });
        } else {
            reserve_config::set_ltv(&mut reserve_config_map, ltv);
        };

        reserve_config::set_liquidation_threshold(
            &mut reserve_config_map, liquidation_threshold
        );
        reserve_config::set_liquidation_bonus(&mut reserve_config_map, liquidation_bonus);

        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(
            CollateralConfigurationChanged {
                asset,
                ltv: new_ltv,
                liquidation_threshold,
                liquidation_bonus
            }
        )
    }

    /// @notice Enable or disable flashloans on a reserve
    /// @dev Emits the ReserveFlashLoaning event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param enabled True if flashloans need to be enabled, false otherwise
    public entry fun set_reserve_flash_loaning(
        account: &signer, asset: address, enabled: bool
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_flash_loan_enabled(&mut reserve_config_map, enabled);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveFlashLoaning { asset, enabled })
    }

    /// @notice Activate or deactivate a reserve
    /// @dev Emits the ReserveActive event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param active True if the reserve needs to be active, false otherwise
    public entry fun set_reserve_active(
        account: &signer, asset: address, active: bool
    ) {
        assert!(
            only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );

        if (!active) {
            check_no_suppliers(asset);
        };
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_active(&mut reserve_config_map, active);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveActive { asset, active })
    }

    /// @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
    /// or rate swap but allows repayments, liquidations, rate rebalances and withdrawals
    /// @dev Emits the ReserveFrozen event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param freeze True if the reserve needs to be frozen, false otherwise
    public entry fun set_reserve_freeze(
        account: &signer, asset: address, freeze: bool
    ) acquires InternalData {
        assert!(
            only_risk_or_pool_or_emergency_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_or_emergency_admin()
        );
        let reserve_config_map = pool::get_reserve_configuration(asset);
        assert!(
            reserve_config::get_frozen(&reserve_config_map) != freeze,
            error_config::get_einvalid_freeze_flag()
        );
        reserve_config::set_frozen(&mut reserve_config_map, freeze);

        let internal_data = borrow_global_mut<InternalData>(@aave_pool);

        let pending_ltv_set = 0;
        let ltv_set = 0;
        if (freeze) {
            pending_ltv_set = reserve_config::get_ltv(&reserve_config_map);
            smart_table::upsert(&mut internal_data.pending_ltv, asset, pending_ltv_set);
            reserve_config::set_ltv(&mut reserve_config_map, 0);
        } else {
            if (smart_table::contains(&internal_data.pending_ltv, asset)) {
                ltv_set = smart_table::remove(&mut internal_data.pending_ltv, asset);
            };
            reserve_config::set_ltv(&mut reserve_config_map, ltv_set);
        };

        event::emit(PendingLtvChanged { asset, pending_ltv_set });

        event::emit(
            CollateralConfigurationChanged {
                asset,
                ltv: ltv_set,
                liquidation_threshold: reserve_config::get_liquidation_threshold(
                    &reserve_config_map
                ),
                liquidation_bonus: reserve_config::get_liquidation_bonus(
                    &reserve_config_map
                )
            }
        );

        pool::set_reserve_configuration(asset, reserve_config_map);
        event::emit(ReserveFrozen { asset, frozen: freeze })
    }

    /// @notice Sets the borrowable in isolation flag for the reserve
    /// @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
    /// borrowed amount will be accumulated in the isolated collateral's total debt exposure
    /// @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
    /// consistency in the debt ceiling calculations
    /// @dev Emits the BorrowableInIsolationChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param borrowable True if the asset should be borrowable in isolation, false otherwise
    public entry fun set_borrowable_in_isolation(
        account: &signer, asset: address, borrowable: bool
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        let reserve_config_map = pool::get_reserve_configuration(asset);

        reserve_config::set_borrowable_in_isolation(&mut reserve_config_map, borrowable);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(BorrowableInIsolationChanged { asset, borrowable })
    }

    /// @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
    /// swap interest rate, liquidate, atoken transfers)
    /// @dev Emits the ReservePaused event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param paused True if pausing the reserve, false if unpausing
    /// @param grace_period Count of seconds after unpause during which liquidations will not be available
    /// - Only applicable whenever unpausing (`paused` as false)
    /// - Passing 0 means no grace period
    /// - Capped to maximum MAX_GRACE_PERIOD
    public entry fun set_reserve_pause(
        account: &signer, asset: address, paused: bool, grace_period: u64
    ) {
        assert!(
            only_pool_or_emergency_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_or_emergency_admin()
        );

        let reserve_data = pool::get_reserve_data(asset);
        if (!paused && grace_period != 0) {
            assert!(
                grace_period
                    <= (reserve_config::get_max_valid_liquidation_grace_period() as u64),
                error_config::get_einvalid_grace_period()
            );

            let until = timestamp::now_seconds() + grace_period;
            pool::set_liquidation_grace_period(reserve_data, until);
            event::emit(LiquidationGracePeriodChanged { asset, grace_period_until: until })
        };

        let reserve_config_map =
            pool::get_reserve_configuration_by_reserve_data(reserve_data);

        reserve_config::set_paused(&mut reserve_config_map, paused);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReservePaused { asset, paused })
    }

    /// @notice Pauses/unpauses a reserve with no grace period
    /// @dev Emits the ReservePaused event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param paused True if pausing the reserve, false if unpausing
    public entry fun set_reserve_pause_no_grace_period(
        account: &signer, asset: address, paused: bool
    ) {
        set_reserve_pause(account, asset, paused, 0);
    }

    /// @notice Disables liquidation grace period for the asset. The liquidation grace period is set in the past
    /// so that liquidations are allowed for the asset
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    public entry fun disable_liquidation_grace_period(
        account: &signer, asset: address
    ) {
        assert!(
            only_pool_or_emergency_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_or_emergency_admin()
        );

        // set the liquidation grace period in the past to disable liquidation grace period
        let reserve_data = pool::get_reserve_data(asset);
        pool::set_liquidation_grace_period(reserve_data, 0);

        event::emit(LiquidationGracePeriodDisabled { asset })
    }

    /// @notice Updates the reserve factor of a reserve
    /// @dev Emits the ReserveFactorChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_reserve_factor The new reserve factor of the reserve
    public entry fun set_reserve_factor(
        account: &signer, asset: address, new_reserve_factor: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        assert!(
            new_reserve_factor <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_reserve_factor()
        );

        sync_indexes_state(asset);

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_reserve_factor: u256 =
            reserve_config::get_reserve_factor(&reserve_config_map);

        reserve_config::set_reserve_factor(&mut reserve_config_map, new_reserve_factor);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(ReserveFactorChanged { asset, old_reserve_factor, new_reserve_factor });

        sync_rates_state(asset);
    }

    /// @notice Sets the debt ceiling for an asset
    /// @dev Emits the DebtCeilingChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_debt_ceiling The new debt ceiling
    public entry fun set_debt_ceiling(
        account: &signer, asset: address, new_debt_ceiling: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_debt_ceiling: u256 =
            reserve_config::get_debt_ceiling(&reserve_config_map);

        if (reserve_config::get_liquidation_threshold(&reserve_config_map) != 0
            && old_debt_ceiling == 0) {
            check_no_suppliers(asset);
        };

        reserve_config::set_debt_ceiling(&mut reserve_config_map, new_debt_ceiling);
        pool::set_reserve_configuration(asset, reserve_config_map);

        if (new_debt_ceiling == 0) {
            pool::reset_isolation_mode_total_debt(asset)
        };

        event::emit(DebtCeilingChanged { asset, old_debt_ceiling, new_debt_ceiling })
    }

    /// @notice Sets siloed borrowing for an asset
    /// @dev Emits the SiloedBorrowingChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_siloed The new siloed borrowing state
    public entry fun set_siloed_borrowing(
        account: &signer, asset: address, new_siloed: bool
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        if (new_siloed) {
            check_no_borrowers(asset);
        };

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_siloed: bool = reserve_config::get_siloed_borrowing(&reserve_config_map);
        reserve_config::set_siloed_borrowing(&mut reserve_config_map, new_siloed);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(
            SiloedBorrowingChanged {
                asset,
                old_state: old_siloed,
                new_state: new_siloed
            }
        )
    }

    /// @notice Updates the borrow cap of a reserve
    /// @dev Emits the BorrowCapChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_borrow_cap The new borrow cap of the reserve
    public entry fun set_borrow_cap(
        account: &signer, asset: address, new_borrow_cap: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_borrow_cap: u256 = reserve_config::get_borrow_cap(&reserve_config_map);

        reserve_config::set_borrow_cap(&mut reserve_config_map, new_borrow_cap);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(BorrowCapChanged { asset, old_borrow_cap, new_borrow_cap })
    }

    /// @notice Updates the supply cap of a reserve
    /// @dev Emits the SupplyCapChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_supply_cap The new supply cap of the reserve
    public entry fun set_supply_cap(
        account: &signer, asset: address, new_supply_cap: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_supply_cap: u256 = reserve_config::get_supply_cap(&reserve_config_map);

        reserve_config::set_supply_cap(&mut reserve_config_map, new_supply_cap);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(SupplyCapChanged { asset, old_supply_cap, new_supply_cap })
    }

    /// @notice Updates the liquidation protocol fee of reserve
    /// @dev Emits the LiquidationProtocolFeeChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_fee The new liquidation protocol fee of the reserve, expressed in bps
    public entry fun set_liquidation_protocol_fee(
        account: &signer, asset: address, new_fee: u256
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        assert!(
            new_fee <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_liquidation_protocol_fee()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        let old_fee = reserve_config::get_liquidation_protocol_fee(&reserve_config_map);

        reserve_config::set_liquidation_protocol_fee(&mut reserve_config_map, new_fee);
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(LiquidationProtocolFeeChanged { asset, old_fee, new_fee })
    }

    /// @notice Adds a new efficiency mode (eMode) category or alters an existing one.
    /// @dev The new ltv and liquidation threshold must be greater than the base
    /// ltvs and liquidation thresholds of all assets within the eMode category
    /// @dev Emits the EModeCategoryAdded event
    /// @param account The account signer of the caller
    /// @param category_id The id of the category to be configured
    /// @param ltv The ltv associated with the category
    /// @param liquidation_threshold The liquidation threshold associated with the category
    /// @param liquidation_bonus The liquidation bonus associated with the category
    /// @param label A label identifying the category
    public entry fun set_emode_category(
        account: &signer,
        category_id: u8,
        ltv: u16,
        liquidation_threshold: u16,
        liquidation_bonus: u16,
        label: String
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        assert!(ltv != 0, error_config::get_einvalid_emode_category_params());

        assert!(
            liquidation_threshold != 0,
            error_config::get_einvalid_emode_category_params()
        );

        // validation of the parameters: the LTV can
        // only be lower or equal than the liquidation threshold
        // (otherwise a loan against the asset would cause instantaneous liquidation)
        assert!(
            ltv <= liquidation_threshold,
            error_config::get_einvalid_emode_category_params()
        );

        assert!(
            liquidation_bonus > (math_utils::get_percentage_factor() as u16),
            error_config::get_einvalid_emode_category_params()
        );

        // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
        // a loan is taken there is enough collateral available to cover the liquidation bonus
        assert!(
            math_utils::percent_mul(
                (liquidation_threshold as u256), (liquidation_bonus as u256)
            ) <= math_utils::get_percentage_factor(),
            error_config::get_einvalid_emode_category_params()
        );

        let reserves = pool::get_reserves_list();
        for (i in 0..vector::length(&reserves)) {
            let reserve_config_map =
                pool::get_reserve_configuration(*vector::borrow(&reserves, i));
            if ((category_id as u256)
                == reserve_config::get_emode_category(&reserve_config_map)) {
                assert!(
                    (ltv as u256) > reserve_config::get_ltv(&reserve_config_map),
                    error_config::get_einvalid_emode_category_params()
                );
                assert!(
                    (liquidation_threshold as u256)
                        > reserve_config::get_liquidation_threshold(&reserve_config_map),
                    error_config::get_einvalid_emode_category_params()
                );
            };
        };

        emode_logic::configure_emode_category(
            category_id,
            ltv,
            liquidation_threshold,
            liquidation_bonus,
            label
        );

        event::emit(
            EModeCategoryAdded {
                category_id,
                ltv,
                liquidation_threshold,
                liquidation_bonus,
                label
            }
        )
    }

    /// @notice Assign an efficiency mode (eMode) category to asset
    /// @dev Emits the EModeAssetCategoryChanged event
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_category_id The new category id of the asset
    public entry fun set_asset_emode_category(
        account: &signer, asset: address, new_category_id: u8
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );

        let reserve_config_map = pool::get_reserve_configuration(asset);
        if (new_category_id != 0) {
            let emode_category = emode_logic::get_emode_category_data(new_category_id);
            let emode_ltv = emode_logic::get_emode_category_ltv(&emode_category);
            assert!(
                (emode_ltv as u256) > reserve_config::get_ltv(&reserve_config_map),
                error_config::get_einvalid_emode_category_assignment()
            );

            let emode_liquidation_threshold =
                emode_logic::get_emode_category_liquidation_threshold(&emode_category);
            assert!(
                (emode_liquidation_threshold as u256)
                    > reserve_config::get_liquidation_threshold(&reserve_config_map),
                error_config::get_einvalid_emode_category_assignment()
            );
        };

        let old_category_id = reserve_config::get_emode_category(&reserve_config_map);
        reserve_config::set_emode_category(
            &mut reserve_config_map, (new_category_id as u256)
        );
        pool::set_reserve_configuration(asset, reserve_config_map);

        event::emit(
            EModeAssetCategoryChanged {
                asset,
                old_category_id: old_category_id as u8,
                new_category_id
            }
        )
    }

    /// @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
    /// are suspended
    /// @dev Emits the ReservePaused event for each reserve
    /// @param account The account signer of the caller
    /// @param paused True if protocol needs to be paused, false otherwise
    /// @param grace_period Count of seconds after unpause during which liquidations will not be available
    /// - Only applicable whenever unpausing (`paused` as false)
    /// - Passing 0 means no grace period
    /// - Capped to maximum MAX_GRACE_PERIOD
    public entry fun set_pool_pause(
        account: &signer, paused: bool, grace_period: u64
    ) {
        assert!(
            only_pool_or_emergency_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_or_emergency_admin()
        );

        let reserves_address = pool::get_reserves_list();
        for (i in 0..vector::length(&reserves_address)) {
            set_reserve_pause(
                account,
                *vector::borrow(&reserves_address, i),
                paused,
                grace_period
            );
        };
    }

    /// @notice Pauses or unpauses all the protocol reserves with no grace period. In the paused state all the protocol interactions
    /// are suspended
    /// @dev Emits the ReservePaused event for each reserve
    /// @param account The account signer of the caller
    /// @param paused True if protocol needs to be paused, false otherwise
    public entry fun set_pool_pause_no_grace_period(
        account: &signer, paused: bool
    ) {
        set_pool_pause(account, paused, 0);
    }

    /// @notice Updates the total flash loan premium.
    /// Total flash loan premium consists of two parts:
    /// - A part is sent to aToken holders as extra balance
    /// - A part is collected by the protocol reserves
    /// @dev Expressed in bps
    /// @dev The premium is calculated on the total amount borrowed
    /// @dev Emits the FlashloanPremiumTotalUpdated event
    /// @param account The account signer of the caller
    /// @param new_flashloan_premium_total The total flashloan premium
    public entry fun update_flashloan_premium_total(
        account: &signer, new_flashloan_premium_total: u128
    ) {
        assert!(
            only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );

        assert!(
            new_flashloan_premium_total
                <= (math_utils::get_percentage_factor() as u128),
            error_config::get_eflashloan_premium_invalid()
        );

        let old_flashloan_premium_total = pool::get_flashloan_premium_total();
        pool::update_flashloan_premiums(
            new_flashloan_premium_total,
            pool::get_flashloan_premium_to_protocol()
        );

        event::emit(
            FlashloanPremiumTotalUpdated {
                old_flashloan_premium_total,
                new_flashloan_premium_total
            }
        );
    }

    /// @notice Updates the flash loan premium collected by protocol reserves
    /// @dev Expressed in bps
    /// @dev The premium to protocol is calculated on the total flashloan premium
    /// @dev Emits the FlashloanPremiumToProtocolUpdated event
    /// @param account The account signer of the caller
    /// @param new_flashloan_premium_to_protocol The part of the flashloan premium sent to the protocol treasury
    public entry fun update_flashloan_premium_to_protocol(
        account: &signer, new_flashloan_premium_to_protocol: u128
    ) {
        assert!(
            only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin()
        );

        assert!(
            new_flashloan_premium_to_protocol
                <= (math_utils::get_percentage_factor() as u128),
            error_config::get_eflashloan_premium_invalid()
        );

        let old_flashloan_premium_to_protocol = pool::get_flashloan_premium_to_protocol();
        pool::update_flashloan_premiums(
            pool::get_flashloan_premium_total(),
            new_flashloan_premium_to_protocol
        );

        event::emit(
            FlashloanPremiumToProtocolUpdated {
                old_flashloan_premium_to_protocol,
                new_flashloan_premium_to_protocol
            }
        )
    }

    /// @notice Updates the global APT fee rate (in micro APT units)
    /// @dev The new apt fee must be less than or equal to MAX_APT_FEE (10 APT)
    /// @dev Emits a FeeChanged event on successful update
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param new_apt_fee The new fee value in micro APT
    public entry fun set_apt_fee(
        account: &signer, asset: address, new_apt_fee: u64
    ) {
        assert!(
            only_risk_or_pool_admins(signer::address_of(account)),
            error_config::get_ecaller_not_risk_or_pool_admin()
        );
        assert!(pool::asset_exists(asset), error_config::get_easset_not_listed());

        pool_fee_manager::set_apt_fee(account, asset, new_apt_fee)
    }

    // Private functions
    /// @notice Initializes the pool configurator
    /// @param account The account signer of the caller
    fun init_module(account: &signer) {
        assert!(
            signer::address_of(account) == @aave_pool,
            error_config::get_enot_pool_owner()
        );

        pool::init_pool(account);
        emode_logic::init_emode(account);
        default_reserve_interest_rate_strategy::init_interest_rate_strategy(account);

        move_to(account, InternalData { pending_ltv: smart_table::new() });
    }

    /// @notice Forcefully syncs the pool state
    /// @param asset The address of the underlying asset of the reserve
    /// This is mostly because the interest rate logic is separated from the pool and isolated in its own module
    fun sync_indexes_state(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let reserve_cache = pool_logic::cache(reserve_data);
        // update pool state
        pool_logic::update_state(reserve_data, &mut reserve_cache);
    }

    /// @notice Forcefully resyncs the interest rate state of the pool
    /// @param asset The address of the underlying asset of the reserve
    fun sync_rates_state(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let reserve_cache = pool_logic::cache(reserve_data);
        // update interest rates and virtual balance
        pool_logic::update_interest_rates_and_virtual_balance(
            reserve_data,
            &reserve_cache,
            asset,
            0,
            0
        );
    }

    /// @notice Checks that there are no suppliers for a reserve
    /// @param asset The address of the underlying asset of the reserve
    fun check_no_suppliers(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let a_token_address = pool::get_reserve_a_token_address(reserve_data);
        let reserve_accrued_to_treasury =
            pool::get_reserve_accrued_to_treasury(reserve_data);
        let a_token_total_supply = a_token_factory::total_supply(a_token_address);

        assert!(
            a_token_total_supply == 0 && reserve_accrued_to_treasury == 0,
            error_config::get_ereserve_liquidity_not_zero()
        );
    }

    /// @notice Checks that there are no borrowers for a reserve
    /// @param asset The address of the underlying asset of the reserve
    fun check_no_borrowers(asset: address) {
        let reserve_data = pool::get_reserve_data(asset);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);
        let total_debt =
            variable_debt_token_factory::total_supply(variable_debt_token_address);

        assert!(total_debt == 0, error_config::get_ereserve_debt_not_zero())
    }

    /// @notice Checks if an account has pool admin privileges
    /// @param account The address to check
    /// @return True if the account is a pool admin, false otherwise
    fun only_pool_admin(account: address): bool {
        acl_manage::is_pool_admin(account)
    }

    /// @notice Checks if an account has pool or emergency admin privileges
    /// @param account The address to check
    /// @return True if the account is a pool or emergency admin, false otherwise
    fun only_pool_or_emergency_admin(account: address): bool {
        acl_manage::is_pool_admin(account) || acl_manage::is_emergency_admin(account)
    }

    /// @notice Checks if an account has asset listing or pool admin privileges
    /// @param account The address to check
    /// @return True if the account is an asset listing or pool admin, false otherwise
    fun only_asset_listing_or_pool_admins(account: address): bool {
        acl_manage::is_asset_listing_admin(account)
            || acl_manage::is_pool_admin(account)
    }

    /// @notice Checks if an account has risk or pool admin privileges
    /// @param account The address to check
    /// @return True if the account is a risk or pool admin, false otherwise
    fun only_risk_or_pool_admins(account: address): bool {
        acl_manage::is_risk_admin(account) || acl_manage::is_pool_admin(account)
    }

    /// @notice Checks if an account has risk, pool, or emergency admin privileges
    /// @param account The address to check
    /// @return True if the account is a risk, pool, or emergency admin, false otherwise
    fun only_risk_or_pool_or_emergency_admins(account: address): bool {
        acl_manage::is_risk_admin(account)
            || acl_manage::is_pool_admin(account)
            || acl_manage::is_emergency_admin(account)
    }

    // Test only functions
    #[test_only]
    /// @notice Initializes the pool configurator for testing
    /// @param account The account signer of the caller
    public fun test_init_module(account: &signer) {
        init_module(account)
    }
}
