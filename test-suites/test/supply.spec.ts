import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { SupplyFuncAddr } from "../configs/supplyBorrow";
import {
  GetReserveConfigurationDataFuncAddr,
  PoolConfiguratorSetReserveActiveFuncAddr,
  PoolConfiguratorSetReserveFreezeFuncAddr,
  PoolConfiguratorSetReservePauseFuncAddr,
  PoolConfiguratorSetSupplyCapFuncAddr,
  PoolManager,
} from "../configs/pool";
import {
  ATokenGetTokenAccountAddressFuncAddr,
  getDecimals,
  UnderlyingBalanceOfFuncAddr,
  UnderlyingDecimalsFuncAddr,
  UnderlyingManager,
  UnderlyingMintFuncAddr,
} from "../configs/tokens";

describe("Supply Unit Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateDeposit() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    try {
      await Transaction(aptos, user, SupplyFuncAddr, [dai, 0, user.accountAddress.toString(), 0]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateDeposit() when reserve is not active (revert expected)", async () => {
    const { users, aave } = testEnv;
    const user = users[0];
    const [, , , , , , , isActiveBefore] = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    expect(isActiveBefore).toBe(true);

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, false]);

    const [, , , , , , , isActiveAfter] = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    expect(isActiveAfter).toBe(false);

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, aave);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      aave,
    ]);

    try {
      await Transaction(aptos, user, SupplyFuncAddr, [aave, daiDepositAmount, user.accountAddress.toString(), 0]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, true]);
  });

  it("validateDeposit() when reserve is frozen (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];

    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [dai, true]);
    const [, , , , , , , , isFrozenAfter] = await View(aptos, GetReserveConfigurationDataFuncAddr, [dai]);
    expect(isFrozenAfter).toBe(true);

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    try {
      await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1c")).toBe(true);
    }
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [dai, false]);
  });

  it("validateDeposit() when reserve is paused (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    const user1 = users[1];
    await Transaction(aptos, user1, PoolConfiguratorSetReservePauseFuncAddr, [dai, true]);

    try {
      await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x1d")).toBe(true);
    }
    await Transaction(aptos, user1, PoolConfiguratorSetReservePauseFuncAddr, [dai, false]);
  });

  it("Tries to supply 1001 DAI  (> SUPPLY_CAP) 1 unit above the limit", async () => {
    const { users, dai } = testEnv;
    const user = users[0];

    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1001 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    const newCap = 1000;
    await Transaction(aptos, PoolManager, PoolConfiguratorSetSupplyCapFuncAddr, [dai, newCap]);

    try {
      await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x33")).toBe(true);
    }

    await Transaction(aptos, PoolManager, PoolConfiguratorSetSupplyCapFuncAddr, [dai, 0]);
  });

  it("User 0 deposits 100 DAI ", async () => {
    const { users, dai, aDai } = testEnv;
    const user = users[0];
    // console.log("user:", user.accountAddress.toString());

    const [aTokenResourceAccountAddress] = await View(aptos, ATokenGetTokenAccountAddressFuncAddr, [aDai]);
    const [aTokenAccountBalanceBefore] = await View(aptos, UnderlyingBalanceOfFuncAddr, [
      aTokenResourceAccountAddress as string,
      dai,
    ]);
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 100 * 10 ** daiDecimals;

    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    const [aTokenAccountBalanceAfter] = await View(aptos, UnderlyingBalanceOfFuncAddr, [
      aTokenResourceAccountAddress as string,
      dai,
    ]);

    const aTokenAccountBalance = BigNumber.from(aTokenAccountBalanceBefore).add(daiDepositAmount).toString();
    expect(BigNumber.from(aTokenAccountBalanceAfter).toString()).toBe(aTokenAccountBalance);
  });

  it("User 1 deposits 10 Dai, 10 USDC, user 2 deposits 7 WETH", async () => {
    const {
      dai,
      usdc,
      weth,
      users: [user1, user2],
    } = testEnv;
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const wethDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, weth);

    const daiAmount = 10 * 10 ** daiDecimals;
    const usdcAmount = 10 * 10 ** usdcDecimals;
    const wethAmount = 7 * 10 ** wethDecimals;

    // mint dai
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user2.accountAddress.toString(),
      daiAmount,
      dai,
    ]);
    // mint usdc
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user1.accountAddress.toString(),
      usdcAmount,
      usdc,
    ]);
    // mint weth
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user2.accountAddress.toString(),
      wethAmount.toString(),
      weth,
    ]);

    // deposit dai
    await Transaction(aptos, user2, SupplyFuncAddr, [dai, daiAmount, user2.accountAddress.toString(), 0]);
    // deposit usdc
    await Transaction(aptos, user1, SupplyFuncAddr, [usdc, usdcAmount, user1.accountAddress.toString(), 0]);
    // deposit weth
    await Transaction(aptos, user2, SupplyFuncAddr, [weth, wethAmount, user2.accountAddress.toString(), 0]);
  });
});
