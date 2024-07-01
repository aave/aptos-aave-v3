import { Account, Ed25519Account } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "./common";
import {
  AAAVE,
  AAVE,
  ADAI,
  ATokenGetMetadataBySymbolFuncAddr,
  AUSDC,
  AWETH,
  DAI,
  getMetadataAddress,
  UnderlyingGetMetadataBySymbolFuncAddr,
  USDC,
  VariableGetMetadataBySymbolFuncAddr,
  VDAI,
  WETH,
} from "./tokens";
import {
  AclManager,
  addEmergencyAdminFuncAddr,
  addRiskAdminFuncAddr,
  isEmergencyAdminFuncAddr,
  isRiskAdminFuncAddr,
} from "./acl_manage";
import { AptosProvider } from "../wrappers/aptosProvider";

dotenv.config();

interface TestEnv {
  emergencyAdmin: Ed25519Account;
  riskAdmin: Ed25519Account;
  users: Ed25519Account[];
  weth: string;
  aWETH: string;
  dai: string;
  aDai: string;
  aAave: string;
  vDai: string;
  aUsdc: string;
  usdc: string;
  aave: string;
}

export const testEnv: TestEnv = {
  emergencyAdmin: {} as Ed25519Account,
  riskAdmin: {} as Ed25519Account,
  users: [] as Ed25519Account[],
  weth: "",
  aWETH: "",
  dai: "",
  aDai: "",
  vDai: "",
  aUsdc: "",
  usdc: "",
  aave: "",
} as TestEnv;

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

const aptosProvider = new AptosProvider();

export async function getAccounts(): Promise<Ed25519Account[]> {
  // 1. create accounts
  const accounts: Ed25519Account[] = [];
  const manager0 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_0") });
  accounts.push(manager0);

  const manager1 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_1") });
  accounts.push(manager1);

  const manager2 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_2") });
  accounts.push(manager2);

  const manager3 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_3") });
  accounts.push(manager3);

  const manager4 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_4") });
  accounts.push(manager4);

  const manager5 = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("test_account_5") });
  accounts.push(manager5);
  return accounts;
}

export async function initializeMakeSuite() {
  // account manage
  testEnv.users = await getAccounts();
  // eslint-disable-next-line prefer-destructuring
  testEnv.emergencyAdmin = testEnv.users[1];
  // eslint-disable-next-line prefer-destructuring
  testEnv.riskAdmin = testEnv.users[2];

  // // token address
  testEnv.aDai = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, ADAI);
  testEnv.aUsdc = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AUSDC);
  testEnv.aWETH = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AWETH);
  testEnv.aAave = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AAAVE);

  testEnv.vDai = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VDAI);

  testEnv.dai = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  testEnv.aave = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);
  testEnv.usdc = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  testEnv.weth = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);

  // setup admins
  const [isRiskAdmin] = await View(aptos, isRiskAdminFuncAddr, [testEnv.riskAdmin.accountAddress.toString()]);
  if (!isRiskAdmin) {
    await Transaction(aptos, AclManager, addRiskAdminFuncAddr, [testEnv.riskAdmin.accountAddress.toString()]);
  }
  const [isEmergencyAdmin] = await View(aptos, isEmergencyAdminFuncAddr, [
    testEnv.emergencyAdmin.accountAddress.toString(),
  ]);
  if (!isEmergencyAdmin) {
    await Transaction(aptos, AclManager, addEmergencyAdminFuncAddr, [testEnv.emergencyAdmin.accountAddress.toString()]);
  }
}
