import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
// POOL
const aptosProvider = new AptosProvider();
export const PoolManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
});
export const PoolManagerAccountAddress = PoolManager.accountAddress.toString();

// Resource Func Addr
/**
 * -------------------------------------------------------------------------
 * Pool
 * -------------------------------------------------------------------------=
 */
// Entry
export const PoolMintToTreasuryFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::mint_to_treasury`;
export const PoolResetIsolationModeTotalDebtFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::reset_isolation_mode_total_debt`;
export const PoolRescueTokensFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::rescue_tokens`;
export const PoolSetBridgeProtocolFeeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::set_bridge_protocol_fee`;
export const PoolSetFlashloanPremiumsFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::set_flashloan_premiums`;

// Pool View
export const PoolGetRevisionFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_revision`;
export const PoolGetReserveConfigurationFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserve_configuration`;
export const PoolGetReserveDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserve_data`;
export const PoolGetReservesCountFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserves_count`;
export const PoolGetReservesListFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserves_list`;
export const PoolGetReserveAddressByIdFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserve_address_by_id`;
export const PoolGetReserveNormalizedVariableDebtFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserve_normalized_variable_debt`;
export const PoolGetReserveNormalizedIncomeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_reserve_normalized_income`;
export const PoolGetUserConfigurationFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_user_configuration`;
export const PoolGetBridgeProtocolFeeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_bridge_protocol_fee`;
export const PoolGetFlashloanPremiumTotalFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_flashloan_premium_total`;
export const PoolGetFlashloanPremiumToProtocolFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::get_flashloan_premium_to_protocol`;
export const PoolMaxNumberReservesFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::max_number_reserves`;
export const PoolScaledATokenTotalSupplyFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::scaled_a_token_total_supply`;
export const PoolScaledATokenBalanceOfFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::scaled_a_token_balance_of`;
export const PoolScaledVariableTokenTotalSupplyFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::scaled_variable_token_total_supply`;
export const PoolScaledVariableTokenBalanceOfFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool::scaled_variable_token_balance_of`;

/**
 * -------------------------------------------------------------------------
 * Pool Configurator
 * -------------------------------------------------------------------------=
 */
// Entry
export const PoolConfiguratorInitReservesFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::init_reserves`;
export const PoolConfiguratorDropReserveFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::drop_reserve`;
export const PoolConfiguratorSetAssetEmodeCategoryFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_asset_emode_category`;
export const PoolConfiguratorSetBorrowCapFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_borrow_cap`;
export const PoolConfiguratorSetBorrowableInIsolationFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_borrowable_in_isolation`;
export const PoolConfiguratorSetDebtCeilingFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_debt_ceiling`;
export const PoolConfiguratorSetEmodeCategoryFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_emode_category`;
export const PoolConfiguratorSetLiquidationProtocolFeeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_liquidation_protocol_fee`;
export const PoolConfiguratorSetPoolPauseFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_pool_pause`;
export const PoolConfiguratorSetReserveActiveFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_active`;
export const PoolConfiguratorSetReserveBorrowingFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_borrowing`;
export const PoolConfiguratorConfigureReserveAsCollateralFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::configure_reserve_as_collateral`;
export const PoolConfiguratorSetReserveFactorFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_factor`;
export const PoolConfiguratorSetReserveFlashLoaningFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_flash_loaning`;
export const PoolConfiguratorSetReserveFreezeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_freeze`;
export const PoolConfiguratorSetReservePauseFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_reserve_pause`;
export const PoolConfiguratorSetSiloedBorrowingFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_siloed_borrowing`;
export const PoolConfiguratorSetSupplyCapFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_supply_cap`;
export const PoolConfiguratorSetUnbackedMintCapFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::set_unbacked_mint_cap`;
export const PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::update_bridge_protocol_fee`;
export const PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::update_flashloan_premium_to_protocol`;
export const PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::update_flashloan_premium_total`;
export const PoolConfiguratorConfigureReservesFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::configure_reserves`;

// View
export const PoolConfiguratorGetRevisionFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_configurator::get_revision`;

/**
 * -------------------------------------------------------------------------
 * Isolation E Mode
 * @notice Internal methods are tested in other modules
 * -------------------------------------------------------------------------=
 */

/**
 * -------------------------------------------------------------------------
 * E Mode Logic
 * -------------------------------------------------------------------------=
 */
// Entry
export const PoolSetUserEmodeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::emode_logic::set_user_emode`;
export const PoolConfigureEmodeCategoryFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::emode_logic::configure_emode_category`;

// View
export const PoolGetEmodeCategoryDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::emode_logic::get_emode_category_data`;
export const PoolGetUserEmodeFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::emode_logic::get_user_emode`;

// Generic Logic
// Internal methods are tested in other modules

/**
 * -------------------------------------------------------------------------
 * default_reserve_interest_rate_strategy
 * -------------------------------------------------------------------------
 */
// Entry
export const SetReserveInterestRateStrategyFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::set_reserve_interest_rate_strategy`;

// View
export const GetGetOptimalUsageRatioFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_optimal_usage_ratio`;
export const GetGetMaxExcessUsageRatioFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_max_excess_usage_ratio`;
export const GetVariableRateSlope1FuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_variable_rate_slope1`;
export const GetVariableRateSlope2FuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_variable_rate_slope2`;
export const GetBaseVariableBorrowRateFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_base_variable_borrow_rate`;
export const GetMaxVariableBorrowRateFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::get_max_variable_borrow_rate`;
export const CalculateInterestRatesFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::default_reserve_interest_rate_strategy::calculate_interest_rates`;

/**
 * -------------------------------------------------------------------------
 * pool data provider
 * -------------------------------------------------------------------------=
 */
// View
export const GetAllReservesTokensFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_all_reserves_tokens`;
export const GetAllATokensFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_all_a_tokens`;
export const GetAllVariableTokensFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_all_var_tokens`;
export const GetReserveConfigurationDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_configuration_data`;
export const GetReserveEModeCategoryFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_emode_category`;
export const GetReserveCapsFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_caps`;
export const GetPausedFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_paused`;
export const GetSiloedBorrowingFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_siloed_borrowing`;
export const GetLiquidationProtocolFeeTokensFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_liquidation_protocol_fee`;
export const GetUnbackedMintCapFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_unbacked_mint_cap`;
export const GetDebtCeilingFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_debt_ceiling`;
export const GetDebtCeilingDecimalsFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_debt_ceiling_decimals`;
export const GetReserveDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_data`;
export const GetReserveDataAndReservesCountFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_data_and_reserves_count`;
export const GetATokenTotalSupplyFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_a_token_total_supply`;
export const GetTotalDebtFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_total_debt`;
export const GetUserReserveDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_user_reserve_data`;
export const GetReserveTokensAddressesFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_reserve_tokens_addresses`;
export const GetFlashLoanEnabledFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_data_provider::get_flash_loan_enabled`;

/**
 * -------------------------------------------------------------------------
 * pool addresses provider
 * -------------------------------------------------------------------------
 */
// View
export const HasIdMappedAccountFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::has_id_mapped_account`;
export const GetMarketIdFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_market_id`;
export const GetAddressFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_address`;
export const GetPoolFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_pool`;
export const GetPoolConfiguratorFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_pool_configurator`;
export const GetPriceOracleFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_price_oracle`;
export const GetAclManagerFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_acl_manager`;
export const GetAclAdminFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_acl_admin`;
export const GetPriceOracleSentinelFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_price_oracle_sentinel`;
export const GetPoolDataProviderFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::get_pool_data_provider`;

// Entry
export const SetMarketIdFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_market_id`;
export const SetAddressFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_address`;
export const SetPoolImplFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_pool_impl`;
export const SetPoolConfiguratorFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_pool_configurator`;
export const SetPriceOracleFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_price_oracle`;
export const SetAclManagerFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_acl_manager`;
export const SetAclAdminFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_acl_admin`;
export const SetPriceOracleSentinelFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_price_oracle_sentinel`;
export const SetPoolDataProviderFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::pool_addresses_provider::set_pool_data_provider`;

/**
 * -------------------------------------------------------------------------
 * ui pool data provider
 * -------------------------------------------------------------------------
 */
// View
export const UiPoolDataProviderGetReservesListFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::get_reserves_list`;
export const UiPoolDataProviderGetReservesDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::get_reserves_data`;
export const UiPoolDataProviderGetUserReservesDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::get_user_reserves_data`;
export const UiPoolDataProviderV3DataAddressFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::ui_pool_data_provider_v3_data_address`;
export const UiPoolDataProviderV3DataObjectFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::ui_pool_data_provider_v3_data_object`;

/**
 * -------------------------------------------------------------------------
 * ui incentives data provider
 * -------------------------------------------------------------------------
 */
// View
export const UiIncentivesDataProviderGetFullReservesIncentiveDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_incentive_data_provider_v3::get_full_reserves_incentive_data`;
export const UiIncentivesDataProviderGetReservesIncentivesDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_incentive_data_provider_v3::get_reserves_incentives_data`;
export const UiIncentivesDataProviderGetUserReservesIncentivesDataFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_incentive_data_provider_v3::get_user_reserves_incentives_data`;
export const UiIncentivesDataProviderV3DataAddressFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::ui_incentive_data_provider_v3_data_address`;
export const UiIncentivesDataProviderV3DataObjectFuncAddr: MoveFunctionId = `${PoolManagerAccountAddress}::ui_pool_data_provider_v3::ui_incentive_data_provider_v3_data_object`;

// Asset Strategy Configurator
export const strategyDAI = {
  // strategy: rateStrategies_1.rateStrategyStableTwo,
  baseLTVAsCollateral: "7500",
  liquidationThreshold: "8000",
  liquidationBonus: "10500",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "8",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "1000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: true,
};

export const strategyUSDC = {
  // strategy: rateStrategies_1.rateStrategyStableOne,
  baseLTVAsCollateral: "8000",
  liquidationThreshold: "8500",
  liquidationBonus: "10500",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "8",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "1000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: true,
};
export const strategyAAVE = {
  // strategy: rateStrategies_1.rateStrategyVolatileOne,
  baseLTVAsCollateral: "5000",
  liquidationThreshold: "6500",
  liquidationBonus: "11000",
  liquidationProtocolFee: "1000",
  borrowingEnabled: false,
  // stableBorrowRateEnabled: false,
  flashLoanEnabled: false,
  reserveDecimals: "8",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "0",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: false,
};

export const strategyWETH = {
  // strategy: rateStrategies_1.rateStrategyVolatileOne,
  baseLTVAsCollateral: "8000",
  liquidationThreshold: "8250",
  liquidationBonus: "10500",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "8",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "1000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: false,
};

export const strategyLINK = {
  // strategy: rateStrategies_1.rateStrategyVolatileOne,
  baseLTVAsCollateral: "7000",
  liquidationThreshold: "7500",
  liquidationBonus: "11000",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "18",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "2000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: false,
};

export const strategyWBTC = {
  // strategy: rateStrategies_1.rateStrategyVolatileOne,
  baseLTVAsCollateral: "7000",
  liquidationThreshold: "7500",
  liquidationBonus: "11000",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "8",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "2000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "0",
  borrowableIsolation: false,
};

export const strategyUSDT = {
  // strategy: rateStrategies_1.rateStrategyStableOne,
  baseLTVAsCollateral: "7500",
  liquidationThreshold: "8000",
  liquidationBonus: "10500",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "6",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "1000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "1000000",
  borrowableIsolation: true,
};

export const strategyEURS = {
  // strategy: rateStrategies_1.rateStrategyStableOne,
  baseLTVAsCollateral: "8000",
  liquidationThreshold: "8500",
  liquidationBonus: "10500",
  liquidationProtocolFee: "1000",
  borrowingEnabled: true,
  // stableBorrowRateEnabled: true,
  flashLoanEnabled: true,
  reserveDecimals: "2",
  // aTokenImpl: types_1.eContractid.AToken,
  reserveFactor: "1000",
  supplyCap: "0",
  borrowCap: "0",
  debtCeiling: "1000000",
  borrowableIsolation: false,
};

// rate Strategy
export const rateStrategyStableTwo = {
  name: "rateStrategyStableTwo",
  optimalUsageRatio: "800000000000000000000000000",
  baseVariableBorrowRate: "0",
  variableRateSlope1: "40000000000000000000000000",
  variableRateSlope2: "750000000000000000000000000",
  stableRateSlope1: "20000000000000000000000000",
  stableRateSlope2: "750000000000000000000000000",
  baseStableRateOffset: "20000000000000000000000000",
  stableRateExcessOffset: "50000000000000000000000000",
  optimalStableToTotalDebtRatio: "200000000000000000000000000",
};

export type ReserveData = {
  /// stores the reserve configuration
  configuration: { data: Number };
  /// the liquidity index. Expressed in ray
  liquidity_index: Number;
  /// the current supply rate. Expressed in ray
  current_liquidity_rate: Number;
  /// variable borrow index. Expressed in ray
  variable_borrow_index: Number;
  /// the current variable borrow rate. Expressed in ray
  current_variable_borrow_rate: Number;
  /// the current stable borrow rate. Expressed in ray
  current_stable_borrow_rate: Number;
  /// timestamp of last update (u40 -> u64)
  last_update_timestamp: Number;
  /// the id of the reserve. Represents the position in the list of the active reserves
  id: Number;
  /// aToken address
  a_token_address: string;
  /// stableDebtToken address
  stable_debt_token_address: string;
  /// variableDebtToken address
  variable_debt_token_address: string;
  /// address of the interest rate strategy
  interest_rate_strategy_address: string;
  /// the current treasury balance, scaled
  accrued_to_treasury: Number;
  /// the outstanding unbacked aTokens minted through the bridging feature
  unbacked: Number;
  /// the outstanding debt borrowed against this asset in isolation mode
  isolation_mode_total_debt: Number;
};
