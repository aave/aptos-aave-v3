import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  AddPoolAdminFuncAddr,
  addAssetListingAdminFuncAddr,
  addBridgeFuncAddr,
  addEmergencyAdminFuncAddr,
  addFlashBorrowerFuncAddr,
  addRiskAdminFuncAddr,
  getAssetListingAdminRoleFuncAddr,
  getBridgeRoleFuncAddr,
  getEmergencyAdminRoleFuncAddr,
  getFlashBorrowerRoleFuncAddr,
  getPoolAdminRoleFuncAddr,
  getRiskAdminRoleFuncAddr,
  grantRoleFuncAddr,
  hasRoleFuncAddr,
  isAssetListingAdminFuncAddr,
  isBridgeFuncAddr,
  isEmergencyAdminFuncAddr,
  isFlashBorrowerFuncAddr,
  isPoolAdminFuncAddr,
  isRiskAdminFuncAddr,
  removeAssetListingAdminFuncAddr,
  removeBridgeFuncAddr,
  removeEmergencyAdminFuncAddr,
  removeFlashBorrowerFuncAddr,
  removePoolAdminFuncAddr,
  removeRiskAdminFuncAddr,
  revokeRoleFuncAddr,
} from "../configs/acl_manage";

export class AclClient extends AptosContractWrapperBaseClass {
  public async hasRole(role: string, user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(hasRoleFuncAddr, [role, user]);
    return resp as boolean;
  }

  public async grantRole(role: string, user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(grantRoleFuncAddr, [role, user]);
  }

  public async revokeRole(role: string, user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(revokeRoleFuncAddr, [role, user]);
  }

  public async addPoolAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(AddPoolAdminFuncAddr, [user]);
  }

  public async removePoolAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removePoolAdminFuncAddr, [user]);
  }

  public async isPoolAdmin(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isPoolAdminFuncAddr, [user]);
    return resp as boolean;
  }

  public async addEmergencyAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(addEmergencyAdminFuncAddr, [user]);
  }

  public async removeEmergencyAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removeEmergencyAdminFuncAddr, [user]);
  }

  public async isEmergencyAdmin(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isEmergencyAdminFuncAddr, [user]);
    return resp as boolean;
  }

  public async addRiskAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(addRiskAdminFuncAddr, [user]);
  }

  public async removeRiskAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removeRiskAdminFuncAddr, [user]);
  }

  public async isRiskAdmin(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isRiskAdminFuncAddr, [user]);
    return resp as boolean;
  }

  public async addFlashBorrower(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(addFlashBorrowerFuncAddr, [user]);
  }

  public async removeFlashBorrower(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removeFlashBorrowerFuncAddr, [user]);
  }

  public async isFlashBorrower(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isFlashBorrowerFuncAddr, [user]);
    return resp as boolean;
  }

  public async addBridge(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(addBridgeFuncAddr, [user]);
  }

  public async removeBridge(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removeBridgeFuncAddr, [user]);
  }

  public async isBridge(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isBridgeFuncAddr, [user]);
    return resp as boolean;
  }

  public async addAssetListingAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(addAssetListingAdminFuncAddr, [user]);
  }

  public async removeAssetListingAdmin(user: AccountAddress): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(removeAssetListingAdminFuncAddr, [user]);
  }

  public async isAssetListingAdmin(user: AccountAddress): Promise<boolean> {
    const [resp] = await this.callViewMethod(isAssetListingAdminFuncAddr, [user]);
    return resp as boolean;
  }

  public async getPoolAdminRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getPoolAdminRoleFuncAddr, []);
    return resp as string;
  }

  public async getEmergencyAdminRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getEmergencyAdminRoleFuncAddr, []);
    return resp as string;
  }

  public async getRiskAdminRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getRiskAdminRoleFuncAddr, []);
    return resp as string;
  }

  public async getFlashBorrowerRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getFlashBorrowerRoleFuncAddr, []);
    return resp as string;
  }

  public async getBridgeRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getBridgeRoleFuncAddr, []);
    return resp as string;
  }

  public async getAssetListingAdminRole(): Promise<string> {
    const [resp] = await this.callViewMethod(getAssetListingAdminRoleFuncAddr, []);
    return resp as string;
  }
}
