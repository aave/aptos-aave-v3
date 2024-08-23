import { AccountAddress, CommittedTransactionResponse } from "@aptos-labs/ts-sdk";
import { AptosContractWrapperBaseClass } from "./baseClass";
import {
  CleanupStagingAreaFuncAddr,
  StageCodeChunkAndPublishToAccountFuncAddr,
  StageCodeChunkAndPublishToObjectFuncAddr,
  StageCodeChunkAndUpgradeObjectCodeFuncAddr,
  StageCodeChunkFuncAddr,
} from "../configs/largePackages";

export class LargePackagesClient extends AptosContractWrapperBaseClass {
  public async stageCodeChunk(
    metadataChunk: Uint8Array,
    codeIndices: Array<number>,
    codeChunks: Array<Uint8Array>,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(StageCodeChunkFuncAddr, [metadataChunk, codeIndices, codeChunks]);
  }

  public async stageCodeChunkAndPublishToAccount(
    metadataChunk: Uint8Array,
    codeIndices: Array<number>,
    codeChunks: Array<Uint8Array>,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(StageCodeChunkAndPublishToAccountFuncAddr, [
      metadataChunk,
      codeIndices,
      codeChunks,
    ]);
  }

  public async stageCodeChunkAndPublishToObject(
    metadataChunk: Uint8Array,
    codeIndices: Array<number>,
    codeChunks: Array<Uint8Array>,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(StageCodeChunkAndPublishToObjectFuncAddr, [
      metadataChunk,
      codeIndices,
      codeChunks,
    ]);
  }

  public async stageCodeChunkAndUpgradeObjectCode(
    metadataChunk: Uint8Array,
    codeIndices: Array<number>,
    codeChunks: Array<Uint8Array>,
    code_object?: AccountAddress,
  ): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(StageCodeChunkAndUpgradeObjectCodeFuncAddr, [
      metadataChunk,
      codeIndices,
      codeChunks,
      code_object,
    ]);
  }

  public async cleanupStagingArea(): Promise<CommittedTransactionResponse> {
    return this.sendTxAndAwaitResponse(CleanupStagingAreaFuncAddr, []);
  }
}
