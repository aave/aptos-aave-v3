import { AccountAddress, CommittedTransactionResponse, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  VariableBalanceOfFuncAddr,
  VariableCreateTokenFuncAddr,
  VariableDecimalsFuncAddr,
  VariableGetMetadataBySymbolFuncAddr,
  VariableGetPreviousIndexFuncAddr,
  VariableGetRevisionFuncAddr,
  VariableGetScaledUserBalanceAndSupplyFuncAddr,
  VariableGetTokenAccountAddressFuncAddr,
  VariableMaximumFuncAddr,
  VariableNameFuncAddr,
  VariableScaleBalanceOfFuncAddr,
  VariableScaleTotalSupplyFuncAddr,
  VariableSupplyFuncAddr,
  VariableSymbolFuncAddr,
} from "../configs/tokens";
import { mapToBN } from "../helpers/contract_helper";
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
    treasuryAddress: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(VariableCreateTokenFuncAddr, [
      maximumSupply,
      name,
      symbol,
      decimals,
      iconUri,
      projectUri,
      underlyingAsset,
      treasuryAddress,
    ]);
  }

  public async getRevision(): Promise<number> {
    const [resp] = await this.callViewMethod(VariableGetRevisionFuncAddr, []);
    return resp as number;
  }

  public async getMetadataBySymbol(symbol: string): Promise<string> {
    const [resp] = await this.callViewMethod(VariableGetMetadataBySymbolFuncAddr, [symbol]);
    return (resp as Metadata).inner;
  }

  public async getTokenAccountAddress(): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(VariableGetTokenAccountAddressFuncAddr, []);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async balanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async scaleBalanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableScaleBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async supply(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableSupplyFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  public async scaleTotalSupply(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableScaleTotalSupplyFuncAddr, [metadataAddress])).map(mapToBN);
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

  // Get the maximum supply from the metadata object.
  public async maximum(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(VariableMaximumFuncAddr, [metadataAddress])).map(mapToBN);
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

  // get metadata address
  public async getMetadataAddress(funcAddr: MoveFunctionId, coinName: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(funcAddr, [coinName]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  // get decimals
  public async getDecimals(funcAddr: MoveFunctionId, metadataAddr: AccountAddress): Promise<BigNumber> {
    const [res] = (await this.callViewMethod(funcAddr, [metadataAddr])).map(mapToBN);
    return res;
  }
}
