import { utils } from "ethers";
import "../helpers/wadraymath";
import { BigNumber } from "@ethersproject/bignumber";
import { AccountAddress } from "@aptos-labs/ts-sdk";
import { PoolManager, rateStrategyStableTwo, strategyDAI } from "../configs/pool";
import { ADAI, ATokenManager, DAI, UnderlyingManager } from "../configs/tokens";
import { AptosProvider } from "../wrappers/aptosProvider";
import { ATokensClient } from "../clients/aTokensClient";
import { UnderlyingTokensClient } from "../clients/underlyingTokensClient";
import { PoolClient } from "../clients/poolClient";

describe("InterestRateStrategy", () => {
  let daiAddress: AccountAddress;
  let aDaiAddress: AccountAddress;
  const aptosProvider = new AptosProvider();
  let aTokensClient: ATokensClient;
  let underlyingTokensClient: UnderlyingTokensClient;
  let poolClient: PoolClient;

  beforeAll(async () => {
    aTokensClient = new ATokensClient(aptosProvider, ATokenManager);
    underlyingTokensClient = new UnderlyingTokensClient(aptosProvider, UnderlyingManager);
    poolClient = new PoolClient(aptosProvider, PoolManager);
    daiAddress = await underlyingTokensClient.getMetadataBySymbol(DAI);
    aDaiAddress = await aTokensClient.getMetadataBySymbol(PoolManager.accountAddress, ADAI);
  });

  it("Checks getters", async () => {
    const optimalUsageRatio = await poolClient.getOptimalUsageRatio(daiAddress);
    expect(optimalUsageRatio.toString()).toBe(rateStrategyStableTwo.optimalUsageRatio);

    const maxExcessUsageRatio = await poolClient.getMaxExcessUsageRatio(daiAddress);
    expect(maxExcessUsageRatio.toString()).toBe(
      BigNumber.from(1).ray().sub(rateStrategyStableTwo.optimalUsageRatio).toString(),
    );

    const baseVariableBorrowRate = await poolClient.getBaseVariableBorrowRate(daiAddress);
    expect(baseVariableBorrowRate.toString()).toBe(
      BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate).toString(),
    );

    const variableRateSlope1 = await poolClient.getVariableRateSlope1(daiAddress);
    expect(variableRateSlope1.toString()).toBe(BigNumber.from(rateStrategyStableTwo.variableRateSlope1).toString());

    const variableRateSlope2 = await poolClient.getVariableRateSlope2(daiAddress);
    expect(variableRateSlope2.toString()).toBe(BigNumber.from(rateStrategyStableTwo.variableRateSlope2).toString());

    const maxVariableBorrowRate = await poolClient.getMaxVariableBorrowRate(daiAddress);
    expect(maxVariableBorrowRate.toString()).toBe(
      BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate)
        .add(BigNumber.from(rateStrategyStableTwo.variableRateSlope1))
        .add(BigNumber.from(rateStrategyStableTwo.variableRateSlope2))
        .toString(),
    );
  });

  it("Checks rates at 0% usage ratio, empty reserve", async () => {
    const { currentLiquidityRate, currentVariableBorrowRate } = await poolClient.calculateInterestRates(
      BigNumber.from(0),
      BigNumber.from(0),
      BigNumber.from(0),
      BigNumber.from(0),
      BigNumber.from(strategyDAI.reserveFactor),
      daiAddress,
      aDaiAddress,
    );

    expect(currentLiquidityRate.toString()).toBe("0");
    expect(currentVariableBorrowRate.toString()).toBe("0");
  });

  it("Deploy an interest rate strategy with optimalUsageRatio out of range (expect revert)", async () => {
    try {
      await poolClient.setReserveInterestRateStrategy(
        daiAddress,
        utils.parseUnits("1.0", 28),
        BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate),
        BigNumber.from(rateStrategyStableTwo.variableRateSlope1),
        BigNumber.from(rateStrategyStableTwo.variableRateSlope2),
      );
    } catch (err) {
      expect(err.toString().includes("default_reserve_interest_rate_strategy: 0x53")).toBe(true);
    }
  });
});
