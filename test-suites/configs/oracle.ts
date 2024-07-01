import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
const aptosProvider = new AptosProvider();
export const OracleManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_mock_oracle"),
});
export const OracleManagerAccountAddress = OracleManager.accountAddress.toString();

// Resource Func Addr
export const GetAssetPriceFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle::get_asset_price`;
export const SetAssetPriceFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle::set_asset_price`;

// Mock Account
