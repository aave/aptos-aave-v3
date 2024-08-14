import { AccountAddress, CommittedTransactionResponse, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  VariableCreateTokenFuncAddr,
  VariableDecimalsFuncAddr,
  VariableGetAssetMetadataFuncAddr,
  VariableGetMetadataBySymbolFuncAddr,
  VariableGetPreviousIndexFuncAddr,
  VariableGetRevisionFuncAddr,
  VariableGetScaledUserBalanceAndSupplyFuncAddr,
  VariableGetTokenAddressFuncAddr,
  VariableGetUnderlyingAddressFuncAddr,
  VariableNameFuncAddr,
  VariableScaledBalanceOfFuncAddr,
  VariableScaledTotalSupplyFuncAddr,
  VariableSymbolFuncAddr,
} from "../configs/tokens";
import { mapToBN } from "../helpers/contractHelper";
import { Metadata } from "../helpers/interfaces";

export class VariableTokensClient extends AptosContractWrapperBaseClass {
  public async createToken(
    maximumSupply: bigint,
    name: string,
    symbol: string,
    decimals: number,
    iconUri: string,
    projectUri: string,
    underlyingAsset: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(VariableCreateTokenFuncAddr, [
      maximumSupply,
      name,
      symbol,
      decimals,
      iconUri,
      projectUri,
      underlyingAsset,
    ]);
  }

  public async getRevision(): Promise<number> {
    const [resp] = await this.callViewMethod(VariableGetRevisionFuncAddr, []);
    return resp as number;
  }

  public async getMetadataBySymbol(owner: AccountAddress, symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(VariableGetMetadataBySymbolFuncAddr, [owner, symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async getTokenAddress(owner: AccountAddress, symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(VariableGetTokenAddressFuncAddr, [owner, symbol]);
    return AccountAddress.fromString(resp as string);
  }

  public async getAssetMetadata(owner: AccountAddress, symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(VariableGetAssetMetadataFuncAddr, [owner, symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async getUnderlyingAssetAddress(metadataAddress: AccountAddress): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(VariableGetUnderlyingAddressFuncAddr, [metadataAddress]);
    return AccountAddress.fromString(resp as string);
  }

  public async scaledBalanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableScaledBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async scaledTotalSupplyOf(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableScaledTotalSupplyFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  public async getScaledUserBalanceAndSupply(
    owner: AccountAddress,
    metadataAddress: AccountAddress,
  ): Promise<BigNumber> {
    const [resp] = (
      await this.callViewMethod(VariableGetScaledUserBalanceAndSupplyFuncAddr, [owner, metadataAddress])
    ).map(mapToBN);
    return resp;
  }

  public async getPreviousIndex(user: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableGetPreviousIndexFuncAddr, [user, metadataAddress])).map(mapToBN);
    return resp;
  }

  // Get the name of the fungible asset from the metadata object.
  public async name(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(VariableNameFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the symbol of the fungible asset from the metadata object.
  public async symbol(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(VariableSymbolFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the decimals from the metadata object.
  public async decimals(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableDecimalsFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  // get decimals
  public async getDecimals(funcAddr: MoveFunctionId, metadataAddr: AccountAddress): Promise<BigNumber> {
    const [res] = (await this.callViewMethod(funcAddr, [metadataAddr])).map(mapToBN);
    return res;
  }
}
