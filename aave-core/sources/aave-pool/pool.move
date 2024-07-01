module aave_pool::pool {
    use std::signer;
    use std::string::{String, utf8};
    use std::vector;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_config::error as error_config;
    use aave_config::reserve::{Self as reserve_config, ReserveConfigurationMap};
    use aave_config::user::{Self as user_config, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::default_reserve_interest_rate_strategy;
    use aave_pool::underlying_token_factory;
    use aave_pool::variable_token_factory;

    friend aave_pool::pool_configurator;
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::bridge_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::isolation_mode_logic;

    #[test_only]
    friend aave_pool::pool_tests;

    const POOL_REVISION: u256 = 0x1;

    #[event]
    struct ReserveInitialized has store, drop {
        // Address of the underlying asset
        asset: address,
        // Address of the corresponding aToken
        a_token: address,
        // Address of the corresponding variable debt token
        variable_debt_token: address
    }

    #[event]
    struct ReserveDataUpdated has store, drop {
        reserve: address,
        liquidity_rate: u256,
        variable_borrow_rate: u256,
        liquidity_index: u256,
        variable_borrow_index: u256,
    }

    #[event]
    struct MintedToTreasury has store, drop {
        reserve: address,
        amountMinted: u256,
    }

    #[event]
    struct IsolationModeTotalDebtUpdated has store, drop {
        asset: address,
        total_debt: u256,
    }

    struct ReserveExtendConfiguration has key, store, drop {
        bridge_protocol_fee: u256,
        flash_loan_premium_total: u128,
        flash_loan_premium_to_protocol: u128,
    }

    struct ReserveData has key, store, copy, drop {
        /// stores the reserve configuration
        configuration: ReserveConfigurationMap,
        /// the liquidity index. Expressed in ray
        liquidity_index: u128,
        /// the current supply rate. Expressed in ray
        current_liquidity_rate: u128,
        /// variable borrow index. Expressed in ray
        variable_borrow_index: u128,
        /// the current variable borrow rate. Expressed in ray
        current_variable_borrow_rate: u128,
        /// timestamp of last update (u40 -> u64)
        last_update_timestamp: u64,
        /// the id of the reserve. Represents the position in the list of the active reserves
        id: u16,
        /// aToken address
        a_token_address: address,
        /// variableDebtToken address
        variable_debt_token_address: address,
        /// the current treasury balance, scaled
        accrued_to_treasury: u256,
        /// the outstanding unbacked aTokens minted through the bridging feature
        unbacked: u128,
        /// the outstanding debt borrowed against this asset in isolation mode
        isolation_mode_total_debt: u128,
    }

    struct ReserveList has key {
        // SmartTable to store reserve data with asset addresses as keys
        value: SmartTable<address, ReserveData>,
        // Count of reserves in the list
        count: u16,
    }

    // List of reserves as a map (reserveId => reserve).
    struct ReserveAddressesList has key {
        value: SmartTable<u256, address>,
    }

    // Map of users address and their configuration data (userAddress => userConfiguration)
    struct UsersConfig has key {
        value: SmartTable<address, UserConfigurationMap>,
    }

    public(friend) fun init_pool(account: &signer) {
        assert!((signer::address_of(account) == @aave_pool),
            error_config::get_ecaller_not_pool_admin());
        move_to(account,
            ReserveList { value: smart_table::new<address, ReserveData>(), count: 0, });
        move_to(account, ReserveAddressesList { value: smart_table::new<u256, address>(), });
        move_to(account,
            UsersConfig { value: smart_table::new<address, UserConfigurationMap>(), });
        move_to(account,
            ReserveExtendConfiguration {
                bridge_protocol_fee: 0,
                flash_loan_premium_total: 0,
                flash_loan_premium_to_protocol: 0,
            });
    }

    #[test_only]
    public fun test_init_pool(account: &signer) {
        init_pool(account);
    }

    #[view]
    public fun get_revision(): u256 {
        POOL_REVISION
    }

    public(friend) fun init_reserve(
        account: &signer,
        underlying_asset: address,
        underlying_asset_decimals: u8,
        treasury: address,
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
    ) acquires ReserveList, ReserveAddressesList {
        // Check if underlying_asset exists
        underlying_token_factory::assert_token_exists(underlying_asset);

        // Borrow the ReserveList resource
        let reserve_data_list = borrow_global_mut<ReserveList>(@aave_pool);

        // Assert that the asset is not already added
        assert!(!smart_table::contains(&reserve_data_list.value, underlying_asset),
            error_config::get_ereserve_already_added());

        // Create a token for the underlying asset
        a_token_factory::create_token(
            account,
            a_token_name,
            a_token_symbol,
            underlying_asset_decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset,
            treasury,
        );
        let a_token_address = a_token_factory::token_address(signer::address_of(account),a_token_symbol);

        // Create variable debt token for the underlying asset
        variable_token_factory::create_token(
            account,
            variable_debt_token_name,
            variable_debt_token_symbol,
            underlying_asset_decimals,
            utf8(b""),
            utf8(b""),
            underlying_asset,
        );
        let variable_debt_token_address = variable_token_factory::token_address(signer::address_of(account), variable_debt_token_symbol);

        // Create Pool
        let reserve_data = ReserveData {
                configuration: reserve_config::init(),
                liquidity_index: (wad_ray_math::ray() as u128),
                current_liquidity_rate: 0,
                variable_borrow_index: (wad_ray_math::ray() as u128),
                current_variable_borrow_rate: 0,
                last_update_timestamp: 0,
                id: 0,
                a_token_address,
                variable_debt_token_address,
                accrued_to_treasury: 0,
                unbacked: 0,
                isolation_mode_total_debt: 0,
            };

        // Add the ReserveData in the smart table
        smart_table::add(&mut reserve_data_list.value, underlying_asset, reserve_data);

        let flag = false;
        let reserve_count = reserve_data_list.count;
        // Reorder assets
        for (i in 0..reserve_count) {
            let reserve_address_list = borrow_global_mut<ReserveAddressesList>(@aave_pool);
            if (!smart_table::contains(&reserve_address_list.value, (i as u256))) {
                // update reserve id
                set_reserve_id(reserve_data_list,underlying_asset, (i as u16));
                // update reserve address list
                add_reserve_address_list(reserve_address_list, (i as u256), underlying_asset);
                flag = true;
            };
        };

        if (!flag) {
            // Assert that the maximum number of reserves hasn't been reached
            assert!(reserve_count < max_number_reserves(), error_config::get_eno_more_reserves_allowed());
            // update reserve id
            set_reserve_id(reserve_data_list, underlying_asset, reserve_count);

            let reserve_address_list = borrow_global_mut<ReserveAddressesList>(@aave_pool);
            // update reserve address list
            add_reserve_address_list(reserve_address_list, (reserve_count as u256), underlying_asset);

            // Update the reserve count
            reserve_data_list.count = reserve_data_list.count + 1;
        };

        // Set the reserve configuration
        let reserve_configuration = reserve_config::init();
        reserve_config::set_decimals(&mut reserve_configuration, (underlying_asset_decimals as u256));
        reserve_config::set_active(&mut reserve_configuration, true);
        reserve_config::set_paused(&mut reserve_configuration, false);
        reserve_config::set_frozen(&mut reserve_configuration, false);
        set_reserve_configuration(underlying_asset, reserve_configuration);

        // emit the ReserveInitialized event
        event::emit(ReserveInitialized {
            asset: underlying_asset,
            a_token: a_token_address,
            variable_debt_token: variable_debt_token_address,
        })
    }

    #[test_only]
    public fun test_init_reserve(
        account: &signer,
        underlying_asset: address,
        underlying_asset_decimals: u8,
        treasury: address,
        a_token_name: String,
        a_token_symbol: String,
        variable_debt_token_name: String,
        variable_debt_token_symbol: String,
    ) acquires ReserveList, ReserveAddressesList {
        init_reserve(
            account,
            underlying_asset,
            underlying_asset_decimals,
            treasury,
            a_token_name,
            a_token_symbol,
            variable_debt_token_name,
            variable_debt_token_symbol
        );
    }

    public(friend) fun drop_reserve(asset: address) acquires ReserveList, ReserveAddressesList {
        assert!(asset != @0x0, error_config::get_ezero_address_not_valid());
        // check if the asset is listed
        let reserve_data = get_reserve_data(asset);

        let variable_debt_token_total_supply = scale_variable_token_total_supply(reserve_data.variable_debt_token_address);
        assert!(variable_debt_token_total_supply == 0, error_config::get_evariable_debt_supply_not_zero());

        let a_token_total_supply = scale_a_token_total_supply(reserve_data.a_token_address);
        assert!(
            a_token_total_supply == 0 && reserve_data.accrued_to_treasury == 0,
            error_config::get_eunderlying_claimable_rights_not_zero()
        );

        // Borrow the ReserveList resource
        let reserve_data_list = borrow_global_mut<ReserveList>(@aave_pool);
        // Remove the ReserveData entry from the smart_table
        smart_table::remove(&mut reserve_data_list.value, asset);

        // Remove ReserveAddressList
        let reserve_address_list = borrow_global_mut<ReserveAddressesList>(@aave_pool);
        if (smart_table::contains(&reserve_address_list.value, (reserve_data.id as u256))) {
            smart_table::remove(&mut reserve_address_list.value, (reserve_data.id as u256));
        };

        // assert assets count in storage
        assert!(smart_table::length(&reserve_address_list.value)
            == smart_table::length(&reserve_data_list.value),
            error_config::get_ereserves_storage_count_mismatch());
    }

    #[test_only]
    public fun test_drop_reserve(asset: address, ) acquires ReserveList, ReserveAddressesList {
        drop_reserve(asset);
    }

    #[view]
    public fun get_reserve_data(asset: address): ReserveData acquires ReserveList {
        // Get the signer address
        let signer_address = @aave_pool;

        // Assert that the signer has created a list
        assert!(exists<ReserveList>(signer_address), error_config::get_euser_not_listed());

        // Get the ReserveList resource
        let reserve_list = borrow_global<ReserveList>(signer_address);

        // Assert that the asset is listed
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());

        // Borrow the ReserveData for the specified asset
        let reserve_data =
            smart_table::borrow<address, ReserveData>(&reserve_list.value, asset);

        // Return the borrowed ReserveData
        *reserve_data
    }

    #[view]
    public fun get_reserve_data_and_reserves_count(asset: address, ): (ReserveData, u256) acquires ReserveList {
        // Get the signer address
        let signer_address = @aave_pool;

        // Assert that the signer has created a list
        assert!(exists<ReserveList>(signer_address), error_config::get_euser_not_listed());

        // Get the ReserveList resource
        let reserve_list = borrow_global<ReserveList>(signer_address);

        // Assert that the asset is listed
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());

        // Borrow the ReserveData for the specified asset
        let reserve_data =
            smart_table::borrow<address, ReserveData>(&reserve_list.value, asset);

        // Return the borrowed ReserveData
        (*reserve_data, (reserve_list.count as u256))
    }

    #[view]
    public fun get_reserve_configuration(asset: address): ReserveConfigurationMap acquires ReserveList {
        let reserve_list = borrow_global<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_info =
            smart_table::borrow<address, ReserveData>(&reserve_list.value, asset);
        reserve_info.configuration
    }

    #[view]
    public fun get_reserves_count(): u256 acquires ReserveList {
        let reserve_list = borrow_global<ReserveList>(@aave_pool);
        (reserve_list.count as u256)
    }

    public fun get_reserve_configuration_by_reserve_data(
        reserve_data: &ReserveData
    ): ReserveConfigurationMap {
        reserve_data.configuration
    }

    public fun get_reserve_last_update_timestamp(reserve: &ReserveData): u64 {
        reserve.last_update_timestamp
    }

    fun set_reserve_id(
        reserve_list: &mut ReserveList,
        asset:address,
        id: u16
    )  {
        let reserve_data = smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.id = id
    }

    fun set_reserve_last_update_timestamp(
        asset: address, last_update_timestamp: u64
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.last_update_timestamp = last_update_timestamp
    }

    public fun get_reserve_id(reserve: &ReserveData): u16 {
        reserve.id
    }

    public fun get_reserve_a_token_address(reserve: &ReserveData): address {
        reserve.a_token_address
    }

    public(friend) fun set_reserve_accrued_to_treasury(
        asset: address, accrued_to_treasury: u256
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.accrued_to_treasury = accrued_to_treasury
    }

    public fun get_reserve_accrued_to_treasury(reserve: &ReserveData): u256 {
        reserve.accrued_to_treasury
    }

    fun set_reserve_variable_borrow_index(
        asset: address, variable_borrow_index: u128
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.variable_borrow_index = variable_borrow_index
    }

    public fun get_reserve_variable_borrow_index(reserve: &ReserveData): u128 {
        reserve.variable_borrow_index
    }

    fun set_reserve_liquidity_index(asset: address, liquidity_index: u128) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.liquidity_index = liquidity_index
    }

    public fun get_reserve_liquidity_index(reserve: &ReserveData): u128 {
        reserve.liquidity_index
    }

    fun set_reserve_current_liquidity_rate(
        asset: address, current_liquidity_rate: u128
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.current_liquidity_rate = current_liquidity_rate
    }

    public fun get_reserve_current_liquidity_rate(reserve: &ReserveData): u128 {
        reserve.current_liquidity_rate
    }

    fun set_reserve_current_variable_borrow_rate(
        asset: address, current_variable_borrow_rate: u128
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.current_variable_borrow_rate = current_variable_borrow_rate
    }

    public fun get_reserve_current_variable_borrow_rate(
        reserve: &ReserveData
    ): u128 {
        reserve.current_variable_borrow_rate
    }

    public fun get_reserve_variable_debt_token_address(
        reserve: &ReserveData
    ): address {
        reserve.variable_debt_token_address
    }

    public(friend) fun set_reserve_unbacked(asset: address, unbacked: u128) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.unbacked = unbacked
    }

    public fun get_reserve_unbacked(reserve: &ReserveData): u128 {
        reserve.unbacked
    }

    public(friend) fun set_reserve_isolation_mode_total_debt(
        asset: address, isolation_mode_total_debt: u128
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);

        reserve_data.isolation_mode_total_debt = isolation_mode_total_debt
    }

    public fun get_reserve_isolation_mode_total_debt(reserve: &ReserveData): u128 {
        reserve.isolation_mode_total_debt
    }

    public(friend) fun set_reserve_configuration(
        asset: address, reserve_config_map: ReserveConfigurationMap
    ) acquires ReserveList {
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_info =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_info.configuration = reserve_config_map;
    }

    #[test_only]
    public fun test_set_reserve_configuration(
        asset: address, reserve_config_map: ReserveConfigurationMap
    ) acquires ReserveList {
        set_reserve_configuration(asset, reserve_config_map);
    }

    #[view]
    public fun get_user_configuration(user: address): UserConfigurationMap acquires UsersConfig {
        let user_config_obj = borrow_global<UsersConfig>(@aave_pool);
        if (smart_table::contains(&user_config_obj.value, user)) {
            let user_config_map = smart_table::borrow(&user_config_obj.value, user);
            return *user_config_map
        };

        user_config::init()
    }

    public(friend) fun set_user_configuration(
        user: address, user_config_map: UserConfigurationMap
    ) acquires UsersConfig {
        let user_config_obj = borrow_global_mut<UsersConfig>(@aave_pool);
        smart_table::upsert(&mut user_config_obj.value, user, user_config_map);
    }

    #[view]
    public fun get_reserve_normalized_income(asset: address): u256 acquires ReserveList {
        let reserve_data = get_reserve_data(asset);
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            return (reserve_data.liquidity_index as u256)
        };
        wad_ray_math::ray_mul(math_utils::calculate_linear_interest(
            (reserve_data.current_liquidity_rate as u256), last_update_timestamp, ),
            (reserve_data.liquidity_index as u256))
    }

    public fun get_normalized_income_by_reserve_data(
        reserve_data: &ReserveData
    ): u256 {
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            return (reserve_data.liquidity_index as u256)
        };
        wad_ray_math::ray_mul(math_utils::calculate_linear_interest(
            (reserve_data.current_liquidity_rate as u256), last_update_timestamp, ),
            (reserve_data.liquidity_index as u256))
    }

    public(friend) fun update_state(
        asset: address, reserve_data: &mut ReserveData,
    ) acquires ReserveList {
        if (reserve_data.last_update_timestamp == timestamp::now_seconds()) { return };

        update_indexes(asset, reserve_data);
        accrue_to_treasury(asset, reserve_data);

        reserve_data.last_update_timestamp = timestamp::now_seconds();
        set_reserve_last_update_timestamp(asset, reserve_data.last_update_timestamp)
    }

    inline fun update_indexes(asset: address, reserve_data: &mut ReserveData, ) {
        if (reserve_data.current_liquidity_rate != 0) {
            let cumulated_liquidity_interest =
                math_utils::calculate_linear_interest(
                    (reserve_data.current_liquidity_rate as u256), reserve_data.last_update_timestamp);
            let next_liquidity_index =
                (wad_ray_math::ray_mul(cumulated_liquidity_interest, (reserve_data.liquidity_index as u256)) as u128);
            reserve_data.liquidity_index = next_liquidity_index;
            set_reserve_liquidity_index(asset, next_liquidity_index)
        };

        let curr_scaled_variable_debt =
            variable_token_factory::scale_total_supply(reserve_data.variable_debt_token_address);
        if (curr_scaled_variable_debt != 0) {
            let cumulated_variable_borrow_interest =
                math_utils::calculate_compounded_interest(
                    (reserve_data.current_variable_borrow_rate as u256),
                    reserve_data.last_update_timestamp,
                    timestamp::now_seconds());
            let next_variable_borrow_index =
                (wad_ray_math::ray_mul(
                    cumulated_variable_borrow_interest,
                    (reserve_data.variable_borrow_index as u256)
                ) as u128);
            reserve_data.variable_borrow_index = next_variable_borrow_index;

            set_reserve_variable_borrow_index(asset, next_variable_borrow_index)
        }
    }

    inline fun accrue_to_treasury(
        asset: address, reserve_data: &mut ReserveData,
    ) {
        let reserve_factor = reserve_config::get_reserve_factor(&reserve_data.configuration);
        if (reserve_factor != 0) {
            let curr_scaled_variable_debt =
                variable_token_factory::scale_total_supply(reserve_data.variable_debt_token_address);
            let prev_total_variable_debt =
                wad_ray_math::ray_mul(curr_scaled_variable_debt, (reserve_data.variable_borrow_index as u256));

            let curr_total_variable_debt =
                wad_ray_math::ray_mul(curr_scaled_variable_debt, (reserve_data.variable_borrow_index as u256), );

            let total_debt_accrued = curr_total_variable_debt - prev_total_variable_debt;
            let amount_to_mint = math_utils::percent_mul(total_debt_accrued, reserve_factor);
            if (amount_to_mint != 0) {
                reserve_data.accrued_to_treasury = reserve_data.accrued_to_treasury + wad_ray_math::ray_div(
                    amount_to_mint, (reserve_data.liquidity_index as u256));
                set_reserve_accrued_to_treasury(asset, reserve_data.accrued_to_treasury)
            }
        }
    }

    #[view]
    public fun get_reserve_normalized_variable_debt(asset: address): u256 acquires ReserveList {
        let reserve_data = get_reserve_data(asset);
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            return (reserve_data.variable_borrow_index as u256)
        };
        wad_ray_math::ray_mul(math_utils::calculate_compounded_interest(
            (reserve_data.current_variable_borrow_rate as u256),
            last_update_timestamp,
            timestamp::now_seconds()),
            (reserve_data.variable_borrow_index as u256))
    }

    public fun get_normalized_debt_by_reserve_data(
        reserve_data: &ReserveData
    ): u256 {
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            return (reserve_data.variable_borrow_index as u256)
        };
        wad_ray_math::ray_mul(math_utils::calculate_compounded_interest(
            (reserve_data.current_variable_borrow_rate as u256),
            last_update_timestamp,
            timestamp::now_seconds()),
            (reserve_data.variable_borrow_index as u256))
    }

    fun add_reserve_address_list(
        reserve_address_list: &mut ReserveAddressesList, index: u256, asset: address
    ) {
        if (smart_table::length(&reserve_address_list.value) == 0) {
            smart_table::add(&mut reserve_address_list.value, index, asset);
        } else {
            assert!(!smart_table::contains(&mut reserve_address_list.value, index),
                error_config::get_ereserve_already_added());
            smart_table::add(&mut reserve_address_list.value, index, asset);
        }
    }

    #[view]
    public fun get_reserves_list(): vector<address> acquires ReserveAddressesList, ReserveList {
        let reserves_list_count = get_reserves_count();
        let dropped_reserves_count = 0;
        let address_list = vector::empty<address>();
        if (reserves_list_count == 0) {
            return address_list
        };

        let reserve_address_list = borrow_global<ReserveAddressesList>(@aave_pool);
        for (i in 0..reserves_list_count) {
            if(smart_table::contains(&reserve_address_list.value, i)){
                let reserve_address = *smart_table::borrow(&reserve_address_list.value, i);
                vector::insert(&mut address_list, ((i - dropped_reserves_count) as u64),
                    reserve_address);
            } else {
                dropped_reserves_count = dropped_reserves_count + 1;
            };
        };
        address_list
    }

    #[view]
    public fun get_reserve_address_by_id(id: u256): address acquires ReserveAddressesList {
        let reserve_address_list = borrow_global<ReserveAddressesList>(@aave_pool);
        if (!smart_table::contains(&reserve_address_list.value, id)) {
            return @0x0
        };

        *smart_table::borrow(&reserve_address_list.value, id)
    }

    public entry fun mint_to_treasury(assets: vector<address>) acquires ReserveList {
        for (i in 0..vector::length(&assets)) {
            let asset_address = *vector::borrow(&assets, i);
            let reserve_data = &mut get_reserve_data(asset_address);
            let reserve_config_map = get_reserve_configuration_by_reserve_data(reserve_data);
            if (!reserve_config::get_active(&reserve_config_map)) { continue };

            let accrued_to_treasury = reserve_data.accrued_to_treasury;
            if (accrued_to_treasury != 0) {
                set_reserve_accrued_to_treasury(asset_address, 0);
                let normalized_income = get_reserve_normalized_income(asset_address);
                let amount_to_mint = wad_ray_math::ray_mul(accrued_to_treasury,
                    normalized_income);
                a_token_factory::mint_to_treasury(amount_to_mint, normalized_income,
                    reserve_data.a_token_address);
                event::emit(MintedToTreasury {
                    reserve: asset_address,
                    amountMinted: accrued_to_treasury
                });
            };
        }
    }

    #[view]
    public fun get_bridge_protocol_fee(): u256 acquires ReserveExtendConfiguration {
        let reserve_extend_configuration = borrow_global<ReserveExtendConfiguration>(
            @aave_pool);
        reserve_extend_configuration.bridge_protocol_fee
    }

    public(friend) fun set_bridge_protocol_fee(protocol_fee: u256) acquires ReserveExtendConfiguration {
        let reserve_extend_configuration = borrow_global_mut<ReserveExtendConfiguration>(
            @aave_pool);
        reserve_extend_configuration.bridge_protocol_fee = protocol_fee
    }

    #[view]
    public fun get_flashloan_premium_total(): u128 acquires ReserveExtendConfiguration {
        let reserve_extend_configuration = borrow_global<ReserveExtendConfiguration>(
            @aave_pool);
        reserve_extend_configuration.flash_loan_premium_total
    }

    public(friend) fun set_flashloan_premiums(
        flash_loan_premium_total: u128, flash_loan_premium_to_protocol: u128
    ) acquires ReserveExtendConfiguration {
        let reserve_extend_configuration = borrow_global_mut<ReserveExtendConfiguration>(
            @aave_pool);
        reserve_extend_configuration.flash_loan_premium_total = flash_loan_premium_total;
        reserve_extend_configuration.flash_loan_premium_to_protocol = flash_loan_premium_to_protocol
    }

    #[view]
    public fun get_flashloan_premium_to_protocol(): u128 acquires ReserveExtendConfiguration {
        let reserve_extend_configuration = borrow_global<ReserveExtendConfiguration>(
            @aave_pool);
        reserve_extend_configuration.flash_loan_premium_to_protocol
    }

    #[view]
    public fun max_number_reserves(): u16 {
        reserve_config::get_max_reserves_count()
    }

    public(friend) fun update_interest_rates(
        reserve_data: &mut ReserveData,
        reserve_address: address,
        liquidity_added: u256,
        liquidity_taken: u256
    ) acquires ReserveList {
        let variable_token_scale_total_supply =
            variable_token_factory::scale_total_supply(reserve_data.variable_debt_token_address);
        let total_variable_debt =
            wad_ray_math::ray_mul(variable_token_scale_total_supply, (reserve_data.variable_borrow_index as u256));

        let (next_liquidity_rate, next_variable_rate) =
            default_reserve_interest_rate_strategy::calculate_interest_rates(
                (reserve_data.unbacked as u256),
                liquidity_added,
                liquidity_taken,
                total_variable_debt,
                reserve_config::get_reserve_factor(&reserve_data.configuration),
                reserve_address,
                reserve_data.a_token_address);
        reserve_data.current_liquidity_rate = (next_liquidity_rate as u128);
        reserve_data.current_variable_borrow_rate = (next_variable_rate as u128);

        set_reserve_current_liquidity_rate(reserve_address, (next_liquidity_rate as u128));
        set_reserve_current_variable_borrow_rate(reserve_address, (next_variable_rate as u128));

        event::emit(ReserveDataUpdated {
            reserve: reserve_address,
            liquidity_rate: next_liquidity_rate,
            variable_borrow_rate: next_variable_rate,
            liquidity_index: (reserve_data.liquidity_index as u256),
            variable_borrow_index: (reserve_data.variable_borrow_index as u256),
        })
    }

    public fun get_isolation_mode_state(
        user_config_map: &UserConfigurationMap
    ): (bool, address, u256) acquires ReserveAddressesList, ReserveList {
        if (user_config::is_using_as_collateral_one(user_config_map)) {
            let asset_id: u256 =
                user_config::get_first_asset_id_by_mask(user_config_map,
                    user_config::get_collateral_mask());
            let asset_address = get_reserve_address_by_id(asset_id);
            let reserves_config_map = get_reserve_configuration(asset_address);
            let ceiling: u256 = reserve_config::get_debt_ceiling(&reserves_config_map);
            if (ceiling != 0) {
                return (true, asset_address, ceiling)
            }
        };
        (false, @0x0, 0)
    }

    public fun get_siloed_borrowing_state(
        account: address
    ): (bool, address) acquires ReserveAddressesList, ReserveList, UsersConfig {
        let user_configuration = get_user_configuration(account);
        if (user_config::is_borrowing_one(&user_configuration)) {
            let asset_id: u256 =
                user_config::get_first_asset_id_by_mask(&user_configuration,
                    user_config::get_borrowing_mask());
            let asset_address = get_reserve_address_by_id(asset_id);
            let reserves_config_map = get_reserve_configuration(asset_address);

            if (reserve_config::get_siloed_borrowing(&reserves_config_map)) {
                return (true, asset_address)
            };
        };
        (false, @0x0)
    }

    public(friend) fun cumulate_to_liquidity_index(
        asset: address, reserve_data: &mut ReserveData, total_liquidity: u256, amount: u256
    ): u256 acquires ReserveList {
        let result =
            wad_ray_math::ray_div(wad_ray_math::wad_to_ray(amount),
                wad_ray_math::wad_to_ray(total_liquidity)) + wad_ray_math::ray_mul(
                wad_ray_math::ray(), (reserve_data.liquidity_index as u256));
        reserve_data.liquidity_index = (result as u128);
        set_reserve_liquidity_index(asset, reserve_data.liquidity_index);

        result
    }

    public(friend) fun reset_isolation_mode_total_debt(asset: address) acquires ReserveList {
        let reserve_config_map = get_reserve_configuration(asset);
        assert!(reserve_config::get_debt_ceiling(&reserve_config_map) == 0,
            error_config::get_edebt_ceiling_not_zero());
        let reserve_list = borrow_global_mut<ReserveList>(@aave_pool);
        assert!(smart_table::contains(&reserve_list.value, asset),
            error_config::get_easset_not_listed());
        let reserve_data =
            smart_table::borrow_mut<address, ReserveData>(&mut reserve_list.value, asset);
        reserve_data.isolation_mode_total_debt = 0;
        event::emit(IsolationModeTotalDebtUpdated { asset, total_debt: 0 })
    }

    public entry fun rescue_tokens(
        account: &signer, token: address, to: address, amount: u256
    ) {
        assert!(only_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_pool_admin());
        underlying_token_factory::transfer_from(signer::address_of(account), to, (amount as u64),
            token);
    }

    #[view]
    public fun scale_a_token_total_supply(a_token_address: address): u256 acquires ReserveList {
        let current_supply_scaled = a_token_factory::scale_total_supply(a_token_address);
        if (current_supply_scaled == 0) {
            return 0
        };
        let underlying_token_address = a_token_factory::get_underlying_asset_address(a_token_address);
        wad_ray_math::ray_mul(current_supply_scaled, get_reserve_normalized_income(underlying_token_address))
    }

    #[view]
    public fun scale_a_token_balance_of(owner: address, a_token_address: address): u256 acquires ReserveList {
        let current_balance_scale = a_token_factory::scale_balance_of(owner, a_token_address);
        if (current_balance_scale == 0) {
            return 0
        };
        let underlying_token_address = a_token_factory::get_underlying_asset_address(a_token_address);
        wad_ray_math::ray_mul(current_balance_scale, get_reserve_normalized_income(underlying_token_address))
    }

    #[view]
    public fun scale_variable_token_total_supply(variable_debt_token_address: address): u256 acquires ReserveList{
        let current_supply_scaled = variable_token_factory::scale_total_supply(variable_debt_token_address);
        if (current_supply_scaled == 0) {
            return 0
        };
        let underlying_token_address = variable_token_factory::get_underlying_asset_address(variable_debt_token_address);

        wad_ray_math::ray_mul(current_supply_scaled, get_reserve_normalized_variable_debt(underlying_token_address))
    }

    #[view]
    public fun scale_variable_token_balance_of(owner: address, variable_debt_token_address: address): u256 acquires ReserveList {
        let current_balance_scale = variable_token_factory::scale_balance_of(owner, variable_debt_token_address);
        if (current_balance_scale == 0) {
            return 0
        };
        let underlying_token_address = variable_token_factory::get_underlying_asset_address(variable_debt_token_address);
        wad_ray_math::ray_mul(current_balance_scale, get_reserve_normalized_variable_debt(underlying_token_address))
    }

    fun only_pool_admin(admin: address): bool {
        acl_manage::is_pool_admin(admin)
    }

    #[test_only]
    public fun set_reserve_current_liquidity_rate_for_testing(
        asset: address, current_liquidity_rate: u128
    ) acquires ReserveList {
        set_reserve_current_liquidity_rate(asset, current_liquidity_rate)
    }

    #[test_only]
    public fun set_reserve_current_variable_borrow_rate_for_testing(
        asset: address, current_variable_borrow_rate: u128
    ) acquires ReserveList {
        set_reserve_current_variable_borrow_rate(asset, current_variable_borrow_rate);
    }

    #[test_only]
    public fun set_reserve_liquidity_index_for_testing(
        asset: address, liquidity_index: u128
    ) acquires ReserveList {
        set_reserve_liquidity_index(asset, liquidity_index)
    }

    #[test_only]
    public fun set_reserve_variable_borrow_index_for_testing(
        asset: address, variable_borrow_index: u128
    ) acquires ReserveList {
        set_reserve_variable_borrow_index(asset, variable_borrow_index)
    }
}
