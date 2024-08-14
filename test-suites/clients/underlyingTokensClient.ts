import { AccountAddress, CommittedTransactionResponse, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  UnderlyingBalanceOfFuncAddr,
  UnderlyingCreateTokenFuncAddr,
  UnderlyingDecimalsFuncAddr,
  UnderlyingGetMetadataBySymbolFuncAddr,
  UnderlyingGetTokenAccountAddressFuncAddr,
  UnderlyingMaximumFuncAddr,
  UnderlyingMintFuncAddr,
  UnderlyingNameFuncAddr,
  UnderlyingSupplyFuncAddr,
  UnderlyingSymbolFuncAddr,
  UnderlyingTokenAddressFuncAddr,
} from "../configs/tokens";
import { mapToBN } from "../helpers/contractHelper";
import { Metadata } from "../helpers/interfaces";

export class UnderlyingTokensClient extends AptosContractWrapperBaseClass {
  public async createToken(
    maximumSupply: bigint,
    name: string,
    symbol: string,
    decimals: number,
    iconUri: string,
    projectUri: string,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(UnderlyingCreateTokenFuncAddr, [
      maximumSupply,
      name,
      symbol,
      decimals,
      iconUri,
      projectUri,
    ]);
  }

  public async mint(
    to: AccountAddress,
    amount: BigNumber,
    metadataAddress: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(UnderlyingMintFuncAddr, [to, amount.toString(), metadataAddress]);
  }

  public async getMetadataBySymbol(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(UnderlyingGetMetadataBySymbolFuncAddr, [symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async getTokenAccountAddress(): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(UnderlyingGetTokenAccountAddressFuncAddr, []);
    return AccountAddress.fromString(resp as string);
  }

  public async supply(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(UnderlyingSupplyFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  // Get the maximum supply from the metadata object.
  public async maximum(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(UnderlyingMaximumFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  // Get the name of the fungible asset from the metadata object.
  public async name(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(UnderlyingNameFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the symbol of the fungible asset from the metadata object.
  public async symbol(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(UnderlyingSymbolFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the decimals from the metadata object.
  public async decimals(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(UnderlyingDecimalsFuncAddr, [metadataAddress])).map(mapToBN);
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

  public async balanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(UnderlyingBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async getTokenAddress(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(UnderlyingTokenAddressFuncAddr, [symbol]);
    return AccountAddress.fromString(resp as string);
  }
}
