/// @title Pool Module
/// @author Aave
/// @notice Main module for the Aave protocol, managing the state of all reserves and users
module aave_pool::pool {
    // imports
    use std::signer;
    use std::vector;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_framework::object;
    use aptos_framework::object::{Object, DeleteRef};
    use aptos_framework::timestamp;

    use aave_acl::acl_manage;
    use aave_config::error_config;
    use aave_config::reserve_config::{Self, ReserveConfigurationMap};
    use aave_config::user_config::{Self, UserConfigurationMap};
    use aave_math::math_utils;
    use aave_math::wad_ray_math;
    use aave_pool::events::Self;

    // friend modules
    friend aave_pool::pool_configurator;
    friend aave_pool::flashloan_logic;
    friend aave_pool::supply_logic;
    friend aave_pool::borrow_logic;
    friend aave_pool::liquidation_logic;
    friend aave_pool::isolation_mode_logic;
    friend aave_pool::pool_token_logic;
    friend aave_pool::pool_logic;

    #[test_only]
    friend aave_pool::pool_tests;
    #[test_only]
    friend aave_pool::collector_tests;
    #[test_only]
    friend aave_pool::ui_incentive_data_provider_v3_tests;
    #[test_only]
    friend aave_pool::ui_pool_data_provider_v3_tests;

    // Structs
    /// @notice Configuration for reserve extensions like flashloan premiums
    struct ReserveExtendConfiguration has key, store, drop {
        /// Total FlashLoan Premium, expressed in bps
        flash_loan_premium_total: u128,
        /// FlashLoan premium paid to protocol treasury, expressed in bps
        flash_loan_premium_to_protocol: u128
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// @notice Stateful information about a reserve
    struct ReserveData has key {
        /// Stores the reserve configuration
        configuration: ReserveConfigurationMap,
        /// The liquidity index. Expressed in ray
        liquidity_index: u128,
        /// The current supply rate. Expressed in ray
        current_liquidity_rate: u128,
        /// Variable borrow index. Expressed in ray
        variable_borrow_index: u128,
        /// The current variable borrow rate. Expressed in ray
        current_variable_borrow_rate: u128,
        /// The current accumulate deficit in underlying tokens
        deficit: u128,
        /// Timestamp of last update (u40 -> u64)
        last_update_timestamp: u64,
        /// The id of the reserve. Represents the position in the list of the active reserves
        id: u16,
        /// Timestamp until when liquidations are not allowed on the reserve, if set to past liquidations will be allowed (u40 -> u64)
        liquidation_grace_period_until: u64,
        /// aToken address
        a_token_address: address,
        /// variableDebtToken address
        variable_debt_token_address: address,
        /// The current treasury balance, scaled
        accrued_to_treasury: u256,
        /// The outstanding debt borrowed against this asset in isolation mode
        isolation_mode_total_debt: u128,
        /// The amount of underlying accounted for by the protocol
        virtual_underlying_balance: u128
    }

    /// @notice A wrapper over the `ReserveData` object with its associated delete ref
    struct ReserveInfo has store {
        object: Object<ReserveData>,
        delete_ref: DeleteRef
    }

    /// @notice Information of all reserves
    struct Reserves has key {
        /// Map of underlying asset address to the associated reserve object
        /// (underlying_asset_of_reserve => ReserveInfo)
        reserves: SmartTable<address, ReserveInfo>,
        /// List of reserves by id, represented as a map (reserveId => reserve)
        reserves_list: SmartTable<u16, address>,
        /// Maximum number of active reserves there have been in the protocol.
        /// It is the upper bound of the reserves list
        count: u16
    }

    /// @notice Map of users address and their configuration data (user_address => UserConfigurationMap)
    struct UsersConfig has key {
        value: SmartTable<address, UserConfigurationMap>
    }

    // Public view functions
    #[view]
    /// @notice Get an object that points to the state of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The object that refers to the state of the reserve
    public fun get_reserve_data(asset: address): Object<ReserveData> acquires Reserves {
        let reserves = get_reserves_ref();

        // assert that the asset is listed
        assert!(
            smart_table::contains(&reserves.reserves, asset),
            error_config::get_easset_not_listed()
        );

        // return the object pointing to the ReserveData
        smart_table::borrow(&reserves.reserves, asset).object
    }

    #[view]
    /// @notice Return the number of active reserves
    /// @return The number of active reserves
    public fun number_of_active_reserves(): u256 acquires Reserves {
        let reserves = get_reserves_ref();
        let size = smart_table::length(&reserves.reserves);
        // NOTE: these two assertions are invariants and should not be triggered
        assert!(
            size == smart_table::length(&reserves.reserves_list),
            error_config::get_ereserves_storage_count_mismatch()
        );
        assert!(
            size <= (reserves.count as u64),
            error_config::get_ereserves_storage_count_mismatch()
        );
        (size as u256)
    }

    #[view]
    /// @notice Return the number of active and dropped reserves
    /// @return The number of active and dropped reserves
    public fun number_of_active_and_dropped_reserves(): u256 acquires Reserves {
        let reserves = get_reserves_ref();
        (reserves.count as u256)
    }

    #[view]
    /// @notice Returns the configuration of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The configuration of the reserve
    public fun get_reserve_configuration(
        asset: address
    ): ReserveConfigurationMap acquires Reserves, ReserveData {
        let reserve_data = object_to_ref(get_reserve_data(asset));
        reserve_data.configuration
    }

    #[view]
    /// @notice Returns the configuration of the reserve by reserve data
    /// @param reserve_data The reserve data object
    /// @return The configuration of the reserve
    public fun get_reserve_configuration_by_reserve_data(
        reserve_data: Object<ReserveData>
    ): ReserveConfigurationMap acquires ReserveData {
        object_to_ref(reserve_data).configuration
    }

    #[view]
    /// @notice Returns the last update timestamp of the reserve
    /// @param reserve_data The reserve data object
    /// @return The last update timestamp
    public fun get_reserve_last_update_timestamp(
        reserve_data: Object<ReserveData>
    ): u64 acquires ReserveData {
        object_to_ref(reserve_data).last_update_timestamp
    }

    #[view]
    /// @notice Returns the ID of the reserve
    /// @param reserve_data The reserve data object
    /// @return The ID of the reserve
    public fun get_reserve_id(reserve_data: Object<ReserveData>): u16 acquires ReserveData {
        object_to_ref(reserve_data).id
    }

    #[view]
    /// @notice Returns the aToken address of the reserve
    /// @param reserve_data The reserve data object
    /// @return The aToken address
    public fun get_reserve_a_token_address(
        reserve_data: Object<ReserveData>
    ): address acquires ReserveData {
        object_to_ref(reserve_data).a_token_address
    }

    #[view]
    /// @notice Returns the accrued to treasury amount of the reserve
    /// @param reserve_data The reserve data object
    /// @return The accrued to treasury amount
    public fun get_reserve_accrued_to_treasury(
        reserve_data: Object<ReserveData>
    ): u256 acquires ReserveData {
        object_to_ref(reserve_data).accrued_to_treasury
    }

    #[view]
    /// @notice Returns the variable borrow index of the reserve
    /// @param reserve_data The reserve data object
    /// @return The variable borrow index
    public fun get_reserve_variable_borrow_index(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).variable_borrow_index
    }

    #[view]
    /// @notice Returns the liquidity index of the reserve
    /// @param reserve_data The reserve data object
    /// @return The liquidity index
    public fun get_reserve_liquidity_index(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).liquidity_index
    }

    #[view]
    /// @notice Returns the current liquidity rate of the reserve
    /// @param reserve_data The reserve data object
    /// @return The current liquidity rate
    public fun get_reserve_current_liquidity_rate(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).current_liquidity_rate
    }

    #[view]
    /// @notice Returns the current variable borrow rate of the reserve
    /// @param reserve_data The reserve data object
    /// @return The current variable borrow rate
    public fun get_reserve_current_variable_borrow_rate(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).current_variable_borrow_rate
    }

    #[view]
    /// @notice Returns the variable debt token address of the reserve
    /// @param reserve_data The reserve data object
    /// @return The variable debt token address
    public fun get_reserve_variable_debt_token_address(
        reserve_data: Object<ReserveData>
    ): address acquires ReserveData {
        object_to_ref(reserve_data).variable_debt_token_address
    }

    #[view]
    /// @notice Returns the isolation mode total debt of the reserve
    /// @param reserve_data The reserve data object
    /// @return The isolation mode total debt
    public fun get_reserve_isolation_mode_total_debt(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).isolation_mode_total_debt
    }

    #[view]
    /// @notice Returns the virtual underlying balance of the reserve
    /// @param reserve_data The reserve data object
    /// @return The virtual underlying balance
    public fun get_reserve_virtual_underlying_balance(
        reserve_data: Object<ReserveData>
    ): u128 acquires ReserveData {
        object_to_ref(reserve_data).virtual_underlying_balance
    }

    #[view]
    /// @notice Returns the liquidation grace period of the given asset
    /// @param reserve_data The reserve data object
    /// @return Timestamp when the liquidation grace period will end
    public fun get_liquidation_grace_period(
        reserve_data: Object<ReserveData>
    ): u64 acquires ReserveData {
        object_to_ref(reserve_data).liquidation_grace_period_until
    }

    #[view]
    /// @notice Returns the current deficit of a reserve
    /// @param reserve_data The reserve data object
    /// @return The current deficit of the reserve
    public fun get_reserve_deficit(reserve_data: Object<ReserveData>): u128 acquires ReserveData {
        object_to_ref(reserve_data).deficit
    }

    #[view]
    /// @notice Returns the user configuration
    /// @param user The address of the user
    /// @return The user configuration
    public fun get_user_configuration(user: address): UserConfigurationMap acquires UsersConfig {
        let user_config_obj = borrow_global<UsersConfig>(@aave_pool);

        if (smart_table::contains(&user_config_obj.value, user)) {
            let user_config_map = smart_table::borrow(&user_config_obj.value, user);
            return *user_config_map
        };

        user_config::init()
    }

    #[view]
    /// @notice Returns the normalized income of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The reserve's normalized income
    public fun get_reserve_normalized_income(asset: address): u256 acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        get_normalized_income_by_reserve_data(reserve_data)
    }

    #[view]
    /// @notice Returns the ongoing normalized income for the reserve
    /// @dev A value of 1e27 means there is no income. As time passes, the income is accrued
    /// @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
    /// @param reserve The reserve data object
    /// @return The normalized income, expressed in ray
    public fun get_normalized_income_by_reserve_data(
        reserve_data: Object<ReserveData>
    ): u256 acquires ReserveData {
        let reserve_data = object_to_ref(reserve_data);
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            //if the index was updated in the same block, no need to perform any calculation
            return (reserve_data.liquidity_index as u256)
        };

        wad_ray_math::ray_mul(
            math_utils::calculate_linear_interest(
                (reserve_data.current_liquidity_rate as u256), last_update_timestamp
            ),
            (reserve_data.liquidity_index as u256)
        )
    }

    #[view]
    /// @notice Returns the normalized variable debt per unit of asset
    /// @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
    /// "dynamic" variable index based on time, current stored index and virtual rate at the current
    /// moment (approx. a borrower would get if opening a position). This means that is always used in
    /// combination with variable debt supply/balances.
    /// If using this function externally, consider that is possible to have an increasing normalized
    /// variable debt that is not equivalent to how the variable debt index would be updated in storage
    /// (e.g. only updates with non-zero variable debt supply)
    /// @param asset The address of the underlying asset of the reserve
    /// @return The reserve normalized variable debt
    public fun get_reserve_normalized_variable_debt(
        asset: address
    ): u256 acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        get_normalized_debt_by_reserve_data(reserve_data)
    }

    #[view]
    /// @notice Returns the ongoing normalized variable debt for the reserve
    /// @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
    /// @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
    /// @param reserve The reserve data object
    /// @return The normalized variable debt, expressed in ray
    public fun get_normalized_debt_by_reserve_data(
        reserve_data: Object<ReserveData>
    ): u256 acquires ReserveData {
        let reserve_data = object_to_ref(reserve_data);
        let last_update_timestamp = reserve_data.last_update_timestamp;
        if (last_update_timestamp == timestamp::now_seconds()) {
            //if the index was updated in the same block, no need to perform any calculation
            return (reserve_data.variable_borrow_index as u256)
        };
        wad_ray_math::ray_mul(
            math_utils::calculate_compounded_interest_now(
                (reserve_data.current_variable_borrow_rate as u256),
                last_update_timestamp
            ),
            (reserve_data.variable_borrow_index as u256)
        )
    }

    #[view]
    /// @notice Returns the list of the underlying assets of all the initialized reserves
    /// @dev It does not include dropped reserves
    /// @return The addresses of the underlying assets of the initialized reserves
    public fun get_reserves_list(): vector<address> acquires Reserves {
        let reserves = get_reserves_ref();
        let address_list = vector[];
        smart_table::for_each_ref(
            &reserves.reserves,
            |k, _v| {
                vector::push_back(&mut address_list, *k);
            }
        );
        address_list
    }

    #[view]
    /// @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the ReserveData struct
    /// @param id The id of the reserve as stored in the ReserveData struct
    /// @return The address of the reserve associated with id
    public fun get_reserve_address_by_id(id: u256): address acquires Reserves {
        let id = (id as u16);
        let reserves = get_reserves_ref();
        if (!smart_table::contains(&reserves.reserves_list, id)) {
            return @0x0
        };
        *smart_table::borrow(&reserves.reserves_list, id)
    }

    #[view]
    /// @notice Returns the total flashloan premium
    /// @return The total flashloan premium
    public fun get_flashloan_premium_total(): u128 acquires ReserveExtendConfiguration {
        let reserve_extend_configuration =
            borrow_global<ReserveExtendConfiguration>(@aave_pool);
        reserve_extend_configuration.flash_loan_premium_total
    }

    #[view]
    /// @notice Returns the flashloan premium to protocol
    /// @return The flashloan premium to protocol
    public fun get_flashloan_premium_to_protocol(): u128 acquires ReserveExtendConfiguration {
        let reserve_extend_configuration =
            borrow_global<ReserveExtendConfiguration>(@aave_pool);
        reserve_extend_configuration.flash_loan_premium_to_protocol
    }

    #[view]
    /// @notice Returns the maximum number of reserves supported to be listed in this Pool
    /// @return The maximum number of reserves supported
    public fun max_number_reserves(): u16 {
        (reserve_config::get_max_reserves_count() as u16)
    }

    #[view]
    /// @notice Checks if a specified asset exists in the reserve list
    /// @dev Ensures the reserve list is initialized before checking for the asset's presence
    /// @param asset The address of the asset to check in the reserve list
    /// @return A boolean indicating whether the asset exists in the reserve list
    public fun asset_exists(asset: address): bool acquires Reserves {
        let reserves = get_reserves_ref();
        smart_table::contains(&reserves.reserves, asset)
    }

    // Public functions
    /// @notice Returns the Isolation Mode state of the user
    /// @param user_config_map The configuration of the user
    /// @return True if the user is in isolation mode, false otherwise
    /// @return The address of the only asset used as collateral
    /// @return The debt ceiling of the reserve
    public fun get_isolation_mode_state(
        user_config_map: &UserConfigurationMap
    ): (bool, address, u256) acquires Reserves, ReserveData {
        if (user_config::is_using_as_collateral_one(user_config_map)) {
            let asset_id =
                user_config::get_first_asset_id_by_mask(
                    user_config_map,
                    user_config::get_collateral_mask()
                );
            let asset_address = get_reserve_address_by_id(asset_id);
            if (asset_address == @0x0) {
                return (false, @0x0, 0)
            };
            let reserves_config_map = get_reserve_configuration(asset_address);
            let ceiling = reserve_config::get_debt_ceiling(&reserves_config_map);
            if (ceiling != 0) {
                return (true, asset_address, ceiling)
            }
        };
        (false, @0x0, 0)
    }

    #[view]
    /// @notice Returns the siloed borrowing state for the user
    /// @param account The address of the user
    /// @return True if the user has borrowed a siloed asset, false otherwise
    /// @return The address of the only borrowed asset
    public fun get_siloed_borrowing_state(
        account: address
    ): (bool, address) acquires UsersConfig, Reserves, ReserveData {
        let user_configuration = get_user_configuration(account);

        if (user_config::is_borrowing_one(&user_configuration)) {
            let asset_id =
                user_config::get_first_asset_id_by_mask(
                    &user_configuration,
                    user_config::get_borrowing_mask()
                );
            let asset_address = get_reserve_address_by_id(asset_id);
            if (asset_address == @0x0) {
                return (false, @0x0)
            };
            let reserves_config_map = get_reserve_configuration(asset_address);

            if (reserve_config::get_siloed_borrowing(&reserves_config_map)) {
                return (true, asset_address)
            };
        };
        (false, @0x0)
    }

    /// @notice Sets the reserve configuration with guard
    /// @param account The account signer of the caller
    /// @param asset The address of the underlying asset of the reserve
    /// @param reserve_config_map The new configuration bitmap
    public fun set_reserve_configuration_with_guard(
        account: &signer, asset: address, reserve_config_map: ReserveConfigurationMap
    ) acquires Reserves, ReserveData {
        assert!(
            acl_manage::is_asset_listing_admin(signer::address_of(account))
                || acl_manage::is_pool_admin(signer::address_of(account)),
            error_config::get_ecaller_not_asset_listing_or_pool_admin()
        );
        set_reserve_configuration(asset, reserve_config_map);
    }

    // Public friend functions
    /// @notice Initializes the pool
    /// @dev Only callable by the pool_configurator module
    /// @param account The account signer of the caller
    public(friend) fun init_pool(account: &signer) {
        assert!(
            (signer::address_of(account) == @aave_pool),
            error_config::get_enot_pool_owner()
        );

        move_to(
            account,
            Reserves {
                reserves: smart_table::new(),
                reserves_list: smart_table::new(),
                count: 0
            }
        );

        move_to(
            account,
            UsersConfig { value: smart_table::new() }
        );

        move_to(
            account,
            ReserveExtendConfiguration {
                flash_loan_premium_total: 0,
                flash_loan_premium_to_protocol: 0
            }
        );
    }

    /// @notice Constructor for the `ReserveData` struct
    /// @param owner The owner of the reserve
    /// @param underlying_asset The address of the underlying asset of the reserve
    /// @param a_token_address The address of the aToken
    /// @param variable_debt_token_address The address of the variable debt token
    /// @param configuration The configuration of the reserve
    /// @return The object that refers to the state of the reserve
    public(friend) fun new_reserve_data(
        owner: &signer,
        underlying_asset: address,
        a_token_address: address,
        variable_debt_token_address: address,
        configuration: ReserveConfigurationMap
    ): Object<ReserveData> acquires Reserves {
        let reserves = get_reserves_mut();

        // look for a vacant id
        let id = reserves.count;
        for (i in 0..reserves.count) {
            if (!smart_table::contains(&reserves.reserves_list, i)) {
                id = i;
                break
            };
        };

        if (id == reserves.count) {
            // assert that the maximum number of reserves hasn't been reached
            assert!(
                reserves.count < (reserve_config::get_max_reserves_count() as u16),
                error_config::get_eno_more_reserves_allowed()
            );

            // update the reserve count
            reserves.count = reserves.count + 1;
        };

        // create the ReserveData object
        let constructor_ref = object::create_object(signer::address_of(owner));
        let data = ReserveData {
            configuration,
            liquidity_index: (wad_ray_math::ray() as u128),
            current_liquidity_rate: 0,
            variable_borrow_index: (wad_ray_math::ray() as u128),
            current_variable_borrow_rate: 0,
            last_update_timestamp: 0,
            deficit: 0,
            id,
            liquidation_grace_period_until: 0,
            a_token_address,
            variable_debt_token_address,
            accrued_to_treasury: 0,
            isolation_mode_total_debt: 0,
            virtual_underlying_balance: 0
        };
        move_to(&object::generate_signer(&constructor_ref), data);

        let data_object =
            object::object_from_constructor_ref<ReserveData>(&constructor_ref);

        // register the object into storage
        smart_table::add(
            &mut reserves.reserves,
            underlying_asset,
            ReserveInfo {
                object: data_object,
                delete_ref: object::generate_delete_ref(&constructor_ref)
            }
        );
        smart_table::add(&mut reserves.reserves_list, id, underlying_asset);

        // return the object
        data_object
    }

    /// @notice This function is used to delete the reserve data for a specified asset
    /// @dev Only callable by the pool_token_logic module
    /// @param asset The address of the underlying asset of the reserve
    public(friend) fun delete_reserve_data(asset: address) acquires Reserves, ReserveData {
        let reserves = get_reserves_mut();
        assert!(
            smart_table::contains(&reserves.reserves, asset),
            error_config::get_easset_not_listed()
        );

        // remove the reserve from mapping
        let ReserveInfo { object, delete_ref } =
            smart_table::remove(&mut reserves.reserves, asset);

        // remove the reserve from list
        let id = object_to_ref(object).id;
        smart_table::remove(&mut reserves.reserves_list, id);

        // remove the reserve object
        object::delete(delete_ref);
    }

    /// @notice This function sets the last update timestamp for a specified asset's reserve data
    /// @dev Only callable by the pool_logic module
    /// @param reserve_data The reserve data object to update
    /// @param last_update_timestamp The new last update timestamp to set, expressed as a u64 value
    public(friend) fun set_reserve_last_update_timestamp(
        reserve_data: Object<ReserveData>, last_update_timestamp: u64
    ) acquires ReserveData {
        object_to_mut(reserve_data).last_update_timestamp = last_update_timestamp
    }

    /// @notice Update accrued_to_treasury of the reserve
    /// @dev Only callable by the pool and flashloan_logic module
    /// @param reserve_data The reserve data object to update
    /// @param accrued_to_treasury The new accrued_to_treasury value
    public(friend) fun set_reserve_accrued_to_treasury(
        reserve_data: Object<ReserveData>, accrued_to_treasury: u256
    ) acquires ReserveData {
        object_to_mut(reserve_data).accrued_to_treasury = accrued_to_treasury;
    }

    /// @notice This function sets the variable borrow index for a specified asset's reserve data
    /// @dev Only callable by the pool_logic module
    /// @param reserve_data The reserve data object to update
    /// @param variable_borrow_index The new variable borrow index to set, expressed as a u128 value
    public(friend) fun set_reserve_variable_borrow_index(
        reserve_data: Object<ReserveData>, variable_borrow_index: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).variable_borrow_index = variable_borrow_index
    }

    /// @notice This function sets the liquidity index for a specified asset's reserve data
    /// @dev Only callable by the pool, pool_logic module
    /// @param reserve_data The reserve data object to update
    /// @param liquidity_index The new liquidity index to set, expressed as a u128 value
    public(friend) fun set_reserve_liquidity_index(
        reserve_data: Object<ReserveData>, liquidity_index: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).liquidity_index = liquidity_index
    }

    /// @notice This function sets the current liquidity rate for a specified asset's reserve data
    /// @dev Only callable by the pool_logic module
    /// @param reserve_data The reserve data object to update
    /// @param current_liquidity_rate The new current liquidity rate to set, expressed as a u128 value
    public(friend) fun set_reserve_current_liquidity_rate(
        reserve_data: Object<ReserveData>, current_liquidity_rate: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).current_liquidity_rate = current_liquidity_rate
    }

    /// @notice This function sets the current variable borrow rate for a specified asset's reserve data
    /// @dev Only callable by the pool_logic module
    /// @param reserve_data The reserve data object to update
    /// @param current_variable_borrow_rate The new current variable borrow rate to set, expressed as a u128 value
    public(friend) fun set_reserve_current_variable_borrow_rate(
        reserve_data: Object<ReserveData>, current_variable_borrow_rate: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).current_variable_borrow_rate =
            current_variable_borrow_rate
    }

    /// @notice Updates isolation_mode_total_debt of the reserve
    /// @dev Only callable by the borrow_logic and isolation_mode_logic module
    /// @param reserve_data The reserve data object to update
    /// @param isolation_mode_total_debt The new isolation_mode_total_debt value
    public(friend) fun set_reserve_isolation_mode_total_debt(
        reserve_data: Object<ReserveData>, isolation_mode_total_debt: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).isolation_mode_total_debt = isolation_mode_total_debt
    }

    /// @notice Sets the virtual underlying balance of the reserve
    /// @param reserve_data The reserve data object to update
    /// @param balance The new virtual underlying balance
    public(friend) fun set_reserve_virtual_underlying_balance(
        reserve_data: Object<ReserveData>, balance: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).virtual_underlying_balance = balance
    }

    /// @notice Sets the liquidation grace period of the given asset
    /// @dev To enable a liquidation grace period, a timestamp in the future should be set,
    ///      To disable a liquidation grace period, any timestamp in the past works, like 0
    /// @dev Only callable by the pool_configurator module
    /// @param reserve_data The reserve data object to update
    /// @param until Timestamp when the liquidation grace period will end
    public(friend) fun set_liquidation_grace_period(
        reserve_data: Object<ReserveData>, until: u64
    ) acquires ReserveData {
        object_to_mut(reserve_data).liquidation_grace_period_until = until
    }

    /// @notice Sets the deficit of the reserve
    /// @dev Only callable by the liquidation_logic module
    /// @param reserve_data The reserve data object to update
    /// @param deficit The new deficit of the reserve
    public(friend) fun set_reserve_deficit(
        reserve_data: Object<ReserveData>, deficit: u128
    ) acquires ReserveData {
        object_to_mut(reserve_data).deficit = deficit
    }

    /// @notice Sets the configuration bitmap of the reserve as a whole
    /// @dev Only callable by the pool_configurator and pool module
    /// @param asset The address of the underlying asset of the reserve
    /// @param reserve_config_map The new configuration bitmap
    public(friend) fun set_reserve_configuration(
        asset: address, reserve_config_map: ReserveConfigurationMap
    ) acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        object_to_mut(reserve_data).configuration = reserve_config_map;
    }

    /// @notice Sets the configuration bitmap of the user
    /// @dev Only callable by the supply_logic, borrow_logic and liquidation_logic module
    /// @param user The address of the user
    /// @param user_config_map The new configuration bitmap
    public(friend) fun set_user_configuration(
        user: address, user_config_map: UserConfigurationMap
    ) acquires UsersConfig {
        let user_config_obj = borrow_global_mut<UsersConfig>(@aave_pool);
        smart_table::upsert(&mut user_config_obj.value, user, user_config_map);
    }

    /// @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
    /// to accumulate the flashloan fee to the reserve, and spread it between all the suppliers
    /// @dev Only callable by the flashloan_logic module
    /// @param reserve_data The reserve data object to update
    /// @param total_liquidity The total liquidity available in the reserve
    /// @param amount The amount to accumulate
    /// @return The next liquidity index of the reserve
    public(friend) fun cumulate_to_liquidity_index(
        reserve_data: Object<ReserveData>, total_liquidity: u256, amount: u256
    ): u256 acquires ReserveData {
        //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
        //division `amount / totalLiquidity` done in ray for precision
        let result =
            wad_ray_math::ray_mul(
                (
                    wad_ray_math::ray_div(
                        wad_ray_math::wad_to_ray(amount),
                        wad_ray_math::wad_to_ray(total_liquidity)
                    ) + wad_ray_math::ray()
                ),
                (object_to_ref(reserve_data).liquidity_index as u256)
            );

        set_reserve_liquidity_index(reserve_data, (result as u128));
        result
    }

    /// @notice Resets the isolation mode total debt of the given asset to zero
    /// @dev Only callable by the pool_configurator module
    /// @dev It requires the given asset has zero debt ceiling
    /// @param asset The address of the underlying asset to reset the isolation_mode_total_debt
    public(friend) fun reset_isolation_mode_total_debt(
        asset: address
    ) acquires Reserves, ReserveData {
        let reserve_data = object_to_mut(get_reserve_data(asset));
        let reserve_config_map = reserve_data.configuration;
        assert!(
            reserve_config::get_debt_ceiling(&reserve_config_map) == 0,
            error_config::get_edebt_ceiling_not_zero()
        );
        reserve_data.isolation_mode_total_debt = 0;

        events::emit_isolated_mode_total_debt_updated(asset, 0);
    }

    /// @notice Updates flash loan premiums. Flash loan premium consists of two parts:
    /// - A part is sent to aToken holders as extra, one time accumulated interest
    /// - A part is collected by the protocol treasury
    /// @dev The total premium is calculated on the total borrowed amount
    /// @dev The premium to protocol is calculated on the total premium, being a percentage of `flash_loan_premium_total`
    /// @dev Only callable by the pool_configurator module
    /// @param flash_loan_premium_total The total premium, expressed in bps
    /// @param flash_loan_premium_to_protocol The part of the premium sent to the protocol treasury, expressed in bps
    public(friend) fun update_flashloan_premiums(
        flash_loan_premium_total: u128, flash_loan_premium_to_protocol: u128
    ) acquires ReserveExtendConfiguration {
        let reserve_extend_configuration =
            borrow_global_mut<ReserveExtendConfiguration>(@aave_pool);

        reserve_extend_configuration.flash_loan_premium_total = flash_loan_premium_total;
        reserve_extend_configuration.flash_loan_premium_to_protocol =
            flash_loan_premium_to_protocol
    }

    // Private functions
    /// @notice Ensures that the reserve list has been initialized
    /// @dev Checks if the global `ReserveList` exists at the specified address
    /// @dev Emits an error if the reserve list is not initialized
    fun assert_reserves_initialized() {
        assert!(
            exists<Reserves>(@aave_pool),
            error_config::get_ereserve_list_not_initialized()
        );
    }

    /// @notice Retrieves an immutable reference to the reserve list for a specified asset
    /// @dev Ensures the reserve list is initialized and contains the specified asset before returning a reference
    /// @return An immutable reference to the `ReserveList`
    inline fun get_reserves_ref(): &Reserves {
        assert_reserves_initialized();
        borrow_global<Reserves>(@aave_pool)
    }

    /// @notice Retrieves a mutable reference to the reserve list for a specified asset
    /// @dev Ensures the reserve list is initialized and contains the specified asset
    /// @return A mutable reference to the reserve list
    inline fun get_reserves_mut(): &mut Reserves {
        assert_reserves_initialized();
        borrow_global_mut<Reserves>(@aave_pool)
    }

    /// @notice Utility to convert an object into an immutable reference
    /// @param obj The object to convert
    /// @return An immutable reference to the object
    inline fun object_to_ref<T: key>(obj: Object<T>): &T {
        borrow_global(object::object_address(&obj))
    }

    /// @notice Utility to convert an object into a mutable reference
    /// @param obj The object to convert
    /// @return A mutable reference to the object
    inline fun object_to_mut<T: key>(obj: Object<T>): &mut T {
        borrow_global_mut(object::object_address(&obj))
    }

    // Test only functions
    #[test_only]
    /// @notice Initializes the pool for testing
    /// @param account The account signer of the caller
    public fun test_init_pool(account: &signer) {
        init_pool(account);
    }

    #[test_only]
    /// @notice Sets the flashloan premiums for testing
    /// @param flash_loan_premium_total The total premium, expressed in bps
    /// @param flash_loan_premium_to_protocol The part of the premium sent to the protocol treasury, expressed in bps
    public fun set_flashloan_premiums_test(
        flash_loan_premium_total: u128, flash_loan_premium_to_protocol: u128
    ) acquires ReserveExtendConfiguration {
        update_flashloan_premiums(
            flash_loan_premium_total, flash_loan_premium_to_protocol
        )
    }

    #[test_only]
    /// @notice Sets the reserve configuration for testing
    /// @param asset The address of the underlying asset of the reserve
    /// @param reserve_config_map The new configuration bitmap
    public fun test_set_reserve_configuration(
        asset: address, reserve_config_map: ReserveConfigurationMap
    ) acquires Reserves, ReserveData {
        set_reserve_configuration(asset, reserve_config_map);
    }

    #[test_only]
    /// @notice Sets the current liquidity rate for testing
    /// @param asset The address of the underlying asset of the reserve
    /// @param current_liquidity_rate The new current liquidity rate
    public fun set_reserve_current_liquidity_rate_for_testing(
        asset: address, current_liquidity_rate: u128
    ) acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        set_reserve_current_liquidity_rate(reserve_data, current_liquidity_rate)
    }

    #[test_only]
    /// @notice Sets the current variable borrow rate for testing
    /// @param asset The address of the underlying asset of the reserve
    /// @param current_variable_borrow_rate The new current variable borrow rate
    public fun set_reserve_current_variable_borrow_rate_for_testing(
        asset: address, current_variable_borrow_rate: u128
    ) acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        set_reserve_current_variable_borrow_rate(
            reserve_data, current_variable_borrow_rate
        );
    }

    #[test_only]
    /// @notice Sets the liquidity index for testing
    /// @param asset The address of the underlying asset of the reserve
    /// @param liquidity_index The new liquidity index
    public fun set_reserve_liquidity_index_for_testing(
        asset: address, liquidity_index: u128
    ) acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        set_reserve_liquidity_index(reserve_data, liquidity_index)
    }

    #[test_only]
    /// @notice Sets the variable borrow index for testing
    /// @param asset The address of the underlying asset of the reserve
    /// @param variable_borrow_index The new variable borrow index
    public fun set_reserve_variable_borrow_index_for_testing(
        asset: address, variable_borrow_index: u128
    ) acquires Reserves, ReserveData {
        let reserve_data = get_reserve_data(asset);
        set_reserve_variable_borrow_index(reserve_data, variable_borrow_index)
    }

    #[test_only]
    /// @notice Sets the user configuration for testing
    /// @param user The address of the user
    /// @param user_config_map The new user configuration
    public fun set_user_configuration_for_testing(
        user: address, user_config_map: UserConfigurationMap
    ) acquires UsersConfig {
        set_user_configuration(user, user_config_map)
    }

    #[test_only]
    /// @notice Sets the reserve deficit for testing
    /// @param reserve_data The reserve data object
    /// @param deficit The new deficit
    public fun set_reserve_deficit_for_testing(
        reserve_data: Object<ReserveData>, deficit: u128
    ) acquires ReserveData {
        set_reserve_deficit(reserve_data, deficit)
    }

    #[test_only]
    /// @notice Sets the accrued to treasury for testing
    /// @param reserve_data The reserve data object
    /// @param accrued_to_treasury The new accrued to treasury
    public fun set_reserve_accrued_to_treasury_for_testing(
        reserve_data: Object<ReserveData>, accrued_to_treasury: u256
    ) acquires ReserveData {
        set_reserve_accrued_to_treasury(reserve_data, accrued_to_treasury)
    }

    #[test_only]
    /// @notice Asserts that reserves are initialized for testing
    public fun assert_reserves_initialized_for_testing() {
        assert_reserves_initialized()
    }

    #[test_only]
    /// @notice Deletes a reserve address by ID for testing
    /// @param id The ID of the reserve to delete
    public fun delete_reserve_address_by_id(id: u16) acquires Reserves {
        let reserves = get_reserves_mut();
        if (smart_table::contains(&reserves.reserves_list, id)) {
            smart_table::remove(&mut reserves.reserves_list, id);
        }
    }

    #[test_only]
    /// @notice Sets the reserves count for testing
    /// @param count The new count
    public fun set_reserves_count(count: u16) acquires Reserves {
        let reserves = get_reserves_mut();
        reserves.count = count
    }
}
