import { Account, AccountAddress, Ed25519Account } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AAAVE, AAVE, ADAI, AUSDC, AWETH, DAI, USDC, VDAI, WETH } from "./tokens";
import { AclManager } from "./aclManage";
import { AptosProvider } from "../wrappers/aptosProvider";
import { aTokens, underlyingTokens, varTokens } from "../scripts/createTokens";
import { AclClient } from "../clients/aclClient";

dotenv.config();

interface TestEnv {
  emergencyAdmin: Ed25519Account;
  riskAdmin: Ed25519Account;
  users: Ed25519Account[];
  weth: AccountAddress;
  aWETH: AccountAddress;
  dai: AccountAddress;
  aDai: AccountAddress;
  aAave: AccountAddress;
  vDai: AccountAddress;
  aUsdc: AccountAddress;
  usdc: AccountAddress;
  aave: AccountAddress;
}

export const testEnv: TestEnv = {
  emergencyAdmin: {} as Ed25519Account,
  riskAdmin: {} as Ed25519Account,
  users: [] as Ed25519Account[],
  weth: AccountAddress.ZERO,
  aWETH: AccountAddress.ZERO,
  dai: AccountAddress.ZERO,
  aDai: AccountAddress.ZERO,
  vDai: AccountAddress.ZERO,
  aUsdc: AccountAddress.ZERO,
  usdc: AccountAddress.ZERO,
  aave: AccountAddress.ZERO,
} as TestEnv;

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

const aptosProvider = new AptosProvider();

export async function getTestAccounts(): Promise<Ed25519Account[]> {
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
  testEnv.users = await getTestAccounts();
  // eslint-disable-next-line prefer-destructuring
  testEnv.emergencyAdmin = testEnv.users[1];
  // eslint-disable-next-line prefer-destructuring
  testEnv.riskAdmin = testEnv.users[2];

  testEnv.aDai = aTokens.find((token) => token.symbol === ADAI).metadataAddress;
  testEnv.aUsdc = aTokens.find((token) => token.symbol === AUSDC).metadataAddress;
  testEnv.aWETH = aTokens.find((token) => token.symbol === AWETH).metadataAddress;
  testEnv.aAave = aTokens.find((token) => token.symbol === AAAVE).metadataAddress;

  testEnv.vDai = varTokens.find((token) => token.symbol === VDAI).metadataAddress;

  testEnv.dai = underlyingTokens.find((token) => token.symbol === DAI).accountAddress;
  testEnv.aave = underlyingTokens.find((token) => token.symbol === AAVE).accountAddress;
  testEnv.usdc = underlyingTokens.find((token) => token.symbol === USDC).accountAddress;
  testEnv.weth = underlyingTokens.find((token) => token.symbol === WETH).accountAddress;

  const aclClient = new AclClient(aptosProvider, AclManager);

  // setup admins
  const isRiskAdmin = await aclClient.isRiskAdmin(testEnv.riskAdmin.accountAddress);
  if (!isRiskAdmin) {
    await aclClient.addAssetListingAdmin(testEnv.riskAdmin.accountAddress);
  }
  const isEmergencyAdmin = await aclClient.isEmergencyAdmin(testEnv.emergencyAdmin.accountAddress);
  if (!isEmergencyAdmin) {
    await aclClient.addEmergencyAdmin(testEnv.emergencyAdmin.accountAddress);
  }
}
