/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */
import { BigNumber } from "ethers";
import { PoolManager, rateStrategyStableTwo } from "../configs/pool";
import { AptosProvider } from "../wrappers/aptosProvider";
import { PoolClient } from "../clients/poolClient";
import { underlyingTokens } from "./createTokens";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initInteresRates() {
  // global aptos provider
  const aptosProvider = new AptosProvider();
  const poolClient = new PoolClient(aptosProvider, PoolManager);

  // set interest rate strategy fr each reserve
  for (const [, underlyingToken] of underlyingTokens.entries()) {
    const txReceipt = await poolClient.setReserveInterestRateStrategy(
      underlyingToken.accountAddress,
      BigNumber.from(rateStrategyStableTwo.optimalUsageRatio),
      BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate),
      BigNumber.from(rateStrategyStableTwo.variableRateSlope1),
      BigNumber.from(rateStrategyStableTwo.variableRateSlope2),
    );
    console.log(chalk.yellow(`${underlyingToken.symbol} interest rate strategy set with tx hash`, txReceipt.hash));
  }
}
