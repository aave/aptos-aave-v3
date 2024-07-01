import * as dotenv from "dotenv";
import { aptos } from "../configs/common";

import { Transaction } from "../helpers/helper";
import {
  PoolConfiguratorReservesFuncAddr,
  PoolManager,
  strategyAAVE,
  strategyDAI,
  strategyUSDC,
  strategyWETH,
} from "../configs/pool";
import { AAVE, DAI, getMetadataAddress, UnderlyingGetMetadataBySymbolFuncAddr, USDC, WETH } from "../configs/tokens";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

dotenv.config();

async function getReserveInfo() {
  // get assets address
  const assets = [];
  const dai = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  const weth = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);
  const usdc = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  const aave = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);
  assets.push(dai);
  assets.push(weth);
  assets.push(usdc);
  assets.push(aave);

  // get assets base ltv
  const baseLtv = [];
  baseLtv.push(strategyDAI.baseLTVAsCollateral);
  baseLtv.push(strategyWETH.baseLTVAsCollateral);
  baseLtv.push(strategyUSDC.baseLTVAsCollateral);
  baseLtv.push(strategyAAVE.baseLTVAsCollateral);

  // get assets liquidation threshold
  const liquidationThreshold = [];
  liquidationThreshold.push(strategyDAI.liquidationThreshold);
  liquidationThreshold.push(strategyWETH.liquidationThreshold);
  liquidationThreshold.push(strategyUSDC.liquidationThreshold);
  liquidationThreshold.push(strategyAAVE.liquidationThreshold);

  // get assets liquidation bonus
  const liquidationBonus = [];
  liquidationBonus.push(strategyDAI.liquidationBonus);
  liquidationBonus.push(strategyWETH.liquidationBonus);
  liquidationBonus.push(strategyUSDC.liquidationBonus);
  liquidationBonus.push(strategyAAVE.liquidationBonus);

  // reserve_factor
  const reserveFactor = [];
  reserveFactor.push(strategyDAI.reserveFactor);
  reserveFactor.push(strategyWETH.reserveFactor);
  reserveFactor.push(strategyUSDC.reserveFactor);
  reserveFactor.push(strategyAAVE.reserveFactor);

  // borrow_cap
  const borrowCap = [];
  borrowCap.push(strategyDAI.borrowCap);
  borrowCap.push(strategyWETH.borrowCap);
  borrowCap.push(strategyUSDC.borrowCap);
  borrowCap.push(strategyAAVE.borrowCap);

  // supply_cap
  const supplyCap = [];
  supplyCap.push(strategyDAI.supplyCap);
  supplyCap.push(strategyWETH.supplyCap);
  supplyCap.push(strategyUSDC.supplyCap);
  supplyCap.push(strategyAAVE.supplyCap);

  // borrowing_enabled
  const borrowingEnabled = [];
  borrowingEnabled.push(strategyDAI.borrowingEnabled);
  borrowingEnabled.push(strategyWETH.borrowingEnabled);
  borrowingEnabled.push(strategyUSDC.borrowingEnabled);
  borrowingEnabled.push(strategyAAVE.borrowingEnabled);

  // flash_loan_enabled
  const flashLoanEnabled = [];
  flashLoanEnabled.push(strategyDAI.flashLoanEnabled);
  flashLoanEnabled.push(strategyWETH.flashLoanEnabled);
  flashLoanEnabled.push(strategyUSDC.flashLoanEnabled);
  flashLoanEnabled.push(strategyAAVE.flashLoanEnabled);

  return {
    assets,
    baseLtv,
    liquidationThreshold,
    liquidationBonus,
    reserveFactor,
    borrowCap,
    supplyCap,
    borrowingEnabled,
    flashLoanEnabled,
  };
}

export async function configReserves() {
  const {
    assets,
    baseLtv,
    liquidationThreshold,
    liquidationBonus,
    reserveFactor,
    borrowCap,
    supplyCap,
    borrowingEnabled,
    flashLoanEnabled,
  } = await getReserveInfo();

  // configure the reserve
  const txReceipt = await Transaction(aptos, PoolManager, PoolConfiguratorReservesFuncAddr, [
    assets,
    baseLtv,
    liquidationThreshold,
    liquidationBonus,
    reserveFactor,
    borrowCap,
    supplyCap,
    borrowingEnabled,
    flashLoanEnabled,
  ]);
  console.log(chalk.green(`Reserve configured with tx hash = ${txReceipt.hash}`));
}
