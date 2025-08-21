#[test_only]
module aave_config::error_tests {
    use aave_config::error_config::{
        get_eaccount_does_not_exist,
        get_eacl_admin_cannot_be_zero,
        get_eaddresses_provider_already_added,
        get_eaddresses_provider_not_registered,
        get_easset_not_borrowable_in_isolation,
        get_easset_not_listed,
        get_eborrow_cap_exceeded,
        get_eborrowing_not_enabled,
        get_ecaller_must_be_pool,
        get_ecaller_not_asset_listing_or_pool_admin,
        get_ecaller_not_atoken,
        get_ecaller_not_emergency_admin,
        get_ecaller_not_pool_admin,
        get_ecaller_not_pool_configurator,
        get_ecaller_not_pool_or_emergency_admin,
        get_ecaller_not_risk_or_pool_admin,
        get_ecollateral_balance_is_zero,
        get_ecollateral_cannot_be_liquidated,
        get_ecollateral_cannot_cover_new_borrow,
        get_ecollateral_same_as_borrowing_currency,
        get_edebt_ceiling_exceeded,
        get_edebt_ceiling_not_zero,
        get_eemode_category_reserved,
        get_eflashloan_disabled,
        get_eflashloan_premium_invalid,
        get_ehealth_factor_lower_than_liquidation_threshold,
        get_ehealth_factor_not_below_threshold,
        get_einconsistent_emode_category,
        get_einconsistent_flashloan_params,
        get_einconsistent_params_length,
        get_einvalid_addresses_provider,
        get_einvalid_addresses_provider_id,
        get_einvalid_amount,
        get_einvalid_borrow_cap,
        get_einvalid_burn_amount,
        get_einvalid_debt_ceiling,
        get_einvalid_decimals,
        get_einvalid_emode_category,
        get_einvalid_emode_category_assignment,
        get_einvalid_emode_category_params,
        get_einvalid_expiration,
        get_einvalid_flashloan_executor_return,
        get_einvalid_interest_rate_mode_selected,
        get_einvalid_liq_bonus,
        get_einvalid_liq_threshold,
        get_einvalid_liquidation_protocol_fee,
        get_einvalid_ltv,
        get_einvalid_mint_amount,
        get_einvalid_optimal_usage_ratio,
        get_einvalid_reserve_factor,
        get_einvalid_reserve_index,
        get_einvalid_reserve_params,
        get_einvalid_signature,
        get_einvalid_supply_cap,
        get_einvalid_unbacked_mint_cap,
        get_eltv_validation_failed,
        get_eno_debt_of_selected_type,
        get_eno_explicit_amount_to_repay_on_behalf,
        get_eno_more_reserves_allowed,
        get_eno_outstanding_variable_debt,
        get_enot_contract,
        get_enot_enough_available_user_balance,
        get_eoperation_not_supported,
        get_epool_addresses_do_not_match,
        get_eprice_oracle_check_failed,
        get_ecap_lower_than_actual_price,
        get_ereserve_already_added,
        get_ereserve_already_initialized,
        get_ereserve_debt_not_zero,
        get_ereserve_frozen,
        get_ereserve_inactive,
        get_ereserve_liquidity_not_zero,
        get_ereserve_paused,
        get_ereserves_storage_count_mismatch,
        get_esigner_and_on_behalf_of_not_same,
        get_esiloed_borrowing_violation,
        get_especified_currency_not_borrowed_by_user,
        get_esupply_cap_exceeded,
        get_eunderlying_balance_zero,
        get_eunderlying_cannot_be_rescued,
        get_eunderlying_claimable_rights_not_zero,
        get_euser_in_isolation_mode_or_ltv_zero,
        get_euser_not_listed,
        get_evariable_debt_supply_not_zero,
        get_ezero_address_not_valid,
        get_eflashloan_payer_not_receiver,
        get_enot_acl_owner,
        get_erole_mismatch,
        get_erole_can_only_renounce_self,
        get_eroles_not_initialized,
        get_eoverflow,
        get_edivision_by_zero,
        get_eoracle_not_admin,
        get_easset_already_exists,
        get_eno_asset_feed,
        get_eoralce_benchmark_length_mismatch,
        get_enegative_oracle_price,
        get_ezero_oracle_price,
        get_ecaller_not_pool_or_asset_listing_admin,
        get_erequested_feed_ids_assets_mismatch,
        get_edifferent_caller_on_behalf_of,
        get_eempty_feed_id,
        get_eno_asset_custom_price,
        get_ezero_asset_custom_price,
        get_erequested_custom_prices_assets_mismatch,
        get_easset_not_registered_with_oracle,
        get_enot_rate_owner,
        get_edefault_interest_rate_strategy_not_initialized,
        get_egho_interest_rate_strategy_not_initialized,
        get_enot_pool_owner,
        get_ereserve_list_not_initialized,
        get_etoken_already_exists,
        get_etoken_not_exist,
        get_eresource_not_exist,
        get_etoken_name_already_exist,
        get_etoken_symbol_already_exist,
        get_ereserve_addresses_list_not_initialized,
        get_einsufficient_coins_to_wrap,
        get_einsufficient_fas_to_unwrap,
        get_eunmapped_coin_to_fa,
        get_enot_rewards_admin,
        get_eincentives_controller_mismatch,
        get_eunauthorized_claimer,
        get_ereward_index_overflow,
        get_einvalid_reward_config,
        get_edistribution_does_not_exist,
        get_ereward_transfer_failed,
        get_enot_emission_admin,
        get_erewards_controller_not_defined,
        get_enot_ecosystem_reserve_funds_admin,
        get_enot_ecosystem_admin_or_recipient,
        get_estream_not_exist,
        get_estream_to_the_contract_itself,
        get_estream_to_the_caller,
        get_estream_deposit_is_zero,
        get_estart_time_before_block_timestamp,
        get_estop_time_before_the_start_time,
        get_edeposit_smaller_than_time_delta,
        get_edeposit_not_multiple_of_time_delta,
        get_estream_withdraw_is_zero,
        get_ewithdraw_exceeds_the_available_balance,
        get_einvalid_rewards_controller_address,
        get_ereward_not_exist,
        get_einvalid_max_rate,
        get_ewithdraw_to_atoken,
        get_esupply_to_atoken,
        get_eslope_2_must_be_gte_slope_1,
        get_ecaller_not_risk_or_pool_or_emergency_admin,
        get_eliquidation_grace_sentinel_check_failed,
        get_einvalid_grace_period,
        get_einvalid_freeze_flag,
        get_emust_not_leave_dust,
        get_emin_asset_decimal_places,
        get_estore_for_asset_not_exist,
        get_easset_no_price_cap,
        get_estale_oracle_price,
        get_eoracle_price_timestamp_in_future,
        get_ezero_oracle_max_asset_price_age,
        get_einvalid_max_apt_fee,
        get_einvalid_emission_rate,
        get_ezero_snapshot_ratio,
        get_einvalid_ratio_timestamp,
        get_esnapshot_overflow,
        get_ezero_ratio_decimals,
        get_emismatch_adapter_type,
        get_einvalid_growth_rate,
        get_einvalid_snapshot_delay,
        get_einvalid_snapshot_ratio,
        get_einvalid_snapshot_timestamp,
        get_ecustom_price_above_price_cap
    };

    const TEST_SUCCESS: u64 = 1;
    const TEST_FAILED: u64 = 2;

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
    /// The expect maximum borrow rate is invalid
    const EINVALID_MAX_RATE: u64 = 92;
    /// Withdrawing to the aToken is not allowed
    const EWITHDRAW_TO_ATOKEN: u64 = 93;
    /// Supplying to the aToken is not allowed
    const ESUPPLY_TO_ATOKEN: u64 = 94;
    /// Variable interest rate slope 2 can not be lower than slope 1
    const ESLOPE_2_MUST_BE_GTE_SLOPE_1: u64 = 95;
    /// The caller of the function is neither a risk nor pool admin nor emergency admin
    const ECALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN: u64 = 96;
    /// Liquidation grace sentinel validation failed
    const ELIQUIDATION_GRACE_SENTINEL_CHECK_FAILED: u64 = 97;
    /// Grace period above a valid range
    const EINVALID_GRACE_PERIOD: u64 = 98;
    /// Freeze flag is invalid
    const EINVALID_FREEZE_FLAG: u64 = 99;

    /// Below a certain threshold liquidators need to take the full position
    const EMUST_NOT_LEAVE_DUST: u64 = 103;

    // Aptos has introduced a new business logic error code range from 1001 to 2000.

    // aave_acl module error code range from 1001 to 1100.

    /// Account is not the acl's owner.
    const ENOT_ACL_OWNER: u64 = 1001;
    /// Account is missing role.
    const EROLE_MISMATCH: u64 = 1002;
    /// can only renounce roles for self
    const EROLE_CAN_ONLY_RENOUNCE_SELF: u64 = 1003;
    /// roles not initialized
    const EROLES_NOT_INITIALIZED: u64 = 1004;

    // aave_math module error code range from 1101 to 1200.

    /// Calculation results in overflow
    const EOVERFLOW: u64 = 1101;
    /// Cannot divide by zero
    const EDIVISION_BY_ZERO: u64 = 1102;

    // aave_oracle module error code range from 1201 to 1300.

    // aave_oracle module error code range from 1201 to 1300.

    /// Caller must be only oracle admin
    const EORACLE_NOT_ADMIN: u64 = 1201;
    /// Asset is already registered with feed
    const EASSET_ALREADY_EXISTS: u64 = 1202;
    /// No asset feed for the given asset
    const ENO_ASSET_FEED: u64 = 1203;
    /// Returned batch of prices equals the requested assets
    const EORACLE_BENCHMARK_LENGTH_MISMATCH: u64 = 1204;
    /// Returned oracle price is negative
    const ENEGATIVE_ORACLE_PRICE: u64 = 1205;
    /// Returned oracle price is zero
    const EZERO_ORACLE_PRICE: u64 = 1206;
    /// The caller of the function is not a risk or asset listing admin
    const ECALLER_NOT_RISK_OR_ASSET_LISTING_ADMIN: u64 = 1207;
    /// Requested assets and feed ids do not match
    const EREQUESTED_FEED_IDS_ASSETS_MISMATCH: u64 = 1208;
    /// On behalf of and caller are different for minting
    const EDIFFERENT_CALLER_ON_BEHALF_OF: u64 = 1209;
    /// Empty oracle feed_id
    const EEMPTY_FEED_ID: u64 = 1210;
    /// No custom price for the given asset
    const ENO_CUSTOM_PRICE: u64 = 1211;
    /// Zero custom price for the given asset
    const EZERO_CUSTOM_PRICE: u64 = 1212;
    /// Requested assets and custom prices do not match
    const EREQUESTED_CUSTOM_PRICES_ASSETS_MISMATCH: u64 = 1213;
    /// The asset is not registered with the oracle
    const EASSET_NOT_REGISTERED_WITH_ORACLE: u64 = 1214;
    /// The asset cap is lower than the actual price of the asset
    const ECAP_LOWER_THAN_ACTUAL_PRICE: u64 = 1215;
    /// The asset does not have a price cap
    const EASSET_NO_PRICE_CAP: u64 = 1216;
    /// The oracle price is stale
    const ESTALE_ORACLE_PRICE: u64 = 1217;
    /// The oracle price timestamp is in the future
    const EORACLE_PRICE_TIMESTAMP_IN_FUTURE: u64 = 1218;
    /// The max asset price age of the asset
    const EZERO_ORACLE_MAX_ASSET_PRICE_AGE: u64 = 1219;
    /// The snapshot ratio is zero
    const EZERO_SNAPSHOT_RATIO: u64 = 1220;
    /// The timestamp ratio is invalid
    const EINVALID_RATIO_TIMESTAMP: u64 = 1221;
    /// The snapshot may overflow very soon
    const ESNAPSHOT_OVERFLOW: u64 = 1222;
    /// The ratio decimals is zero
    const EZERO_RATIO_DECIMALS: u64 = 1223;
    /// The adapter type that is being updated is not the one stored
    const EMISMATCH_ADAPTER_TYPE: u64 = 1224;
    /// The growth rate is invalid
    const EINVALID_GROWTH_RATE: u64 = 1225;
    /// The snapshot delay is invalid
    const EINVALID_SNAPSHOT_DELAY: u64 = 1226;
    /// The snapshot ratio is invalid
    const EINVALID_SNAPSHOT_RATIO: u64 = 1227;
    /// The snapshot timestamp is invalid
    const EINVALID_SNAPSHOT_TIMESTAMP: u64 = 1228;
    /// The assigned custom price is above the price cap
    const ECUSTOM_PRICE_ABOVE_PRICE_CAP: u64 = 1229;

    // aave_rate module error code range from 1301 to 1400.

    /// Account is not the rate's owner.
    const ENOT_RATE_OWNER: u64 = 1301;
    /// default interest rate strategy not initialized
    const EDEFAULT_INTEREST_RATE_STRATEGY_NOT_INITIALIZED: u64 = 1302;
    /// gho interest rate strategy not initialized
    const EGHO_INTEREST_RATE_STRATEGY_NOT_INITIALIZED: u64 = 1303;

    // aave_pool module error code range from 1401 to 1500.

    /// Account is not the pool's owner.
    const ENOT_POOL_OWNER: u64 = 1401;
    /// User is not listed
    const EUSER_NOT_LISTED: u64 = 1402;
    /// Mismatch of reserves count in storage
    const ERESERVES_STORAGE_COUNT_MISMATCH: u64 = 1403;
    /// The person who signed must be consistent with on_behalf_of
    const ESIGNER_AND_ON_BEHALF_OF_NOT_SAME: u64 = 1404;
    /// Account does not exist
    const EACCOUNT_DOES_NOT_EXIST: u64 = 1405;
    /// Flashloan payer is different from the flashloan receiver
    const EFLASHLOAN_PAYER_NOT_RECEIVER: u64 = 1406;
    /// Price oracle validation failed
    const EPRICE_ORACLE_CHECK_FAILED: u64 = 1407;
    /// reserve list not initialized
    const ERESERVE_LIST_NOT_INITIALIZED: u64 = 1408;
    // reserve addresses list not initialized
    const ERESERVE_ADDRESSES_LIST_NOT_INITIALIZED: u64 = 1409;
    /// The expect maximum apt fee is invalid
    const EINVALID_MAX_APT_FEE: u64 = 1410;

    /// coin migrations
    /// User has insufficient coins to wrap
    const EINSUFFICIENT_COINS_TO_WRAP: u64 = 1415;
    /// User has insufficient fungible assets to unwrap
    const EINSUFFICIENT_FAS_TO_UNWRAP: u64 = 1416;
    /// The coin has not been mapped to a fungible asset by Aptos
    const EUNMAPPED_COIN_TO_FA: u64 = 1417;

    // aave_tokens module error code range from 1501 to 1600.

    /// Token already exists
    const ETOKEN_ALREADY_EXISTS: u64 = 1501;
    /// Token not exist
    const ETOKEN_NOT_EXIST: u64 = 1502;
    /// Resource not exist
    const ERESOURCE_NOT_EXIST: u64 = 1503;
    /// Token name already exist
    const ETOKEN_NAME_ALREADY_EXIST: u64 = 1504;
    /// Token symbol already exist
    const ETOKEN_SYMBOL_ALREADY_EXIST: u64 = 1505;
    /// Asset minimum decimal places requirement is violated
    const EMIN_ASSET_DECIMAL_PLACES: u64 = 1506;

    // Periphery error codes should be above 3000

    /// Caller is not rewards admin
    const ENOT_REWARDS_ADMIN: u64 = 3001;
    /// Incentives controller mismatch
    const EINCENTIVES_CONTROLLER_MISMATCH: u64 = 3002;
    /// Claimer is not authorized to make the reward claim
    const EUNAUTHORIZED_CLAIMER: u64 = 3003;
    /// Reward index overflow
    const EREWARD_INDEX_OVERFLOW: u64 = 3004;
    /// Invalid config data used in rewards controller / distributor
    const EINVALID_REWARD_CONFIG: u64 = 3005;
    /// Distribution does not exist
    const EDISTRIBUTION_DOES_NOT_EXIST: u64 = 3006;
    /// Rewards transfer failed
    const EREWARD_TRANSFER_FAILED: u64 = 3007;
    /// Caller is not emission admin
    const ENOT_EMISSION_ADMIN: u64 = 3008;
    /// Rewards controller is not defined
    const EREWARDS_CONTROLLER_NOT_DEFINED: u64 = 3009;
    /// Caller does not have the ecosystem reserve funds admin role
    const ENOT_ECOSYSTEM_RESERVE_FUNDS_ADMIN: u64 = 3010;
    /// Caller does not have the ecosystem admin or recipient role
    const ENOT_ECOSYSTEM_ADMIN_OR_RECIPIENT: u64 = 3011;
    /// Stream does not exist
    const ESTREAM_NOT_EXIST: u64 = 3012;
    /// Creating a stream to the contract itself
    const ESTREAM_TO_THE_CONTRACT_ITSELF: u64 = 3013;
    /// Creating a stream to the caller
    const ESTREAM_TO_THE_CALLER: u64 = 3014;
    /// Stream deposit is zero
    const ESTREAM_DEPOSIT_IS_ZERO: u64 = 3015;
    /// Stream start time is before block timestamp
    const ESTART_TIME_BEFORE_BLOCK_TIMESTAMP: u64 = 3016;
    /// Stream stop time is before start time
    const ESTOP_TIME_BEFORE_THE_START_TIME: u64 = 3017;
    /// Stream deposit is smaller than time delta
    const EDEPOSIT_SMALLER_THAN_TIME_DELTA: u64 = 3018;
    /// Stream deposit is not a multiple of time delta
    const EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA: u64 = 3019;
    /// Stream withdraw amount is zero
    const ESTREAM_WITHDRAW_IS_ZERO: u64 = 3020;
    /// Stream withdraw amount exceeds available balance
    const EWITHDRAW_EXCEEDS_THE_AVAILABLE_BALANCE: u64 = 3021;
    /// Rewards controller address is not valid
    const EINVALID_REWARDS_CONTROLLER_ADDRESS: u64 = 3022;
    /// Reward does not exist
    const EREWARD_NOT_EXIST: u64 = 3023;
    /// Secondary fungible store does not exist for the asset
    const ESTORE_FOR_ASSET_NOT_EXIST: u64 = 3024;
    /// The expect maximum emission rate is invalid
    const EINVALID_EMISSION_RATE: u64 = 3025;

    #[test]
    fun test_get_ecaller_not_pool_admin() {
        assert!(get_ecaller_not_pool_admin() == ECALLER_NOT_POOL_ADMIN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ecaller_not_emergency_admin() {
        assert!(
            get_ecaller_not_emergency_admin() == ECALLER_NOT_EMERGENCY_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_not_pool_or_emergency_admin() {
        assert!(
            get_ecaller_not_pool_or_emergency_admin()
                == ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_not_risk_or_pool_admin() {
        assert!(
            get_ecaller_not_risk_or_pool_admin() == ECALLER_NOT_RISK_OR_POOL_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_not_asset_listing_or_pool_admin() {
        assert!(
            get_ecaller_not_asset_listing_or_pool_admin()
                == ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eaddresses_provider_not_registered() {
        assert!(
            get_eaddresses_provider_not_registered()
                == EADDRESSES_PROVIDER_NOT_REGISTERED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_addresses_provider_id() {
        assert!(
            get_einvalid_addresses_provider_id() == EINVALID_ADDRESSES_PROVIDER_ID,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_enot_contract() {
        assert!(get_enot_contract() == ENOT_CONTRACT, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ecaller_not_pool_configurator() {
        assert!(
            get_ecaller_not_pool_configurator() == ECALLER_NOT_POOL_CONFIGURATOR,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_not_atoken() {
        assert!(get_ecaller_not_atoken() == ECALLER_NOT_ATOKEN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_addresses_provider() {
        assert!(
            get_einvalid_addresses_provider() == EINVALID_ADDRESSES_PROVIDER,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_flashloan_executor_return() {
        assert!(
            get_einvalid_flashloan_executor_return()
                == EINVALID_FLASHLOAN_EXECUTOR_RETURN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ereserve_already_added() {
        assert!(get_ereserve_already_added() == ERESERVE_ALREADY_ADDED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ereserves_storage_count_mismatch() {
        assert!(
            get_ereserves_storage_count_mismatch() == ERESERVES_STORAGE_COUNT_MISMATCH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eno_more_reserves_allowed() {
        assert!(
            get_eno_more_reserves_allowed() == ENO_MORE_RESERVES_ALLOWED, TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eemode_category_reserved() {
        assert!(get_eemode_category_reserved() == EEMODE_CATEGORY_RESERVED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_emode_category_assignment() {
        assert!(
            get_einvalid_emode_category_assignment()
                == EINVALID_EMODE_CATEGORY_ASSIGNMENT,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ereserve_liquidity_not_zero() {
        assert!(
            get_ereserve_liquidity_not_zero() == ERESERVE_LIQUIDITY_NOT_ZERO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eflashloan_premium_invalid() {
        assert!(
            get_eflashloan_premium_invalid() == EFLASHLOAN_PREMIUM_INVALID,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_reserve_params() {
        assert!(get_einvalid_reserve_params() == EINVALID_RESERVE_PARAMS, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_emode_category_params() {
        assert!(
            get_einvalid_emode_category_params() == EINVALID_EMODE_CATEGORY_PARAMS,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_must_be_pool() {
        assert!(get_ecaller_must_be_pool() == ECALLER_MUST_BE_POOL, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_mint_amount() {
        assert!(get_einvalid_mint_amount() == EINVALID_MINT_AMOUNT, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_burn_amount() {
        assert!(get_einvalid_burn_amount() == EINVALID_BURN_AMOUNT, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_amount() {
        assert!(get_einvalid_amount() == EINVALID_AMOUNT, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ereserve_inactive() {
        assert!(get_ereserve_inactive() == ERESERVE_INACTIVE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ereserve_frozen() {
        assert!(get_ereserve_frozen() == ERESERVE_FROZEN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ereserve_paused() {
        assert!(get_ereserve_paused() == ERESERVE_PAUSED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eborrowing_not_enabled() {
        assert!(get_eborrowing_not_enabled() == EBORROWING_NOT_ENABLED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_enot_enough_available_user_balance() {
        assert!(
            get_enot_enough_available_user_balance()
                == ENOT_ENOUGH_AVAILABLE_USER_BALANCE,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_interest_rate_mode_selected() {
        assert!(
            get_einvalid_interest_rate_mode_selected()
                == EINVALID_INTEREST_RATE_MODE_SELECTED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecollateral_balance_is_zero() {
        assert!(
            get_ecollateral_balance_is_zero() == ECOLLATERAL_BALANCE_IS_ZERO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ehealth_factor_lower_than_liquidation_threshold() {
        assert!(
            get_ehealth_factor_lower_than_liquidation_threshold()
                == EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecollateral_cannot_cover_new_borrow() {
        assert!(
            get_ecollateral_cannot_cover_new_borrow()
                == ECOLLATERAL_CANNOT_COVER_NEW_BORROW,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecollateral_same_as_borrowing_currency() {
        assert!(
            get_ecollateral_same_as_borrowing_currency()
                == ECOLLATERAL_SAME_AS_BORROWING_CURRENCY,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eno_debt_of_selected_type() {
        assert!(
            get_eno_debt_of_selected_type() == ENO_DEBT_OF_SELECTED_TYPE, TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eno_explicit_amount_to_repay_on_behalf() {
        assert!(
            get_eno_explicit_amount_to_repay_on_behalf()
                == ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eno_outstanding_variable_debt() {
        assert!(
            get_eno_outstanding_variable_debt() == ENO_OUTSTANDING_VARIABLE_DEBT,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eunderlying_balance_zero() {
        assert!(get_eunderlying_balance_zero() == EUNDERLYING_BALANCE_ZERO, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ehealth_factor_not_below_threshold() {
        assert!(
            get_ehealth_factor_not_below_threshold()
                == EHEALTH_FACTOR_NOT_BELOW_THRESHOLD,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecollateral_cannot_be_liquidated() {
        assert!(
            get_ecollateral_cannot_be_liquidated() == ECOLLATERAL_CANNOT_BE_LIQUIDATED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_especified_currency_not_borrowed_by_user() {
        assert!(
            get_especified_currency_not_borrowed_by_user()
                == ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einconsistent_flashloan_params() {
        assert!(
            get_einconsistent_flashloan_params() == EINCONSISTENT_FLASHLOAN_PARAMS,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eborrow_cap_exceeded() {
        assert!(get_eborrow_cap_exceeded() == EBORROW_CAP_EXCEEDED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_esupply_cap_exceeded() {
        assert!(get_esupply_cap_exceeded() == ESUPPLY_CAP_EXCEEDED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_edebt_ceiling_exceeded() {
        assert!(get_edebt_ceiling_exceeded() == EDEBT_CEILING_EXCEEDED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eunderlying_claimable_rights_not_zero() {
        assert!(
            get_eunderlying_claimable_rights_not_zero()
                == EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_evariable_debt_supply_not_zero() {
        assert!(
            get_evariable_debt_supply_not_zero() == EVARIABLE_DEBT_SUPPLY_NOT_ZERO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eltv_validation_failed() {
        assert!(get_eltv_validation_failed() == ELTV_VALIDATION_FAILED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einconsistent_emode_category() {
        assert!(
            get_einconsistent_emode_category() == EINCONSISTENT_EMODE_CATEGORY,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_easset_not_borrowable_in_isolation() {
        assert!(
            get_easset_not_borrowable_in_isolation()
                == EASSET_NOT_BORROWABLE_IN_ISOLATION,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ereserve_already_initialized() {
        assert!(
            get_ereserve_already_initialized() == ERESERVE_ALREADY_INITIALIZED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_euser_in_isolation_mode_or_ltv_zero() {
        assert!(
            get_euser_in_isolation_mode_or_ltv_zero()
                == EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_ltv() {
        assert!(get_einvalid_ltv() == EINVALID_LTV, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_liq_threshold() {
        assert!(get_einvalid_liq_threshold() == EINVALID_LIQ_THRESHOLD, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_decimals() {
        assert!(get_einvalid_decimals() == EINVALID_DECIMALS, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_reserve_factor() {
        assert!(get_einvalid_reserve_factor() == EINVALID_RESERVE_FACTOR, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_borrow_cap() {
        assert!(get_einvalid_borrow_cap() == EINVALID_BORROW_CAP, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_supply_cap() {
        assert!(get_einvalid_supply_cap() == EINVALID_SUPPLY_CAP, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_liquidation_protocol_fee() {
        assert!(
            get_einvalid_liquidation_protocol_fee()
                == EINVALID_LIQUIDATION_PROTOCOL_FEE,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_emode_category() {
        assert!(get_einvalid_emode_category() == EINVALID_EMODE_CATEGORY, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_unbacked_mint_cap() {
        assert!(
            get_einvalid_unbacked_mint_cap() == EINVALID_UNBACKED_MINT_CAP,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_debt_ceiling() {
        assert!(get_einvalid_debt_ceiling() == EINVALID_DEBT_CEILING, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_reserve_index() {
        assert!(get_einvalid_reserve_index() == EINVALID_RESERVE_INDEX, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eacl_admin_cannot_be_zero() {
        assert!(
            get_eacl_admin_cannot_be_zero() == EACL_ADMIN_CANNOT_BE_ZERO, TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einconsistent_params_length() {
        assert!(
            get_einconsistent_params_length() == EINCONSISTENT_PARAMS_LENGTH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ezero_address_not_valid() {
        assert!(get_ezero_address_not_valid() == EZERO_ADDRESS_NOT_VALID, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_expiration() {
        assert!(get_einvalid_expiration() == EINVALID_EXPIRATION, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_signature() {
        assert!(get_einvalid_signature() == EINVALID_SIGNATURE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eoperation_not_supported() {
        assert!(get_eoperation_not_supported() == EOPERATION_NOT_SUPPORTED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_edebt_ceiling_not_zero() {
        assert!(get_edebt_ceiling_not_zero() == EDEBT_CEILING_NOT_ZERO, TEST_SUCCESS);
    }

    #[test]
    fun test_get_easset_not_listed() {
        assert!(get_easset_not_listed() == EASSET_NOT_LISTED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_optimal_usage_ratio() {
        assert!(
            get_einvalid_optimal_usage_ratio() == EINVALID_OPTIMAL_USAGE_RATIO,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eunderlying_cannot_be_rescued() {
        assert!(
            get_eunderlying_cannot_be_rescued() == EUNDERLYING_CANNOT_BE_RESCUED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eaddresses_provider_already_added() {
        assert!(
            get_eaddresses_provider_already_added()
                == EADDRESSES_PROVIDER_ALREADY_ADDED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_epool_addresses_do_not_match() {
        assert!(
            get_epool_addresses_do_not_match() == EPOOL_ADDRESSES_DO_NOT_MATCH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_esiloed_borrowing_violation() {
        assert!(
            get_esiloed_borrowing_violation() == ESILOED_BORROWING_VIOLATION,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ereserve_debt_not_zero() {
        assert!(get_ereserve_debt_not_zero() == ERESERVE_DEBT_NOT_ZERO, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eflashloan_disabled() {
        assert!(get_eflashloan_disabled() == EFLASHLOAN_DISABLED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_max_rate() {
        assert!(get_einvalid_max_rate() == EINVALID_MAX_RATE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ewithdraw_to_atoken() {
        assert!(get_ewithdraw_to_atoken() == EWITHDRAW_TO_ATOKEN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_esupply_to_atoken() {
        assert!(get_esupply_to_atoken() == ESUPPLY_TO_ATOKEN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eslope_2_must_be_gte_slope_1() {
        assert!(
            get_eslope_2_must_be_gte_slope_1() == ESLOPE_2_MUST_BE_GTE_SLOPE_1,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecaller_not_risk_or_pool_or_emergency_admin() {
        assert!(
            get_ecaller_not_risk_or_pool_or_emergency_admin()
                == ECALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eliquidation_grace_sentinel_check_failed() {
        assert!(
            get_eliquidation_grace_sentinel_check_failed()
                == ELIQUIDATION_GRACE_SENTINEL_CHECK_FAILED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_grace_period() {
        assert!(get_einvalid_grace_period() == EINVALID_GRACE_PERIOD, TEST_SUCCESS);
    }

    #[test]
    fun test_get_einvalid_freeze_flag() {
        assert!(get_einvalid_freeze_flag() == EINVALID_FREEZE_FLAG, TEST_SUCCESS);
    }

    #[test]
    fun test_get_emust_not_leave_dust() {
        assert!(get_emust_not_leave_dust() == EMUST_NOT_LEAVE_DUST, TEST_SUCCESS);
    }

    #[test]
    fun test_get_enot_acl_owner() {
        assert!(get_enot_acl_owner() == ENOT_ACL_OWNER, TEST_SUCCESS);
    }

    #[test]
    fun test_get_erole_mismatch() {
        assert!(get_erole_mismatch() == EROLE_MISMATCH, TEST_SUCCESS);
    }

    #[test]
    fun test_get_erole_can_only_renounce_self() {
        assert!(
            get_erole_can_only_renounce_self() == EROLE_CAN_ONLY_RENOUNCE_SELF,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eroles_not_initialized() {
        assert!(get_eroles_not_initialized() == EROLES_NOT_INITIALIZED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eoverflow() {
        assert!(get_eoverflow() == EOVERFLOW, TEST_SUCCESS);
    }

    #[test]
    fun test_get_edivision_by_zero() {
        assert!(get_edivision_by_zero() == EDIVISION_BY_ZERO, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eoracle_not_admin() {
        assert!(get_eoracle_not_admin() == EORACLE_NOT_ADMIN, TEST_SUCCESS);
    }

    #[test]
    fun test_get_easset_already_exists() {
        assert!(get_easset_already_exists() == EASSET_ALREADY_EXISTS, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eno_asset_feed() {
        assert!(get_eno_asset_feed() == ENO_ASSET_FEED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eoralce_benchmark_length_mismatch() {
        assert!(
            get_eoralce_benchmark_length_mismatch()
                == EORACLE_BENCHMARK_LENGTH_MISMATCH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_enegative_oracle_price() {
        assert!(get_enegative_oracle_price() == ENEGATIVE_ORACLE_PRICE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ezero_oracle_price() {
        assert!(get_ezero_oracle_price() == EZERO_ORACLE_PRICE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ecaller_not_pool_or_asset_listing_admin() {
        assert!(
            get_ecaller_not_pool_or_asset_listing_admin()
                == ECALLER_NOT_RISK_OR_ASSET_LISTING_ADMIN,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_erequested_feed_ids_assets_mismatch() {
        assert!(
            get_erequested_feed_ids_assets_mismatch()
                == EREQUESTED_FEED_IDS_ASSETS_MISMATCH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_edifferent_caller_on_behalf_of() {
        assert!(
            get_edifferent_caller_on_behalf_of() == EDIFFERENT_CALLER_ON_BEHALF_OF,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eempty_feed_id() {
        assert!(get_eempty_feed_id() == EEMPTY_FEED_ID, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eno_asset_custom_price() {
        assert!(get_eno_asset_custom_price() == ENO_CUSTOM_PRICE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_ezero_asset_custom_price() {
        assert!(get_ezero_asset_custom_price() == EZERO_CUSTOM_PRICE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_erequested_custom_prices_assets_mismatch() {
        assert!(
            get_erequested_custom_prices_assets_mismatch()
                == EREQUESTED_CUSTOM_PRICES_ASSETS_MISMATCH,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_easset_not_registered_with_oracle() {
        assert!(
            get_easset_not_registered_with_oracle()
                == EASSET_NOT_REGISTERED_WITH_ORACLE,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ecap_lower_than_actual_price() {
        assert!(
            get_ecap_lower_than_actual_price() == ECAP_LOWER_THAN_ACTUAL_PRICE,
            TEST_SUCCESS
        );
    }

    #[test]
    public fun test_get_ezero_snapshot_ratio() {
        assert!(get_ezero_snapshot_ratio() == EZERO_SNAPSHOT_RATIO, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_ezero_ratio_decimals() {
        assert!(get_ezero_ratio_decimals() == EZERO_RATIO_DECIMALS, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_emismatch_adapter_type() {
        assert!(get_emismatch_adapter_type() == EMISMATCH_ADAPTER_TYPE, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_einvalid_growth_rate() {
        assert!(get_einvalid_growth_rate() == EINVALID_GROWTH_RATE, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_einvalid_snapshot_delay() {
        assert!(get_einvalid_snapshot_delay() == EINVALID_SNAPSHOT_DELAY, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_einvalid_snapshot_ratio() {
        assert!(get_einvalid_snapshot_ratio() == EINVALID_SNAPSHOT_RATIO, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_einvalid_snapshot_timestamp() {
        assert!(
            get_einvalid_snapshot_timestamp() == EINVALID_SNAPSHOT_TIMESTAMP,
            TEST_SUCCESS
        );
    }

    #[test]
    public fun test_ecustom_price_above_price_cap() {
        assert!(
            get_ecustom_price_above_price_cap() == ECUSTOM_PRICE_ABOVE_PRICE_CAP,
            TEST_SUCCESS
        );
    }

    #[test]
    public fun test_get_einvalid_ratio_timestamp() {
        assert!(get_einvalid_ratio_timestamp() == EINVALID_RATIO_TIMESTAMP, TEST_SUCCESS);
    }

    #[test]
    public fun test_get_esnapshot_overflow() {
        assert!(get_esnapshot_overflow() == ESNAPSHOT_OVERFLOW, TEST_SUCCESS);
    }

    #[test]
    fun test_get_easset_no_price_cap() {
        assert!(get_easset_no_price_cap() == EASSET_NO_PRICE_CAP, TEST_SUCCESS);
    }

    #[test]
    fun test_get_estale_oracle_price() {
        assert!(get_estale_oracle_price() == ESTALE_ORACLE_PRICE, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eoracle_price_timestamp_in_future() {
        assert!(
            get_eoracle_price_timestamp_in_future()
                == EORACLE_PRICE_TIMESTAMP_IN_FUTURE,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ezero_oracle_max_asset_price_age() {
        assert!(
            get_ezero_oracle_max_asset_price_age() == EZERO_ORACLE_MAX_ASSET_PRICE_AGE,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_enot_rate_owner() {
        assert!(get_enot_rate_owner() == ENOT_RATE_OWNER, TEST_SUCCESS);
    }

    #[test]
    fun test_get_edefault_interest_rate_strategy_not_initialized() {
        assert!(
            get_edefault_interest_rate_strategy_not_initialized()
                == EDEFAULT_INTEREST_RATE_STRATEGY_NOT_INITIALIZED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_egho_interest_rate_strategy_not_initialized() {
        assert!(
            get_egho_interest_rate_strategy_not_initialized()
                == EGHO_INTEREST_RATE_STRATEGY_NOT_INITIALIZED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_enot_pool_owner() {
        assert!(get_enot_pool_owner() == ENOT_POOL_OWNER, TEST_SUCCESS);
    }

    #[test]
    fun test_get_euser_not_listed() {
        assert!(get_euser_not_listed() == EUSER_NOT_LISTED, TEST_SUCCESS);
    }

    #[test]
    fun test_get_esigner_and_on_behalf_of_not_same() {
        assert!(
            get_esigner_and_on_behalf_of_not_same()
                == ESIGNER_AND_ON_BEHALF_OF_NOT_SAME,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_eaccount_does_not_exist() {
        assert!(get_eaccount_does_not_exist() == EACCOUNT_DOES_NOT_EXIST, TEST_SUCCESS);
    }

    #[test]
    fun test_get_eflashloan_payer_not_receiver() {
        assert!(
            get_eflashloan_payer_not_receiver() == EFLASHLOAN_PAYER_NOT_RECEIVER,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_einvalid_liq_bonus() {
        assert!(get_einvalid_liq_bonus() == EINVALID_LIQ_BONUS, TEST_SUCCESS);
    }

    #[test]
    fun test_get_price_oracle_check_failed() {
        assert!(
            get_eprice_oracle_check_failed() == EPRICE_ORACLE_CHECK_FAILED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_ereserve_list_not_initialized() {
        assert!(
            get_ereserve_list_not_initialized() == ERESERVE_LIST_NOT_INITIALIZED,
            TEST_SUCCESS
        );
    }

    #[test]
    fun test_get_etoken_already_exists() {
        assert!(get_etoken_already_exists() == ETOKEN_ALREADY_EXISTS, TEST_SUCCESS)
    }

    #[test]
    fun test_get_etoken_not_exist() {
        assert!(get_etoken_not_exist() == ETOKEN_NOT_EXIST, TEST_SUCCESS)
    }

    #[test]
    fun test_get_eresource_not_exist() {
        assert!(get_eresource_not_exist() == ERESOURCE_NOT_EXIST, TEST_SUCCESS)
    }

    #[test]
    fun test_get_etoken_name_already_exist() {
        assert!(
            get_etoken_name_already_exist() == ETOKEN_NAME_ALREADY_EXIST, TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_etoken_symbol_already_exist() {
        assert!(
            get_etoken_symbol_already_exist() == ETOKEN_SYMBOL_ALREADY_EXIST,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_emin_asset_decimal_places() {
        assert!(
            get_emin_asset_decimal_places() == EMIN_ASSET_DECIMAL_PLACES, TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_ereserve_addresses_list_not_initialized() {
        assert!(
            get_ereserve_addresses_list_not_initialized()
                == ERESERVE_ADDRESSES_LIST_NOT_INITIALIZED,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_einvalid_max_apt_fee() {
        assert!(get_einvalid_max_apt_fee() == EINVALID_MAX_APT_FEE, TEST_SUCCESS)
    }

    #[test]
    fun test_get_einsufficient_coins_to_wrap() {
        assert!(
            get_einsufficient_coins_to_wrap() == EINSUFFICIENT_COINS_TO_WRAP,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_einsufficient_fas_to_unwrap() {
        assert!(
            get_einsufficient_fas_to_unwrap() == EINSUFFICIENT_FAS_TO_UNWRAP,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_eunmapped_coin_to_fa() {
        assert!(get_eunmapped_coin_to_fa() == EUNMAPPED_COIN_TO_FA, TEST_SUCCESS)
    }

    #[test]
    fun test_get_enot_rewards_admin() {
        assert!(get_enot_rewards_admin() == ENOT_REWARDS_ADMIN, TEST_SUCCESS)
    }

    #[test]
    fun test_get_eincentives_controller_mismatch() {
        assert!(
            get_eincentives_controller_mismatch() == EINCENTIVES_CONTROLLER_MISMATCH,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_eunauthorized_claimer() {
        assert!(get_eunauthorized_claimer() == EUNAUTHORIZED_CLAIMER, TEST_SUCCESS)
    }

    #[test]
    fun test_get_ereward_index_overflow() {
        assert!(get_ereward_index_overflow() == EREWARD_INDEX_OVERFLOW, TEST_SUCCESS)
    }

    #[test]
    fun test_get_einvalid_reward_config() {
        assert!(get_einvalid_reward_config() == EINVALID_REWARD_CONFIG, TEST_SUCCESS)
    }

    #[test]
    fun test_get_edistribution_does_not_exist() {
        assert!(
            get_edistribution_does_not_exist() == EDISTRIBUTION_DOES_NOT_EXIST,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_ereward_transfer_failed() {
        assert!(get_ereward_transfer_failed() == EREWARD_TRANSFER_FAILED, TEST_SUCCESS)
    }

    #[test]
    fun test_get_enot_emission_admin() {
        assert!(get_enot_emission_admin() == ENOT_EMISSION_ADMIN, TEST_SUCCESS)
    }

    #[test]
    fun test_get_erewards_controller_not_defined() {
        assert!(
            get_erewards_controller_not_defined() == EREWARDS_CONTROLLER_NOT_DEFINED,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_enot_ecosystem_reserve_funds_admin() {
        assert!(
            get_enot_ecosystem_reserve_funds_admin()
                == ENOT_ECOSYSTEM_RESERVE_FUNDS_ADMIN,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_enot_ecosystem_admin_or_recipient() {
        assert!(
            get_enot_ecosystem_admin_or_recipient()
                == ENOT_ECOSYSTEM_ADMIN_OR_RECIPIENT,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_estream_not_exist() {
        assert!(get_estream_not_exist() == ESTREAM_NOT_EXIST, TEST_SUCCESS)
    }

    #[test]
    fun test_get_estream_to_the_contract_itself() {
        assert!(
            get_estream_to_the_contract_itself() == ESTREAM_TO_THE_CONTRACT_ITSELF,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_estream_to_the_caller() {
        assert!(get_estream_to_the_caller() == ESTREAM_TO_THE_CALLER, TEST_SUCCESS)
    }

    #[test]
    fun test_get_estream_deposit_is_zero() {
        assert!(get_estream_deposit_is_zero() == ESTREAM_DEPOSIT_IS_ZERO, TEST_SUCCESS)
    }

    #[test]
    fun test_get_estart_time_before_block_timestamp() {
        assert!(
            get_estart_time_before_block_timestamp()
                == ESTART_TIME_BEFORE_BLOCK_TIMESTAMP,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_estop_time_before_the_start_time() {
        assert!(
            get_estop_time_before_the_start_time() == ESTOP_TIME_BEFORE_THE_START_TIME,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_edeposit_smaller_than_time_delta() {
        assert!(
            get_edeposit_smaller_than_time_delta() == EDEPOSIT_SMALLER_THAN_TIME_DELTA,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_edeposit_not_multiple_of_time_delta() {
        assert!(
            get_edeposit_not_multiple_of_time_delta()
                == EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_estream_withdraw_is_zero() {
        assert!(get_estream_withdraw_is_zero() == ESTREAM_WITHDRAW_IS_ZERO, TEST_SUCCESS)
    }

    #[test]
    fun test_get_ewithdraw_exceeds_the_available_balance() {
        assert!(
            get_ewithdraw_exceeds_the_available_balance()
                == EWITHDRAW_EXCEEDS_THE_AVAILABLE_BALANCE,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_einvalid_rewards_controller_address() {
        assert!(
            get_einvalid_rewards_controller_address()
                == EINVALID_REWARDS_CONTROLLER_ADDRESS,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_ereward_not_exist() {
        assert!(get_ereward_not_exist() == EREWARD_NOT_EXIST, TEST_SUCCESS)
    }

    #[test]
    fun test_get_estore_for_asset_not_exist() {
        assert!(
            get_estore_for_asset_not_exist() == ESTORE_FOR_ASSET_NOT_EXIST,
            TEST_SUCCESS
        )
    }

    #[test]
    fun test_get_einvalid_emission_rate() {
        assert!(get_einvalid_emission_rate() == EINVALID_EMISSION_RATE, TEST_SUCCESS)
    }
}
