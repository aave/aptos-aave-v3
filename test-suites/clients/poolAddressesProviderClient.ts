import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { AptosContractWrapperBaseClass } from "./baseClass";
import { Metadata } from "../helpers/interfaces";
import {
  GetAclAdminFuncAddr,
  GetAclManagerFuncAddr,
  GetAddressFuncAddr,
  GetMarketIdFuncAddr,
  GetPoolConfiguratorFuncAddr,
  GetPoolDataProviderFuncAddr,
  GetPoolFuncAddr,
  GetPriceOracleFuncAddr,
  GetPriceOracleSentinelFuncAddr,
  HasIdMappedAccountFuncAddr,
  SetAclAdminFuncAddr,
  SetAclManagerFuncAddr,
  SetAddressFuncAddr,
  SetMarketIdFuncAddr,
  SetPoolConfiguratorFuncAddr,
  SetPoolDataProviderFuncAddr,
  SetPoolImplFuncAddr,
  SetPriceOracleFuncAddr,
  SetPriceOracleSentinelFuncAddr,
} from "../configs/pool";

export class PoolAddressesProviderClient extends AptosContractWrapperBaseClass {
  public async hasIdMappedAccount(id: string): Promise<boolean> {
    const [resp] = await this.callViewMethod(HasIdMappedAccountFuncAddr, [id]);
    return resp as boolean;
  }

  public async getMarketId(): Promise<string | undefined> {
    const [resp] = await this.callViewMethod(GetMarketIdFuncAddr, []);
    return resp ? (resp as Metadata).inner : undefined;
  }

  public async getAddress(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetAddressFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getPool(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetPoolFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getPoolConfigurator(symbol: string): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetPoolConfiguratorFuncAddr, [symbol]);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getPriceOracle(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetPriceOracleFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getAclManager(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetAclManagerFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getAclAdmin(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetAclAdminFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getPriceOracleSentinel(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetPriceOracleSentinelFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async getPoolDataProvider(): Promise<AccountAddress | undefined> {
    const [resp] = await this.callViewMethod(GetPoolDataProviderFuncAddr, []);
    return resp ? AccountAddress.fromString((resp as Metadata).inner) : undefined;
  }

  public async setMarketId(newMarketId: string): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetMarketIdFuncAddr, [newMarketId]);
  }

  public async setAddress(id: string, addr: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetAddressFuncAddr, [id, addr]);
  }

  public async setPoolImpl(newPoolImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetPoolImplFuncAddr, [newPoolImpl]);
  }

  public async setPoolConfigurator(newPoolConfiguratorImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetPoolConfiguratorFuncAddr, [newPoolConfiguratorImpl]);
  }

  public async setPriceOracle(newPriceOracleImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetPriceOracleFuncAddr, [newPriceOracleImpl]);
  }

  public async setAclManager(newAclManagerImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetAclManagerFuncAddr, [newAclManagerImpl]);
  }

  public async setAclAdmin(newAclAdminImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetAclAdminFuncAddr, [newAclAdminImpl]);
  }

  public async setPriceOracleSentinel(
    newPriceOracleSentinelImpl: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetPriceOracleSentinelFuncAddr, [newPriceOracleSentinelImpl]);
  }

  public async setPoolDataProvider(newPoolDataProviderImpl: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(SetPoolDataProviderFuncAddr, [newPoolDataProviderImpl]);
  }
}
