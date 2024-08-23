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
export const IsBorrowAllowedFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle_sentinel::is_borrow_allowed`;
export const IsLiquidationAllowedFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle_sentinel::is_liquidation_allowed`;
export const SetGracePeriodFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle_sentinel::set_grace_period`;
export const GetGracePeriodFuncAddr: MoveFunctionId = `${OracleManagerAccountAddress}::oracle_sentinel::get_grace_period`;

// Mock Account
