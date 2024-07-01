import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
const aptosProvider = new AptosProvider();
export const BridgeManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
});
export const BridgeManagerAccountAddress = BridgeManager.accountAddress.toString();

// Resource Func Addr
export const MintUnbackedFuncAddr: MoveFunctionId = `${BridgeManagerAccountAddress}::bridge_logic::mint_unbacked`;
export const BackUnbackedFuncAddr: MoveFunctionId = `${BridgeManagerAccountAddress}::bridge_logic::back_unbacked`;

// Mock Account
