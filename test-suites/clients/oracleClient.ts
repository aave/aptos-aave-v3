import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import { mapToBN } from "../helpers/contract_helper";
import { GetAssetPriceFuncAddr, SetAssetPriceFuncAddr } from "../configs/oracle";

export class OracleClient extends AptosContractWrapperBaseClass {
  public async setAssetPrice(asset: AccountAddress, price: BigNumber): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetAssetPriceFuncAddr, [asset, price.toString()]);
  }

  public async getAssetPrice(asset: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(GetAssetPriceFuncAddr, [asset])).map(mapToBN);
    return resp;
  }
}
