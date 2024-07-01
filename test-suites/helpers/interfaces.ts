import { BigNumber } from "@ethersproject/bignumber";
import "./wadraymath";

export interface Metadata {
  inner: string;
}

export interface UserReserveData {
  scaledATokenBalance: BigNumber;
  currentATokenBalance: BigNumber;
  currentVariableDebt: BigNumber;
  scaledVariableDebt: BigNumber;
  liquidityRate: BigNumber;
  usageAsCollateralEnabled: Boolean;
  walletBalance: BigNumber;
  [key: string]: BigNumber | string | Boolean;
}

export interface ReserveData {
  address: string;
  symbol: string;
  decimals: BigNumber;
  reserveFactor: BigNumber;
  availableLiquidity: BigNumber;
  totalLiquidity: BigNumber;
  totalVariableDebt: BigNumber;
  scaledVariableDebt: BigNumber;
  variableBorrowRate: BigNumber;
  supplyUsageRatio: BigNumber;
  borrowUsageRatio: BigNumber;
  liquidityIndex: BigNumber;
  variableBorrowIndex: BigNumber;
  aTokenAddress: string;
  lastUpdateTimestamp: BigNumber;
  liquidityRate: BigNumber;
  unbacked: BigNumber;
  accruedToTreasuryScaled: BigNumber;
  [key: string]: BigNumber | string;
}
