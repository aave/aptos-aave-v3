import { AAVE_PROFILES } from "@aave/aave-v3-aptos-ts-sdk";
import { Account } from "@aptos-labs/ts-sdk";
import { Command } from "commander";
import { PathLike } from "fs";
import fs from "fs";

const generateProfileEnvData = (profileName: string) => {
  const account = Account.generate();
  console.info("==========================================================================");
  console.info(`                   [PROFILE]: ${profileName.toUpperCase()}                `);
  console.info("==========================================================================");
  console.info("Account: " + account.accountAddress.toString());
  console.info("Public Key:  " + account.publicKey.toString());
  console.info("Private Key: " + account.privateKey.toString());
  console.info("\n");
  let name = "";
  if (profileName === AAVE_PROFILES.AAVE_MOCK_UNDERLYINGS) {
    name = "AAVE_MOCK_UNDERLYING_TOKENS_PRIVATE_KEY";
  } else {
    name = `${profileName.toUpperCase()}_PRIVATE_KEY`;
  }
  const genAccount = `${name}=${account.privateKey.toString().slice("ed25519-priv-".length)}`;
  return genAccount;
};

const program = new Command();

program
  .name("Profiles Generator")
  .description("A CLI tool for generating profiles for aave-aptos")
  .version("1.0.0");

program
  .command("generate")
  .description("Generates profiles for aave-aptos and persists them as ENVs in a file")
  .argument("<string>", "path to profile file")
  .action((path: PathLike, options) => {
    let envContents: Array<string> = [];
    envContents.push("APTOS_NETWORK=local");
    envContents.push("ARTIFACTS_LEVEL=all");
    envContents.push("MOVE_VERSION=2.1");
    envContents.push("COMPILER_VERSION=2.0");
    envContents.push("DEFAULT_FUND_AMOUNT=100000000");

    for (const profile of Object.values(AAVE_PROFILES)) {
      envContents.push(generateProfileEnvData(profile));
    }

    envContents.push(generateProfileEnvData("DEFAULT_FUNDER"));
    envContents.push(generateProfileEnvData("AAVE_DATA_FEEDS"));
    envContents.push(generateProfileEnvData("AAVE_PLATFORM"));

    if (!fs.existsSync(path)) {
      console.info(`Profile file does not exist under ${path}. Creating a new one...`);
    } else {
      console.info(`Profile file already exists under ${path}. Contents will be overwritten!`);
    }
    fs.writeFileSync(path, envContents.join("\n"), { encoding: "utf8" });
    console.info(`Writing data to ${path} done!`);
  });

program.parse(process.argv);
