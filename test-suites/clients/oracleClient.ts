import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import { mapToBN } from "../helpers/contractHelper";
import {
  GetAssetPriceFuncAddr,
  GetGracePeriodFuncAddr,
  IsBorrowAllowedFuncAddr,
  IsLiquidationAllowedFuncAddr,
  SetAssetPriceFuncAddr,
  SetGracePeriodFuncAddr,
} from "../configs/oracle";

export class OracleClient extends AptosContractWrapperBaseClass {
  public async setAssetPrice(asset: AccountAddress, price: BigNumber): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetAssetPriceFuncAddr, [asset, price.toString()]);
  }

  public async getAssetPrice(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetAssetPriceFuncAddr, [asset])).map(mapToBN);
    return resp;
  }

  public async isBorrowAllowed(): Promise<boolean> {
    const [resp] = await this.callViewMethod(IsBorrowAllowedFuncAddr, []);
    return resp as boolean;
  }

  public async isLiquidationAllowed(): Promise<boolean> {
    const [resp] = await this.callViewMethod(IsLiquidationAllowedFuncAddr, []);
    return resp as boolean;
  }

  public async setGracePeriod(newGracePeriod: BigNumber): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetGracePeriodFuncAddr, [newGracePeriod.toString()]);
  }

  public async getGracePeriod(): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetGracePeriodFuncAddr, [])).map(mapToBN);
    return resp;
  }
}
