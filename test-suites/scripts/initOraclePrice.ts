/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */
import { BigNumber } from "ethers";
import { OracleManager } from "../configs/oracle";
import { AptosProvider } from "../wrappers/aptosProvider";
import { OracleClient } from "../clients/oracleClient";
import { underlyingTokens } from "./createTokens";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initReserveOraclePrice() {
  // global aptos provider
  const aptosProvider = new AptosProvider();
  const oracleClient = new OracleClient(aptosProvider, OracleManager);

  for (const [, underlyingToken] of underlyingTokens.entries()) {
    const txReceipt = await oracleClient.setAssetPrice(underlyingToken.accountAddress, BigNumber.from(1));
    console.log(
      chalk.yellow(
        `Price set by oracle for underlying asset ${underlyingToken.symbol} with tx hash = ${txReceipt.hash}`,
      ),
    );
  }
}
