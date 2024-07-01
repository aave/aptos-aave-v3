import { AccountAddress, CommittedTransactionResponse, MoveFunctionId } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  ATokenAssetMetadataFuncAddr,
  ATokenBalanceOfFuncAddr,
  ATokenCreateTokenFuncAddr,
  ATokenDecimalsFuncAddr,
  ATokenGetGetPreviousIndexFuncAddr,
  ATokenGetMetadataBySymbolFuncAddr,
  ATokenGetReserveTreasuryAddressFuncAddr,
  ATokenGetRevisionFuncAddr,
  ATokenGetTokenAccountAddressFuncAddr,
  ATokenGetUnderlyingAssetAddressFuncAddr,
  ATokenMaximumFuncAddr,
  ATokenNameFuncAddr,
  ATokenRescueTokensFuncAddr,
  ATokenScaleBalanceOfFuncAddr,
  ATokenScaleTotalSupplyFuncAddr,
  ATokenSupplyFuncAddr,
  ATokenSymbolFuncAddr,
  ATokenTokenAddressFuncAddr,
} from "../configs/tokens";
import { mapToBN } from "../helpers/contract_helper";
import { Metadata } from "../helpers/interfaces";

export class ATokensClient extends AptosContractWrapperBaseClass {
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
    return this.sendTxAndAwaitResponse(ATokenCreateTokenFuncAddr, [
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

  public async rescueTokens(
    token: AccountAddress,
    to: AccountAddress,
    amount: BigNumber,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(ATokenRescueTokensFuncAddr, [token, to, amount.toString()]);
  }

  public async getRevision(): Promise<number> {
    const [resp] = await this.callViewMethod(ATokenGetRevisionFuncAddr, []);
    return resp as number;
  }

  public async getMetadataBySymbol(symbol: string): Promise<string> {
    const [resp] = await this.callViewMethod(ATokenGetMetadataBySymbolFuncAddr, [symbol]);
    return (resp as Metadata).inner;
  }

  public async getTokenAccountAddress(metadataAddress: AccountAddress): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(ATokenGetTokenAccountAddressFuncAddr, [metadataAddress]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async tokenAddress(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(ATokenTokenAddressFuncAddr, [symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async assetMetadata(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(ATokenAssetMetadataFuncAddr, [symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async getReserveTreasuryAddress(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(ATokenGetReserveTreasuryAddressFuncAddr, [symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async getUnderlyingAssetAddress(symbol: string): Promise<AccountAddress> {
    const [resp] = await this.callViewMethod(ATokenGetUnderlyingAssetAddressFuncAddr, [symbol]);
    return AccountAddress.fromString((resp as Metadata).inner);
  }

  public async balanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async scaleBalanceOf(owner: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenScaleBalanceOfFuncAddr, [owner, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async supply(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenSupplyFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  public async scaleTotalSupply(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenScaleTotalSupplyFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  public async getPreviousIndex(user: AccountAddress, metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenGetGetPreviousIndexFuncAddr, [user, metadataAddress])).map(mapToBN);
    return resp;
  }

  public async getScaledUserBalanceAndSupply(
    user: AccountAddress,
    metadataAddress: AccountAddress,
  ): Promise<{ scaledUserBalance: BigNumber; supply: BigNumber }> {
    const [scaledUserBalance, supply] = (
      await this.callViewMethod(ATokenGetGetPreviousIndexFuncAddr, [user, metadataAddress])
    ).map(mapToBN);
    return { scaledUserBalance, supply };
  }

  // Get the maximum supply from the metadata object.
  public async maximum(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenMaximumFuncAddr, [metadataAddress])).map(mapToBN);
    return resp;
  }

  // Get the name of the fungible asset from the metadata object.
  public async name(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(ATokenNameFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the symbol of the fungible asset from the metadata object.
  public async symbol(metadataAddress: AccountAddress): Promise<string> {
    const [resp] = await this.callViewMethod(ATokenSymbolFuncAddr, [metadataAddress]);
    return resp as string;
  }

  // Get the decimals from the metadata object.
  public async decimals(metadataAddress: AccountAddress): Promise<BigNumber> {
    const [resp] = (await this.callViewMethod(ATokenDecimalsFuncAddr, [metadataAddress])).map(mapToBN);
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
