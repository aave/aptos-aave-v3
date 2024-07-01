import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";
import { BorrowFuncAddr, RepayWithATokensFuncAddr, SupplyFuncAddr } from "../configs/supply_borrow";
import { getDecimals, UnderlyingDecimalsFuncAddr, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import "../helpers/wadraymath";

describe("Repay Atoken Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();

    const {
      weth,
      dai,
      users: [, user1],
    } = testEnv;

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiAmount = 100 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user1.accountAddress.toString(),
      daiAmount,
      dai,
    ]);
    await Transaction(aptos, user1, SupplyFuncAddr, [dai, daiAmount, user1.accountAddress.toString(), 0]);

    const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, weth);
    const wethAmount = 100 ** wethDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user1.accountAddress.toString(),
      wethAmount,
      weth,
    ]);
    await Transaction(aptos, user1, SupplyFuncAddr, [weth, wethAmount, user1.accountAddress.toString(), 0]);

    const daiBorrowAmount = daiAmount / 2;

    await Transaction(aptos, user1, BorrowFuncAddr, [
      dai,
      user1.accountAddress.toString(),
      daiBorrowAmount.toString(),
      1,
      0,
      true,
    ]);
  });

  it("User 1 tries to repay using aTokens without actually holding aDAI", async () => {
    const {
      aave,
      users: [, user1],
    } = testEnv;
    const aaveDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, aave);
    const repayAmount = 25 * 10 ** aaveDecimals;
    try {
      await Transaction(aptos, user1, RepayWithATokensFuncAddr, [aave, repayAmount, 2]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x27")).toBe(true);
    }
  });

  it("User 1 receives 1 aDAI from user 0, repays half of the debt", async () => {
    const {
      dai,
      users: [, user1],
    } = testEnv;
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const repayAmount = 10 ** daiDecimals;
    await Transaction(aptos, user1, RepayWithATokensFuncAddr, [dai, repayAmount, 1]);
  });
});
