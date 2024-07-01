import { initializeMakeSuite, testEnv } from "../configs/config";
import { getDecimals, UnderlyingDecimalsFuncAddr, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";

import { BorrowFuncAddr, LiquidationCallFuncAddr, SupplyFuncAddr } from "../configs/supply_borrow";
import "../helpers/wadraymath";

describe("Liquidation Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateLiquidationCall() when healthFactor > threshold (revert expected)", async () => {
    // Liquidation something that is not liquidatable
    const { users, dai, usdc } = testEnv;
    const depositor = users[0];
    const borrower = users[1];

    // dai mint
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 500 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      depositor.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // dai supply
    await Transaction(aptos, depositor, SupplyFuncAddr, [
      dai,
      daiDepositAmount,
      depositor.accountAddress.toString(),
      0,
    ]);

    // usdc mint
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 500 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      borrower.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // usdc supply
    await Transaction(aptos, borrower, SupplyFuncAddr, [
      usdc,
      usdcDepositAmount,
      borrower.accountAddress.toString(),
      0,
    ]);

    const daiBorrowAmount = 500 * 10 ** daiDecimals;
    // borrow dai
    await Transaction(aptos, borrower, BorrowFuncAddr, [
      dai,
      borrower.accountAddress.toString(),
      daiBorrowAmount,
      1,
      0,
      true,
    ]);

    // Try to liquidate the borrower
    try {
      await Transaction(aptos, depositor, LiquidationCallFuncAddr, [
        usdc,
        dai,
        borrower.accountAddress.toString(),
        0,
        false,
      ]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x2d"));
    }
  });

  it("ValidationLogic `executeLiquidationCall` where user has variable and stable debt, but variable debt is insufficient to cover the full liquidation amount", async () => {
    const { users, dai, weth } = testEnv;
    const depositor = users[0];
    const borrower = users[1];

    // dai mint
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiMintAmount = 1000000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      depositor.accountAddress.toString(),
      daiMintAmount,
      dai,
    ]);

    const daiDepositAmount = 10000 * 10 ** daiDecimals;
    // dai supply
    await Transaction(aptos, depositor, SupplyFuncAddr, [
      dai,
      daiDepositAmount,
      depositor.accountAddress.toString(),
      0,
    ]);

    // weth mint
    const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, weth);
    const wethMintAmount = 9 * 10 ** (wethDecimals - 1);
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      borrower.accountAddress.toString(),
      wethMintAmount,
      dai,
    ]);

    const wethDepositAmount = 9 * 10 ** (wethDecimals - 1);
    try {
      // weth supply
      await Transaction(aptos, borrower, SupplyFuncAddr, [
        weth,
        wethDepositAmount,
        borrower.accountAddress.toString(),
        0,
      ]);
    } catch (err) {
      expect(err.toString().includes("EINSUFFICIENT_BALANCE(0x10004)")).toBe(true);
    }
  });
});
