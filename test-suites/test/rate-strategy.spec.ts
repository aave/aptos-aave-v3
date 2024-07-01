import { utils } from "ethers";

import "../helpers/wadraymath";

import { BigNumber } from "@ethersproject/bignumber";
import {
  CalculateInterestRatesFuncAddr,
  GetBaseVariableBorrowRateFuncAddr,
  GetGetMaxExcessUsageRatioFuncAddr,
  GetGetOptimalUsageRatioFuncAddr,
  GetMaxVariableBorrowRateFuncAddr,
  GetVariableRateSlope1FuncAddr,
  GetVariableRateSlope2FuncAddr,
  PoolManager,
  rateStrategyStableTwo,
  SetReserveInterestRateStrategyFuncAddr,
  strategyDAI,
} from "../configs/pool";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";

import {
  ADAI,
  ATokenGetMetadataBySymbolFuncAddr,
  DAI,
  getMetadataAddress,
  UnderlyingGetMetadataBySymbolFuncAddr,
} from "../configs/tokens";

describe("InterestRateStrategy", () => {
  let daiAddress: string;
  let aDaiAddress: string;

  beforeAll(async () => {
    daiAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
    aDaiAddress = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, ADAI);
  });

  it("Checks getters", async () => {
    const [optimalUsageRatio] = await View(aptos, GetGetOptimalUsageRatioFuncAddr, [daiAddress]);
    expect(optimalUsageRatio).toBe(rateStrategyStableTwo.optimalUsageRatio);

    const [maxExcessUsageRatio] = await View(aptos, GetGetMaxExcessUsageRatioFuncAddr, [daiAddress]);
    expect(maxExcessUsageRatio).toBe(BigNumber.from(1).ray().sub(rateStrategyStableTwo.optimalUsageRatio).toString());

    const [baseVariableBorrowRate] = await View(aptos, GetBaseVariableBorrowRateFuncAddr, [daiAddress]);
    expect(baseVariableBorrowRate).toBe(rateStrategyStableTwo.baseVariableBorrowRate);

    const [variableRateSlope1] = await View(aptos, GetVariableRateSlope1FuncAddr, [daiAddress]);
    expect(variableRateSlope1).toBe(rateStrategyStableTwo.variableRateSlope1);

    const [variableRateSlope2] = await View(aptos, GetVariableRateSlope2FuncAddr, [daiAddress]);
    expect(variableRateSlope2).toBe(rateStrategyStableTwo.variableRateSlope2);

    const [maxVariableBorrowRate] = await View(aptos, GetMaxVariableBorrowRateFuncAddr, [daiAddress]);
    expect(maxVariableBorrowRate).toBe(
      BigNumber.from(rateStrategyStableTwo.baseVariableBorrowRate)
        .add(BigNumber.from(rateStrategyStableTwo.variableRateSlope1))
        .add(BigNumber.from(rateStrategyStableTwo.variableRateSlope2))
        .toString(),
    );
  });

  it("Checks rates at 0% usage ratio, empty reserve", async () => {
    const params: string[] = ["0", "0", "0", "0", strategyDAI.reserveFactor, daiAddress, aDaiAddress];
    const [currentLiquidityRate, currentVariableBorrowRate] = await View(aptos, CalculateInterestRatesFuncAddr, [
      ...params,
    ]);
    expect(currentLiquidityRate).toBe("0");
    expect(currentVariableBorrowRate).toBe("0");
  });

  it("Deploy an interest rate strategy with optimalUsageRatio out of range (expect revert)", async () => {
    const params: string[] = [
      utils.parseUnits("1.0", 28).toString(),
      rateStrategyStableTwo.baseVariableBorrowRate,
      rateStrategyStableTwo.variableRateSlope1,
      rateStrategyStableTwo.variableRateSlope2,
    ];
    try {
      await Transaction(aptos, PoolManager, SetReserveInterestRateStrategyFuncAddr, [daiAddress, ...params]);
    } catch (err) {
      expect(err.toString().includes("default_reserve_interest_rate_strategy: 0x53")).toBe(true);
    }
  });
});
