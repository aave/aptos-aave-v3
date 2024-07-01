import {
  Account,
  Network,
  Ed25519PrivateKey,
  AptosConfig,
  Aptos,
  AccountPublicKey,
  AccountAddress,
} from "@aptos-labs/ts-sdk";
import fs from "fs";
import path from "path";
import { PathLike } from "node:fs";
import YAML from "yaml";
import dotenv from "dotenv";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

export interface AccountProfileConfig {
  private_key: string;
  public_key: string;
  account: string;
  rest_url: string;
  faucet_url: string;
}

export class AptosProvider {
  private readonly network: Network;

  private readonly oracleUrl: string;

  private accountProfilesMap: Map<string, Account> = new Map();

  private accountPrivateKeysMap: Map<string, Ed25519PrivateKey> = new Map();

  private aptos: Aptos;

  constructor() {
    // read vars from .env file
    if (!process.env.APTOS_NETWORK) {
      throw new Error("Missing APTOS_NETWORK in .env file");
    }
    switch (process.env.APTOS_NETWORK.toLowerCase()) {
      case "testnet": {
        this.network = Network.TESTNET;
        break;
      }
      case "devnet": {
        this.network = Network.DEVNET;
        break;
      }
      case "mainnet": {
        this.network = Network.MAINNET;
        break;
      }
      case "local": {
        this.network = Network.LOCAL;
        break;
      }
      default:
        throw new Error(`Unknown network ${process.env.APTOS_NETWORK ? process.env.APTOS_NETWORK : "undefined"}`);
    }

    if (!process.env.PYTH_HERMES_URL) {
      throw new Error("Missing PYTH_HERMES_URL in .env file");
    }
    this.oracleUrl = process.env.PYTH_HERMES_URL;
    let aptosConfigFile = process.env.APTOS_CONFIG_FILE;

    // if aptos path not set presume local path
    if (!process.env.APTOS_CONFIG_FILE) {
      const basePath = path.resolve(__dirname, "../../");
      aptosConfigFile = path.join(basePath, ".aptos/config.yaml");
    }

    // read profile set
    if (!fs.existsSync(aptosConfigFile as PathLike)) {
      throw new Error(`Package path ${aptosConfigFile} does not exist`);
    }
    const aptosConfigData = fs.readFileSync(aptosConfigFile, "utf8");

    const parsedYaml = YAML.parse(aptosConfigData);
    for (const profile of Object.keys(parsedYaml.profiles)) {
      const profileConfig = parsedYaml.profiles[profile] as AccountProfileConfig;
      const aptosPrivateKey = new Ed25519PrivateKey(profileConfig.private_key);
      this.accountPrivateKeysMap.set(profile, aptosPrivateKey);
      const profileAccount = Account.fromPrivateKey({ privateKey: aptosPrivateKey });
      this.accountProfilesMap.set(profile, profileAccount);
    }

    const config = new AptosConfig({ network: this.network });
    this.aptos = new Aptos(config);
  }

  /** Returns the aptos instance. */
  public getAptos(): Aptos {
    return this.aptos;
  }

  /** Returns the account profile by name if found. */
  public getProfileAccountByName(profileName: string): Account {
    return this.accountProfilesMap.get(profileName);
  }

  /** Returns the account profile private key by name if found. */
  public getProfilePrivateKeyByName(profileName: string): Ed25519PrivateKey {
    return this.accountPrivateKeysMap.get(profileName);
  }

  /** Returns the account profile public key by name if found. */
  public getProfilePublicKeyByName(profileName: string): AccountPublicKey {
    return this.accountProfilesMap.get(profileName).publicKey;
  }

  /** Returns the account profile address by name if found. */
  public getProfileAccountAddressByByName(profileName: string): AccountAddress {
    return this.accountProfilesMap.get(profileName).accountAddress;
  }

  /** Gets the selected network. */
  public getNetwork(): Network {
    return this.network;
  }

  /** Gets the oracle url. */
  public getOracleUrl(): string {
    return this.oracleUrl;
  }
}
