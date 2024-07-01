import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { PoolManager, PoolManagerAccountAddress, PoolRescueTokensFuncAddr } from "../configs/pool";
import {
  ATokenRescueTokensFuncAddr,
  getDecimals,
  UnderlyingBalanceOfFuncAddr,
  UnderlyingDecimalsFuncAddr,
  UnderlyingManager,
  UnderlyingMintFuncAddr,
} from "../configs/tokens";

describe("Rescue tokens", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("User tries to rescue tokens from Pool (revert expected)", async () => {
    const {
      usdc,
      users: [rescuer],
    } = testEnv;
    const amount = 1;
    try {
      await Transaction(aptos, rescuer, PoolRescueTokensFuncAddr, [usdc, rescuer.accountAddress.toString(), amount]);
    } catch (err) {
      expect(err.toString().includes("pool: 0x1")).toBe(true);
    }
  });

  it("PoolAdmin rescue tokens from Pool", async () => {
    const {
      usdc,
      users: [locker],
    } = testEnv;
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcAmount = 10 * 10 ** usdcDecimals;
    // mint usdc
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [PoolManagerAccountAddress, usdcAmount, usdc]);

    const [lockerBalanceBefore] = await View(aptos, UnderlyingBalanceOfFuncAddr, [
      locker.accountAddress.toString(),
      usdc,
    ]);
    const [poolManagerBalanceBefore] = await View(aptos, UnderlyingBalanceOfFuncAddr, [
      PoolManagerAccountAddress,
      usdc,
    ]);

    await Transaction(aptos, PoolManager, PoolRescueTokensFuncAddr, [
      usdc,
      locker.accountAddress.toString(),
      usdcAmount,
    ]);

    const [lockerBalanceAfter] = await View(aptos, UnderlyingBalanceOfFuncAddr, [
      locker.accountAddress.toString(),
      usdc,
    ]);
    expect(BigNumber.from(lockerBalanceBefore).toString()).toBe(
      BigNumber.from(lockerBalanceAfter).sub(usdcAmount).toString(),
    );

    const [poolManagerBalanceAfter] = await View(aptos, UnderlyingBalanceOfFuncAddr, [PoolManagerAccountAddress, usdc]);
    expect(BigNumber.from(poolManagerBalanceBefore).toString()).toBe(
      BigNumber.from(poolManagerBalanceAfter).add(usdcAmount).toString(),
    );
  });

  it("User tries to rescue tokens from AToken (revert expected)", async () => {
    const {
      aDai,
      users: [rescuer],
    } = testEnv;
    const amount = 1;
    try {
      await Transaction(aptos, rescuer, ATokenRescueTokensFuncAddr, [aDai, rescuer.accountAddress.toString(), amount]);
    } catch (err) {
      expect(err.toString().includes("token_base: ENOT_OWNER(0x1)")).toBe(true);
    }
  });

  it("User tries to rescue tokens of underlying from AToken (revert expected)", async () => {
    const {
      dai,
      users: [rescuer],
    } = testEnv;
    const amount = 1;
    try {
      await Transaction(aptos, rescuer, ATokenRescueTokensFuncAddr, [dai, rescuer.accountAddress.toString(), amount]);
    } catch (err) {
      expect(err.toString().includes("token_base: ENOT_OWNER(0x1)")).toBe(true);
    }
  });

  it("PoolAdmin tries to rescue tokens of underlying from AToken (revert expected)", async () => {
    const {
      dai,
      users: [rescuer],
    } = testEnv;
    const amount = 1;
    try {
      await Transaction(aptos, PoolManager, ATokenRescueTokensFuncAddr, [
        dai,
        rescuer.accountAddress.toString(),
        amount,
      ]);
    } catch (err) {
      expect(err.toString().includes("error: Execution failed")).toBe(true);
    }
  });
});
