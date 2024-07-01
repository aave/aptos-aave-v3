import { Transaction } from "../helpers/helper";
import { PoolConfiguratorAddReservesFuncAddr, PoolManager } from "../configs/pool";
import {
  AAAVE,
  AAVE,
  ADAI,
  ATokenGetMetadataBySymbolFuncAddr,
  AUSDC,
  AWETH,
  DAI,
  getDecimals,
  getMetadataAddress,
  UnderlyingDecimalsFuncAddr,
  UnderlyingGetMetadataBySymbolFuncAddr,
  USDC,
  VAAVE,
  VariableGetMetadataBySymbolFuncAddr,
  VDAI,
  VUSDC,
  VWETH,
  WETH,
} from "../configs/tokens";
import { aptos } from "../configs/common";
import { AclManager, AddPoolAdminFuncAddr } from "../configs/acl_manage";
import { getAccounts, testEnv } from "../configs/config";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

async function getTokenInfo() {
  // underlying tokens
  const underlying = [];
  const decimals = [];
  const daiAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, daiAddress);
  underlying.push(daiAddress);
  decimals.push(daiDecimals);

  const wethAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);
  const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, wethAddress);
  underlying.push(wethAddress);
  decimals.push(wethDecimals);

  const usdcAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdcAddress);
  underlying.push(usdcAddress);
  decimals.push(usdcDecimals);

  const aaveAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);
  const aaveDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, aaveAddress);
  underlying.push(aaveAddress);
  decimals.push(aaveDecimals);

  // a tokens
  const aTokens = [];
  const adaiAddress = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, ADAI);
  const awethAddress = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AWETH);
  const ausdcAddress = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AUSDC);
  const aaaveAddress = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AAAVE);
  aTokens.push(adaiAddress);
  aTokens.push(awethAddress);
  aTokens.push(ausdcAddress);
  aTokens.push(aaaveAddress);

  // v tokens
  const vTokens = [];
  const vdaiAddress = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VDAI);
  const vwethAddress = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VWETH);
  const vusdcAddress = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VUSDC);
  const vaaveAddress = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VAAVE);
  vTokens.push(vdaiAddress);
  vTokens.push(vwethAddress);
  vTokens.push(vusdcAddress);
  vTokens.push(vaaveAddress);

  return {
    underlyingTokens: underlying,
    aTokens,
    vTokens,
    decimals,
  };
}

export async function addReserves() {
  // step1. get token info
  const { underlyingTokens, aTokens, vTokens, decimals } = await getTokenInfo();
  const userAccounts = await getAccounts();

  // step2. Add pool admin
  let txReceipt = await Transaction(aptos, AclManager, AddPoolAdminFuncAddr, [PoolManager.accountAddress.toString()]);
  console.log(chalk.green(`Pool admin added with tx hash = ${txReceipt.hash}`));

  // step3. Add the reserve
  txReceipt = await Transaction(aptos, PoolManager, PoolConfiguratorAddReservesFuncAddr, [
    aTokens,
    vTokens,
    decimals,
    underlyingTokens,
  ]);
  console.log(chalk.green(`Reserves added in batch to pool with tx hash = ${txReceipt.hash}`));
}
