import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv, underlyingTokens, USDC } from "../configs/config";
import "../helpers/wadraymath";
import {
  AclClient,
  AptosProvider,
  consts,
  CoreClient,
  OracleClient,
  PoolClient,
  UnderlyingTokensClient,
} from "@aave/aave-v3-aptos-ts-sdk";
import { AccountAddress } from "@aptos-labs/ts-sdk";

describe("Pool Liquidation: Liquidator receiving the underlying asset", () => {
  let aptosProvider: AptosProvider;
  let coreClient: CoreClient;
  let underlyingTokensClient: UnderlyingTokensClient;
  let poolClient: PoolClient;
  let oracleClient: OracleClient;
  let aclClient: AclClient;

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
    oracleClient = new OracleClient(
      aptosProvider,
      aptosProvider.getOracleProfileAccount(),
    );
    aclClient = new AclClient(
      aptosProvider,
      aptosProvider.getOracleProfileAccount(),
    );
  });

  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("It's not possible to liquidate on a non-active collateral or a non active principal", async () => {
    const {
      weth,
      users: [, user],
      aave,
    } = testEnv;

    await poolClient.setReserveActive(aave, false);

    const aaveDecimals = Number(await underlyingTokensClient.decimals(aave));
    const debtToCover = 1000 * 10 ** aaveDecimals;
    try {
      await coreClient
        .liquidationCall(
          weth,
          aave,
          user.accountAddress,
          BigInt(debtToCover),
          false,
        );
    } catch (err) {
      expect(err.toString().includes("validation_logic: 0x1b")).toBe(true);
    }

    await poolClient.setReserveActive(aave, true);
  });

  it("User 3 deposits 1000 USDC, user 4 0.06775 WETH, user 4 borrows - drops HF, liquidates the borrow", async () => {
    const {
      usdc,
      users: [, , , depositor, borrower, liquidator],
      weth,
    } = testEnv;


    await underlyingTokensClient.decimals(usdc);
    await underlyingTokensClient.decimals(weth);

    // mints USDC to depositor
    const usdcDecimals = Number(await underlyingTokensClient.decimals(usdc));
    const usdcDepositAmount = 1000 * 10 ** usdcDecimals;

    await underlyingTokensClient.mint(depositor.accountAddress, BigInt(usdcDepositAmount), usdc );

    // usdc supply
    await coreClient
      .withSigner(depositor)
      .supply(
        usdc,
        BigInt(usdcDepositAmount),
        depositor.accountAddress,
        consts.AAVE_REFERRAL,
      );

    // mints WETH to borrower - fix: using weth decimals instead of usdc decimals
    const wethDecimals = Number(await underlyingTokensClient.decimals(weth));
    const wethDepositAmount = 10000 * 10 ** wethDecimals;

    await underlyingTokensClient
      .mint(borrower.accountAddress, BigInt(wethDepositAmount), weth);

    const amountWETHtoDeposit = 6675 * 10 ** wethDecimals;
    // weth supply
    await coreClient
      .withSigner(borrower)
      .supply(
        weth,
        BigInt(amountWETHtoDeposit),
        borrower.accountAddress,
        consts.AAVE_REFERRAL,
      );

    await coreClient
      .withSigner(borrower)
      .setUserUseReserveAsCollateral(
        weth,
        true

      );

    const { availableBorrowsBase } = await coreClient.getUserAccountData(
      borrower.accountAddress,
    );

    const usdcPrice = await oracleClient.getAssetPrice(usdc);

    // const amountUSDCToBorrow = BigNumber.from(available_borrows_base).div(BigNumber.from(usdcPrice)).toNumber() * 10 ** usdcDecimals;
    const amountUSDCToBorrow = 100 * 10 ** usdcDecimals;

    // borrower borrows
    await coreClient
      .withSigner(borrower)
      .borrow(
        usdc,
        BigInt(amountUSDCToBorrow),
        consts.INTEREST_RATE_MODES.VARIABLE,
        consts.AAVE_REFERRAL,
        borrower.accountAddress,
      );

    // drops HF below 1
    await oracleClient.setAssetCustomPrice(usdc, 11200n);

    // mints usdc to the liquidator - fix: use correct parameters order
    await underlyingTokensClient
      .mint(liquidator.accountAddress, BigInt(usdcDepositAmount), usdc);

    // get User Reserve Data
    // const [
    //     current_a_token_balance_before,
    //     current_variable_debt_before,
    //     scaled_variable_debt_before,
    //     liquidity_rate_before,
    //     usage_as_collateral_enabled_before
    // ] = await View(aptos, GetUserReserveDataFuncAddr, [usdc, borrower.accountAddress.toString()])
    //
    // const usdcReserveDataBefore = await getReserveData(usdc.toString());
    // const wethReserveDataBefore = await getReserveData(weth.toString());
    const amountToLiquidate = 100 * 10 ** usdcDecimals;

    // liquidator liquidationCall
    try {
      await coreClient
        .withSigner(liquidator)
        .liquidationCall(
          weth,
          usdc,
          borrower.accountAddress,
          BigInt(amountToLiquidate),
          false,
        );
    } catch (err) {
      // console.log("err:", err.toString())
      expect(err.toString().includes("validation_logic: 0x2d")).toBe(true);
    }
  });
});
