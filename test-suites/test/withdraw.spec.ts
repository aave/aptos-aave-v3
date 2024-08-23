import { BigNumber } from "@ethersproject/bignumber";
import { Ed25519Account } from "@aptos-labs/ts-sdk";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  BorrowFuncAddr,
  GetUserAccountDataFuncAddr,
  SupplyBorrowManager,
  SupplyFuncAddr,
  WithdrawFuncAddr,
} from "../configs/supplyBorrow";
import { ATokenManager, UnderlyingManager, UnderlyingMintFuncAddr } from "../configs/tokens";
import { PoolManager } from "../configs/pool";
import "../helpers/wadraymath";
import { GetAssetPriceFuncAddr, OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";
import { CoreClient } from "../clients/coreClient";
import { AptosProvider } from "../wrappers/aptosProvider";
import { ATokensClient } from "../clients/aTokensClient";
import { UnderlyingTokensClient } from "../clients/underlyingTokensClient";
import { PoolClient } from "../clients/poolClient";

const aptosProvider = new AptosProvider();
let coreClient: CoreClient;
let aTokensClient: ATokensClient;
let underlyingTokensClient: UnderlyingTokensClient;
let poolClient: PoolClient;

describe("Withdraw Test", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
    coreClient = new CoreClient(aptosProvider, SupplyBorrowManager);
    aTokensClient = new ATokensClient(aptosProvider, ATokenManager);
    underlyingTokensClient = new UnderlyingTokensClient(aptosProvider, UnderlyingManager);
    poolClient = new PoolClient(aptosProvider, PoolManager);
  });

  it("validateWithdraw() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      coreClient.setSigner(user as Ed25519Account);
      await coreClient.withdraw(dai, BigNumber.from(0), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateWithdraw() when amount > user balance (revert expected)", async () => {
    const { users, dai, aDai } = testEnv;
    const user = users[0];
    const scaleUserBalance = await aTokensClient.scaledBalanceOf(user.accountAddress, aDai);
    const { reserveLiquidityIndex } = await poolClient.getReserveData2(dai);
    const userBalance = scaleUserBalance.rayMul(BigNumber.from(reserveLiquidityIndex));
    const newUserBalance = userBalance.add(1000000000000000);
    try {
      coreClient.setSigner(user as Ed25519Account);
      await coreClient.withdraw(dai, newUserBalance, user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x20")).toBe(true);
    }
  });

  it("validateWithdraw() when reserve is paused (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    const daiDecimals = (await underlyingTokensClient.decimals(dai)).toNumber();
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    await underlyingTokensClient.mint(user.accountAddress, BigNumber.from(daiDepositAmount), dai);

    const user1 = users[1];

    coreClient.setSigner(user1 as Ed25519Account);
    await poolClient.setReservePause(dai, true);

    const daiWithdrawAmount = 100 * 10 ** daiDecimals;
    try {
      coreClient.setSigner(user as Ed25519Account);
      await coreClient.withdraw(dai, BigNumber.from(daiWithdrawAmount), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1d")).toBe(true);
    }

    coreClient.setSigner(user1 as Ed25519Account);
    await poolClient.setReservePause(dai, false);
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
    const daiDecimals = (await underlyingTokensClient.decimals(dai)).toNumber();
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // dai supply
    await Transaction(aptos, user, SupplyFuncAddr, [dai, daiDepositAmount, user.accountAddress.toString(), 0]);

    // usdc mint
    const usdcDecimals = (await underlyingTokensClient.decimals(usdc)).toNumber();
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
    const daiDecimals = (await underlyingTokensClient.decimals(dai)).toNumber();
    const daiDepositAmount = 10 * 10 ** daiDecimals;
    await Transaction(aptos, UnderlyingManager, UnderlyingMintFuncAddr, [
      user1.accountAddress.toString(),
      daiDepositAmount,
      dai,
    ]);

    // dai supply
    await Transaction(aptos, user1, SupplyFuncAddr, [dai, daiDepositAmount, user1.accountAddress.toString(), 0]);

    const aDaiBalanceBefore = await aTokensClient.scaledBalanceOf(user1.accountAddress, aDai);
    const withdrawnAmount = 10 ** daiDecimals;
    coreClient.setSigner(user1);
    await coreClient.withdraw(dai, BigNumber.from(withdrawnAmount), user1.accountAddress);

    const aDaiBalanceAfter = await aTokensClient.scaledBalanceOf(user1.accountAddress, aDai);
    expect(aDaiBalanceAfter.toString()).toBe(aDaiBalanceBefore.sub(withdrawnAmount).toString());
  });
});
