import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import {
  AptosProvider,
  consts,
  CoreClient,
  OracleClient,
  PoolClient,
  UnderlyingTokensClient,
} from "@aave/aave-v3-aptos-ts-sdk";

describe("Borrow Test", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let underlyingTokensClient: UnderlyingTokensClient;
  let poolClient: PoolClient;
  let oracleClient: OracleClient;

  beforeAll(async () => {
    await initializeMakeSuite();
    aptosProvider = AptosProvider.fromEnvs();
    coreClient = new CoreClient(
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

  it("validateBorrow() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await coreClient
        .withSigner(user)
        .borrow(
          dai,
          BigInt(0),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateBorrow() when reserve is not active (revert expected)", async () => {
    const { users, aave, usdc } = testEnv;
    const user = users[0];

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;

    // usdc mint
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // usdc supply
    await coreClient
      .withSigner(user)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // get reserve status
    const { isActive: isActiveBefore } =
      await poolClient.getReserveConfigurationData(aave);
    expect(isActiveBefore).toBe(true);

    // set the reserve to be not active
    await poolClient.setReserveActive(aave, false);

    const { isActive: isActiveAfter } =
      await poolClient.getReserveConfigurationData(aave);
    expect(isActiveAfter).toBe(false);

    const aaveDecimals = Number(await underlyingTokensClient.decimals(aave));

    const aaveDepositAmount = 1000 * 10 ** aaveDecimals;

    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(aaveDepositAmount),
      aave
    );

    // try to borrow
    try {
      await coreClient
        .withSigner(user)
        .borrow(
          aave,
          BigInt(aaveDepositAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }

    // set active again
    await poolClient.setReserveActive(aave, true);
  });

  it("validateBorrow() when reserve is frozen (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[0];

    // mint dai
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // mint usdc
    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;

    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // deposit usdc
    await coreClient
      .withSigner(user)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const { isActive: isActiveBefore, isFrozen: isFrozenBefore } =
      await poolClient.getReserveConfigurationData(dai);
    expect(isActiveBefore).toBe(true);
    expect(isFrozenBefore).toBe(false);

    // freeze the reserve now
    await poolClient.setReserveFreeze(dai, true);

    // check frozen status
    const { isActive: isActiveAfter, isFrozen: isFrozenAfter } =
      await poolClient.getReserveConfigurationData(dai);
    expect(isActiveAfter).toBe(true);
    expect(isFrozenAfter).toBe(true);

    // try to borrow
    try {
      await coreClient
        .withSigner(user)
        .borrow(
          dai,
          BigInt(daiDepositAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1c")).toBe(true);
    }

    // set to unfrozen again
    await poolClient.setReserveFreeze(dai, false);
  });

  it("validateBorrow() when borrowing is not enabled (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[0];

    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    // mint dai
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // deposit dai
    await coreClient
      .withSigner(user)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;

    // mint usdc
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // deposit usdc
    await coreClient
      .withSigner(user)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // Disable borrowing
    await poolClient.setReserveBorrowing(dai, false);

    // check borrowing is disabled
    const { borrowingEnabled: borrowingEnabledAfter } =
      await poolClient.getReserveConfigurationData(dai);
    expect(borrowingEnabledAfter).toBe(false);

    // now try to borrow
    try {
      await coreClient
        .withSigner(user)
        .borrow(
          dai,
          BigInt(daiDepositAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1e")).toBe(true);
    }

    // Enable borrowing again
    await poolClient.setReserveBorrowing(dai, true);
  });

  it("validateBorrow() borrowing when user has already a HF < threshold", async () => {
    const { users, dai, usdc } = testEnv;
    const user = users[0];
    const depositor = users[1];

    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 2000 * 10 ** daiDecimals;

    // Mint dai to depositor
    await underlyingTokensClient.mint(
      depositor.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // Deposit dai from depositor
    await coreClient
      .withSigner(depositor)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        depositor.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 2000 * 10 ** usdcDecimals;

    // Mint usdc to user
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // Deposit usdc from user
    await coreClient
      .withSigner(user)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(user)
      .setUserUseReserveAsCollateral(
        usdc,
        true
      );

    const borrowAmount = 1000 * 10 ** daiDecimals;

    // User borrows dai
    await coreClient
      .withSigner(user)
      .borrow(
        dai,
        BigInt(borrowAmount),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        user.accountAddress,
      );

    // Get dai price
    const daiPrice = await oracleClient.getAssetPrice(dai);

    // The oracle sets the price of dai
    await oracleClient.setAssetCustomPrice(dai, daiPrice  *2n);

    const userBorrowDaiAmount = 200 * 10 ** daiDecimals;

    // Try to borrow more dai, expecting it to fail
    try {
      await coreClient
        .withSigner(user)
        .borrow(
          dai,
          BigInt(userBorrowDaiAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("pool_validation: 0x24")).toBe(true);
    }
  });

  it("validateBorrow() with eMode > 0, borrowing asset not in category (revert expected)", async () => {
    const {
      users: [user, usdcProvider],
      dai,
      usdc,
    } = testEnv;

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;

    // Mint USDC to usdcProvider
    await underlyingTokensClient.mint(
      usdcProvider.accountAddress,
      BigInt(usdcDepositAmount),
      usdc
    );

    // Deposit USDC
    await coreClient
      .withSigner(usdcProvider)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        usdcProvider.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    // Mint DAI to user
    await underlyingTokensClient.mint(
      user.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // Deposit DAI
    await coreClient
      .withSigner(user)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // Set EMode category
    await poolClient.setEmodeCategory(
      101,
      9800,
      9900,
      10100,
      "NO-ASSETS",
    );

    const userBorrowDaiAmount = 100 * 10 ** daiDecimals;

    try {
      // Set user EMode
      await poolClient.withSigner(user).setUserEmode(101);

      // Try borrowing DAI, which is not in the EMode category
      await coreClient
        .withSigner(user)
        .borrow(
          dai,
          BigInt(userBorrowDaiAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          consts.AAVE_REFERRAL,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x3a")).toBe(true);
    }
  });

  it("User 2 supplies WETH, and borrows DAI", async () => {
    const {
      dai,
      weth,
      users: [, borrower],
    } = testEnv;

    // Get initial WETH balance
    const { currentATokenBalance: currentWethBalanceBefore } =
      await poolClient.getUserReserveData(weth, borrower.accountAddress);

    const wethDecimals = Number(await underlyingTokensClient.decimals(weth));
    const wethDepositAmount = 2000 * 10 ** wethDecimals;

    // Mint WETH to borrower
    await underlyingTokensClient.mint(
      borrower.accountAddress,
      BigInt(wethDepositAmount),
      weth
    );

    // Deposit WETH
    await coreClient
      .withSigner(borrower)
      .supply(
        weth,
        BigInt(wethDepositAmount),
        borrower.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(borrower)
      .setUserUseReserveAsCollateral(
        weth,
        true
      );

    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 1000 * 10 ** daiDecimals;

    // Mint DAI to borrower
    await underlyingTokensClient.mint(
      borrower.accountAddress,
      BigInt(daiDepositAmount),
      dai
    );

    // Deposit DAI
    await coreClient
      .withSigner(borrower)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        borrower.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // Borrow DAI
    const firstDaiBorrow = 50 * 10 ** daiDecimals;
    await coreClient
      .withSigner(borrower)
      .borrow(
        dai,
        BigInt(firstDaiBorrow),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        borrower.accountAddress,
      );

    // Get WETH token balance after
    const { currentATokenBalance } = await poolClient.getUserReserveData(
      weth,
      borrower.accountAddress,
    );

    // Check if the final aToken balance equals initial balance + deposited amount
    const expectedBalance = BigNumber.from(currentWethBalanceBefore)
      .add(wethDepositAmount)
      .toString();
    expect(BigNumber.from(currentATokenBalance).toString()).toBe(
      expectedBalance,
    );
  });
});
