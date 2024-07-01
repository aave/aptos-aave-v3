import { PoolManager, rateStrategyStableTwo, SetReserveInterestRateStrategyFuncAddr } from "../configs/pool";
import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";
import { AAVE, DAI, getMetadataAddress, UnderlyingGetMetadataBySymbolFuncAddr, USDC, WETH } from "../configs/tokens";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initReserveInterestRateStrategy() {
  const params: string[] = [
    rateStrategyStableTwo.optimalUsageRatio,
    rateStrategyStableTwo.baseVariableBorrowRate,
    rateStrategyStableTwo.variableRateSlope1,
    rateStrategyStableTwo.variableRateSlope2,
  ];
  const daiAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  const wethAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);
  const usdcAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  const aaveAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);

  // config dai rate strategy
  let txReceipt = await Transaction(aptos, PoolManager, SetReserveInterestRateStrategyFuncAddr, [
    daiAddress,
    ...params,
  ]);
  console.log(chalk.green(`DAI Reserve Interest rate strategy set with tx hash = ${txReceipt.hash}`));

  // config weth rate strategy
  txReceipt = await Transaction(aptos, PoolManager, SetReserveInterestRateStrategyFuncAddr, [wethAddress, ...params]);
  console.log(chalk.green(`WETH Reserve Interest rate strategy set with tx hash = ${txReceipt.hash}`));

  // config usdc rate strategy
  txReceipt = await Transaction(aptos, PoolManager, SetReserveInterestRateStrategyFuncAddr, [usdcAddress, ...params]);
  console.log(chalk.green(`USDC Reserve Interest rate strategy set with tx hash = ${txReceipt.hash}`));

  // config aave rate strategy
  txReceipt = await Transaction(aptos, PoolManager, SetReserveInterestRateStrategyFuncAddr, [aaveAddress, ...params]);
  console.log(chalk.green(`AAVE Reserve Interest rate strategy set with tx hash = ${txReceipt.hash}`));
}
