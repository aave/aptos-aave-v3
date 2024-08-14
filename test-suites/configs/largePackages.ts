import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
const aptosProvider = new AptosProvider();
export const LargePackagesManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_large_packages"),
});
export const LargePackagesAccountAddress = LargePackagesManager.accountAddress.toString();

// Resource Func Addr
export const StageCodeChunkFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk`;
export const StageCodeChunkAndPublishToAccountFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_publish_to_account`;
export const StageCodeChunkAndPublishToObjectFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_publish_to_object`;
export const StageCodeChunkAndUpgradeObjectCodeFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::stage_code_chunk_and_upgrade_object_code`;
export const CleanupStagingAreaFuncAddr: MoveFunctionId = `${LargePackagesAccountAddress}::large_packages::cleanup_staging_area`;

// Mock Account
