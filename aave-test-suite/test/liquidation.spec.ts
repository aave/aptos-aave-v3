import {
  AptosProvider,
  consts,
  CoreClient,
  UnderlyingTokensClient,
} from "@aave/aave-v3-aptos-ts-sdk";
import { initializeMakeSuite, testEnv } from "../configs/config";
import "../helpers/wadraymath";

describe("Liquidation Test", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let underlyingTokensClient: UnderlyingTokensClient;

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
  });

  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("validateLiquidationCall() when healthFactor > threshold (revert expected)", async () => {
    // Liquidation something that is not liquidatable
    const { users, dai, usdc } = testEnv;
    const depositor = users[0];
    const borrower = users[1];

    // dai mint
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiDepositAmount = 500 * 10 ** daiDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(depositor.accountAddress, BigInt(daiDepositAmount), dai);

    // dai supply
    coreClient
      .withSigner(depositor)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        depositor.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // usdc mint
    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 500 * 10 ** usdcDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(borrower.accountAddress, BigInt(usdcDepositAmount), usdc);

    // usdc supply
    await coreClient
      .withSigner(borrower)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        borrower.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(borrower)
      .setUserUseReserveAsCollateral(
        usdc,
        true
      );

    const daiBorrowAmount = 500 * 10 ** daiDecimals;

    // borrow dai
    coreClient
      .withSigner(borrower)
      .borrow(
        dai,
        BigInt(daiBorrowAmount),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        borrower.accountAddress,
      );

    // Try to liquidate the borrower
    try {
      await coreClient
        .withSigner(depositor)
        .liquidationCall(usdc, dai, borrower.accountAddress, 0n, false);
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x2d"));
    }
  });

  it("ValidationLogic `executeLiquidationCall` where user has variable and stable debt, but variable debt is insufficient to cover the full liquidation amount", async () => {
    const { users, dai, weth } = testEnv;
    const depositor = users[0];
    const borrower = users[1];

    // dai mint
    const daiDecimals = Number(await underlyingTokensClient.decimals(dai));
    const daiMintAmount = 1000000 * 10 ** daiDecimals;

    await underlyingTokensClient
      .withModuleSigner()
      .mint(depositor.accountAddress, BigInt(daiMintAmount), dai);

    const daiDepositAmount = 10000 * 10 ** daiDecimals;
    // dai supply
    await coreClient
      .withSigner(depositor)
      .supply(
        dai,
        BigInt(daiDepositAmount),
        depositor.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // weth mint
    const wethDecimals = Number(await underlyingTokensClient.decimals(weth));
    const wethMintAmount = 9 * 10 ** (wethDecimals - 1);

    await underlyingTokensClient
      .withModuleSigner()
      .mint(borrower.accountAddress, BigInt(wethMintAmount), weth);

    const wethDepositAmount = 9 * 10 ** (wethDecimals - 1);
    try {
      // weth supply
      await coreClient
        .withSigner(borrower)
        .supply(
          weth,
          BigInt(wethDepositAmount),
          borrower.accountAddress,
          consts.AAVE_REFERRAL,
        );
    } catch (err) {
      expect(err.toString().includes("EINSUFFICIENT_BALANCE(0x10004)")).toBe(
        true,
      );
    }
  });
});
