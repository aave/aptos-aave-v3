/* eslint-disable no-await-in-loop */
import dotenv from "dotenv";
import path from "path";
import { Account } from "@aptos-labs/ts-sdk";
import fs from "fs";
import { PathLike } from "node:fs";
import { AptosProvider } from "../wrappers/aptosProvider";
import { PackagePublisher } from "../wrappers/packagePublisher";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

const parseArgs = () => {
  const args: { [key: string]: any } = {};
  process.argv.slice(2).forEach((arg) => {
    const [key, value] = arg.split("=");
    if (key.startsWith("--")) {
      args[key.slice(2)] = value;
    }
  });
  return args;
};

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

(async () => {
  // parse cmd args
  const args = parseArgs();
  if (!args.module) {
    throw new Error("Missing cmd argument `--module`");
  }

  // check module path
  const modulePath = args.module as fs.PathOrFileDescriptor;
  if (!fs.existsSync(modulePath as PathLike)) {
    throw new Error(`Module under expected path ${modulePath} does not exist`);
  }

  // global aptos provider
  const aptosProvider = new AptosProvider();

  // all atokens-related operations client
  const senderProfile = args.profile as string;
  const senderAccount = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName(senderProfile) });
  const packagePublisher = new PackagePublisher(aptosProvider, senderAccount as Account, modulePath);

  try {
    const txResponses = await packagePublisher.publish();
    for (const txResponse of txResponses) {
      console.log(chalk.yellow("Subpackage successfully published with tx hash", txResponse.hash));
    }
    console.log(chalk.green("Publishing package finished successfully!"));
  } catch (ex) {
    console.error("Exception = ", ex);
  }
})();
