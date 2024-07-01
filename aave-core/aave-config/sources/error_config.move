module aave_config::error {
    /// The caller of the function is not a pool admin
    const ECALLER_NOT_POOL_ADMIN: u64 = 1;
    /// The caller of the function is not an emergency admin
    const ECALLER_NOT_EMERGENCY_ADMIN: u64 = 2;
    /// The caller of the function is not a pool or emergency admin
    const ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN: u64 = 3;
    /// The caller of the function is not a risk or pool admin
    const ECALLER_NOT_RISK_OR_POOL_ADMIN: u64 = 4;
    /// The caller of the function is not an asset listing or pool admin
    const ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN: u64 = 5;
    /// The caller of the function is not a bridge
    const ECALLER_NOT_BRIDGE: u64 = 6;
    /// Pool addresses provider is not registered
    const EADDRESSES_PROVIDER_NOT_REGISTERED: u64 = 7;
    /// Invalid id for the pool addresses provider
    const EINVALID_ADDRESSES_PROVIDER_ID: u64 = 8;
    /// Address is not a contract
    const ENOT_CONTRACT: u64 = 9;
    /// The caller of the function is not the pool configurator
    const ECALLER_NOT_POOL_CONFIGURATOR: u64 = 10;
    /// The caller of the function is not an AToken
    const ECALLER_NOT_ATOKEN: u64 = 11;
    /// The address of the pool addresses provider is invalid
    const EINVALID_ADDRESSES_PROVIDER: u64 = 12;
    /// Invalid return value of the flashloan executor function
    const EINVALID_FLASHLOAN_EXECUTOR_RETURN: u64 = 13;
    /// Reserve has already been added to reserve list
    const ERESERVE_ALREADY_ADDED: u64 = 14;
    /// Maximum amount of reserves in the pool reached
    const ENO_MORE_RESERVES_ALLOWED: u64 = 15;
    /// Zero eMode category is reserved for volatile heterogeneous assets
    const EEMODE_CATEGORY_RESERVED: u64 = 16;
    /// Invalid eMode category assignment to asset
    const EINVALID_EMODE_CATEGORY_ASSIGNMENT: u64 = 17;
    /// The liquidity of the reserve needs to be 0
    const ERESERVE_LIQUIDITY_NOT_ZERO: u64 = 18;
    /// Invalid flashloan premium
    const EFLASHLOAN_PREMIUM_INVALID: u64 = 19;
    /// Invalid risk parameters for the reserve
    const EINVALID_RESERVE_PARAMS: u64 = 20;
    /// Invalid risk parameters for the eMode category
    const EINVALID_EMODE_CATEGORY_PARAMS: u64 = 21;
    /// Invalid bridge protocol fee
    const EBRIDGE_PROTOCOL_FEE_INVALID: u64 = 22;
    /// The caller of this function must be a pool
    const ECALLER_MUST_BE_POOL: u64 = 23;
    /// Invalid amount to mint
    const EINVALID_MINT_AMOUNT: u64 = 24;
    /// Invalid amount to burn
    const EINVALID_BURN_AMOUNT: u64 = 25;
    /// Amount must be greater than 0
    const EINVALID_AMOUNT: u64 = 26;
    /// Action requires an active reserve
    const ERESERVE_INACTIVE: u64 = 27;
    /// Action cannot be performed because the reserve is frozen
    const ERESERVE_FROZEN: u64 = 28;
    /// Action cannot be performed because the reserve is paused
    const ERESERVE_PAUSED: u64 = 29;
    /// Borrowing is not enabled
    const EBORROWING_NOT_ENABLED: u64 = 30;
    /// User cannot withdraw more than the available balance
    const ENOT_ENOUGH_AVAILABLE_USER_BALANCE: u64 = 32;
    /// Invalid interest rate mode selected
    const EINVALID_INTEREST_RATE_MODE_SELECTED: u64 = 33;
    /// The collateral balance is 0
    const ECOLLATERAL_BALANCE_IS_ZERO: u64 = 34;
    /// Health factor is lesser than the liquidation threshold
    const EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD: u64 = 35;
    /// There is not enough collateral to cover a new borrow
    const ECOLLATERAL_CANNOT_COVER_NEW_BORROW: u64 = 36;
    /// Collateral is (mostly) the same currency that is being borrowed
    const ECOLLATERAL_SAME_AS_BORROWING_CURRENCY: u64 = 37;
    /// For repayment of a specific type of debt, the user needs to have debt that type
    const ENO_DEBT_OF_SELECTED_TYPE: u64 = 39;
    /// To repay on behalf of a user an explicit amount to repay is needed
    const ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF: u64 = 40;
    /// User does not have outstanding variable rate debt on this reserve
    const ENO_OUTSTANDING_VARIABLE_DEBT: u64 = 42;
    /// The underlying balance needs to be greater than 0
    const EUNDERLYING_BALANCE_ZERO: u64 = 43;
    /// Interest rate rebalance conditions were not met
    const EINTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET: u64 = 44;
    /// Health factor is not below the threshold
    const EHEALTH_FACTOR_NOT_BELOW_THRESHOLD: u64 = 45;
    /// The collateral chosen cannot be liquidated
    const ECOLLATERAL_CANNOT_BE_LIQUIDATED: u64 = 46;
    /// User did not borrow the specified currency
    const ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER: u64 = 47;
    /// Inconsistent flashloan parameters
    const EINCONSISTENT_FLASHLOAN_PARAMS: u64 = 49;
    /// Borrow cap is exceeded
    const EBORROW_CAP_EXCEEDED: u64 = 50;
    /// Supply cap is exceeded
    const ESUPPLY_CAP_EXCEEDED: u64 = 51;
    /// Unbacked mint cap is exceeded
    const EUNBACKED_MINT_CAP_EXCEEDED: u64 = 52;
    /// Debt ceiling is exceeded
    const EDEBT_CEILING_EXCEEDED: u64 = 53;
    /// Claimable rights over underlying not zero (aToken supply or accruedToTreasury)
    const EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO: u64 = 54;
    /// Variable debt supply is not zero
    const EVARIABLE_DEBT_SUPPLY_NOT_ZERO: u64 = 56;
    /// Ltv validation failed
    const ELTV_VALIDATION_FAILED: u64 = 57;
    /// Inconsistent eMode category
    const EINCONSISTENT_EMODE_CATEGORY: u64 = 58;
    /// Price oracle sentinel validation failed
    const EPRICE_ORACLE_SENTINEL_CHECK_FAILED: u64 = 59;
    /// Asset is not borrowable in isolation mode
    const EASSET_NOT_BORROWABLE_IN_ISOLATION: u64 = 60;
    /// Reserve has already been initialized
    const ERESERVE_ALREADY_INITIALIZED: u64 = 61;
    /// User is in isolation mode or ltv is zero
    const EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO: u64 = 62;
    /// Invalid ltv parameter for the reserve
    const EINVALID_LTV: u64 = 63;
    /// Invalid liquidity threshold parameter for the reserve
    const EINVALID_LIQ_THRESHOLD: u64 = 64;
    /// Invalid liquidity bonus parameter for the reserve
    const EINVALID_LIQ_BONUS: u64 = 65;
    /// Invalid decimals parameter of the underlying asset of the reserve
    const EINVALID_DECIMALS: u64 = 66;
    /// Invalid reserve factor parameter for the reserve
    const EINVALID_RESERVE_FACTOR: u64 = 67;
    /// Invalid borrow cap for the reserve
    const EINVALID_BORROW_CAP: u64 = 68;
    /// Invalid supply cap for the reserve
    const EINVALID_SUPPLY_CAP: u64 = 69;
    /// Invalid liquidation protocol fee for the reserve
    const EINVALID_LIQUIDATION_PROTOCOL_FEE: u64 = 70;
    /// Invalid eMode category for the reserve
    const EINVALID_EMODE_CATEGORY: u64 = 71;
    /// Invalid unbacked mint cap for the reserve
    const EINVALID_UNBACKED_MINT_CAP: u64 = 72;
    /// Invalid debt ceiling for the reserve
    const EINVALID_DEBT_CEILING: u64 = 73;
    /// Invalid reserve index
    const EINVALID_RESERVE_INDEX: u64 = 74;
    /// ACL admin cannot be set to the zero address
    const EACL_ADMIN_CANNOT_BE_ZERO: u64 = 75;
    /// Array parameters that should be equal length are not
    const EINCONSISTENT_PARAMS_LENGTH: u64 = 76;
    /// Zero address not valid
    const EZERO_ADDRESS_NOT_VALID: u64 = 77;
    /// Invalid expiration
    const EINVALID_EXPIRATION: u64 = 78;
    /// Invalid signature
    const EINVALID_SIGNATURE: u64 = 79;
    /// Operation not supported
    const EOPERATION_NOT_SUPPORTED: u64 = 80;
    /// Debt ceiling is not zero
    const EDEBT_CEILING_NOT_ZERO: u64 = 81;
    /// Asset is not listed
    const EASSET_NOT_LISTED: u64 = 82;
    /// Invalid optimal usage ratio
    const EINVALID_OPTIMAL_USAGE_RATIO: u64 = 83;
    /// The underlying asset cannot be rescued
    const EUNDERLYING_CANNOT_BE_RESCUED: u64 = 85;
    /// Reserve has already been added to reserve list
    const EADDRESSES_PROVIDER_ALREADY_ADDED: u64 = 86;
    /// The token implementation pool address and the pool address provided by the initializing pool do not match
    const EPOOL_ADDRESSES_DO_NOT_MATCH: u64 = 87;

    /// User is trying to borrow multiple assets including a siloed one
    const ESILOED_BORROWING_VIOLATION: u64 = 89;
    /// the total debt of the reserve needs to be 0
    const ERESERVE_DEBT_NOT_ZERO: u64 = 90;
    /// FlashLoaning for this asset is disabled
    const EFLASHLOAN_DISABLED: u64 = 91;
    /// User is not listed
    const EUSER_NOT_LISTED: u64 = 92;

    /// Mismatch of reserves count in storage
    const ERESERVES_STORAGE_COUNT_MISMATCH: u64 = 93;
    /// The person who signed must be consistent with on_behalf_of
    const ESIGNER_AND_ON_BEHALF_OF_NO_SAME: u64 = 94;

    public fun get_ecaller_not_pool_admin(): u64 {
        ECALLER_NOT_POOL_ADMIN
    }

    public fun get_ecaller_not_emergency_admin(): u64 {
        ECALLER_NOT_EMERGENCY_ADMIN
    }

    public fun get_ecaller_not_pool_or_emergency_admin(): u64 {
        ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN
    }

    public fun get_ecaller_not_risk_or_pool_admin(): u64 {
        ECALLER_NOT_RISK_OR_POOL_ADMIN
    }

    public fun get_ecaller_not_asset_listing_or_pool_admin(): u64 {
        ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    }

    public fun get_ecaller_not_bridge(): u64 {
        ECALLER_NOT_BRIDGE
    }

    public fun get_eaddresses_provider_not_registered(): u64 {
        EADDRESSES_PROVIDER_NOT_REGISTERED
    }

    public fun get_einvalid_addresses_provider_id(): u64 {
        EINVALID_ADDRESSES_PROVIDER_ID
    }

    public fun get_enot_contract(): u64 {
        ENOT_CONTRACT
    }

    public fun get_ecaller_not_pool_configurator(): u64 {
        ECALLER_NOT_POOL_CONFIGURATOR
    }

    public fun get_ecaller_not_atoken(): u64 {
        ECALLER_NOT_ATOKEN
    }

    public fun get_einvalid_addresses_provider(): u64 {
        EINVALID_ADDRESSES_PROVIDER
    }

    public fun get_einvalid_flashloan_executor_return(): u64 {
        EINVALID_FLASHLOAN_EXECUTOR_RETURN
    }

    public fun get_ereserve_already_added(): u64 {
        ERESERVE_ALREADY_ADDED
    }

    public fun get_ereserves_storage_count_mismatch(): u64 {
        ERESERVES_STORAGE_COUNT_MISMATCH
    }

    public fun get_eno_more_reserves_allowed(): u64 {
        ENO_MORE_RESERVES_ALLOWED
    }

    public fun get_eemode_category_reserved(): u64 {
        EEMODE_CATEGORY_RESERVED
    }

    public fun get_einvalid_emode_category_assignment(): u64 {
        EINVALID_EMODE_CATEGORY_ASSIGNMENT
    }

    public fun get_ereserve_liquidity_not_zero(): u64 {
        ERESERVE_LIQUIDITY_NOT_ZERO
    }

    public fun get_eflashloan_premium_invalid(): u64 {
        EFLASHLOAN_PREMIUM_INVALID
    }

    public fun get_einvalid_reserve_params(): u64 {
        EINVALID_RESERVE_PARAMS
    }

    public fun get_einvalid_emode_category_params(): u64 {
        EINVALID_EMODE_CATEGORY_PARAMS
    }

    public fun get_ebridge_protocol_fee_invalid(): u64 {
        EBRIDGE_PROTOCOL_FEE_INVALID
    }

    public fun get_ecaller_must_be_pool(): u64 {
        ECALLER_MUST_BE_POOL
    }

    public fun get_einvalid_mint_amount(): u64 {
        EINVALID_MINT_AMOUNT
    }

    public fun get_einvalid_burn_amount(): u64 {
        EINVALID_BURN_AMOUNT
    }

    public fun get_einvalid_amount(): u64 {
        EINVALID_AMOUNT
    }

    public fun get_ereserve_inactive(): u64 {
        ERESERVE_INACTIVE
    }

    public fun get_ereserve_frozen(): u64 {
        ERESERVE_FROZEN
    }

    public fun get_ereserve_paused(): u64 {
        ERESERVE_PAUSED
    }

    public fun get_eborrowing_not_enabled(): u64 {
        EBORROWING_NOT_ENABLED
    }

    public fun get_enot_enough_available_user_balance(): u64 {
        ENOT_ENOUGH_AVAILABLE_USER_BALANCE
    }

    public fun get_einvalid_interest_rate_mode_selected(): u64 {
        EINVALID_INTEREST_RATE_MODE_SELECTED
    }

    public fun get_ecollateral_balance_is_zero(): u64 {
        ECOLLATERAL_BALANCE_IS_ZERO
    }

    public fun get_ehealth_factor_lower_than_liquidation_threshold(): u64 {
        EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    }

    public fun get_ecollateral_cannot_cover_new_borrow(): u64 {
        ECOLLATERAL_CANNOT_COVER_NEW_BORROW
    }

    public fun get_ecollateral_same_as_borrowing_currency(): u64 {
        ECOLLATERAL_SAME_AS_BORROWING_CURRENCY
    }

    public fun get_eno_debt_of_selected_type(): u64 {
        ENO_DEBT_OF_SELECTED_TYPE
    }

    public fun get_eno_explicit_amount_to_repay_on_behalf(): u64 {
        ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    }

    public fun get_eno_outstanding_variable_debt(): u64 {
        ENO_OUTSTANDING_VARIABLE_DEBT
    }

    public fun get_eunderlying_balance_zero(): u64 {
        EUNDERLYING_BALANCE_ZERO
    }

    public fun get_einterest_rate_rebalance_conditions_not_met(): u64 {
        EINTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
    }

    public fun get_ehealth_factor_not_below_threshold(): u64 {
        EHEALTH_FACTOR_NOT_BELOW_THRESHOLD
    }

    public fun get_ecollateral_cannot_be_liquidated(): u64 {
        ECOLLATERAL_CANNOT_BE_LIQUIDATED
    }

    public fun get_especified_currency_not_borrowed_by_user(): u64 {
        ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
    }

    public fun get_einconsistent_flashloan_params(): u64 {
        EINCONSISTENT_FLASHLOAN_PARAMS
    }

    public fun get_eborrow_cap_exceeded(): u64 {
        EBORROW_CAP_EXCEEDED
    }

    public fun get_esupply_cap_exceeded(): u64 {
        ESUPPLY_CAP_EXCEEDED
    }

    public fun get_eunbacked_mint_cap_exceeded(): u64 {
        EUNBACKED_MINT_CAP_EXCEEDED
    }

    public fun get_edebt_ceiling_exceeded(): u64 {
        EDEBT_CEILING_EXCEEDED
    }

    public fun get_eunderlying_claimable_rights_not_zero(): u64 {
        EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO
    }

    public fun get_evariable_debt_supply_not_zero(): u64 {
        EVARIABLE_DEBT_SUPPLY_NOT_ZERO
    }

    public fun get_eltv_validation_failed(): u64 {
        ELTV_VALIDATION_FAILED
    }

    public fun get_einconsistent_emode_category(): u64 {
        EINCONSISTENT_EMODE_CATEGORY
    }

    public fun get_eprice_oracle_sentinel_check_failed(): u64 {
        EPRICE_ORACLE_SENTINEL_CHECK_FAILED
    }

    public fun get_easset_not_borrowable_in_isolation(): u64 {
        EASSET_NOT_BORROWABLE_IN_ISOLATION
    }

    public fun get_ereserve_already_initialized(): u64 {
        ERESERVE_ALREADY_INITIALIZED
    }

    public fun get_euser_in_isolation_mode_or_ltv_zero(): u64 {
        EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO
    }

    public fun get_einvalid_ltv(): u64 {
        EINVALID_LTV
    }

    public fun get_einvalid_liq_threshold(): u64 {
        EINVALID_LIQ_THRESHOLD
    }

    public fun get_einvalid_liq_bonus(): u64 {
        EINVALID_LIQ_BONUS
    }

    public fun get_einvalid_decimals(): u64 {
        EINVALID_DECIMALS
    }

    public fun get_einvalid_reserve_factor(): u64 {
        EINVALID_RESERVE_FACTOR
    }

    public fun get_einvalid_borrow_cap(): u64 {
        EINVALID_BORROW_CAP
    }

    public fun get_einvalid_supply_cap(): u64 {
        EINVALID_SUPPLY_CAP
    }

    public fun get_einvalid_liquidation_protocol_fee(): u64 {
        EINVALID_LIQUIDATION_PROTOCOL_FEE
    }

    public fun get_einvalid_emode_category(): u64 {
        EINVALID_EMODE_CATEGORY
    }

    public fun get_einvalid_unbacked_mint_cap(): u64 {
        EINVALID_UNBACKED_MINT_CAP
    }

    public fun get_einvalid_debt_ceiling(): u64 {
        EINVALID_DEBT_CEILING
    }

    public fun get_einvalid_reserve_index(): u64 {
        EINVALID_RESERVE_INDEX
    }

    public fun get_eacl_admin_cannot_be_zero(): u64 {
        EACL_ADMIN_CANNOT_BE_ZERO
    }

    public fun get_einconsistent_params_length(): u64 {
        EINCONSISTENT_PARAMS_LENGTH
    }

    public fun get_ezero_address_not_valid(): u64 {
        EZERO_ADDRESS_NOT_VALID
    }

    public fun get_einvalid_expiration(): u64 {
        EINVALID_EXPIRATION
    }

    public fun get_einvalid_signature(): u64 {
        EINVALID_SIGNATURE
    }

    public fun get_eoperation_not_supported(): u64 {
        EOPERATION_NOT_SUPPORTED
    }

    public fun get_edebt_ceiling_not_zero(): u64 {
        EDEBT_CEILING_NOT_ZERO
    }

    public fun get_easset_not_listed(): u64 {
        EASSET_NOT_LISTED
    }

    public fun get_einvalid_optimal_usage_ratio(): u64 {
        EINVALID_OPTIMAL_USAGE_RATIO
    }

    public fun get_eunderlying_cannot_be_rescued(): u64 {
        EUNDERLYING_CANNOT_BE_RESCUED
    }

    public fun get_eaddresses_provider_already_added(): u64 {
        EADDRESSES_PROVIDER_ALREADY_ADDED
    }

    public fun get_epool_addresses_do_not_match(): u64 {
        EPOOL_ADDRESSES_DO_NOT_MATCH
    }

    public fun get_esiloed_borrowing_violation(): u64 {
        ESILOED_BORROWING_VIOLATION
    }

    public fun get_ereserve_debt_not_zero(): u64 {
        ERESERVE_DEBT_NOT_ZERO
    }

    public fun get_eflashloan_disabled(): u64 {
        EFLASHLOAN_DISABLED
    }

    public fun get_euser_not_listed(): u64 {
        EUSER_NOT_LISTED
    }

    public fun get_esigner_and_on_behalf_of_no_same(): u64 {
        ESIGNER_AND_ON_BEHALF_OF_NO_SAME
    }

}
