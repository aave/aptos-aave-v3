/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */
import { BigNumber } from "ethers";
import { PoolManager } from "../configs/pool";
import { AptosProvider } from "../wrappers/aptosProvider";
import { PoolClient } from "../clients/poolClient";
import { aTokens, underlyingTokens, varTokens } from "./createTokens";
import { ATokensClient } from "../clients/aTokensClient";
import { VariableTokensClient } from "../clients/variableTokensClient";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initReserves() {
  // global aptos provider
  const aptosProvider = new AptosProvider();
  const poolClient = new PoolClient(aptosProvider, PoolManager);
  const aTokensClient = new ATokensClient(aptosProvider);
  const varTokensClient = new VariableTokensClient(aptosProvider);

  // create reserves input data
  const underlyingAssets = underlyingTokens.map((token) => token.accountAddress);
  const underlyingAssetDecimals = underlyingTokens.map((token) => BigNumber.from(token.decimals).toNumber());
  const treasuries = underlyingTokens.map((token) => token.treasury);
  const aTokenNames = aTokens.map((token) => token.name);
  const aTokenSymbols = aTokens.map((token) => token.symbol);
  const varTokenNames = varTokens.map((token) => token.name);
  const varTokenSymbols = varTokens.map((token) => token.symbol);

  // init reserves
  const txReceipt = await poolClient.initReserves(
    underlyingAssets,
    underlyingAssetDecimals,
    treasuries,
    aTokenNames,
    aTokenSymbols,
    varTokenNames,
    varTokenSymbols,
  );
  console.log(chalk.yellow("Reserves set with tx hash", txReceipt.hash));

  // reserve atokens
  for (const [, aToken] of aTokens.entries()) {
    const aTokenMetadataAddress = await aTokensClient.getMetadataBySymbol(PoolManager.accountAddress, aToken.symbol);
    console.log(chalk.yellow(`${aToken.symbol} atoken metadata address: `, aTokenMetadataAddress.toString()));
    aToken.metadataAddress = aTokenMetadataAddress;

    const aTokenAddress = await aTokensClient.getTokenAddress(PoolManager.accountAddress, aToken.symbol);
    console.log(chalk.yellow(`${aToken.symbol} atoken account address: `, aTokenAddress.toString()));
    aToken.accountAddress = aTokenAddress;
  }

  // reserve var debt tokens
  for (const [, varToken] of varTokens.entries()) {
    const varTokenMetadataAddress = await varTokensClient.getMetadataBySymbol(
      PoolManager.accountAddress,
      varToken.symbol,
    );
    console.log(
      chalk.yellow(`${varToken.symbol} var debt token metadata address: `, varTokenMetadataAddress.toString()),
    );
    varToken.metadataAddress = varTokenMetadataAddress;

    const varTokenAddress = await varTokensClient.getTokenAddress(PoolManager.accountAddress, varToken.symbol);
    console.log(chalk.yellow(`${varToken.symbol} var debt token account address: `, varTokenAddress.toString()));
    varToken.accountAddress = varTokenAddress;
  }
}
