import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { BorrowFuncAddr, GetUserAccountDataFuncAddr, SupplyFuncAddr, WithdrawFuncAddr } from "../configs/supply_borrow";
import {
  ATokenBalanceOfFuncAddr,
  ATokenScaleBalanceOfFuncAddr,
  getDecimals,
  UnderlyingDecimalsFuncAddr,
  UnderlyingManager,
  UnderlyingMintFuncAddr,
} from "../configs/tokens";
import { GetReserveDataFuncAddr, PoolConfiguratorSetReservePauseFuncAddr } from "../configs/pool";
import "../helpers/wadraymath";
import { GetAssetPriceFuncAddr, OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";

describe("Withdraw Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateWithdraw() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await Transaction(aptos, user, WithdrawFuncAddr, [dai, 0, user.accountAddress.toString()]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateWithdraw() when amount > user balance (revert expected)", async () => {
    const { users, dai, aDai } = testEnv;
    const user = users[0];
    const [scaleUserBalance] = await View(aptos, ATokenScaleBalanceOfFuncAddr, [user.accountAddress.toString(), aDai]);
    const [, , , , , , liquidityIndex, ,] = await View(aptos, GetReserveDataFuncAddr, [dai]);
    const userBalance = BigNumber.from(scaleUserBalance).rayMul(BigNumber.from(liquidityIndex));
    const newUserBalance = userBalance.add(1000000000000000).toString();
    try {
      await Transaction(aptos, user, WithdrawFuncAddr, [dai, newUserBalance, user.accountAddress.toString()]);
    } catch (err) {
      // console.log("err:", err.toString())
      expect(err.toString().includes("validation_logic: 0x20")).toBe(true);
    }
  });

  it("validateWithdraw() when reserve is paused (revert expected)", async () => {
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

    const daiWithdrawAmount = 100 * 10 ** daiDecimals;
    try {
      await Transaction(aptos, user, WithdrawFuncAddr, [dai, daiWithdrawAmount, user.accountAddress.toString()]);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1d")).toBe(true);
    }
    await Transaction(aptos, user1, PoolConfiguratorSetReservePauseFuncAddr, [dai, false]);
  });

  it("validateHFAndLtv() with HF < 1 (revert expected)", async () => {
    const {
      usdc,
      dai,
      users: [user, usdcProvider],
    } = testEnv;

    // set price
    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [usdc, 1]);
    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [dai, 1]);

    // dai mint
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // dai supply
    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    // usdc mint
    const usdcDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, usdc);
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      usdcProvider.accountAddress.toString(),
      usdcDepositAmount,
      usdc,
    ]);

    // usdc supply
    await Transaction(aptos, usdcProvider, SupplyFuncAddr, [
      usdc,
      usdcDepositAmount,
      usdcProvider.accountAddress.toString(),
      0,
    ]);

    const [usdcPrice] = await View(aptos, GetAssetPriceFuncAddr, [usdc]);
    const [, , availableBorrowsBase, , ,] = await View(aptos, GetUserAccountDataFuncAddr, [
      user.accountAddress.toString(),
    ]);
    const amountUSDCToBorrow = ((availableBorrowsBase as number) / (usdcPrice as number)) * 10 ** usdcDecimals;
    // console.log("available_borrows_base:", availableBorrowsBase);
    // console.log("amountUSDCToBorrow:", amountUSDCToBorrow);

    // usdc borrow
    await Transaction(aptos, user, BorrowFuncAddr, [
      usdc,
      user.accountAddress.toString(),
      amountUSDCToBorrow,
      1,
      0,
      true,
    ]);

    const daiWithdrawAmount = 500 * 10 ** usdcDecimals;
    try {
      await Transaction(aptos, user, WithdrawFuncAddr, [dai, daiWithdrawAmount, user.accountAddress.toString()]);
    } catch (err) {
      expect(err.toString().includes("pool_validation: 0x23")).toBe(true);
    }
  });

  it("User 1 deposits 10 Dai Withdraws 1 DAI", async () => {
    const {
      dai,
      aDai,
      users: [user1],
    } = testEnv;
    // dai mint
    const daiDecimals = await getDecimals(UnderlyingDecimalsFuncAddr, dai);
    const daiDepositAmount = 10 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user1.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // dai supply
    await Transaction(aptos, user1, SupplyFuncAddr, [dai, daiDepositAmount, user1.accountAddress.toString(), 0]);

    const [aDaiBalanceBefore] = await View(aptos, ATokenBalanceOfFuncAddr, [user1.accountAddress.toString(), aDai]);
    const withdrawnAmount = 10 ** daiDecimals;
    await Transaction(aptos, user1, WithdrawFuncAddr, [dai, withdrawnAmount, user1.accountAddress.toString()]);

    const [aDaiBalanceAfter] = await View(aptos, ATokenBalanceOfFuncAddr, [user1.accountAddress.toString(), aDai]);
    expect(aDaiBalanceAfter).toBe(((aDaiBalanceBefore as number) - withdrawnAmount).toString());
  });
});
