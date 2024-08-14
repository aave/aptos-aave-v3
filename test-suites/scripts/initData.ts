/* eslint-disable no-console */
import * as dotenv from "dotenv";
import { initReserveOraclePrice } from "./initOraclePrice";
import { configReserves } from "./configReserves";
import { initReserves } from "./initReserves";
import { createTokens } from "./createTokens";
import { createRoles } from "./createRoles";
import { initInteresRates } from "./initInterestRate";
import { initPoolAddressesProvider } from "./initPoolAddressesProvider";

dotenv.config();

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

(async () => {
  // step1. create roles
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating roles..."));
  await createRoles();
  console.log(chalk.green("created roles successfully!"));

  // step2. create tokens
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating tokens..."));
  await createTokens();
  console.log(chalk.green("created tokens successfully!"));

  // step3. init interest rate strategies
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("initializing interest rate strategies..."));
  await initInteresRates();
  console.log(chalk.green("initialized interest rate strategies successfully!"));

  // step3. init reserves and interest rate strategies
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("initializing reserves..."));
  await initReserves();
  console.log(chalk.green("initialized reserves successfully!"));

  // step4. config reserves
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("configuring reserves..."));
  await configReserves();
  console.log(chalk.green("configured reserves successfully!"));

  // step5. config oracle price
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("configuring reserve prices..."));
  await initReserveOraclePrice();
  console.log(chalk.green("configured reserve prices successfully!"));

  // step6. config pool addresses provider
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("configuring pool addresses provider..."));
  await initPoolAddressesProvider();
  console.log(chalk.green("configured pool addresses provider successfully!"));
})();
