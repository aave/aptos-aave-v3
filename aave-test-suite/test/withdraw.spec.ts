import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import "../helpers/wadraymath";
import {
  AptosProvider,
  ATokensClient,
  CoreClient,
  OracleClient,
  PoolClient,
  UnderlyingTokensClient,
  consts,
} from "@aave/aave-v3-aptos-ts-sdk";

describe("Withdraw Test", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let aTokensClient: ATokensClient;
  let underlyingTokensClient: UnderlyingTokensClient;
  let poolClient: PoolClient;
  let oracleClient: OracleClient;

  beforeEach(async () => {
    aptosProvider = AptosProvider.fromEnvs();
    coreClient = new CoreClient(
      aptosProvider,
      aptosProvider.getPoolProfileAccount(),
    );
    aTokensClient = new ATokensClient(
      aptosProvider,
      aptosProvider.getPoolProfileAccount(),
    );
    underlyingTokensClient = new UnderlyingTokensClient(
      aptosProvider,
      aptosProvider.getUnderlyingTokensProfileAccount(),
    );
    poolClient = new PoolClient(
      aptosProvider,
      aptosProvider.getPoolProfileAccount(),
    );
    oracleClient = new OracleClient(
      aptosProvider,
      aptosProvider.getOracleProfileAccount(),
    );
  });

  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateWithdraw() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await coreClient
        .withSigner(user)
        .withdraw(dai, BigNumber.from(0).toBigInt(), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateWithdraw() when amount > user balance (revert expected)", async () => {
    const { users, dai, aDai } = testEnv;
    const user = users[0];
    const scaleUserBalance = await aTokensClient.scaledBalanceOf(
      user.accountAddress,
      aDai,
    );
    const reserveData = await poolClient.getReserveData(dai);
    const userBalance = BigNumber.from(scaleUserBalance).rayMul(
      BigNumber.from(reserveData.liquidityIndex),
    );
    const newUserBalance = userBalance.add(1000000000000000);
    try {
      await coreClient
        .withSigner(user)
        .withdraw(dai, newUserBalance.toBigInt(), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x20")).toBe(true);
    }
  });

  it("validateWithdraw() when reserve is paused (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    const user1 = users[1];

    await poolClient.withSigner(user1).setReservePaused(dai, true);

    const daiWithdrawAmount = 100 * 10 ** daiDecimals;
    try {
      await coreClient
        .withSigner(user)
        .withdraw(dai, BigInt(daiWithdrawAmount), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1d")).toBe(true);
    }

    await poolClient.withSigner(user1).setReservePaused(dai, false);
  });

  it("validateHFAndLtv() with HF < 1 (revert expected)", async () => {
    const {
      usdc,
      dai,
      users: [user, usdcProvider],
    } = testEnv;

    // set prices
    await oracleClient.setAssetCustomPrice(usdc, 1n);
    await oracleClient.setAssetCustomPrice(dai, 1n);

    // dai mint
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // dai supply
    await coreClient
      .withSigner(user)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(user)
      .setUserUseReserveAsCollateral(
        dai,
        true
      );

    // usdc mint
    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;
    await underlyingTokensClient.mint(
      usdcProvider.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // usdc supply
    await coreClient
      .withSigner(usdcProvider)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        usdcProvider.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // usdc borrow
    const usdcPrice = await oracleClient.getAssetPrice(usdc);
    const { availableBorrowsBase } = await coreClient.getUserAccountData(
      user.accountAddress,
    );

    // Calculate borrow amount as an integer
    const amountUSDCToBorrow = Math.floor(
      (Number(availableBorrowsBase) / Number(usdcPrice)) * 0.8 * 10 ** usdcDecimals
    );

    // usdc borrow
    await coreClient
      .withSigner(user)
      .borrow(
        usdc,
        BigInt(amountUSDCToBorrow),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        user.accountAddress,
      );

    // withdraw
    const daiWithdrawAmount = 500 * 10 ** usdcDecimals;
    try {
      await coreClient
        .withSigner(user)
        .withdraw(dai, BigInt(daiWithdrawAmount), user.accountAddress);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x23")).toBe(true);
    }
  });

  it("User 1 deposits 10 Dai Withdraws 1 DAI", async () => {
    const {
      dai,
      aDai,
      users: [user1],
    } = testEnv;
    // dai mint
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 10 * 10 ** daiDecimals;

    await underlyingTokensClient.mint(
      user1.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // dai supply
    await coreClient
      .withSigner(user1)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        user1.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const aDaiBalanceBefore = await aTokensClient.scaledBalanceOf(
      user1.accountAddress,
      aDai,
    );
    const withdrawnAmount = 10 ** daiDecimals;
    await coreClient
      .withSigner(user1)
      .withdraw(dai, BigInt(withdrawnAmount), user1.accountAddress);

    const aDaiBalanceAfter = await aTokensClient.scaledBalanceOf(
      user1.accountAddress,
      aDai,
    );

    // Get the liquidity index to calculate the scaled amount
    const reserveData = await poolClient.getReserveData(dai);
    const scaledWithdrawnAmount = BigNumber.from(withdrawnAmount)
      .rayDiv(BigNumber.from(reserveData.liquidityIndex))
      .toString();

    expect(aDaiBalanceAfter.toString()).toBe(
      BigNumber.from(aDaiBalanceBefore)
        .sub(BigNumber.from(scaledWithdrawnAmount))
        .toString(),
    );
  });
});
