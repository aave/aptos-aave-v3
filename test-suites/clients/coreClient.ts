import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  BorrowFuncAddr,
  FinalizeTransferFuncAddr,
  GetUserAccountDataFuncAddr,
  LiquidationCallFuncAddr,
  RepayFuncAddr,
  RepayWithATokensFuncAddr,
  SetUserUseReserveAsCollateralFuncAddr,
  SupplyFuncAddr,
  WithdrawFuncAddr,
} from "../configs/supplyBorrow";
import { mapToBN } from "../helpers/contractHelper";

export class CoreClient extends AptosContractWrapperBaseClass {
  /// User supplies
  public async supply(
    asset: AccountAddress,
    amount: BigNumber,
    onBehalfOf: AccountAddress,
    referralCode: number,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SupplyFuncAddr, [asset, amount.toString(), onBehalfOf, referralCode]);
  }

  /// User withdraws
  public async withdraw(
    asset: AccountAddress,
    amount: BigNumber,
    to: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(WithdrawFuncAddr, [asset, amount.toString(), to]);
  }

  /// User borrows
  public async borrow(
    asset: AccountAddress,
    amount: BigNumber,
    interestRateMode: number,
    referralCode: number,
    onBehalfOf: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(BorrowFuncAddr, [
      asset,
      amount.toString(),
      interestRateMode,
      referralCode,
      onBehalfOf,
    ]);
  }

  /// User repays
  public async repay(
    asset: AccountAddress,
    amount: BigNumber,
    interestRateMode: number,
    onBehalfOf: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(RepayFuncAddr, [asset, amount.toString(), interestRateMode, onBehalfOf]);
  }

  /// User repays with A tokens
  public async repayWithATokens(
    asset: AccountAddress,
    amount: BigNumber,
    interestRateMode: number,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(RepayWithATokensFuncAddr, [asset, amount.toString(), interestRateMode]);
  }

  /// User finalizes the transfer
  public async finalizeTransfer(
    asset: AccountAddress,
    from: AccountAddress,
    to: AccountAddress,
    amount: BigNumber,
    balance_from_before: BigNumber,
    balance_to_before: BigNumber,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(FinalizeTransferFuncAddr, [
      asset,
      from,
      to,
      amount.toString(),
      balance_from_before.toString(),
      balance_to_before.toString(),
    ]);
  }

  /// User liquidates a position
  public async liquidationCall(
    collateralAsset: AccountAddress,
    debtAsset: AccountAddress,
    user: AccountAddress,
    debtToCover: BigNumber,
    receiveAToken: boolean,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(LiquidationCallFuncAddr, [
      collateralAsset,
      debtAsset,
      user,
      debtToCover.toString(),
      receiveAToken,
    ]);
  }

  /// User finalizes the transfer
  public async setUserUseReserveAsCollateral(
    asset: AccountAddress,
    useAsCollateral: boolean,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetUserUseReserveAsCollateralFuncAddr, [asset, useAsCollateral]);
  }

  /// Returns all user account data
  public async getUserAccountData(user: AccountAddress): Promise<{
    totalCollateralBase: BigNumber;
    totalDebtBase: BigNumber;
    availableBorrowsBase: BigNumber;
    currentLiquidationThreshold: BigNumber;
    ltv: BigNumber;
    healthFactor: BigNumber;
  }> {
    const [totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor] = (
      await this.callViewMethod(GetUserAccountDataFuncAddr, [user])
    ).map(mapToBN);
    return { totalCollateralBase, totalDebtBase, availableBorrowsBase, currentLiquidationThreshold, ltv, healthFactor };
  }
}
