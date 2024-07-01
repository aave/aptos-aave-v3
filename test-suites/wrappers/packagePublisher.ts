import { Account, CommittedTransactionResponse, Ed25519Account } from "@aptos-labs/ts-sdk";
import fs from "fs";
import path from "path";
import { PathLike } from "node:fs";
import toml from "toml";
import { AptosProvider } from "./aptosProvider";
import { LargePackagesClient } from "../clients/largePackagesClient";

export class PackagePublisher {
  private static MAX_TRANSACTION_SIZE: number = 60000;

  private aptosProvider: AptosProvider;

  private senderAccount: Account;

  private packagePath: fs.PathOrFileDescriptor;

  private largePackagesClient: LargePackagesClient;

  constructor(aptosProvider: AptosProvider, senderAccount: Account, packagePath: fs.PathOrFileDescriptor) {
    if (!fs.existsSync(packagePath as PathLike)) {
      throw new Error(`Package path ${packagePath.toString()} does not exist`);
    }
    this.packagePath = packagePath;
    this.aptosProvider = aptosProvider;
    this.senderAccount = senderAccount;
    this.largePackagesClient = new LargePackagesClient(aptosProvider, this.senderAccount as Ed25519Account);
  }

  /** Sets the package path. */
  public setPackagePath(packagePath: fs.PathOrFileDescriptor) {
    this.packagePath = packagePath;
  }

  /** Gets the package path. */
  public getPackagePath(): fs.PathOrFileDescriptor {
    return this.packagePath;
  }

  /** Publishes the entire package and all of its modules. */
  public async publish(): Promise<Array<CommittedTransactionResponse>> {
    // get and check the package name
    const tomlFilePath = path.join(this.packagePath.toString(), "Move.toml");
    console.log("Package Toml File Path:", tomlFilePath);
    if (!fs.existsSync(tomlFilePath)) {
      throw new Error(`Toml file under expected package path ${tomlFilePath} does not exist`);
    }

    // get toml name and verify
    const tomlContents = fs.readFileSync(tomlFilePath, { encoding: "utf8" });
    const parsedToml = toml.parse(tomlContents);
    if (!parsedToml.package || !parsedToml.package.name) {
      throw new Error("Toml file was expected to have a section package with a package name");
    }
    console.log("Parsed Module Name from TOML:", parsedToml.package.name);
    const packageName = parsedToml.package.name;

    // get and check the build directory
    const buildDir = path.join(this.packagePath.toString(), "build");
    if (!fs.existsSync(buildDir)) {
      throw new Error(`Build directory ${buildDir} does not exist`);
    }

    // package metadata
    const packageMetadataPath = path.join(buildDir, packageName, "package-metadata.bcs");
    if (!fs.existsSync(packageMetadataPath)) {
      throw new Error(`Package metadata directory ${packageMetadataPath} does not exist`);
    }
    const packageMetadata = fs.readFileSync(path.join(buildDir, packageName, "package-metadata.bcs"));

    // module(s) data inside the package
    const modulesBytecodeDir = path.join(buildDir, packageName, "bytecode_modules");
    if (!fs.existsSync(modulesBytecodeDir)) {
      throw new Error(`Bytecode Directory ${modulesBytecodeDir} does not exist`);
    }
    const moveBytecodeFiles = fs.readdirSync(modulesBytecodeDir).filter((file) => file.endsWith(".mv"));
    console.log("Move Bytecode Files:", moveBytecodeFiles.join(","));
    const packageModulesBytecode: Array<Buffer> = [];
    for (const moveBytecodeFile of moveBytecodeFiles) {
      const moduleData = fs.readFileSync(path.join(buildDir, packageName, "bytecode_modules", moveBytecodeFile));
      packageModulesBytecode.push(moduleData);
    }

    // Construct artifacts for publishing
    const moduleBytecode = packageModulesBytecode.map((moduleData) => new Uint8Array(moduleData));
    const metadataBytes = new Uint8Array(packageMetadata);

    // decide how to publish the package
    let totalSize = metadataBytes.length;
    for (const module of moduleBytecode) {
      totalSize += module.length;
    }
    // small package
    if (totalSize < PackagePublisher.MAX_TRANSACTION_SIZE) {
      console.log(`Publishing small package of size ${totalSize}...`);
      return this.publishSmallPackage(metadataBytes, moduleBytecode);
    } 
      console.log(`Publishing large package of size ${totalSize}...`);
      return this.publishLargePackage(metadataBytes, moduleBytecode);
    
  }

  // ====================== SMALL PACKAGES ==================== //
  async publishSmallPackage(
    metadataBytes: Uint8Array,
    moduleBytecode: Uint8Array[],
  ): Promise<Array<CommittedTransactionResponse>> {
    // construct the transaction
    const transaction = await this.aptosProvider.getAptos().publishPackageTransaction({
      account: this.senderAccount.accountAddress,
      metadataBytes,
      moduleBytecode,
    });

    // send the transaction
    const pendingTransaction = await this.aptosProvider.getAptos().signAndSubmitTransaction({
      signer: this.senderAccount,
      transaction,
    });

    console.log(`Publish small package transaction hash: ${pendingTransaction.hash}`);
    const txResponse = await this.aptosProvider
      .getAptos()
      .waitForTransaction({ transactionHash: pendingTransaction.hash });
    return [txResponse];
  }

  // ====================== LARGE PACKAGES ==================== //
  async createLargePackagePublishingPayload(
    chunkedPackageMetadata: Uint8Array,
    modulesIndices: number[],
    chunkedModules: Uint8Array[],
    publish: boolean,
  ): Promise<CommittedTransactionResponse> {
    if (publish) {
      return this.largePackagesClient.stageCodeChunkAndPublishToAccount(
        chunkedPackageMetadata,
        modulesIndices,
        chunkedModules,
      );
    }
    return this.largePackagesClient.stageCodeChunk(chunkedPackageMetadata, modulesIndices, chunkedModules);
  }

  static createChunks(data: Uint8Array): Uint8Array[] {
    const chunks: Uint8Array[] = [];
    let readData: number = 0;

    while (readData < data.length) {
      const startReadData: number = readData;
      readData = Math.min(readData + PackagePublisher.MAX_TRANSACTION_SIZE, data.length);
      const takenData: Uint8Array = data.slice(startReadData, readData);
      chunks.push(takenData);
    }

    return chunks;
  }

  async publishLargePackage(
    metadataBytes: Uint8Array,
    moduleBytecode: Uint8Array[],
  ): Promise<Array<CommittedTransactionResponse>> {
    const txResponses: CommittedTransactionResponse[] = [];
    const metadataChunks = PackagePublisher.createChunks(metadataBytes);
    console.log(`Created ${metadataChunks.length} METADATA chunks`);

    for (const metadataChunk of metadataChunks.slice(0, -1)) {
      console.log("Publishing metadata chunk ...", metadataChunk.length);
      txResponses.push(await this.createLargePackagePublishingPayload(metadataChunk, [], [], false));
    }

    let metadataChunk = metadataChunks[metadataChunks.length - 1];
    let takenSize = metadataChunk.length;
    let modulesIndices: number[] = [];
    let dataChunks: Uint8Array[] = [];

    for (let idx = 0; idx < moduleBytecode.length; idx++) {
      console.log("Publishing module bytecode ...");
      const module = moduleBytecode[idx];
      const chunkedModule = PackagePublisher.createChunks(module);

      for (const chunk of chunkedModule) {
        console.log("Publishing module bytecode chunk ...", metadataChunk.length, modulesIndices, dataChunks.length);
        if (takenSize + chunk.length > PackagePublisher.MAX_TRANSACTION_SIZE) {
          txResponses.push(
            await this.createLargePackagePublishingPayload(metadataChunk, modulesIndices, dataChunks, false),
          );
          metadataChunk = new Uint8Array([]);
          modulesIndices = [];
          dataChunks = [];
          takenSize = 0;
        }

        if (!modulesIndices.includes(idx)) {
          modulesIndices.push(idx);
        }

        dataChunks.push(chunk);
        takenSize += chunk.length;
      }
    }

    // Add the last chunk
    console.log("Publishing last module bytecode chunk ...", metadataChunk.length, modulesIndices, dataChunks.length);
    txResponses.push(await this.createLargePackagePublishingPayload(metadataChunk, modulesIndices, dataChunks, true));

    console.log(`Published TOTAL of ${txResponses.length} chunked txs`);

    // return the results
    return txResponses;
  }
}
