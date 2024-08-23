import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { getDecimals, UnderlyingDecimalsFuncAddr, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { BorrowFuncAddr, SupplyFuncAddr } from "../configs/supplyBorrow";
import {
  GetReserveConfigurationDataFuncAddr,
  GetUserReserveDataFuncAddr,
  PoolConfiguratorSetEmodeCategoryFuncAddr,
  PoolConfiguratorSetReserveActiveFuncAddr,
  PoolConfiguratorSetReserveBorrowingFuncAddr,
  PoolConfiguratorSetReserveFreezeFuncAddr,
  PoolManager,
  PoolSetUserEmodeFuncAddr,
} from "../configs/pool";
import { GetAssetPriceFuncAddr, OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";
import { ZERO_ADDRESS } from "../helpers/constants";

describe("Borrow Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateBorrow() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await Transaction(aptos, user, BorrowFuncAddr, [dai, user.accountAddress.toString(), 0, 1, 0, true]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateBorrow() when reserve is not active (revert expected)", async () => {
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
      await Transaction(aptos, user, BorrowFuncAddr, [
        aave,
        user.accountAddress.toString(),
        aaveDepositAmount,
        1,
        0,
        true,
      ]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, true]);
  });

  it("validateBorrow() when reserve is frozen (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[0];

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    // console.log('user Address:', user.accountAddress.toString())
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // deposit usdc
    await Transaction(aptos, user, SupplyFuncAddr, [usdc, usdcDepositAmount, user.accountAddress.toString(), 0]);

    const [, , , , , , , isActiveBefore, isFrozenBefore] = await View(aptos, GetReserveConfigurationDataFuncAddr, [
      dai,
    ]);
    expect(isActiveBefore).toBe(true);
    expect(isFrozenBefore).toBe(false);

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [dai, true]);
    const [, , , , , , , isActiveAfter, isFrozenAfter] = await View(aptos, GetReserveConfigurationDataFuncAddr, [dai]);
    expect(isActiveAfter).toBe(true);
    expect(isFrozenAfter).toBe(true);

    try {
      await Transaction(aptos, user, BorrowFuncAddr, [
        dai,
        user.accountAddress.toString(),
        daiDepositAmount,
        1,
        0,
        true,
      ]);
    } catch (err) {
      // console.log('err:', err.toString())
      expect(err.toString().includes("validation_logic: 0x1c")).toBe(true);
    }
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [dai, false]);
  });

  it("validateBorrow() when borrowing is not enabled (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[0];

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);
    // deposit dai
    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // deposit usdc
    await Transaction(aptos, user, SupplyFuncAddr, [usdc, usdcDepositAmount, user.accountAddress.toString(), 0]);

    // Disable borrowing
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveBorrowingFuncAddr, [dai, false]);

    const [, , , , , , borrowingEnabledAfter, ,] = await View(aptos, GetReserveConfigurationDataFuncAddr, [dai]);
    expect(borrowingEnabledAfter).toBe(false);

    try {
      await Transaction(aptos, user, BorrowFuncAddr, [
        dai,
        user.accountAddress.toString(),
        daiDepositAmount,
        1,
        0,
        true,
      ]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1e")).toBe(true);
    }
    // Enable borrowing
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveBorrowingFuncAddr, [dai, true]);
  });

  it("validateBorrow() borrowing when user has already a HF < threshold", async () => {
    const { users, dai, usdc } = testEnv;
    const user = users[0];
    const depositor = users[1];

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 2000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      depositor.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // deposit dai
    await Transaction(aptos, depositor, SupplyFuncAddr, [
      dai,
      daiDepositAmount,
      depositor.accountAddress.toString(),
      0,
    ]);

    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 2000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // deposit usdc
    await Transaction(aptos, user, SupplyFuncAddr, [usdc, usdcDepositAmount, user.accountAddress.toString(), 0]);

    const borrowAmount = 1000 * 10 ** daiDecimals;
    // user borrow dai
    await Transaction(aptos, user, BorrowFuncAddr, [dai, user.accountAddress.toString(), borrowAmount, 1, 0, true]);

    const [daiPrice] = await View(aptos, GetAssetPriceFuncAddr, [dai]);

    // The oracle sets the price of dai
    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [dai, (daiPrice as number) * 2]);

    const userBorrowDaiAmount = 200 * 10 ** daiDecimals;
    try {
      await Transaction(aptos, user, BorrowFuncAddr, [
        dai,
        user.accountAddress.toString(),
        userBorrowDaiAmount,
        1,
        0,
        true,
      ]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("pool_validation: 0x24")).toBe(true);
    }
  });

  it("validateBorrow() with eMode > 0, borrowing asset not in category (revert expected)", async () => {
    const {
      users: [user, usdcProvider],
      dai,
      usdc,
    } = testEnv;

    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      usdcProvider.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);
    // deposit usdc
    await Transaction(aptos, usdcProvider, SupplyFuncAddr, [
      usdc,
      usdcDepositAmount,
      usdcProvider.accountAddress.toString(),
      0,
    ]);

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // deposit dai
    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    // set EMode Category
    await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
      101,
      9800,
      9900,
      10100,
      ZERO_ADDRESS,
      "NO-ASSETS",
    ]);

    const userBorrowDaiAmount = 100 * 10 ** daiDecimals;
    try {
      // set User EMode
      await Transaction(aptos, user, PoolSetUserEmodeFuncAddr, [101]);
      await Transaction(aptos, user, BorrowFuncAddr, [
        dai,
        user.accountAddress.toString(),
        userBorrowDaiAmount,
        1,
        0,
        true,
      ]);
    } catch (err) {
      // console.log('err:', err.toString())
      expect(err.toString().includes("pool_validation: 0x3a")).toBe(true);
    }
  });

  it("User 2 supplies WETH,and borrows DAI", async () => {
    const {
      dai,
      weth,
      users: [, borrower],
    } = testEnv;

    const [currentATokenBalanceBefore, , , ,] = await View(aptos, GetUserReserveDataFuncAddr, [
      weth,
      borrower.accountAddress.toString(),
    ]);

    const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, weth);
    const wethDepositAmount = 2000 * 10 ** wethDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      borrower.accountAddress.toString(),
      wethDepositAmount,
      weth,
    ]);
    // deposit weth
    await Transaction(aptos, borrower, SupplyFuncAddr, [
      weth,
      wethDepositAmount,
      borrower.accountAddress.toString(),
      0,
    ]);

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      borrower.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);
    // deposit dai
    await Transaction(aptos, borrower, SupplyFuncAddr, [dai, daiDepositAmount, borrower.accountAddress.toString(), 0]);

    // Borrow DAI
    const firstDaiBorrow = 50 * 10 ** daiDecimals;
    await Transaction(aptos, borrower, BorrowFuncAddr, [
      dai,
      borrower.accountAddress.toString(),
      firstDaiBorrow,
      1,
      0,
      true,
    ]);

    const [currentATokenBalance, , , ,] = await View(aptos, GetUserReserveDataFuncAddr, [
      weth,
      borrower.accountAddress.toString(),
    ]);

    const accountBalance = BigNumber.from(currentATokenBalanceBefore).add(wethDepositAmount).toString();
    expect(BigNumber.from(currentATokenBalance).toString()).toBe(accountBalance);
  });
});
