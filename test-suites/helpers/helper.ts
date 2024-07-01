import {
  AccountAddress,
  Aptos,
  Ed25519Account,
  EntryFunctionArgumentTypes,
  MoveFunctionId,
  SimpleEntryFunctionArgumentTypes,
  UserTransactionResponse,
} from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";

export const GetAccountBalance = async (
  aptos: Aptos,
  name: string,
  accountAddress: AccountAddress,
  versionToWaitFor?: bigint,
): Promise<BigNumber> => {
  const amount = await aptos.getAccountAPTAmount({
    accountAddress,
    minimumLedgerVersion: versionToWaitFor,
  });
  return BigNumber.from(amount);
};

export async function FundAccount(
  aptos: Aptos,
  account: Ed25519Account,
  amount: number,
): Promise<UserTransactionResponse> {
  return aptos.fundAccount({
    accountAddress: account.accountAddress,
    amount,
  });
}

export async function Transaction(
  aptos: Aptos,
  signer: Ed25519Account,
  func_addr: MoveFunctionId,
  func_args: Array<EntryFunctionArgumentTypes | SimpleEntryFunctionArgumentTypes>,
) {
  const transaction = await aptos.transaction.build.simple({
    sender: signer.accountAddress,
    data: {
      function: func_addr,
      functionArguments: func_args,
    },
  });
  // using signAndSubmit combined
  const commitTx = await aptos.signAndSubmitTransaction({
    signer,
    transaction,
  });
  return aptos.waitForTransaction({ transactionHash: commitTx.hash });
}

export async function View(
  aptos: Aptos,
  func_addr: MoveFunctionId,
  func_args: Array<EntryFunctionArgumentTypes | SimpleEntryFunctionArgumentTypes>,
) {
  // console.log('func_addr:', func_addr, 'func_args:', func_args)
  return aptos.view({
    payload: {
      function: func_addr,
      functionArguments: func_args,
    },
  });
}

export function StringToHex(str: string): string {
  let hexResult: string = "0x";
  // eslint-disable-next-line no-plusplus
  for (let i = 0; i < str.length; i++) {
    const hexValue: string = str.charCodeAt(i).toString(16); // .toUpperCase(); // Get the hexadecimal representation of a character
    hexResult += hexValue.padStart(2, "0"); // Ensure that each character has two hexadecimal digits，If there are any deficiencies, add 0 in front.
  }
  return hexResult;
}
