import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
const aptosProvider = new AptosProvider();
export const FlashLoanManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
});
export const FlashLoanManagerAccountAddress = FlashLoanManager.accountAddress.toString();

// Resource Func Addr
export const ExecuteFlashLoanFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::flashloan`;
export const PayFlashLoanComplexFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::pay_flash_loan_complex`;
export const ExecuteFlashLoanSimpleFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::flash_loan_simple`;
export const PayFlashLoanSimpleFuncAddr: MoveFunctionId = `${FlashLoanManagerAccountAddress}::flash_loan_logic::pay_flash_loan_simple`;

// Mock Account
