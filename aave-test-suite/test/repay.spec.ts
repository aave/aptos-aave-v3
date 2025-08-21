import {
  AptosProvider,
  consts,
  CoreClient,
  PoolClient,
  UnderlyingTokensClient,
} from "@aave/aave-v3-aptos-ts-sdk";
import { initializeMakeSuite, testEnv } from "../configs/config";

describe("Repay Test", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let underlyingTokensClient: UnderlyingTokensClient;
  let poolClient: PoolClient;

  beforeEach(async () => {
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
  });

  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateRepay() when amount == 0 (revert expected)", async () => {
    const { users, dai } = testEnv;
    const user = users[0];
    try {
      await coreClient
        .withSigner(user)
        .repay(
          dai,
          BigInt(0),
          consts.INTEREST_RATE_MODES.VARIABLE,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1a")).toBe(true);
    }
  });

  it("validateRepay() when reserve is not active (revert expected)", async () => {
    const { users, aave, usdc } = testEnv;
    const user = users[0];

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 10000 * 10 ** usdcDecimals;

    // mint usdc
    await underlyingTokensClient
      .withModuleSigner()
      .mint(user.accountAddress, BigInt(usdcDepositAmount), usdc);

    // usdc supply
    await coreClient
      .withSigner(user)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const { isActive: isActiveBefore } =
      await poolClient.getReserveConfigurationData(aave);

    expect(isActiveBefore).toBe(true);

    await poolClient.withModuleSigner().setReserveActive(aave, false);

    const { isActive: isActiveAfter } =
      await poolClient.getReserveConfigurationData(aave);

    expect(isActiveAfter).toBe(false);

    const aaveDecimals = Number(await underlyingTokensClient.decimals(aave));
    const aaveDepositAmount = 1000 * 10 ** aaveDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(user.accountAddress, BigInt(aaveDepositAmount), aave);

    try {
      await coreClient
        .withSigner(user)
        .repay(
          aave,
          BigInt(aaveDepositAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          user.accountAddress,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }

    await poolClient.withModuleSigner().setReserveActive(aave, true);
  });

  it("validateRepay() the variable debt when is 0  (revert expected)", async () => {
    const { users, usdc, dai } = testEnv;
    const user = users[5];

    // console.log("user:", user.accountAddress.toString());
    // dai mint
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 2000 * 10 ** daiDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(user.accountAddress, BigInt(daiDepositAmount), dai);

    // dai supply
    await coreClient
      .withSigner(user)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        user.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // usdc mint
    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 2000 * 10 ** usdcDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(user.accountAddress, BigInt(usdcDepositAmount), usdc);

    // usdc supply
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

    const userBorrowAmount = 250 * 10 ** daiDecimals;
    // user borrow dai
    await coreClient
      .withSigner(user)
      .borrow(
        dai,
        BigInt(userBorrowAmount),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        user.accountAddress,
      );

    try {
      await coreClient
        .withSigner(user)
        .repay(
          dai,
          BigInt(userBorrowAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          user.accountAddress,
        );
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

    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const repayAmount = 2 * 10 ** usdcDecimals;
    // console.log("user1:", user1.accountAddress.toString());
    try {
      await coreClient
        .withSigner(user1)
        .repay(
          usdc,
          BigInt(repayAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
          user1.accountAddress,
        );
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("validation_logic: 0x27")).toBe(true);
    }
  });
});
