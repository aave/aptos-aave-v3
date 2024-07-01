import * as dotenv from "dotenv";
import { initReserveOraclePrice } from "./init_oracle_price";
import { configReserves } from "./config_reserves";
import { addReserves } from "./init_reserve";
import { initReserveInterestRateStrategy } from "./init_interest_rate";
import { createTokens } from "./create_token";

dotenv.config();

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

(async () => {
  // step1. create tokens
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating tokens..."));
  await createTokens();
  console.log(chalk.green("created tokens successfully!"));

  // step2. init reserves
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("creating reserves..."));
  await addReserves();
  console.log(chalk.green("initiated reserves successfully!"));

  // step3. init reserve interest rate strategy
  console.log(chalk.yellow("---------------------------------------------"));
  console.log(chalk.cyan("initializing interest rate strategies..."));
  await initReserveInterestRateStrategy();
  console.log(chalk.green("initialized reserve interest rate strategy successfully!"));

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
})();
