import {
  AccountAddress,
  Aptos,
  CommittedTransactionResponse,
  Ed25519Account,
  EntryFunctionArgumentTypes,
  HexInput,
  MoveFunctionId,
  MoveValue,
  SimpleEntryFunctionArgumentTypes,
  UserTransactionResponse,
  isBlockMetadataTransactionResponse,
  isUserTransactionResponse,
  Event,
} from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AptosProvider } from "../wrappers/aptosProvider";

const GetAccountBalance = async (
  aptos: Aptos,
  accountAddress: AccountAddress,
  versionToWaitFor?: bigint,
): Promise<BigNumber> => {
  const amount = await aptos.getAccountAPTAmount({
    accountAddress,
    minimumLedgerVersion: versionToWaitFor,
  });
  return BigNumber.from(amount);
};

async function FundAccount(aptos: Aptos, account: AccountAddress, amount: number): Promise<UserTransactionResponse> {
  return aptos.fundAccount({
    accountAddress: account,
    amount,
  });
}

async function Transaction(
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

async function View(
  aptos: Aptos,
  func_addr: MoveFunctionId,
  func_args: Array<EntryFunctionArgumentTypes | SimpleEntryFunctionArgumentTypes>,
) {
  return aptos.view({
    payload: {
      function: func_addr,
      functionArguments: func_args,
    },
  });
}

export class AptosContractWrapperBaseClass {
  protected signer: Ed25519Account;

  protected readonly aptosProvider: AptosProvider;

  constructor(aptosProvider: AptosProvider, signer?: Ed25519Account) {
    this.aptosProvider = aptosProvider;
    this.signer = signer;
  }

  /** Sets the signer. */
  public setSigner(senderAccount: Ed25519Account) {
    this.signer = senderAccount;
  }

  /** Returns the signer. */
  public getSigner(): Ed25519Account {
    return this.signer;
  }

  /** Sends and awaits a response. */
  public async sendTxAndAwaitResponse(
    functionId: MoveFunctionId,
    func_args: Array<EntryFunctionArgumentTypes | SimpleEntryFunctionArgumentTypes>,
  ): Promise<CommittedTransactionResponse> {
    return Transaction(this.aptosProvider.getAptos(), this.signer, functionId, func_args);
  }

  /** Calls a view method. */
  public async callViewMethod(
    functionId: MoveFunctionId,
    func_args: Array<EntryFunctionArgumentTypes | SimpleEntryFunctionArgumentTypes>,
  ): Promise<MoveValue[]> {
    return View(this.aptosProvider.getAptos(), functionId, func_args);
  }

  /// funds a given account
  public async fundAccount(account: AccountAddress, amount: BigNumber): Promise<UserTransactionResponse> {
    return FundAccount(this.aptosProvider.getAptos(), account, amount.toNumber());
  }

  /// returns the account apt balance
  public async getAccountAptBalance(
    account: Ed25519Account,
    accountAddress: AccountAddress,
    versionToWaitFor?: bigint,
  ): Promise<BigNumber> {
    return GetAccountBalance(this.aptosProvider.getAptos(), accountAddress, versionToWaitFor);
  }

  /// gets all events for a tx hash
  public async getTxEvents(aptos: Aptos, txHash: HexInput): Promise<Array<{ data: any }>> {
    const txResponse = await this.aptosProvider.getAptos().getTransactionByHash({ transactionHash: txHash });
    let events: Array<Event> = [];
    if (isBlockMetadataTransactionResponse(txResponse) || isUserTransactionResponse(txResponse)) {
      events = txResponse.events;
    }
    return events.map((event) => ({
      data: JSON.parse(event.data),
    }));
  }
}
