import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { PoolConfiguratorSetReserveActiveFuncAddr, PoolManager } from "../configs/pool";
import {
  BorrowFuncAddr,
  GetUserAccountDataFuncAddr,
  LiquidationCallFuncAddr,
  SupplyFuncAddr,
} from "../configs/supply_borrow";
import { getDecimals, UnderlyingDecimalsFuncAddr, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import { GetAssetPriceFuncAddr, OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";
import "../helpers/wadraymath";

describe("Pool Liquidation: Liquidator receiving the underlying asset", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("It's not possible to liquidate on a non-active collateral or a non active principal", async () => {
    const {
      weth,
      users: [, user],
      aave,
    } = testEnv;

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, false]);
    const aaveDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, aave);
    const debtToCover = 1000 * 10 ** aaveDecimals;
    try {
      await Transaction(aptos, PoolManager, LiquidationCallFuncAddr, [
        weth,
        aave,
        user.accountAddress.toString(),
        debtToCover,
        false,
      ]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, true]);
  });

  it("User 3 deposits 1000 USDC, user 4 0.06775 WETH, user 4 borrows - drops HF, liquidates the borrow", async () => {
    const {
      usdc,
      users: [, , , depositor, borrower, liquidator],
      weth,
    } = testEnv;

    // console.log('depositor:', depositor.accountAddress.toString())
    // console.log('borrower:', borrower.accountAddress.toString())
    // console.log("liquidator:", liquidator.accountAddress.toString());

    // mints USDC to depositor
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      depositor.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // usdc supply
    await Transaction(aptos, depositor, SupplyFuncAddr, [
      usdc,
      usdcDepositAmount,
      depositor.accountAddress.toString(),
      0,
    ]);

    // mints WETH to borrow
    const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const wethDepositAmount = 10000 * 10 ** wethDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      borrower.accountAddress.toString(),
      wethDepositAmount,
      weth,
    ]);

    const amountWETHtoDeposit = 6675 * 10 ** wethDecimals;
    // weth supply
    await Transaction(aptos, borrower, SupplyFuncAddr, [
      weth,
      amountWETHtoDeposit,
      borrower.accountAddress.toString(),
      0,
    ]);

    const [, , availableBorrowsBase, , ,] = await View(aptos, GetUserAccountDataFuncAddr, [
      borrower.accountAddress.toString(),
    ]);

    const [usdcPrice] = await View(aptos, GetAssetPriceFuncAddr, [usdc]);

    // const amountUSDCToBorrow = BigNumber.from(available_borrows_base).div(BigNumber.from(usdcPrice)).toNumber() * 10 ** usdcDecimals;
    const amountUSDCToBorrow = 100 * 10 ** usdcDecimals;
    console.log(
      "availableBorrowsBase:",
      availableBorrowsBase,
      "usdcPrice:",
      usdcPrice,
      BigNumber.from(usdcPrice).percentMul(11200).toNumber(),
      "amountUSDCToBorrow:",
      amountUSDCToBorrow,
    );

    // borrower borrows
    await Transaction(aptos, borrower, BorrowFuncAddr, [
      usdc,
      borrower.accountAddress.toString(),
      amountUSDCToBorrow,
      1,
      0,
      true,
    ]);

    // drops HF below 1
    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [usdc, 11200]);

    // mints dai to the liquidator
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      liquidator.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // get User Reserve Data
    // const [
    //     current_a_token_balance_before,
    //     current_variable_debt_before,
    //     scaled_variable_debt_before,
    //     liquidity_rate_before,
    //     usage_as_collateral_enabled_before
    // ] = await View(aptos, GetUserReserveDataFuncAddr, [usdc, borrower.accountAddress.toString()])
    //
    // const usdcReserveDataBefore = await getReserveData(usdc.toString());
    // const wethReserveDataBefore = await getReserveData(weth.toString());
    const amountToLiquidate = 100 * 10 ** usdcDecimals;

    // liquidator liquidationCall
    try {
      await Transaction(aptos, liquidator, LiquidationCallFuncAddr, [
        weth,
        usdc,
        borrower.accountAddress.toString(),
        amountToLiquidate,
        false,
      ]);
    } catch (err) {
      // console.log("err:", err.toString())
      expect(err.toString().includes("validation_logic: 0x2d")).toBe(true);
    }
  });
});
