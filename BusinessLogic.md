# AAVE Business Logic


## Pool
> source code: crest/blob/dev/aave-pool/sources/pool.move

### Add resources to the pool
- 1. Add Token (underlying token, a token, variable token)
- 2. Determine whether the underlying token is in the pool. If it already exists, it will not be added and an error will be returned directly.
- 3. Determine whether the total size of the pool exceeds the total size set by the system. If it has exceeded, no more additions can be made.
- 4. Create resource objects and resource configurations and join the pool
- 5. Update the added resource count = count + 1
- 6. Update the map of reserve_address_list (address=>count)
- 7. Release event ReserveInitialized
```bash=
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
    /// the current stable borrow rate. Expressed in ray
    current_stable_borrow_rate: u128,
    /// timestamp of last update (u40 -> u64)
    last_update_timestamp: u64,
    /// the id of the reserve. Represents the position in the list of the active reserves
    id: u16,
    /// aToken address
    a_token_address: address,
    /// stableDebtToken address
    stable_debt_token_address: address,
    /// variableDebtToken address
    variable_debt_token_address: address,
    /// address of the interest rate strategy
    interest_rate_strategy_address: address,
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
    count: u256,
}

// List of reserves as a map (reserveId => reserve).
struct ReserveAddressesList has key {
    value: SmartTable<u256, address>,
}

public fun add_reserve(
    account: &signer,
    a_token_tmpl: address,
    stable_debt_token_impl: address,
    variable_debt_token_impl: address,
    underlying_asset_decimals: u256,
    interest_rate_strategy_address: address,
    underlying_asset: address,
    // _treasury: address,
    // _incentives_controller: address,
    // _a_token_name: String,
    // _a_token_symbol: String,
    // _variable_debt_token_name: String,
    // _variable_debt_token_symbol: String,
    // _stable_debt_token_name: String,
    // _stable_debt_token_symbol: String,
    // _params: String
) acquires ReserveList, ReserveAddressesList {
    // Get the signers address
    let singer_address = signer::address_of(account);

    // Borrow the ReserveList resource
    let reserve_data_list = borrow_global_mut<ReserveList>(singer_address);

    // Assert that the asset is not already added
    assert!(
        !smart_table::contains(&reserve_data_list.value, underlying_asset),
        error_config::get_ereserve_already_added()
    );

    // Assert that the maximum number of reserves has not been reached
    assert!(
        reserve_data_list.count < (reserve_config::get_max_reserves_count()),
        error_config::get_eno_more_reserves_allowed()
    );

    // Increment the reserve count
    let count = reserve_data_list.count + 1;

    let reserve_configuration = reserve_config::init();
    reserve_config::set_decimals(&mut reserve_configuration, underlying_asset_decimals);
    reserve_config::set_active(&mut reserve_configuration, true);
    reserve_config::set_paused(&mut reserve_configuration, false);
    reserve_config::set_frozen(&mut reserve_configuration, false);

    // Create a new ReserveData entry
    let reserve_data = ReserveData {
        configuration: reserve_configuration,
        liquidity_index: (wad_ray_math::ray() as u128),
        current_liquidity_rate: 0,
        variable_borrow_index: (wad_ray_math::ray() as u128),
        current_variable_borrow_rate: 0,
        current_stable_borrow_rate: 0,
        last_update_timestamp: 0,
        id: (count as u16),
        a_token_address: a_token_tmpl,
        stable_debt_token_address: stable_debt_token_impl,
        variable_debt_token_address: variable_debt_token_impl,
        interest_rate_strategy_address,
        accrued_to_treasury: 0,
        unbacked: 0,
        isolation_mode_total_debt: 0,
    };

    // Add or update the ReserveData in the smart table
    smart_table::add(&mut reserve_data_list.value, underlying_asset, reserve_data);

    // Update the reserve count
    reserve_data_list.count = count;

    // update reserve address list
    add_reserve_address_list(count, underlying_asset);

    // emit the ReserveInitialized event
    event::emit(ReserveInitialized {
        asset: underlying_asset,
        a_token: a_token_tmpl,
        stable_debt_token: stable_debt_token_impl,
        variable_debt_token: variable_debt_token_impl,
        interest_rate_strategy_address,
    })
}
```

> Solidity Source Code(Line: 82)
> Link:  https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/pool/PoolConfigurator.sol
### Configuration of pool resources
```bash=
struct ReserveConfigurationMap has key, store, copy, drop {
    /// bit 0-15: LTV
    /// bit 16-31: Liq. threshold
    /// bit 32-47: Liq. bonus
    /// bit 48-55: Decimals
    /// bit 56: reserve is active
    /// bit 57: reserve is frozen
    /// bit 58: borrowing is enabled
    /// bit 59: stable rate borrowing enabled
    /// bit 60: asset is paused
    /// bit 61: borrowing in isolation mode is enabled
    /// bit 62: siloed borrowing enabled
    /// bit 63: flashloaning enabled
    /// bit 64-79: reserve factor
    /// bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    /// bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    /// bit 152-167 liquidation protocol fee
    /// bit 168-175 eMode category
    /// bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    /// bit 212-251 debt ceiling for isolation mode with (ReserveConfigurationMap::DEBT_CEILING_DECIMALS) decimals
    /// bit 252-255 unused
    data: u256,
}

# Source Code: crest/blob/dev/aave-config/sources/reserve_config.move
    
```

### Delete pool resources
- 1. Determine whether the resource address to be deleted is the 0 address, and exit if it is the 0 address.
- 2. Determine whether the resource to be deleted exists. If it does not exist, exit with an error.
- 3. Get variable_debt_token total_supply and determine whether total_supply is 0. If it is not 0, exit
- 4. Get the total_supply of a_token, and check a_debt_token_total_supply == 0 && reserve_data.accrued_to_treasury == 0, if the check fails, exit
- 5. Remove resources and the relationship between resource id and address
- 6. Update resource count=count-1
```bash=
public fun drop_reserve(account: &signer, asset: address) acquires ReserveList, ReserveAddressesList {
    assert!(asset != @0x0, error_config::get_ezero_address_not_valid());

    // Get the signers address
    let singer_address = signer::address_of(account);
    // Borrow the ReserveList resource
    let reserve_data_list = borrow_global_mut<ReserveList>(singer_address);
    // Assert that the asset is listed
    assert!(smart_table::contains(&reserve_data_list.value, asset), error_config::get_easset_not_listed());

    // Get the ReserveData
    let reserve_data = smart_table::borrow(&reserve_data_list.value, asset);

    let variable_debt_token_total_supply = variable_token_factory::supply(reserve_data.variable_debt_token_address);
    assert!(variable_debt_token_total_supply == 0, error_config::get_evariable_debt_supply_not_zero());

    let a_debt_token_total_supply = a_token_factory::supply(reserve_data.a_token_address);
    assert!(
        a_debt_token_total_supply == 0 && reserve_data.accrued_to_treasury == 0,
        error_config::get_eunderlying_claimable_rights_not_zero()
    );

    // Remove the ReserveData entry from the smart_table
    smart_table::remove(&mut reserve_data_list.value, asset);

    // Remove ReserveAddressList
    let reserve_address_list = borrow_global_mut<ReserveAddressesList>(singer_address);
    if (smart_table::contains(&reserve_address_list.value, (reserve_data.id as u256))) {
        smart_table::remove(&mut reserve_address_list.value, (reserve_data.id as u256));
    };
    // Decrease the reserve count
    reserve_data_list.count = reserve_data_list.count - 1;
}
```
## User
> source code: crest/tree/dev/aave-supply-borrow/sources
### Supply
- 1. Update the status of the pool (update_state)
- 2. validate_supply
```bash=
// Supply Validate
public fun validate_supply(reserve_data: &ReserveData, amount: u256) {
    assert!(amount != 0, error_config::get_einvalid_amount());
    let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(reserve_data);
    let (is_active, is_frozen, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
    assert!(is_active, error_config::get_ereserve_inactive());
    assert!(!is_paused, error_config::get_ereserve_paused());
    assert!(!is_frozen, error_config::get_ereserve_frozen());

    let supply_cap = reserve_config::get_supply_cap(&reserve_configuration);
    let a_token_supply = a_token_factory::supply(pool::get_reserve_token_address(reserve_data));
    let accrued_to_treasury_liquidity = wad_ray_math::ray_mul(pool::get_reserve_accrued_to_treasury(reserve_data),
        (pool::get_reserve_liquidity_index(reserve_data) as u256)
    );
    let total_supply = a_token_supply + accrued_to_treasury_liquidity + amount;
    let max_supply = supply_cap * (10 ^ reserve_config::get_decimals(&reserve_configuration));

    assert!(supply_cap == 0 || total_supply <= max_supply, error_config::get_esupply_cap_exceeded());
}
```
- 3. Update interest rates update_interest_rates
- 4. Transfer standard assets to aToken
- 5. Mint atoken to on_behalf_of account
- 6. Determine whether on_behalf_of is the first deposit. If so, verify whether it can be automatically used as collateral.
- 7. Update the mortgage configuration and save it to the asset configuration
- 8. Event of deposit submission
```bash=
public entry fun supply(
    account: &signer,
    asset: address,
    amount: u256,
    on_behalf_of: address,
    referral_code: u16
) {
    let reserve_data = pool::get_reserve_data(asset);
    pool::update_state(asset, &mut reserve_data);
    validation_logic::validate_supply(&reserve_data, amount);
    pool::update_interest_rates(&mut reserve_data, asset, amount, 0);

    let account_address = signer::address_of(account);
    let token_a_address = pool::get_reserve_token_address(&reserve_data);
    let a_token_account = a_token_factory::get_token_account_address(token_a_address);
    // transfer the asset to the a_token address
    underlying_token_factory::transfer_from(
        account,
        account_address,
        a_token_account,
        (amount as u64),
        asset
    );
    let is_first_supply: bool = a_token_factory::balance_of(account_address, token_a_address) == 0;
    a_token_factory::mint(
        account_address,
        on_behalf_of,
        amount,
        (pool::get_reserve_liquidity_index(&reserve_data) as u256),
        token_a_address
    );
    if (is_first_supply) {
        if (pool_validation::validate_automatic_use_as_collateral(account_address, asset)) {
            let user_config_map = pool::get_user_configuration(on_behalf_of);
            user_config::set_using_as_collateral(&mut user_config_map,
                (pool::get_reserve_id(&reserve_data) as u256), true);
            pool::set_user_configuration(on_behalf_of, user_config_map);
            event::emit(ReserveUsedAsCollateralEnabled {
                reserve: asset,
                user: account_address
            });
        }
    };
    // Emit a supply event
    event::emit(Supply {
        reserve: asset,
        user: account_address,
        on_behalf_of,
        amount,
        referral_code,
    });
}
```
### Withdraw
- 1. Update the status of the pool (update_state)
- 2. Get the account balance of the current withdrawal
- 3. Verify withdrawal validate_withdraw
```bash=
public fun validate_withdraw(reserve_data: &ReserveData, amount: u256, user_balance: u256) {
    assert!(amount != 0, error_config::get_einvalid_amount());
    assert!(amount <= user_balance, error_config::get_enot_enough_available_user_balance());
    let reserve_configuration = pool::get_reserve_configuration_by_reserve_data(reserve_data);
    let (is_active, _, _, _, is_paused) = reserve_config::get_flags(&reserve_configuration);
    assert!(is_active, error_config::get_ereserve_inactive());
    assert!(!is_paused, error_config::get_ereserve_paused());
}
```
- 4. Update interest rates update_interest_rates
- 5. Determine whether it is collateral and whether the withdrawal amount is equal to the user's account balance. If so, update the status of the collateral to uncollateralized and publish an uncollateralized event.
- 5.burn atoken from on_behalf_of account
- 6. Determine whether it is collateral and whether it is borrowing money. If so, verify the health factor and loan ratio validateHFAndLtv
- 7. Submit the event of withdrawal
```bash=
public entry fun withdraw(
    account: &signer,
    asset: address,
    amount: u256,
    to: address,
    user_emode_category: u8,
) {
    let account_address = signer::address_of(account);
    let (reserve_data, reserves_count) = pool::get_reserve_data_and_reserves_count(asset);
    // update pool state
    pool::update_state(asset, &mut reserve_data);
    let user_balance = wad_ray_math::ray_mul(
        a_token_factory::balance_of(account_address, pool::get_reserve_token_address(&reserve_data)),
        (pool::get_reserve_liquidity_index(&reserve_data) as u256)
    );
    let amount_to_withdraw = amount;
    if (amount == math_utils::u256_max()) {
        amount_to_withdraw = user_balance;
    };

    // validate withdraw
    validation_logic::validate_withdraw(&reserve_data, amount_to_withdraw, user_balance);

    // update interest rates
    pool::update_interest_rates(&mut reserve_data, asset, 0, amount_to_withdraw);

    let user_config_map = pool::get_user_configuration(account_address);
    let reserve_id = pool::get_reserve_id(&reserve_data);
    let is_collateral = user_config::is_using_as_collateral(&user_config_map,
        (reserve_id as u256)
    );

    if (is_collateral && amount_to_withdraw == user_balance) {
        user_config::set_using_as_collateral(&mut user_config_map, (reserve_id as u256), false);
        pool::set_user_configuration(account_address, user_config_map);
        event::emit(ReserveUsedAsCollateralDisabled {
            reserve: asset,
            user: account_address
        });
    };

    // burn a token
    a_token_factory::burn(
        account_address,
        to,
        amount_to_withdraw,
        (pool::get_reserve_liquidity_index(&reserve_data) as u256),
        pool::get_reserve_token_address(&reserve_data)
    );

    if (is_collateral && user_config::is_borrowing_any(&user_config_map)) {
        let (emode_ltv, emode_liq_threshold, emode_asset_price) = emode_logic::get_emode_configuration(
            user_emode_category
        );
        pool_validation::validate_hf_and_ltv(
            &mut reserve_data,
            reserves_count,
            &user_config_map,
            account_address,
            user_emode_category,
            emode_ltv,
            emode_liq_threshold,
            emode_asset_price
        );
    };
    // Emit a withdraw event
    event::emit(Withdraw {
        reserve: asset,
        user: account_address,
        to,
        amount,
    });
}
```
### Borrow
- 1. Update the status of the resource, mainly updating two fields: variableBorrowIndex and accumulatedToTreasury
- 2. Get the resource isolationModeActive activation status and isolationModeDebtCeiling isolation mode debt ceiling and isolationModeCollateralAddress isolation mode with address
- 3. Verify Borrow, whether it meets the conditions for borrowing
    - 3.1 Verify that the amount of borrowed money cannot be 0
    ```bash=
    require(params.amount != 0, Errors.INVALID_AMOUNT);
    ```
    - 3.2 Get the resource configuration flags: active, frozen, borrowing is enabled, stable rate borrowing enabled, asset is paused and verify
    ```bash=
      struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
      }
      
    # Get the flag of the resource and verify it  
    (
      vars.isActive,
      vars.isFrozen,
      vars.borrowingEnabled,
      vars.stableRateBorrowingEnabled,
      vars.isPaused
    ) = params.reserveCache.reserveConfiguration.getFlags();

    require(vars.isActive, Errors.RESERVE_INACTIVE);
    require(!vars.isPaused, Errors.RESERVE_PAUSED);
    require(!vars.isFrozen, Errors.RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);
    ```
    
     - 3.3 Verify whether borrowing is allowed through oracle sentinel isBorrowAllowed
     - 3.4 Judgment interestRateMode must be one of two types of interest rates: variable and immutable.
     - 3.5 By obtaining the total debt, determine whether the maximum number of borrowable Tokens exceeds BORROW_CAP_EXCEEDED
     - 3.6 Check whether the borrowed assets can be borrowed in isolation mode and the total risk exposure is not greater than the mortgage debt limit
     - 3.7 Determine the resource EModeCategory must be equal to the user's userEModeCategory
     - 3.8 Calculate user account data (user collateral is base currency, user base currency debt, user's maximum loan value, health factor) and verify the data
    ```bash=
    require(vars.userCollateralInBaseCurrency != 0, Errors.COLLATERAL_BALANCE_IS_ZERO);
    require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

    require(
      vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );
    ```
    - 3.9 Determine whether the collateral can cover the new borrowing
    ```bash=
     vars.amountInBaseCurrency =
     IPriceOracleGetter(params.oracle).getAssetPrice(
        vars.eModePriceSource != address(0) ? vars.eModePriceSource : params.asset
     ) * params.amount;
    
    unchecked {
      vars.amountInBaseCurrency /= vars.assetUnit;
    }

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency)
      .percentDiv(vars.currentLtv); //LTV is calculated in percentage

    require(
      vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency,
      Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
    );
    ```
    - 4.0 Check if the user has borrowed from any reserves
    ```bash=
    if (params.userConfig.isBorrowingAny()) {
      (vars.siloedBorrowingEnabled, vars.siloedBorrowingAddress) = params
        .userConfig
        .getSiloedBorrowingState(reservesData, reservesList);

      if (vars.siloedBorrowingEnabled) {
        require(vars.siloedBorrowingAddress == params.asset, Errors.SILOED_BORROWING_VIOLATION);
      } else {
        require(
          !params.reserveCache.reserveConfiguration.getSiloedBorrowing(),
          Errors.SILOED_BORROWING_VIOLATION
        );
      }
    }
  }
    ```
- 4. According to the interest rate model, Mint specifies the number of Tokens corresponding to the interest rate and gives them to the borrower.
- 5. Determine whether it is the first time to borrow money. If it is the first time to borrow money, modify the user's status and call setBorrowing(reserve.id, true) to set the user's borrowing resources to true.
- 6. Determine whether it is isolationModeActive. If activated, obtain the total debt in the next isolation mode and submit the event to update the status of the isolation mode IsolationModeTotalDebtUpdated
- 7. Recalculate the interest rate updateInterestRates and update the currentLiquidityRate, currentStableBorrowRate, currentVariableBorrowRate of the resource and submit the event
```bash=
event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
);
```
- 8. Determine whether releaseUnderlying == true, if true, transfer the token amount of the loan to the current user
- 9. Submit loan event
```bash=
event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
);
```
### Repay
- 1. Update the status of repayment resources (mainly update two fields: variableBorrowIndex and accruedToTreasury)
```bash=
 function executeRepay(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteRepayParams memory params
) external returns (uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);
}
```
- 2. Obtain the current user's debt (including variable interest rate debt and non-variable interest rate debt)
```bash=
(uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(
            params.onBehalfOf,
            reserveCache
        );
```
- 3. validate Repay
```bash=
  ValidationLogic.validateRepay(
        reserveCache,
        params.amount,
        params.interestRateMode,
        params.onBehalfOf,
        stableDebt,
        variableDebt
    );
  /**
   * @notice Validates a repay action.
   * @param reserveCache The cached data of the reserve
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param interestRateMode The interest rate mode of the debt being repaid
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param stableDebt The borrow balance of the user
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amountSent,
    DataTypes.InterestRateMode interestRateMode,
    address onBehalfOf,
    uint256 stableDebt,
    uint256 variableDebt
  ) internal view {
    # step1. The repayment amount cannot be 0
    require(amountSent != 0, Errors.INVALID_AMOUNT);
    
    require(
      amountSent != type(uint256).max || msg.sender == onBehalfOf,
      Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );

    (bool isActive, , , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);

    require(
      (stableDebt != 0 && interestRateMode == DataTypes.InterestRateMode.STABLE) ||
        (variableDebt != 0 && interestRateMode == DataTypes.InterestRateMode.VARIABLE),
      Errors.NO_DEBT_OF_SELECTED_TYPE
    );
  } 
```
- 4. Get the payback amount
```bash=
 uint256 paybackAmount = params.interestRateMode == DataTypes.InterestRateMode.STABLE
            ? stableDebt
            : variableDebt;

// Allows a user to repay with aTokens without leaving dust from interest.
if (params.useATokens && params.amount == type(uint256).max) {
    params.amount = IAToken(reserveCache.aTokenAddress).balanceOf(msg.sender);
}

if (params.amount < paybackAmount) {
    paybackAmount = params.amount;
}
```

- 5.Burn the specified number of tokens according to the interest rate model
```bash=
if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
    (reserveCache.nextTotalStableDebt, reserveCache.nextAvgStableBorrowRate) = IStableDebtToken(
        reserveCache.stableDebtTokenAddress
    ).burn(params.onBehalfOf, paybackAmount);
} else {
    reserveCache.nextScaledVariableDebt = IVariableDebtToken(
        reserveCache.variableDebtTokenAddress
    ).burn(params.onBehalfOf, paybackAmount, reserveCache.nextVariableBorrowIndex);
}
```
- 6.Recalculate the interest rate updateInterestRates and update the currentLiquidityRate, currentStableBorrowRate, currentVariableBorrowRate of the resource and submit the event
```bash=
function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
    ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams({
        unbacked: reserve.unbacked,
        liquidityAdded: liquidityAdded,
        liquidityTaken: liquidityTaken,
        totalStableDebt: reserveCache.nextTotalStableDebt,
        totalVariableDebt: vars.totalVariableDebt,
        averageStableBorrowRate: reserveCache.nextAvgStableBorrowRate,
        reserveFactor: reserveCache.reserveFactor,
        reserve: reserveAddress,
        aToken: reserveCache.aTokenAddress
      })
    );

    reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
    reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
    reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
}
```
- 7. Calculate variable and immutable debt - whether the investment recovery amount is equal to 0, if equal to 0, update the status of the resource the user is borrowing to false
```bash=
if (stableDebt + variableDebt - paybackAmount == 0) {
    userConfig.setBorrowing(reserve.id, false);
}
```
- 8. updated the isolated debt whenever a position collateralized by an isolated asset is repaid or liquidated
```bash=
IsolationModeLogic.updateIsolatedDebtIfIsolated(
    reservesData,
    reservesList,
    userConfig,
    reserveCache,
    paybackAmount
);
```
- 9. Determine whether the user uses token to repay the loan
```bash=
if (params.useATokens) {
    IAToken(reserveCache.aTokenAddress).burn(
        msg.sender,
        reserveCache.aTokenAddress,
        paybackAmount,
        reserveCache.nextLiquidityIndex
    );
} else {
    IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, paybackAmount);
    IAToken(reserveCache.aTokenAddress).handleRepayment(
        msg.sender,
        params.onBehalfOf,
        paybackAmount
    );
}
```
- 10. Submit repayment event
```bash=
event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
);
emit Repay(params.asset, params.onBehalfOf, msg.sender, paybackAmount, params.useATokens);
```
### Liquidation
- 1. Obtain mortgage resources and debt assets and update debt assets (mainly update two fields: variableBorrowIndex and accruedToTreasury)
```bash=
function executeLiquidationCall(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ExecuteLiquidationCallParams memory params
) external {
    LiquidationCallLocalVars memory vars;

    DataTypes.ReserveData storage collateralReserve = reservesData[params.collateralAsset];
    DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
    DataTypes.UserConfigurationMap storage userConfig = usersConfig[params.user];
    vars.debtReserveCache = debtReserve.cache();
    debtReserve.updateState(vars.debtReserveCache);
```
- 2. Calculate user data and obtain health factor
```bash=
(,,,, vars.healthFactor,) = GenericLogic.calculateUserAccountData(
    reservesData,
    reservesList,
    eModeCategories,
    DataTypes.CalculateUserAccountDataParams({
        userConfig: userConfig,
        reservesCount: params.reservesCount,
        user: params.user,
        oracle: params.priceOracle,
        userEModeCategory: params.userEModeCategory
    })
);
```
- 3. Calculate Debt Gets the user's total debt with variable interest rates, the user's total debt and debts that need to be liquidated
```bash=
function _calculateDebt(
    DataTypes.ReserveCache memory debtReserveCache,
    DataTypes.ExecuteLiquidationCallParams memory params,
    uint256 healthFactor
) internal view returns (uint256, uint256, uint256) {
    (uint256 userStableDebt, uint256 userVariableDebt) = Helpers.getUserCurrentDebt(
        params.user,
        debtReserveCache
    );

    uint256 userTotalDebt = userStableDebt + userVariableDebt;

    uint256 closeFactor = healthFactor > CLOSE_FACTOR_HF_THRESHOLD
        ? DEFAULT_LIQUIDATION_CLOSE_FACTOR
        : MAX_LIQUIDATION_CLOSE_FACTOR;

    uint256 maxLiquidatableDebt = userTotalDebt.percentMul(closeFactor);

    uint256 actualDebtToLiquidate = params.debtToCover > maxLiquidatableDebt
        ? maxLiquidatableDebt
        : params.debtToCover;

    return (userVariableDebt, userTotalDebt, actualDebtToLiquidate);
}
```
- 4.validate liquidation
```bash=
ValidationLogic.validateLiquidationCall(
    userConfig,
    collateralReserve,
    DataTypes.ValidateLiquidationCallParams({
        debtReserveCache: vars.debtReserveCache,
        totalDebt: vars.userTotalDebt,
        healthFactor: vars.healthFactor,
        priceOracleSentinel: params.priceOracleSentinel
    })
);

function validateLiquidationCall(
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ValidateLiquidationCallParams memory params
) internal view {
    ValidateLiquidationCallLocalVars memory vars;

    (vars.collateralReserveActive, , , , vars.collateralReservePaused) = collateralReserve
      .configuration
      .getFlags();

    (vars.principalReserveActive, , , , vars.principalReservePaused) = params
      .debtReserveCache
      .reserveConfiguration
      .getFlags();

    # step1. Verify the active status of the collateral and primary debt, must be active
    require(vars.collateralReserveActive && vars.principalReserveActive, Errors.RESERVE_INACTIVE);
    # step2. Verify the moratorium status of the collateral and primary debt, which must be non-moratorium
    require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.RESERVE_PAUSED);

    # step3. Verify whether the conditions to allow forced liquidation are met
    require(
      params.priceOracleSentinel == address(0) ||
        params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
        IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
      Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
    );
    # step4. Verify that the health factor is not below the threshold
    require(
      params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
    );

    vars.isCollateralEnabled =
      collateralReserve.configuration.getLiquidationThreshold() != 0 &&
      userConfig.isUsingAsCollateral(collateralReserve.id);

    //if collateral is not enabled as collateral by user, it cannot be liquidated
    # step4. Verify whether the collateral has been enabled, if so, an error will be reported
    require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
    # step5. Verify that the total debt cannot be 0. If it is 0, an error will be reported.
    require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
}
```
- 5. Get configuration data
```bash=
(
    vars.collateralAToken,
    vars.collateralPriceSource,
    vars.debtPriceSource,
    vars.liquidationBonus
) = _getConfigurationData(eModeCategories, collateralReserve, params);

/**
* @notice Returns the configuration data for the debt and the collateral reserves.
* @param eModeCategories The configuration of all the efficiency mode categories
* @param collateralReserve The data of the collateral reserve
* @param params The additional parameters needed to execute the liquidation function
* @return The collateral aToken
* @return The address to use as price source for the collateral
* @return The address to use as price source for the debt
* @return The liquidation bonus to apply to the collateral
*/
function _getConfigurationData(
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params
) internal view returns (IAToken, address, address, uint256) {
    IAToken collateralAToken = IAToken(collateralReserve.aTokenAddress);
    uint256 liquidationBonus = collateralReserve.configuration.getLiquidationBonus();

    address collateralPriceSource = params.collateralAsset;
    address debtPriceSource = params.debtAsset;

    if (params.userEModeCategory != 0) {
        address eModePriceSource = eModeCategories[params.userEModeCategory].priceSource;

        if (
            EModeLogic.isInEModeCategory(
            params.userEModeCategory,
            collateralReserve.configuration.getEModeCategory()
        )
        ) {
            liquidationBonus = eModeCategories[params.userEModeCategory].liquidationBonus;

            if (eModePriceSource != address(0)) {
                collateralPriceSource = eModePriceSource;
            }
        }

        // when in eMode, debt will always be in the same eMode category, can skip matching category check
        if (eModePriceSource != address(0)) {
            debtPriceSource = eModePriceSource;
        }
    }

    return (collateralAToken, collateralPriceSource, debtPriceSource, liquidationBonus);
}
```
- 6.Get the user's collateral balance
```bash=
vars.userCollateralBalance = vars.collateralAToken.balanceOf(params.user);
```
- 7.Calculate available collateral for liquidation
```bash=
 (
    vars.actualCollateralToLiquidate,
    vars.actualDebtToLiquidate,
    vars.liquidationProtocolFeeAmount
) = _calculateAvailableCollateralToLiquidate(
    collateralReserve,
    vars.debtReserveCache,
    vars.collateralPriceSource,
    vars.debtPriceSource,
    vars.actualDebtToLiquidate,
    vars.userCollateralBalance,
    vars.liquidationBonus,
    IPriceOracleGetter(params.priceOracle)
);
```
- 8.It is judged that the user's total debt is equal to the actual debt to be liquidated. If the conditions are met, the borrowing resources will be updated to the unborrowable state.
```bash=
if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
    userConfig.setBorrowing(debtReserve.id, false);
}
```
- 9.If the liquidated collateral equals the user balance, we set the currency to no longer be used as collateral, and submit a collateral disable event
```bash=
if (
    vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount ==
    vars.userCollateralBalance
) {
    userConfig.setUsingAsCollateral(collateralReserve.id, false);
    emit ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);
}
```
- 10.Burn Debt Token
```bash=
function _burnDebtTokens(
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
) internal {
    if (vars.userVariableDebt >= vars.actualDebtToLiquidate) {
        vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
            vars.debtReserveCache.variableDebtTokenAddress
        ).burn(
            params.user,
            vars.actualDebtToLiquidate,
            vars.debtReserveCache.nextVariableBorrowIndex
        );
    } else {
        // If the user does not have variable debt, no need to try to burn variable debt tokens
        if (vars.userVariableDebt != 0) {
            vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
                vars.debtReserveCache.variableDebtTokenAddress
            ).burn(params.user, vars.userVariableDebt, vars.debtReserveCache.nextVariableBorrowIndex);
        }
        (
            vars.debtReserveCache.nextTotalStableDebt,
            vars.debtReserveCache.nextAvgStableBorrowRate
        ) = IStableDebtToken(vars.debtReserveCache.stableDebtTokenAddress).burn(
            params.user,
            vars.actualDebtToLiquidate - vars.userVariableDebt
        );
    }
}
```
- 11. Recalculate the interest rate of the debt resource updateInterestRates and update the currentLiquidityRate, currentStableBorrowRate, currentVariableBorrowRate of the resource and submit the event
```bash=
function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
    ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams({
        unbacked: reserve.unbacked,
        liquidityAdded: liquidityAdded,
        liquidityTaken: liquidityTaken,
        totalStableDebt: reserveCache.nextTotalStableDebt,
        totalVariableDebt: vars.totalVariableDebt,
        averageStableBorrowRate: reserveCache.nextAvgStableBorrowRate,
        reserveFactor: reserveCache.reserveFactor,
        reserve: reserveAddress,
        aToken: reserveCache.aTokenAddress
      })
    );

    reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
    reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
    reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
}
```
- 12.updated the isolated debt whenever a position collateralized by an isolated asset is repaid or liquidated
```bash=
IsolationModeLogic.updateIsolatedDebtIfIsolated(
    reservesData,
    reservesList,
    userConfig,
    reserveCache,
    paybackAmount
);
```
- 13. Determine whether to liquidate with atoken (1. If liquidating with atoken: liquidate the user aToken by transferring them to the liquidator 2. If liquidating without atoken: destroy the collateral aTokens and transfer the underlying standard debt Token to the liquidator)
```bash=
 if (params.receiveAToken) {
    _liquidateATokens(reservesData, reservesList, usersConfig, collateralReserve, params, vars);
} else {
    _burnCollateralATokens(collateralReserve, params, vars);
}
```

- 14.If it is judged that the amount of the liquidation agreement fee is not equal to 0, then the amount of the liquidation agreement fee will be transferred to the treasury of the collateral token.
```bash=
// Transfer fee to treasury if it is non-zero
if (vars.liquidationProtocolFeeAmount != 0) {
    uint256 liquidityIndex = collateralReserve.getNormalizedIncome();
    uint256 scaledDownLiquidationProtocolFee = vars.liquidationProtocolFeeAmount.rayDiv(
        liquidityIndex
    );
    uint256 scaledDownUserBalance = vars.collateralAToken.scaledBalanceOf(params.user);
    // To avoid trying to send more aTokens than available on balance, due to 1 wei imprecision
    if (scaledDownLiquidationProtocolFee > scaledDownUserBalance) {
        vars.liquidationProtocolFeeAmount = scaledDownUserBalance.rayMul(liquidityIndex);
    }
    vars.collateralAToken.transferOnLiquidation(
        params.user,
        vars.collateralAToken.RESERVE_TREASURY_ADDRESS(),
        vars.liquidationProtocolFeeAmount
    );
}
```
- 15.Transfer debt assets that are being repaid to aToken to maintain liquidity
```bash=
IERC20(params.debtAsset).safeTransferFrom(
    msg.sender,
    vars.debtReserveCache.aTokenAddress,
    vars.actualDebtToLiquidate
);

IAToken(vars.debtReserveCache.aTokenAddress).handleRepayment(
    msg.sender,
    params.user,
    vars.actualDebtToLiquidate
);
```
- 16.Submit liquidation event
```bash=
event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
);

emit LiquidationCall(
    params.collateralAsset,
    params.debtAsset,
    params.user,
    vars.actualDebtToLiquidate,
    vars.actualCollateralToLiquidate,
    msg.sender,
    params.receiveAToken
);
```
## Bridge
> source code: crest/blob/dev/aave-bridge/sources/bridge_logic.move
 
### MintUnbacked
- 1.Get resource data and update resource status
 
```bash=
function executeMintUnbacked(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);
```
- 2. validate supply
```bash=

ValidationLogic.validateSupply(reserveCache, reserve, amount);

function validateSupply(
    DataTypes.ReserveCache memory reserveCache,
    DataTypes.ReserveData storage reserve,
    uint256 amount
) internal view {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , , bool isPaused) = reserveCache
      .reserveConfiguration
      .getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();
    require(
      supplyCap == 0 ||
        ((IAToken(reserveCache.aTokenAddress).scaledTotalSupply() +
          uint256(reserve.accruedToTreasury)).rayMul(reserveCache.nextLiquidityIndex) + amount) <=
        supplyCap * (10 ** reserveCache.reserveConfiguration.getDecimals()),
      Errors.SUPPLY_CAP_EXCEEDED
    );
}
```
- 3. Get unbacked in the resource and determine whether unbacked exceeds the maximum value
```bash=
uint256 unbackedMintCap = reserveCache.reserveConfiguration.getUnbackedMintCap();
uint256 reserveDecimals = reserveCache.reserveConfiguration.getDecimals();

uint256 unbacked = reserve.unbacked += amount.toUint128();

require(
  unbacked <= unbackedMintCap * (10 ** reserveDecimals),
  Errors.UNBACKED_MINT_CAP_EXCEEDED
);
```

- 4.Recalculate the interest rate of the debt resource updateInterestRates and update the currentLiquidityRate, currentStableBorrowRate, currentVariableBorrowRate of the resource and submit the event 
```bash=
reserve.updateInterestRates(reserveCache, asset, 0, 0);

function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
    ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams({
        unbacked: reserve.unbacked,
        liquidityAdded: liquidityAdded,
        liquidityTaken: liquidityTaken,
        totalStableDebt: reserveCache.nextTotalStableDebt,
        totalVariableDebt: vars.totalVariableDebt,
        averageStableBorrowRate: reserveCache.nextAvgStableBorrowRate,
        reserveFactor: reserveCache.reserveFactor,
        reserve: reserveAddress,
        aToken: reserveCache.aTokenAddress
      })
    );

    reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
    reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
    reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
}
```
- 5. Mint atoken to on_behalf_of account
- 6. Determine whether on_behalf_of is the first deposit. If so, verify whether it can be automatically used as collateral.
```bash=
bool isFirstSupply = IAToken(reserveCache.aTokenAddress).mint(
  msg.sender,
  onBehalfOf,
  amount,
  reserveCache.nextLiquidityIndex
);

if (isFirstSupply) {
  if (
    ValidationLogic.validateAutomaticUseAsCollateral(
      reservesData,
      reservesList,
      userConfig,
      reserveCache.reserveConfiguration,
      reserveCache.aTokenAddress
    )
  ) {
    userConfig.setUsingAsCollateral(reserve.id, true);
    emit ReserveUsedAsCollateralEnabled(asset, onBehalfOf);
  }
}
```
- 7. Submit MintUnbacked event
```bash=
event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
);
emit MintUnbacked(asset, msg.sender, onBehalfOf, amount, referralCode);
```

### BackUnbacked
- 1.Get resource data and update resource status
```bash=
  function executeBackUnbacked(
    DataTypes.ReserveData storage reserve,
    address asset,
    uint256 amount,
    uint256 fee,
    uint256 protocolFeeBps
  ) external returns (uint256) {
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);
```
- 2.Update resourcesaccruedToTreasury and unbacked fields
```bash=
uint256 backingAmount = (amount < reserve.unbacked) ? amount : reserve.unbacked;

uint256 feeToProtocol = fee.percentMul(protocolFeeBps);
uint256 feeToLP = fee - feeToProtocol;
uint256 added = backingAmount + fee;

reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
  IERC20(reserveCache.aTokenAddress).totalSupply() +
    uint256(reserve.accruedToTreasury).rayMul(reserveCache.nextLiquidityIndex),
  feeToLP
);

reserve.accruedToTreasury += feeToProtocol.rayDiv(reserveCache.nextLiquidityIndex).toUint128();

reserve.unbacked -= backingAmount.toUint128();
```
- 3.Recalculate the interest rate of the debt resource updateInterestRates and update the currentLiquidityRate, currentStableBorrowRate, currentVariableBorrowRate of the resource and submit the event
```bash=
reserve.updateInterestRates(reserveCache, asset, added, 0);

function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
    ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams({
        unbacked: reserve.unbacked,
        liquidityAdded: liquidityAdded,
        liquidityTaken: liquidityTaken,
        totalStableDebt: reserveCache.nextTotalStableDebt,
        totalVariableDebt: vars.totalVariableDebt,
        averageStableBorrowRate: reserveCache.nextAvgStableBorrowRate,
        reserveFactor: reserveCache.reserveFactor,
        reserve: reserveAddress,
        aToken: reserveCache.aTokenAddress
      })
    );

    reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
    reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
    reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
}
```
- 4. Transfer standard assets to the corresponding token address
```bash=
IERC20(asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, added);
```

- 5. Submit BackUnbacked event
```bash=
emit BackUnbacked(asset, msg.sender, backingAmount, fee);
```