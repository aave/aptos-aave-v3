import {
  Aptos,
  Event,
  HexInput,
  isBlockMetadataTransactionResponse,
  isUserTransactionResponse,
  MoveValue,
} from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { ReserveData, UserReserveData } from "./interfaces";
import { aptos } from "../configs/common";
import { View } from "./helper";
import {
  GetReserveConfigurationDataFuncAddr,
  GetReserveDataFuncAddr,
  GetReserveTokensAddressesFuncAddr,
  GetUserReserveDataFuncAddr,
} from "../configs/pool";

import {
  ATokenGetTokenAccountAddressFuncAddr,
  ATokenScaledBalanceOfFuncAddr,
  UnderlyingBalanceOfFuncAddr,
  UnderlyingSymbolFuncAddr,
  VariableScaledTotalSupplyFuncAddr,
} from "../configs/tokens";

export function mapToBN(value: MoveValue): BigNumber {
  return BigNumber.from(value.toString());
}

// eslint-disable-next-line @typescript-eslint/no-shadow
export async function getTxEvents(aptos: Aptos, txHash: HexInput): Promise<Array<{ data: any }>> {
  const txResponse = await aptos.getTransactionByHash({ transactionHash: txHash });
  let events: Array<Event> = [];
  if (isBlockMetadataTransactionResponse(txResponse) || isUserTransactionResponse(txResponse)) {
    events = txResponse.events;
  }
  return events.map((event) => ({
    data: JSON.parse(event.data),
  }));
}

export const getReserveData = async (reserve: string): Promise<ReserveData> => {
  const [
    unbacked,
    accruedToTreasuryScaled,
    ,
    totalVariableDebt,
    liquidityRate,
    variableBorrowRate,
    liquidityIndex,
    variableBorrowIndex,
    lastUpdateTimestamp,
  ] = await View(aptos, GetReserveDataFuncAddr, [reserve]);

  const [decimals, , , , reserveFactor, , , ,] = await View(aptos, GetReserveConfigurationDataFuncAddr, [reserve]);

  const [aToken, vToken] = await View(aptos, GetReserveTokensAddressesFuncAddr, [reserve]);

  const [scaledVariableDebt] = await View(aptos, VariableScaledTotalSupplyFuncAddr, [vToken.toString()]);
  const [symbol] = await View(aptos, UnderlyingSymbolFuncAddr, [reserve]);

  const [aTokenAccount] = await View(aptos, ATokenGetTokenAccountAddressFuncAddr, [aToken.toString()]);
  const [availableLiquidity] = await View(aptos, UnderlyingBalanceOfFuncAddr, [aTokenAccount.toString(), reserve]);

  const totalLiquidity = BigNumber.from(availableLiquidity).add(BigNumber.from(unbacked));

  const totalDebt = BigNumber.from(totalVariableDebt);

  const borrowUsageRatio = totalDebt.eq(0)
    ? BigNumber.from(0)
    : totalDebt.rayDiv(BigNumber.from(availableLiquidity).add(totalDebt));

  const supplyUsageRatio = totalDebt.eq(0) ? BigNumber.from(0) : totalDebt.rayDiv(totalLiquidity.add(totalDebt));

  // expect(supplyUsageRatio.toNumber()).toBeLessThanOrEqual(borrowUsageRatio.toNumber());

  return {
    reserveFactor: BigNumber.from(reserveFactor),
    unbacked: BigNumber.from(unbacked),
    accruedToTreasuryScaled: BigNumber.from(accruedToTreasuryScaled),
    availableLiquidity: BigNumber.from(availableLiquidity),
    totalLiquidity,
    borrowUsageRatio,
    supplyUsageRatio,
    totalVariableDebt: BigNumber.from(totalVariableDebt),
    liquidityRate: BigNumber.from(liquidityRate),
    variableBorrowRate: BigNumber.from(variableBorrowRate),
    liquidityIndex: BigNumber.from(liquidityIndex),
    variableBorrowIndex: BigNumber.from(variableBorrowIndex),
    lastUpdateTimestamp: BigNumber.from(lastUpdateTimestamp),
    scaledVariableDebt: BigNumber.from(scaledVariableDebt),
    address: reserve,
    aTokenAddress: aToken.toString(),
    symbol: symbol.toString(),
    decimals: BigNumber.from(decimals),
  };
};
const getATokenUserData = async (reserve: string, user: string) => {
  const [aTokenAddress] = await View(aptos, GetReserveTokensAddressesFuncAddr, [reserve]);
  const [scaledBalance] = await View(aptos, ATokenScaledBalanceOfFuncAddr, [user, aTokenAddress.toString()]);
  return scaledBalance.toString();
};

export const getUserData = async (reserve: string, user: string, sender?: string): Promise<UserReserveData> => {
  const [currentATokenBalance, currentVariableDebt, scaledVariableDebt, liquidityRate, usageAsCollateralEnabled] =
    await View(aptos, GetUserReserveDataFuncAddr, [reserve, user]);
  const scaledATokenBalance = await getATokenUserData(reserve, user);
  const [walletBalance] = await View(aptos, UnderlyingBalanceOfFuncAddr, [sender || user, reserve]);

  return {
    scaledATokenBalance: BigNumber.from(scaledATokenBalance),
    currentATokenBalance: BigNumber.from(currentATokenBalance),
    currentVariableDebt: BigNumber.from(currentVariableDebt),
    scaledVariableDebt: BigNumber.from(scaledVariableDebt),
    liquidityRate: BigNumber.from(liquidityRate),
    usageAsCollateralEnabled: usageAsCollateralEnabled as boolean,
    walletBalance: BigNumber.from(walletBalance),
  };
};
