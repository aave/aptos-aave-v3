import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";
import { AAVE, DAI, getMetadataAddress, UnderlyingGetMetadataBySymbolFuncAddr, USDC, WETH } from "../configs/tokens";
import { OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initReserveOraclePrice() {
  const daiAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  const wethAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);
  const usdcAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  const aaveAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);

  // config dai price
  let txReceipt = await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [daiAddress, 1]);
  console.log(chalk.green(`DAI price set with tx hash = ${txReceipt.hash}`));

  // config weth price
  txReceipt = await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [wethAddress, 1]);
  console.log(chalk.green(`WETH price set with tx hash = ${txReceipt.hash}`));

  // config usdc price
  txReceipt = await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [usdcAddress, 1]);
  console.log(chalk.green(`USDC price set with tx hash = ${txReceipt.hash}`));

  // config aave price
  txReceipt = await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [aaveAddress, 1]);
  console.log(chalk.green(`AAVE price set with tx hash = ${txReceipt.hash}`));
}
