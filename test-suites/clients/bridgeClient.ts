import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import { BackUnbackedFuncAddr, MintUnbackedFuncAddr } from "../configs/bridge";

export class BridgeClient extends AptosContractWrapperBaseClass {
  public async backUnbacked(
    asset: AccountAddress,
    amount: BigNumber,
    fee: BigNumber,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(BackUnbackedFuncAddr, [asset, amount.toString(), fee.toString()]);
  }

  public async mintUnbacked(
    asset: AccountAddress,
    amount: BigNumber,
    onBehalfOf: AccountAddress,
    referralCode: number,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(MintUnbackedFuncAddr, [asset, amount.toString(), onBehalfOf, referralCode]);
  }
}
