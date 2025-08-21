/// @title Errors library
/// @author Aave
/// @notice Defines the error messages emitted by the different contracts of the Aave protocol
module aave_config::error_config {
    // Error constants
    /// @notice The caller of the function is not a pool admin
    const ECALLER_NOT_POOL_ADMIN: u64 = 1;
    /// @notice The caller of the function is not an emergency admin
    const ECALLER_NOT_EMERGENCY_ADMIN: u64 = 2;
    /// @notice The caller of the function is not a pool or emergency admin
    const ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN: u64 = 3;
    /// @notice The caller of the function is not a risk or pool admin
    const ECALLER_NOT_RISK_OR_POOL_ADMIN: u64 = 4;
    /// @notice The caller of the function is not an asset listing or pool admin
    const ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN: u64 = 5;
    /// @notice Pool addresses provider is not registered
    const EADDRESSES_PROVIDER_NOT_REGISTERED: u64 = 7;
    /// @notice Invalid id for the pool addresses provider
    const EINVALID_ADDRESSES_PROVIDER_ID: u64 = 8;
    /// @notice Address is not a contract
    const ENOT_CONTRACT: u64 = 9;
    /// @notice The caller of the function is not the pool configurator
    const ECALLER_NOT_POOL_CONFIGURATOR: u64 = 10;
    /// @notice The caller of the function is not an AToken
    const ECALLER_NOT_ATOKEN: u64 = 11;
    /// @notice The address of the pool addresses provider is invalid
    const EINVALID_ADDRESSES_PROVIDER: u64 = 12;
    /// @notice Invalid return value of the flashloan executor function
    const EINVALID_FLASHLOAN_EXECUTOR_RETURN: u64 = 13;
    /// @notice Reserve has already been added to reserve list
    const ERESERVE_ALREADY_ADDED: u64 = 14;
    /// @notice Maximum amount of reserves in the pool reached
    const ENO_MORE_RESERVES_ALLOWED: u64 = 15;
    /// @notice Zero eMode category is reserved for volatile heterogeneous assets
    const EEMODE_CATEGORY_RESERVED: u64 = 16;
    /// @notice Invalid eMode category assignment to asset
    const EINVALID_EMODE_CATEGORY_ASSIGNMENT: u64 = 17;
    /// @notice The liquidity of the reserve needs to be 0
    const ERESERVE_LIQUIDITY_NOT_ZERO: u64 = 18;
    /// @notice Invalid flashloan premium
    const EFLASHLOAN_PREMIUM_INVALID: u64 = 19;
    /// @notice Invalid risk parameters for the reserve
    const EINVALID_RESERVE_PARAMS: u64 = 20;
    /// @notice Invalid risk parameters for the eMode category
    const EINVALID_EMODE_CATEGORY_PARAMS: u64 = 21;
    /// @notice The caller of this function must be a pool
    const ECALLER_MUST_BE_POOL: u64 = 23;
    /// @notice Invalid amount to mint
    const EINVALID_MINT_AMOUNT: u64 = 24;
    /// @notice Invalid amount to burn
    const EINVALID_BURN_AMOUNT: u64 = 25;
    /// @notice Amount must be greater than 0
    const EINVALID_AMOUNT: u64 = 26;
    /// @notice Action requires an active reserve
    const ERESERVE_INACTIVE: u64 = 27;
    /// @notice Action cannot be performed because the reserve is frozen
    const ERESERVE_FROZEN: u64 = 28;
    /// @notice Action cannot be performed because the reserve is paused
    const ERESERVE_PAUSED: u64 = 29;
    /// @notice Borrowing is not enabled
    const EBORROWING_NOT_ENABLED: u64 = 30;
    /// @notice User cannot withdraw more than the available balance
    const ENOT_ENOUGH_AVAILABLE_USER_BALANCE: u64 = 32;
    /// @notice Invalid interest rate mode selected
    const EINVALID_INTEREST_RATE_MODE_SELECTED: u64 = 33;
    /// @notice The collateral balance is 0
    const ECOLLATERAL_BALANCE_IS_ZERO: u64 = 34;
    /// @notice Health factor is lesser than the liquidation threshold
    const EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD: u64 = 35;
    /// @notice There is not enough collateral to cover a new borrow
    const ECOLLATERAL_CANNOT_COVER_NEW_BORROW: u64 = 36;
    /// @notice Collateral is (mostly) the same currency that is being borrowed
    const ECOLLATERAL_SAME_AS_BORROWING_CURRENCY: u64 = 37;
    /// @notice For repayment of a specific type of debt, the user needs to have debt that type
    const ENO_DEBT_OF_SELECTED_TYPE: u64 = 39;
    /// @notice To repay on behalf of a user an explicit amount to repay is needed
    const ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF: u64 = 40;
    /// @notice User does not have outstanding variable rate debt on this reserve
    const ENO_OUTSTANDING_VARIABLE_DEBT: u64 = 42;
    /// @notice The underlying balance needs to be greater than 0
    const EUNDERLYING_BALANCE_ZERO: u64 = 43;
    /// @notice Health factor is not below the threshold
    const EHEALTH_FACTOR_NOT_BELOW_THRESHOLD: u64 = 45;
    /// @notice The collateral chosen cannot be liquidated
    const ECOLLATERAL_CANNOT_BE_LIQUIDATED: u64 = 46;
    /// @notice User did not borrow the specified currency
    const ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER: u64 = 47;
    /// @notice Inconsistent flashloan parameters
    const EINCONSISTENT_FLASHLOAN_PARAMS: u64 = 49;
    /// @notice Borrow cap is exceeded
    const EBORROW_CAP_EXCEEDED: u64 = 50;
    /// @notice Supply cap is exceeded
    const ESUPPLY_CAP_EXCEEDED: u64 = 51;
    /// @notice Debt ceiling is exceeded
    const EDEBT_CEILING_EXCEEDED: u64 = 53;
    /// @notice Claimable rights over underlying not zero (aToken supply or accruedToTreasury)
    const EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO: u64 = 54;
    /// @notice Variable debt supply is not zero
    const EVARIABLE_DEBT_SUPPLY_NOT_ZERO: u64 = 56;
    /// @notice Ltv validation failed
    const ELTV_VALIDATION_FAILED: u64 = 57;
    /// @notice Inconsistent eMode category
    const EINCONSISTENT_EMODE_CATEGORY: u64 = 58;
    /// @notice Asset is not borrowable in isolation mode
    const EASSET_NOT_BORROWABLE_IN_ISOLATION: u64 = 60;
    /// @notice Reserve has already been initialized
    const ERESERVE_ALREADY_INITIALIZED: u64 = 61;
    /// @notice User is in isolation mode or ltv is zero
    const EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO: u64 = 62;
    /// @notice Invalid ltv parameter for the reserve
    const EINVALID_LTV: u64 = 63;
    /// @notice Invalid liquidity threshold parameter for the reserve
    const EINVALID_LIQ_THRESHOLD: u64 = 64;
    /// @notice Invalid liquidity bonus parameter for the reserve
    const EINVALID_LIQ_BONUS: u64 = 65;
    /// @notice Invalid decimals parameter of the underlying asset of the reserve
    const EINVALID_DECIMALS: u64 = 66;
    /// @notice Invalid reserve factor parameter for the reserve
    const EINVALID_RESERVE_FACTOR: u64 = 67;
    /// @notice Invalid borrow cap for the reserve
    const EINVALID_BORROW_CAP: u64 = 68;
    /// @notice Invalid supply cap for the reserve
    const EINVALID_SUPPLY_CAP: u64 = 69;
    /// @notice Invalid liquidation protocol fee for the reserve
    const EINVALID_LIQUIDATION_PROTOCOL_FEE: u64 = 70;
    /// @notice Invalid eMode category for the reserve
    const EINVALID_EMODE_CATEGORY: u64 = 71;
    /// @notice Invalid unbacked mint cap for the reserve
    const EINVALID_UNBACKED_MINT_CAP: u64 = 72;
    /// @notice Invalid debt ceiling for the reserve
    const EINVALID_DEBT_CEILING: u64 = 73;
    /// @notice Invalid reserve index
    const EINVALID_RESERVE_INDEX: u64 = 74;
    /// @notice ACL admin cannot be set to the zero address
    const EACL_ADMIN_CANNOT_BE_ZERO: u64 = 75;
    /// @notice Array parameters that should be equal length are not
    const EINCONSISTENT_PARAMS_LENGTH: u64 = 76;
    /// @notice Zero address not valid
    const EZERO_ADDRESS_NOT_VALID: u64 = 77;
    /// @notice Invalid expiration
    const EINVALID_EXPIRATION: u64 = 78;
    /// @notice Invalid signature
    const EINVALID_SIGNATURE: u64 = 79;
    /// @notice Operation not supported
    const EOPERATION_NOT_SUPPORTED: u64 = 80;
    /// @notice Debt ceiling is not zero
    const EDEBT_CEILING_NOT_ZERO: u64 = 81;
    /// @notice Asset is not listed
    const EASSET_NOT_LISTED: u64 = 82;
    /// @notice Invalid optimal usage ratio
    const EINVALID_OPTIMAL_USAGE_RATIO: u64 = 83;
    /// @notice The underlying asset cannot be rescued
    const EUNDERLYING_CANNOT_BE_RESCUED: u64 = 85;
    /// @notice Reserve has already been added to reserve list
    const EADDRESSES_PROVIDER_ALREADY_ADDED: u64 = 86;
    /// @notice The token implementation pool address and the pool address provided by the initializing pool do not match
    const EPOOL_ADDRESSES_DO_NOT_MATCH: u64 = 87;
    /// @notice User is trying to borrow multiple assets including a siloed one
    const ESILOED_BORROWING_VIOLATION: u64 = 89;
    /// @notice the total debt of the reserve needs to be 0
    const ERESERVE_DEBT_NOT_ZERO: u64 = 90;
    /// @notice FlashLoaning for this asset is disabled
    const EFLASHLOAN_DISABLED: u64 = 91;
    /// @notice The expect maximum borrow rate is invalid
    const EINVALID_MAX_RATE: u64 = 92;
    /// @notice Withdrawing to the aToken is not allowed
    const EWITHDRAW_TO_ATOKEN: u64 = 93;
    /// @notice Supplying to the aToken is not allowed
    const ESUPPLY_TO_ATOKEN: u64 = 94;
    /// @notice Variable interest rate slope 2 can not be lower than slope 1
    const ESLOPE_2_MUST_BE_GTE_SLOPE_1: u64 = 95;
    /// @notice The caller of the function is neither a risk nor pool admin nor emergency admin
    const ECALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN: u64 = 96;
    /// @notice Liquidation grace sentinel validation failed
    const ELIQUIDATION_GRACE_SENTINEL_CHECK_FAILED: u64 = 97;
    /// @notice Grace period above a valid range
    const EINVALID_GRACE_PERIOD: u64 = 98;
    /// @notice Freeze flag is invalid
    const EINVALID_FREEZE_FLAG: u64 = 99;
    /// @notice Below a certain threshold liquidators need to take the full position
    const EMUST_NOT_LEAVE_DUST: u64 = 103;

    // Aptos has introduced a new business logic error code range from 1001 to 2000.

    // aave_acl module error code range from 1001 to 1100.
    /// @notice Account is not the acl's owner
    const ENOT_ACL_OWNER: u64 = 1001;
    /// @notice Account is missing role
    const EROLE_MISMATCH: u64 = 1002;
    /// @notice Can only renounce roles for self
    const EROLE_CAN_ONLY_RENOUNCE_SELF: u64 = 1003;
    /// @notice Roles not initialized
    const EROLES_NOT_INITIALIZED: u64 = 1004;

    // aave_math module error code range from 1101 to 1200.
    /// @notice Calculation results in overflow
    const EOVERFLOW: u64 = 1101;
    /// @notice Cannot divide by zero
    const EDIVISION_BY_ZERO: u64 = 1102;

    // aave_oracle module error code range from 1201 to 1300.
    /// @notice Caller must be only oracle admin
    const EORACLE_NOT_ADMIN: u64 = 1201;
    /// @notice Asset is already registered with feed
    const EASSET_ALREADY_EXISTS: u64 = 1202;
    /// @notice No asset feed for the given asset
    const ENO_ASSET_FEED: u64 = 1203;
    /// @notice Returned batch of prices equals the requested assets
    const EORACLE_BENCHMARK_LENGTH_MISMATCH: u64 = 1204;
    /// @notice Returned oracle price is negative
    const ENEGATIVE_ORACLE_PRICE: u64 = 1205;
    /// @notice Returned oracle price is zero
    const EZERO_ORACLE_PRICE: u64 = 1206;
    /// @notice The caller of the function is not a pool or asset listing admin
    const ECALLER_NOT_POOL_OR_ASSET_LISTING_ADMIN: u64 = 1207;
    /// @notice Requested assets and feed ids do not match
    const EREQUESTED_FEED_IDS_ASSETS_MISMATCH: u64 = 1208;
    /// @notice On behalf of and caller are different for minting
    const EDIFFERENT_CALLER_ON_BEHALF_OF: u64 = 1209;
    /// @notice Empty oracle feed_id
    const EEMPTY_FEED_ID: u64 = 1210;
    /// @notice No custom price for the given asset
    const ENO_CUSTOM_PRICE: u64 = 1211;
    /// @notice Zero custom price for the given asset
    const EZERO_CUSTOM_PRICE: u64 = 1212;
    /// @notice Requested assets and custom prices do not match
    const EREQUESTED_CUSTOM_PRICES_ASSETS_MISMATCH: u64 = 1213;
    /// @notice The asset is not registered with the oracle
    const EASSET_NOT_REGISTERED_WITH_ORACLE: u64 = 1214;
    /// @notice The asset cap is lower than the actual price of the asset
    const ECAP_LOWER_THAN_ACTUAL_PRICE: u64 = 1215;
    /// @notice The asset does not have a price cap
    const EASSET_NO_PRICE_CAP: u64 = 1216;
    /// @notice The oracle price is stale
    const ESTALE_ORACLE_PRICE: u64 = 1217;
    /// @notice The oracle price timestamp is in the future
    const EORACLE_PRICE_TIMESTAMP_IN_FUTURE: u64 = 1218;
    /// @notice The max asset price age of the asset is zero
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
    /// @notice Account is not the rate's owner
    const ENOT_RATE_OWNER: u64 = 1301;
    /// @notice Default interest rate strategy not initialized
    const EDEFAULT_INTEREST_RATE_STRATEGY_NOT_INITIALIZED: u64 = 1302;
    /// @notice GHO interest rate strategy not initialized
    const EGHO_INTEREST_RATE_STRATEGY_NOT_INITIALIZED: u64 = 1303;

    // aave_pool module error code range from 1401 to 1500.
    /// @notice Account is not the pool's owner
    const ENOT_POOL_OWNER: u64 = 1401;
    /// @notice User is not listed
    const EUSER_NOT_LISTED: u64 = 1402;
    /// @notice Mismatch of reserves count in storage
    const ERESERVES_STORAGE_COUNT_MISMATCH: u64 = 1403;
    /// @notice The person who signed must be consistent with on_behalf_of
    const ESIGNER_AND_ON_BEHALF_OF_NOT_SAME: u64 = 1404;
    /// @notice Account does not exist
    const EACCOUNT_DOES_NOT_EXIST: u64 = 1405;
    /// @notice Flashloan payer is different from the flashloan receiver
    const EFLASHLOAN_PAYER_NOT_RECEIVER: u64 = 1406;
    /// @notice Price oracle validation failed
    const EPRICE_ORACLE_CHECK_FAILED: u64 = 1407;
    /// @notice Reserve list not initialized
    const ERESERVE_LIST_NOT_INITIALIZED: u64 = 1408;
    /// @notice Reserve addresses list not initialized
    const ERESERVE_ADDRESSES_LIST_NOT_INITIALIZED: u64 = 1409;
    /// @notice The expect maximum apt fee is invalid
    const EINVALID_MAX_APT_FEE: u64 = 1410;

    /// Coin migrations
    /// @notice User has insufficient coins to wrap
    const EINSUFFICIENT_COINS_TO_WRAP: u64 = 1415;
    /// @notice User has insufficient fungible assets to unwrap
    const EINSUFFICIENT_FAS_TO_UNWRAP: u64 = 1416;
    /// @notice The coin has not been mapped to a fungible asset by Aptos
    const EUNMAPPED_COIN_TO_FA: u64 = 1417;

    // aave_tokens module error code range from 1501 to 1600.
    /// @notice Token already exists
    const ETOKEN_ALREADY_EXISTS: u64 = 1501;
    /// @notice Token not exist
    const ETOKEN_NOT_EXIST: u64 = 1502;
    /// @notice Resource not exist
    const ERESOURCE_NOT_EXIST: u64 = 1503;
    /// @notice Token name already exist
    const ETOKEN_NAME_ALREADY_EXIST: u64 = 1504;
    /// @notice Token symbol already exist
    const ETOKEN_SYMBOL_ALREADY_EXIST: u64 = 1505;
    /// @notice Asset minimum decimal places requirement is violated
    const EMIN_ASSET_DECIMAL_PLACES: u64 = 1506;

    // Periphery error codes should be above 3000
    /// @notice Caller is not rewards admin
    const ENOT_REWARDS_ADMIN: u64 = 3001;
    /// @notice Incentives controller mismatch
    const EINCENTIVES_CONTROLLER_MISMATCH: u64 = 3002;
    /// @notice Claimer is not authorized to make the reward claim
    const EUNAUTHORIZED_CLAIMER: u64 = 3003;
    /// @notice Reward index overflow
    const EREWARD_INDEX_OVERFLOW: u64 = 3004;
    /// @notice Invalid config data used in rewards controller / distributor
    const EINVALID_REWARD_CONFIG: u64 = 3005;
    /// @notice Distribution does not exist
    const EDISTRIBUTION_DOES_NOT_EXIST: u64 = 3006;
    /// @notice Rewards transfer failed
    const EREWARD_TRANSFER_FAILED: u64 = 3007;
    /// @notice Caller is not emission admin
    const ENOT_EMISSION_ADMIN: u64 = 3008;
    /// @notice Rewards controller is not defined
    const EREWARDS_CONTROLLER_NOT_DEFINED: u64 = 3009;
    /// @notice Caller does not have the ecosystem reserve funds admin role
    const ENOT_ECOSYSTEM_RESERVE_FUNDS_ADMIN: u64 = 3010;
    /// @notice Caller does not have the ecosystem admin or recipient role
    const ENOT_ECOSYSTEM_ADMIN_OR_RECIPIENT: u64 = 3011;
    /// @notice Stream does not exist
    const ESTREAM_NOT_EXIST: u64 = 3012;
    /// @notice Creating a stream to the contract itself
    const ESTREAM_TO_THE_CONTRACT_ITSELF: u64 = 3013;
    /// @notice Creating a stream to the caller
    const ESTREAM_TO_THE_CALLER: u64 = 3014;
    /// @notice Stream deposit is zero
    const ESTREAM_DEPOSIT_IS_ZERO: u64 = 3015;
    /// @notice Stream start time is before block timestamp
    const ESTART_TIME_BEFORE_BLOCK_TIMESTAMP: u64 = 3016;
    /// @notice Stream stop time is before start time
    const ESTOP_TIME_BEFORE_THE_START_TIME: u64 = 3017;
    /// @notice Stream deposit is smaller than time delta
    const EDEPOSIT_SMALLER_THAN_TIME_DELTA: u64 = 3018;
    /// @notice Stream deposit is not a multiple of time delta
    const EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA: u64 = 3019;
    /// @notice Stream withdraw amount is zero
    const ESTREAM_WITHDRAW_IS_ZERO: u64 = 3020;
    /// @notice Stream withdraw amount exceeds available balance
    const EWITHDRAW_EXCEEDS_THE_AVAILABLE_BALANCE: u64 = 3021;
    /// @notice Rewards controller address is not valid
    const EINVALID_REWARDS_CONTROLLER_ADDRESS: u64 = 3022;
    /// @notice Reward does not exist
    const EREWARD_NOT_EXIST: u64 = 3023;
    /// @notice Secondrary fungible store does not exist for the asset
    const ESTORE_FOR_ASSET_NOT_EXIST: u64 = 3024;
    /// @notice The expect maximum emission rate is invalid
    const EINVALID_EMISSION_RATE: u64 = 3025;

    // Public functions
    /// @notice Returns the error code for caller not being a pool admin
    /// @return Error code as u64
    public fun get_ecaller_not_pool_admin(): u64 {
        ECALLER_NOT_POOL_ADMIN
    }

    /// @notice Returns the error code for caller not being an emergency admin
    /// @return Error code as u64
    public fun get_ecaller_not_emergency_admin(): u64 {
        ECALLER_NOT_EMERGENCY_ADMIN
    }

    /// @notice Returns the error code for caller not being a pool or emergency admin
    /// @return Error code as u64
    public fun get_ecaller_not_pool_or_emergency_admin(): u64 {
        ECALLER_NOT_POOL_OR_EMERGENCY_ADMIN
    }

    /// @notice Returns the error code for caller not being a risk or pool admin
    /// @return Error code as u64
    public fun get_ecaller_not_risk_or_pool_admin(): u64 {
        ECALLER_NOT_RISK_OR_POOL_ADMIN
    }

    /// @notice Returns the error code for caller not being a risk, pool, or emergency admin
    /// @return Error code as u64
    public fun get_ecaller_not_risk_or_pool_or_emergency_admin(): u64 {
        ECALLER_NOT_RISK_OR_POOL_OR_EMERGENCY_ADMIN
    }

    /// @notice Returns the error code for caller not being an asset listing or pool admin
    /// @return Error code as u64
    public fun get_ecaller_not_asset_listing_or_pool_admin(): u64 {
        ECALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    }

    /// @notice Returns the error code for addresses provider not being registered
    /// @return Error code as u64
    public fun get_eaddresses_provider_not_registered(): u64 {
        EADDRESSES_PROVIDER_NOT_REGISTERED
    }

    /// @notice Returns the error code for invalid addresses provider ID
    /// @return Error code as u64
    public fun get_einvalid_addresses_provider_id(): u64 {
        EINVALID_ADDRESSES_PROVIDER_ID
    }

    /// @notice Returns the error code for address not being a contract
    /// @return Error code as u64
    public fun get_enot_contract(): u64 {
        ENOT_CONTRACT
    }

    /// @notice Returns the error code for caller not being a pool configurator
    /// @return Error code as u64
    public fun get_ecaller_not_pool_configurator(): u64 {
        ECALLER_NOT_POOL_CONFIGURATOR
    }

    /// @notice Returns the error code for caller not being an AToken
    /// @return Error code as u64
    public fun get_ecaller_not_atoken(): u64 {
        ECALLER_NOT_ATOKEN
    }

    /// @notice Returns the error code for invalid addresses provider
    /// @return Error code as u64
    public fun get_einvalid_addresses_provider(): u64 {
        EINVALID_ADDRESSES_PROVIDER
    }

    /// @notice Returns the error code for invalid flashloan executor return
    /// @return Error code as u64
    public fun get_einvalid_flashloan_executor_return(): u64 {
        EINVALID_FLASHLOAN_EXECUTOR_RETURN
    }

    /// @notice Returns the error code for reserve already added
    /// @return Error code as u64
    public fun get_ereserve_already_added(): u64 {
        ERESERVE_ALREADY_ADDED
    }

    /// @notice Returns the error code for reserves storage count mismatch
    /// @return Error code as u64
    public fun get_ereserves_storage_count_mismatch(): u64 {
        ERESERVES_STORAGE_COUNT_MISMATCH
    }

    /// @notice Returns the error code for no more reserves allowed
    /// @return Error code as u64
    public fun get_eno_more_reserves_allowed(): u64 {
        ENO_MORE_RESERVES_ALLOWED
    }

    /// @notice Returns the error code for eMode category reserved
    /// @return Error code as u64
    public fun get_eemode_category_reserved(): u64 {
        EEMODE_CATEGORY_RESERVED
    }

    /// @notice Returns the error code for invalid eMode category assignment
    /// @return Error code as u64
    public fun get_einvalid_emode_category_assignment(): u64 {
        EINVALID_EMODE_CATEGORY_ASSIGNMENT
    }

    /// @notice Returns the error code for reserve liquidity not zero
    /// @return Error code as u64
    public fun get_ereserve_liquidity_not_zero(): u64 {
        ERESERVE_LIQUIDITY_NOT_ZERO
    }

    /// @notice Returns the error code for flashloan premium invalid
    /// @return Error code as u64
    public fun get_eflashloan_premium_invalid(): u64 {
        EFLASHLOAN_PREMIUM_INVALID
    }

    /// @notice Returns the error code for invalid reserve parameters
    /// @return Error code as u64
    public fun get_einvalid_reserve_params(): u64 {
        EINVALID_RESERVE_PARAMS
    }

    /// @notice Returns the error code for invalid eMode category parameters
    /// @return Error code as u64
    public fun get_einvalid_emode_category_params(): u64 {
        EINVALID_EMODE_CATEGORY_PARAMS
    }

    /// @notice Returns the error code for caller must be pool
    /// @return Error code as u64
    public fun get_ecaller_must_be_pool(): u64 {
        ECALLER_MUST_BE_POOL
    }

    /// @notice Returns the error code for invalid mint amount
    /// @return Error code as u64
    public fun get_einvalid_mint_amount(): u64 {
        EINVALID_MINT_AMOUNT
    }

    /// @notice Returns the error code for invalid burn amount
    /// @return Error code as u64
    public fun get_einvalid_burn_amount(): u64 {
        EINVALID_BURN_AMOUNT
    }

    /// @notice Returns the error code for invalid amount
    /// @return Error code as u64
    public fun get_einvalid_amount(): u64 {
        EINVALID_AMOUNT
    }

    /// @notice Returns the error code for reserve inactive
    /// @return Error code as u64
    public fun get_ereserve_inactive(): u64 {
        ERESERVE_INACTIVE
    }

    /// @notice Returns the error code for reserve frozen
    /// @return Error code as u64
    public fun get_ereserve_frozen(): u64 {
        ERESERVE_FROZEN
    }

    /// @notice Returns the error code for reserve paused
    /// @return Error code as u64
    public fun get_ereserve_paused(): u64 {
        ERESERVE_PAUSED
    }

    /// @notice Returns the error code for borrowing not enabled
    /// @return Error code as u64
    public fun get_eborrowing_not_enabled(): u64 {
        EBORROWING_NOT_ENABLED
    }

    /// @notice Returns the error code for not enough available user balance
    /// @return Error code as u64
    public fun get_enot_enough_available_user_balance(): u64 {
        ENOT_ENOUGH_AVAILABLE_USER_BALANCE
    }

    /// @notice Returns the error code for invalid interest rate mode selected
    /// @return Error code as u64
    public fun get_einvalid_interest_rate_mode_selected(): u64 {
        EINVALID_INTEREST_RATE_MODE_SELECTED
    }

    /// @notice Returns the error code for collateral balance is zero
    /// @return Error code as u64
    public fun get_ecollateral_balance_is_zero(): u64 {
        ECOLLATERAL_BALANCE_IS_ZERO
    }

    /// @notice Returns the error code for health factor lower than liquidation threshold
    /// @return Error code as u64
    public fun get_ehealth_factor_lower_than_liquidation_threshold(): u64 {
        EHEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    }

    /// @notice Returns the error code for collateral cannot cover new borrow
    /// @return Error code as u64
    public fun get_ecollateral_cannot_cover_new_borrow(): u64 {
        ECOLLATERAL_CANNOT_COVER_NEW_BORROW
    }

    /// @notice Returns the error code for collateral same as borrowing currency
    /// @return Error code as u64
    public fun get_ecollateral_same_as_borrowing_currency(): u64 {
        ECOLLATERAL_SAME_AS_BORROWING_CURRENCY
    }

    /// @notice Returns the error code for no debt of selected type
    /// @return Error code as u64
    public fun get_eno_debt_of_selected_type(): u64 {
        ENO_DEBT_OF_SELECTED_TYPE
    }

    /// @notice Returns the error code for no explicit amount to repay on behalf
    /// @return Error code as u64
    public fun get_eno_explicit_amount_to_repay_on_behalf(): u64 {
        ENO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    }

    /// @notice Returns the error code for no outstanding variable debt
    /// @return Error code as u64
    public fun get_eno_outstanding_variable_debt(): u64 {
        ENO_OUTSTANDING_VARIABLE_DEBT
    }

    /// @notice Returns the error code for underlying balance zero
    /// @return Error code as u64
    public fun get_eunderlying_balance_zero(): u64 {
        EUNDERLYING_BALANCE_ZERO
    }

    /// @notice Returns the error code for health factor not below threshold
    /// @return Error code as u64
    public fun get_ehealth_factor_not_below_threshold(): u64 {
        EHEALTH_FACTOR_NOT_BELOW_THRESHOLD
    }

    /// @notice Returns the error code for collateral cannot be liquidated
    /// @return Error code as u64
    public fun get_ecollateral_cannot_be_liquidated(): u64 {
        ECOLLATERAL_CANNOT_BE_LIQUIDATED
    }

    /// @notice Returns the error code for specified currency not borrowed by user
    /// @return Error code as u64
    public fun get_especified_currency_not_borrowed_by_user(): u64 {
        ESPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
    }

    /// @notice Returns the error code for inconsistent flashloan parameters
    /// @return Error code as u64
    public fun get_einconsistent_flashloan_params(): u64 {
        EINCONSISTENT_FLASHLOAN_PARAMS
    }

    /// @notice Returns the error code for borrow cap exceeded
    /// @return Error code as u64
    public fun get_eborrow_cap_exceeded(): u64 {
        EBORROW_CAP_EXCEEDED
    }

    /// @notice Returns the error code for supply cap exceeded
    /// @return Error code as u64
    public fun get_esupply_cap_exceeded(): u64 {
        ESUPPLY_CAP_EXCEEDED
    }

    /// @notice Returns the error code for debt ceiling exceeded
    /// @return Error code as u64
    public fun get_edebt_ceiling_exceeded(): u64 {
        EDEBT_CEILING_EXCEEDED
    }

    /// @notice Returns the error code for underlying claimable rights not zero
    /// @return Error code as u64
    public fun get_eunderlying_claimable_rights_not_zero(): u64 {
        EUNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO
    }

    /// @notice Returns the error code for variable debt supply not zero
    /// @return Error code as u64
    public fun get_evariable_debt_supply_not_zero(): u64 {
        EVARIABLE_DEBT_SUPPLY_NOT_ZERO
    }

    /// @notice Returns the error code for LTV validation failed
    /// @return Error code as u64
    public fun get_eltv_validation_failed(): u64 {
        ELTV_VALIDATION_FAILED
    }

    /// @notice Returns the error code for inconsistent eMode category
    /// @return Error code as u64
    public fun get_einconsistent_emode_category(): u64 {
        EINCONSISTENT_EMODE_CATEGORY
    }

    /// @notice Returns the error code for asset not borrowable in isolation
    /// @return Error code as u64
    public fun get_easset_not_borrowable_in_isolation(): u64 {
        EASSET_NOT_BORROWABLE_IN_ISOLATION
    }

    /// @notice Returns the error code for reserve already initialized
    /// @return Error code as u64
    public fun get_ereserve_already_initialized(): u64 {
        ERESERVE_ALREADY_INITIALIZED
    }

    /// @notice Returns the error code for user in isolation mode or LTV zero
    /// @return Error code as u64
    public fun get_euser_in_isolation_mode_or_ltv_zero(): u64 {
        EUSER_IN_ISOLATION_MODE_OR_LTV_ZERO
    }

    /// @notice Returns the error code for invalid LTV
    /// @return Error code as u64
    public fun get_einvalid_ltv(): u64 {
        EINVALID_LTV
    }

    /// @notice Returns the error code for invalid liquidation threshold
    /// @return Error code as u64
    public fun get_einvalid_liq_threshold(): u64 {
        EINVALID_LIQ_THRESHOLD
    }

    /// @notice Returns the error code for invalid liquidation bonus
    /// @return Error code as u64
    public fun get_einvalid_liq_bonus(): u64 {
        EINVALID_LIQ_BONUS
    }

    /// @notice Returns the error code for invalid decimals
    /// @return Error code as u64
    public fun get_einvalid_decimals(): u64 {
        EINVALID_DECIMALS
    }

    /// @notice Returns the error code for invalid reserve factor
    /// @return Error code as u64
    public fun get_einvalid_reserve_factor(): u64 {
        EINVALID_RESERVE_FACTOR
    }

    /// @notice Returns the error code for invalid borrow cap
    /// @return Error code as u64
    public fun get_einvalid_borrow_cap(): u64 {
        EINVALID_BORROW_CAP
    }

    /// @notice Returns the error code for invalid supply cap
    /// @return Error code as u64
    public fun get_einvalid_supply_cap(): u64 {
        EINVALID_SUPPLY_CAP
    }

    /// @notice Returns the error code for invalid liquidation protocol fee
    /// @return Error code as u64
    public fun get_einvalid_liquidation_protocol_fee(): u64 {
        EINVALID_LIQUIDATION_PROTOCOL_FEE
    }

    /// @notice Returns the error code for invalid eMode category
    /// @return Error code as u64
    public fun get_einvalid_emode_category(): u64 {
        EINVALID_EMODE_CATEGORY
    }

    /// @notice Returns the error code for invalid unbacked mint cap
    /// @return Error code as u64
    public fun get_einvalid_unbacked_mint_cap(): u64 {
        EINVALID_UNBACKED_MINT_CAP
    }

    /// @notice Returns the error code for invalid debt ceiling
    /// @return Error code as u64
    public fun get_einvalid_debt_ceiling(): u64 {
        EINVALID_DEBT_CEILING
    }

    /// @notice Returns the error code for invalid reserve index
    /// @return Error code as u64
    public fun get_einvalid_reserve_index(): u64 {
        EINVALID_RESERVE_INDEX
    }

    /// @notice Returns the error code for ACL admin cannot be zero
    /// @return Error code as u64
    public fun get_eacl_admin_cannot_be_zero(): u64 {
        EACL_ADMIN_CANNOT_BE_ZERO
    }

    /// @notice Returns the error code for inconsistent params length
    /// @return Error code as u64
    public fun get_einconsistent_params_length(): u64 {
        EINCONSISTENT_PARAMS_LENGTH
    }

    /// @notice Returns the error code for zero address not valid
    /// @return Error code as u64
    public fun get_ezero_address_not_valid(): u64 {
        EZERO_ADDRESS_NOT_VALID
    }

    /// @notice Returns the error code for invalid expiration
    /// @return Error code as u64
    public fun get_einvalid_expiration(): u64 {
        EINVALID_EXPIRATION
    }

    /// @notice Returns the error code for invalid signature
    /// @return Error code as u64
    public fun get_einvalid_signature(): u64 {
        EINVALID_SIGNATURE
    }

    /// @notice Returns the error code for operation not supported
    /// @return Error code as u64
    public fun get_eoperation_not_supported(): u64 {
        EOPERATION_NOT_SUPPORTED
    }

    /// @notice Returns the error code for debt ceiling not zero
    /// @return Error code as u64
    public fun get_edebt_ceiling_not_zero(): u64 {
        EDEBT_CEILING_NOT_ZERO
    }

    /// @notice Returns the error code for asset not listed
    /// @return Error code as u64
    public fun get_easset_not_listed(): u64 {
        EASSET_NOT_LISTED
    }

    /// @notice Returns the error code for zero snapshot ratio
    /// @return Error code as u64
    public fun get_ezero_snapshot_ratio(): u64 {
        EZERO_SNAPSHOT_RATIO
    }

    /// @notice Returns the error code for invalid snapshot ratio
    /// @return Error code as u64
    public fun get_einvalid_ratio_timestamp(): u64 {
        EINVALID_RATIO_TIMESTAMP
    }

    /// @notice Returns the error code for snapshot overflow
    /// @return Error code as u64
    public fun get_esnapshot_overflow(): u64 {
        ESNAPSHOT_OVERFLOW
    }

    /// @notice Returns the error code for zero ration decimals
    /// @return Error code as u64
    public fun get_ezero_ratio_decimals(): u64 {
        EZERO_RATIO_DECIMALS
    }

    /// @notice Returns the error code for a mismatch on the adapter type
    /// @return Error code as u64
    public fun get_emismatch_adapter_type(): u64 {
        EMISMATCH_ADAPTER_TYPE
    }

    /// @notice Returns the error code for invalid growth rate
    /// @return Error code as u64
    public fun get_einvalid_growth_rate(): u64 {
        EINVALID_GROWTH_RATE
    }

    /// @notice Returns the error code for invalid snapshot delay
    /// @return Error code as u64
    public fun get_einvalid_snapshot_delay(): u64 {
        EINVALID_SNAPSHOT_DELAY
    }

    /// @notice Returns the error code for invalid snapshot ratio
    /// @return Error code as u64
    public fun get_einvalid_snapshot_ratio(): u64 {
        EINVALID_SNAPSHOT_RATIO
    }

    /// @notice Returns the error code for invalid snapshot timestamp
    /// @return Error code as u64
    public fun get_einvalid_snapshot_timestamp(): u64 {
        EINVALID_SNAPSHOT_TIMESTAMP
    }

    /// @notice Returns the error code for custom price above price cap
    /// @return Error code as u64
    public fun get_ecustom_price_above_price_cap(): u64 {
        ECUSTOM_PRICE_ABOVE_PRICE_CAP
    }

    /// @notice Returns the error code for invalid optimal usage ratio
    /// @return Error code as u64
    public fun get_einvalid_optimal_usage_ratio(): u64 {
        EINVALID_OPTIMAL_USAGE_RATIO
    }

    /// @notice Returns the error code for underlying cannot be rescued
    /// @return Error code as u64
    public fun get_eunderlying_cannot_be_rescued(): u64 {
        EUNDERLYING_CANNOT_BE_RESCUED
    }

    /// @notice Returns the error code for addresses provider already added
    /// @return Error code as u64
    public fun get_eaddresses_provider_already_added(): u64 {
        EADDRESSES_PROVIDER_ALREADY_ADDED
    }

    /// @notice Returns the error code for pool addresses do not match
    /// @return Error code as u64
    public fun get_epool_addresses_do_not_match(): u64 {
        EPOOL_ADDRESSES_DO_NOT_MATCH
    }

    /// @notice Returns the error code for siloed borrowing violation
    /// @return Error code as u64
    public fun get_esiloed_borrowing_violation(): u64 {
        ESILOED_BORROWING_VIOLATION
    }

    /// @notice Returns the error code for reserve debt not zero
    /// @return Error code as u64
    public fun get_ereserve_debt_not_zero(): u64 {
        ERESERVE_DEBT_NOT_ZERO
    }

    /// @notice Returns the error code for not ACL owner
    /// @return Error code as u64
    public fun get_enot_acl_owner(): u64 {
        ENOT_ACL_OWNER
    }

    /// @notice Returns the error code for role mismatch
    /// @return Error code as u64
    public fun get_erole_mismatch(): u64 {
        EROLE_MISMATCH
    }

    /// @notice Returns the error code for role can only renounce self
    /// @return Error code as u64
    public fun get_erole_can_only_renounce_self(): u64 {
        EROLE_CAN_ONLY_RENOUNCE_SELF
    }

    /// @notice Returns the error code for roles not initialized
    /// @return Error code as u64
    public fun get_eroles_not_initialized(): u64 {
        EROLES_NOT_INITIALIZED
    }

    /// @notice Returns the error code for overflow
    /// @return Error code as u64
    public fun get_eoverflow(): u64 {
        EOVERFLOW
    }

    /// @notice Returns the error code for division by zero
    /// @return Error code as u64
    public fun get_edivision_by_zero(): u64 {
        EDIVISION_BY_ZERO
    }

    /// @notice Returns the error code for not pool owner
    /// @return Error code as u64
    public fun get_enot_pool_owner(): u64 {
        ENOT_POOL_OWNER
    }

    /// @notice Returns the error code for flashloan disabled
    /// @return Error code as u64
    public fun get_eflashloan_disabled(): u64 {
        EFLASHLOAN_DISABLED
    }

    /// @notice Returns the error code for invalid max rate
    /// @return Error code as u64
    public fun get_einvalid_max_rate(): u64 {
        EINVALID_MAX_RATE
    }

    /// @notice Returns the error code for withdraw to aToken
    /// @return Error code as u64
    public fun get_ewithdraw_to_atoken(): u64 {
        EWITHDRAW_TO_ATOKEN
    }

    /// @notice Returns the error code for supply to aToken
    /// @return Error code as u64
    public fun get_esupply_to_atoken(): u64 {
        ESUPPLY_TO_ATOKEN
    }

    /// @notice Returns the error code for slope 2 must be greater than or equal to slope 1
    /// @return Error code as u64
    public fun get_eslope_2_must_be_gte_slope_1(): u64 {
        ESLOPE_2_MUST_BE_GTE_SLOPE_1
    }

    /// @notice Returns the error code for liquidation grace sentinel check failed
    /// @return Error code as u64
    public fun get_eliquidation_grace_sentinel_check_failed(): u64 {
        ELIQUIDATION_GRACE_SENTINEL_CHECK_FAILED
    }

    /// @notice Returns the error code for invalid grace period
    /// @return Error code as u64
    public fun get_einvalid_grace_period(): u64 {
        EINVALID_GRACE_PERIOD
    }

    /// @notice Returns the error code for invalid freeze flag
    /// @return Error code as u64
    public fun get_einvalid_freeze_flag(): u64 {
        EINVALID_FREEZE_FLAG
    }

    /// @notice Returns the error code for must not leave dust
    /// @return Error code as u64
    public fun get_emust_not_leave_dust(): u64 {
        EMUST_NOT_LEAVE_DUST
    }

    /// @notice Returns the error code for oracle not admin
    /// @return Error code as u64
    public fun get_eoracle_not_admin(): u64 {
        EORACLE_NOT_ADMIN
    }

    /// @notice Returns the error code for asset already exists
    /// @return Error code as u64
    public fun get_easset_already_exists(): u64 {
        EASSET_ALREADY_EXISTS
    }

    /// @notice Returns the error code for no asset feed
    /// @return Error code as u64
    public fun get_eno_asset_feed(): u64 {
        ENO_ASSET_FEED
    }

    /// @notice Returns the error code for no asset custom price
    /// @return Error code as u64
    public fun get_eno_asset_custom_price(): u64 {
        ENO_CUSTOM_PRICE
    }

    /// @notice Returns the error code for zero asset custom price
    /// @return Error code as u64
    public fun get_ezero_asset_custom_price(): u64 {
        EZERO_CUSTOM_PRICE
    }

    /// @notice Returns the error code for oracle benchmark length mismatch
    /// @return Error code as u64
    public fun get_eoralce_benchmark_length_mismatch(): u64 {
        EORACLE_BENCHMARK_LENGTH_MISMATCH
    }

    /// @notice Returns the error code for negative oracle price
    /// @return Error code as u64
    public fun get_enegative_oracle_price(): u64 {
        ENEGATIVE_ORACLE_PRICE
    }

    /// @notice Returns the error code for zero oracle price
    /// @return Error code as u64
    public fun get_ezero_oracle_price(): u64 {
        EZERO_ORACLE_PRICE
    }

    /// @notice Returns the error code for caller not pool or asset listing admin
    /// @return Error code as u64
    public fun get_ecaller_not_pool_or_asset_listing_admin(): u64 {
        ECALLER_NOT_POOL_OR_ASSET_LISTING_ADMIN
    }

    /// @notice Returns the error code for requested feed ids assets mismatch
    /// @return Error code as u64
    public fun get_erequested_feed_ids_assets_mismatch(): u64 {
        EREQUESTED_FEED_IDS_ASSETS_MISMATCH
    }

    /// @notice Returns the error code for requested custom prices assets mismatch
    /// @return Error code as u64
    public fun get_erequested_custom_prices_assets_mismatch(): u64 {
        EREQUESTED_CUSTOM_PRICES_ASSETS_MISMATCH
    }

    /// @notice Returns the error code for asset not registered with oracle
    /// @return Error code as u64
    public fun get_easset_not_registered_with_oracle(): u64 {
        EASSET_NOT_REGISTERED_WITH_ORACLE
    }

    /// @notice Returns the error code for cap lower than actual price
    /// @return Error code as u64
    public fun get_ecap_lower_than_actual_price(): u64 {
        ECAP_LOWER_THAN_ACTUAL_PRICE
    }

    /// @notice Returns the error code for asset no price cap
    /// @return Error code as u64
    public fun get_easset_no_price_cap(): u64 {
        EASSET_NO_PRICE_CAP
    }

    /// @notice Returns the error code for stale oracle price
    /// @return Error code as u64
    public fun get_estale_oracle_price(): u64 {
        ESTALE_ORACLE_PRICE
    }

    /// @notice Returns the error code for oracle price timestamp being in the future
    /// @return Error code as u64
    public fun get_eoracle_price_timestamp_in_future(): u64 {
        EORACLE_PRICE_TIMESTAMP_IN_FUTURE
    }

    /// @notice Returns the error code for oracle max asset price age being zero
    /// @return Error code as u64
    public fun get_ezero_oracle_max_asset_price_age(): u64 {
        EZERO_ORACLE_MAX_ASSET_PRICE_AGE
    }

    /// @notice Returns the error code for different caller on behalf of
    /// @return Error code as u64
    public fun get_edifferent_caller_on_behalf_of(): u64 {
        EDIFFERENT_CALLER_ON_BEHALF_OF
    }

    /// @notice Returns the error code for empty feed id
    /// @return Error code as u64
    public fun get_eempty_feed_id(): u64 {
        EEMPTY_FEED_ID
    }

    /// @notice Returns the error code for user not listed
    /// @return Error code as u64
    public fun get_euser_not_listed(): u64 {
        EUSER_NOT_LISTED
    }

    /// @notice Returns the error code for signer and on behalf of not same
    /// @return Error code as u64
    public fun get_esigner_and_on_behalf_of_not_same(): u64 {
        ESIGNER_AND_ON_BEHALF_OF_NOT_SAME
    }

    /// @notice Returns the error code for account does not exist
    /// @return Error code as u64
    public fun get_eaccount_does_not_exist(): u64 {
        EACCOUNT_DOES_NOT_EXIST
    }

    /// @notice Returns the error code for flashloan payer not receiver
    /// @return Error code as u64
    public fun get_eflashloan_payer_not_receiver(): u64 {
        EFLASHLOAN_PAYER_NOT_RECEIVER
    }

    /// @notice Returns the error code for price oracle check failed
    /// @return Error code as u64
    public fun get_eprice_oracle_check_failed(): u64 {
        EPRICE_ORACLE_CHECK_FAILED
    }

    /// @notice Returns the error code for not rate owner
    /// @return Error code as u64
    public fun get_enot_rate_owner(): u64 {
        ENOT_RATE_OWNER
    }

    /// @notice Returns the error code for default interest rate strategy not initialized
    /// @return Error code as u64
    public fun get_edefault_interest_rate_strategy_not_initialized(): u64 {
        EDEFAULT_INTEREST_RATE_STRATEGY_NOT_INITIALIZED
    }

    /// @notice Returns the error code for GHO interest rate strategy not initialized
    /// @return Error code as u64
    public fun get_egho_interest_rate_strategy_not_initialized(): u64 {
        EGHO_INTEREST_RATE_STRATEGY_NOT_INITIALIZED
    }

    /// @notice Returns the error code for reserve list not initialized
    /// @return Error code as u64
    public fun get_ereserve_list_not_initialized(): u64 {
        ERESERVE_LIST_NOT_INITIALIZED
    }

    /// @notice Returns the error code for token already exists
    /// @return Error code as u64
    public fun get_etoken_already_exists(): u64 {
        ETOKEN_ALREADY_EXISTS
    }

    /// @notice Returns the error code for token not exist
    /// @return Error code as u64
    public fun get_etoken_not_exist(): u64 {
        ETOKEN_NOT_EXIST
    }

    /// @notice Returns the error code for resource not exist
    /// @return Error code as u64
    public fun get_eresource_not_exist(): u64 {
        ERESOURCE_NOT_EXIST
    }

    /// @notice Returns the error code for token name already exist
    /// @return Error code as u64
    public fun get_etoken_name_already_exist(): u64 {
        ETOKEN_NAME_ALREADY_EXIST
    }

    /// @notice Returns the error code for token symbol already exist
    /// @return Error code as u64
    public fun get_etoken_symbol_already_exist(): u64 {
        ETOKEN_SYMBOL_ALREADY_EXIST
    }

    /// @notice Returns the error code for min asset decimal places
    /// @return Error code as u64
    public fun get_emin_asset_decimal_places(): u64 {
        EMIN_ASSET_DECIMAL_PLACES
    }

    /// @notice Returns the error code for reserve addresses list not initialized
    /// @return Error code as u64
    public fun get_ereserve_addresses_list_not_initialized(): u64 {
        ERESERVE_ADDRESSES_LIST_NOT_INITIALIZED
    }

    /// @notice Returns the error code for invalid max APT fee
    /// @return Error code as u64
    public fun get_einvalid_max_apt_fee(): u64 {
        EINVALID_MAX_APT_FEE
    }

    /// @notice Returns the error code for insufficient coins to wrap
    /// @return Error code as u64
    public fun get_einsufficient_coins_to_wrap(): u64 {
        EINSUFFICIENT_COINS_TO_WRAP
    }

    /// @notice Returns the error code for insufficient FAs to unwrap
    /// @return Error code as u64
    public fun get_einsufficient_fas_to_unwrap(): u64 {
        EINSUFFICIENT_FAS_TO_UNWRAP
    }

    /// @notice Returns the error code for unmapped coin to FA
    /// @return Error code as u64
    public fun get_eunmapped_coin_to_fa(): u64 {
        EUNMAPPED_COIN_TO_FA
    }

    /// @notice Returns the error code for not rewards admin
    /// @return Error code as u64
    public fun get_enot_rewards_admin(): u64 {
        ENOT_REWARDS_ADMIN
    }

    /// @notice Returns the error code for incentives controller mismatch
    /// @return Error code as u64
    public fun get_eincentives_controller_mismatch(): u64 {
        EINCENTIVES_CONTROLLER_MISMATCH
    }

    /// @notice Returns the error code for unauthorized claimer
    /// @return Error code as u64
    public fun get_eunauthorized_claimer(): u64 {
        EUNAUTHORIZED_CLAIMER
    }

    /// @notice Returns the error code for reward index overflow
    /// @return Error code as u64
    public fun get_ereward_index_overflow(): u64 {
        EREWARD_INDEX_OVERFLOW
    }

    /// @notice Returns the error code for invalid reward config
    /// @return Error code as u64
    public fun get_einvalid_reward_config(): u64 {
        EINVALID_REWARD_CONFIG
    }

    /// @notice Returns the error code for distribution does not exist
    /// @return Error code as u64
    public fun get_edistribution_does_not_exist(): u64 {
        EDISTRIBUTION_DOES_NOT_EXIST
    }

    /// @notice Returns the error code for reward transfer failed
    /// @return Error code as u64
    public fun get_ereward_transfer_failed(): u64 {
        EREWARD_TRANSFER_FAILED
    }

    /// @notice Returns the error code for not emission admin
    /// @return Error code as u64
    public fun get_enot_emission_admin(): u64 {
        ENOT_EMISSION_ADMIN
    }

    /// @notice Returns the error code for rewards controller not defined
    /// @return Error code as u64
    public fun get_erewards_controller_not_defined(): u64 {
        EREWARDS_CONTROLLER_NOT_DEFINED
    }

    /// @notice Returns the error code for not ecosystem reserve funds admin
    /// @return Error code as u64
    public fun get_enot_ecosystem_reserve_funds_admin(): u64 {
        ENOT_ECOSYSTEM_RESERVE_FUNDS_ADMIN
    }

    /// @notice Returns the error code for not ecosystem admin or recipient
    /// @return Error code as u64
    public fun get_enot_ecosystem_admin_or_recipient(): u64 {
        ENOT_ECOSYSTEM_ADMIN_OR_RECIPIENT
    }

    /// @notice Returns the error code for stream not exist
    /// @return Error code as u64
    public fun get_estream_not_exist(): u64 {
        ESTREAM_NOT_EXIST
    }

    /// @notice Returns the error code for stream to the contract itself
    /// @return Error code as u64
    public fun get_estream_to_the_contract_itself(): u64 {
        ESTREAM_TO_THE_CONTRACT_ITSELF
    }

    /// @notice Returns the error code for stream to the caller
    /// @return Error code as u64
    public fun get_estream_to_the_caller(): u64 {
        ESTREAM_TO_THE_CALLER
    }

    /// @notice Returns the error code for stream deposit is zero
    /// @return Error code as u64
    public fun get_estream_deposit_is_zero(): u64 {
        ESTREAM_DEPOSIT_IS_ZERO
    }

    /// @notice Returns the error code for start time before block timestamp
    /// @return Error code as u64
    public fun get_estart_time_before_block_timestamp(): u64 {
        ESTART_TIME_BEFORE_BLOCK_TIMESTAMP
    }

    /// @notice Returns the error code for stop time before the start time
    /// @return Error code as u64
    public fun get_estop_time_before_the_start_time(): u64 {
        ESTOP_TIME_BEFORE_THE_START_TIME
    }

    /// @notice Returns the error code for deposit smaller than time delta
    /// @return Error code as u64
    public fun get_edeposit_smaller_than_time_delta(): u64 {
        EDEPOSIT_SMALLER_THAN_TIME_DELTA
    }

    /// @notice Returns the error code for deposit not multiple of time delta
    /// @return Error code as u64
    public fun get_edeposit_not_multiple_of_time_delta(): u64 {
        EDEPOSIT_NOT_MULTIPLE_OF_TIME_DELTA
    }

    /// @notice Returns the error code for stream withdraw is zero
    /// @return Error code as u64
    public fun get_estream_withdraw_is_zero(): u64 {
        ESTREAM_WITHDRAW_IS_ZERO
    }

    /// @notice Returns the error code for withdraw exceeds the available balance
    /// @return Error code as u64
    public fun get_ewithdraw_exceeds_the_available_balance(): u64 {
        EWITHDRAW_EXCEEDS_THE_AVAILABLE_BALANCE
    }

    /// @notice Returns the error code for invalid rewards controller address
    /// @return Error code as u64
    public fun get_einvalid_rewards_controller_address(): u64 {
        EINVALID_REWARDS_CONTROLLER_ADDRESS
    }

    /// @notice Returns the error code for reward not exist
    /// @return Error code as u64
    public fun get_ereward_not_exist(): u64 {
        EREWARD_NOT_EXIST
    }

    /// @notice Returns the error code for store for asset not exist
    /// @return Error code as u64
    public fun get_estore_for_asset_not_exist(): u64 {
        ESTORE_FOR_ASSET_NOT_EXIST
    }

    /// @notice Returns the error code for invalid emission rate
    /// @return Error code as u64
    public fun get_einvalid_emission_rate(): u64 {
        EINVALID_EMISSION_RATE
    }
}
