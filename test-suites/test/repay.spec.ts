import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { BorrowFuncAddr, RepayFuncAddr, SupplyFuncAddr } from "../configs/supplyBorrow";
import { getDecimals, UnderlyingDecimalsFuncAddr, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import {
  GetReserveConfigurationDataFuncAddr,
  PoolConfiguratorSetReserveActiveFuncAddr,
  PoolManager,
} from "../configs/pool";

describe("Repay Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateRepay() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await Transaction(aptos, user, RepayFuncAddr, [dai, 0, 1, user.accountAddress.toString(), false]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateRepay() when reserve is not active (revert expected)", async () => {
    const { users, aave, usdc } = testEnv;
    const user = users[0];

    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);
    // usdc supply
    await Transaction(aptos, user, SupplyFuncAddr, [usdc, usdcDepositAmount, user.accountAddress.toString(), 0]);

    const [, , , , , , , isActiveBefore] = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    expect(isActiveBefore).toBe(true);

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, false]);

    const [, , , , , , , isActiveAfter] = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    expect(isActiveAfter).toBe(false);

    const aaveDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, aave);
    const aaveDepositAmount = 1000 * 10 ** aaveDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      aaveDepositAmount,
      aave,
    ]);

    try {
      await Transaction(aptos, user, RepayFuncAddr, [
        aave,
        aaveDepositAmount,
        1,
        user.accountAddress.toString(),
        false,
      ]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, true]);
  });

  it("validateRepay() the variable debt when is 0  (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[5];

    // console.log("user:", user.accountAddress.toString());
    // dai mint
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 2000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);
    // dai supply
    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    // usdc mint
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 2000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);
    // dai supply
    await Transaction(aptos, user, SupplyFuncAddr, [usdc, usdcDepositAmount, user.accountAddress.toString(), 0]);

    const userBorrowAmount = 250 * 10 ** daiDecimals;
    // user borrow dai
    await Transaction(aptos, user, BorrowFuncAddr, [dai, user.accountAddress.toString(), userBorrowAmount, 1, 0, true]);

    try {
      await Transaction(aptos, user, RepayFuncAddr, [dai, userBorrowAmount, 2, user.accountAddress.toString(), false]);
    } catch (err) {
      // console.log('err:', err.toString())
      expect(err.toString().includes("validation_logic: 0x27")).toBe(true);
    }
  });

  it("User 1 tries to repay using actually holding aUsdc", async () => {
    const {
      usdc,
      users: [, , , user1],
    } = testEnv;
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const repayAmount = 2 * 10 ** usdcDecimals;
    // console.log("user1:", user1.accountAddress.toString());
    try {
      await Transaction(aptos, user1, RepayFuncAddr, [usdc, repayAmount, 1, user1.accountAddress.toString(), false]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x27")).toBe(true);
    }
  });
});
