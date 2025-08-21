import {
  AptosProvider,
  consts,
  CoreClient,
  UnderlyingTokensClient,
} from "@aave/aave-v3-aptos-ts-sdk";
import { initializeMakeSuite, testEnv } from "../configs/config";
import "../helpers/wadraymath";

describe("Repay Atoken Test", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let underlyingTokensClient: UnderlyingTokensClient;

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

    const {
      weth,
      dai,
      users: [, user1],
    } = testEnv;

    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiAmount = 100 * 10 ** daiDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(user1.accountAddress, BigInt(daiAmount), dai);

    await coreClient
      .withSigner(user1)
      .supply(
        dai,
        BigInt(daiAmount),
        user1.accountAddress,
        consts.AAVE_REFERRAL,
      );

    const wethDecimals = Number(await underlyingTokensClient.decimals(weth));
    const wethAmount = 100 ** wethDecimals;
    await underlyingTokensClient
      .withModuleSigner()
      .mint(user1.accountAddress, BigInt(wethAmount), weth);

    await coreClient
      .withSigner(user1)
      .supply(
        weth,
        BigInt(wethAmount),
        user1.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(user1)
      .setUserUseReserveAsCollateral(
        weth,
        true
      );

    const daiBorrowAmount = daiAmount / 2;

    await coreClient
      .withSigner(user1)
      .borrow(
        dai,
        BigInt(daiBorrowAmount),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        user1.accountAddress,
      );
  });

  it("User 1 tries to repay using aTokens without actually holding aDAI", async () => {
    const {
      aave,
      users: [, user1],
    } = testEnv;
    const aaveDecimals = Number(await underlyingTokensClient.decimals(aave));
    const repayAmount = 25 * 10 ** aaveDecimals;
    try {
      await coreClient
        .withSigner(user1)
        .repayWithATokens(
          aave,
          BigInt(repayAmount),
          consts.INTEREST_RATE_MODES.VARIABLE,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x27")).toBe(true);
    }
  });

  it("User 1 receives 1 aDAI from user 0, repays half of the debt", async () => {
    const {
      dai,
      users: [, user1],
    } = testEnv;
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const repayAmount = 10 ** daiDecimals;
    await coreClient
      .withSigner(user1)
      .repayWithATokens(
        dai,
        BigInt(repayAmount),
        consts.INTEREST_RATE_MODES.VARIABLE,
      );
  });
});
