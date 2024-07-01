import {
  Account,
  AccountAddress,
  CommittedTransactionResponse,
  InputEntryFunctionData,
  InputViewFunctionData,
  MoveFunctionId,
  MoveValue,
} from "@aptos-labs/ts-sdk";
import { AptosProvider } from "./aptosProvider";

export class AptosContractWrapperBaseClass {
  protected sender: Account;

  protected readonly aptosProvider: AptosProvider;

  protected readonly contractName: string;

  protected readonly moduleAccountAddress: AccountAddress;

  constructor(
    aptosProvider: AptosProvider,
    contractName: string,
    senderAccount: Account,
    moduleAccountAddress: AccountAddress,
  ) {
    this.aptosProvider = aptosProvider;
    this.sender = senderAccount;
    this.contractName = contractName;
    this.moduleAccountAddress = moduleAccountAddress;
  }

  /** Sets the sender. */
  public setSender(senderAccount: Account) {
    this.sender = senderAccount;
  }

  /** Returns the sender. */
  public getSender(): Account {
    return this.sender;
  }

  /** Sends and awaits a response. */
  public async sendTxAndAwaitResponse(
    functionId: MoveFunctionId,
    data: InputEntryFunctionData,
  ): Promise<CommittedTransactionResponse> {
    const transaction = await this.aptosProvider
      .getAptos()
      .transaction.build.simple({ sender: this.sender.accountAddress, data });
    const pendingTxn = await this.aptosProvider
      .getAptos()
      .signAndSubmitTransaction({ signer: this.sender, transaction });
    return this.aptosProvider.getAptos().waitForTransaction({ transactionHash: pendingTxn.hash });
  }

  /** Calls a view method. */
  public async callViewMethod(payload: InputViewFunctionData): Promise<MoveValue[]> {
    return this.aptosProvider.getAptos().view({ payload });
  }
}
