/* eslint-disable no-console */
import { BigNumber } from "@ethersproject/bignumber";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  GetReserveConfigurationDataFuncAddr,
  PoolConfiguratorConfigureReserveAsCollateralFuncAddr,
  PoolConfiguratorSetAssetEmodeCategoryFuncAddr,
  PoolConfiguratorSetBorrowCapFuncAddr,
  PoolConfiguratorSetEmodeCategoryFuncAddr,
  PoolConfiguratorSetReserveFactorFuncAddr,
  PoolConfiguratorSetSupplyCapFuncAddr,
  PoolConfiguratorSetUnbackedMintCapFuncAddr,
  PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr,
  PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr,
  PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr,
  PoolManager,
} from "../configs/pool";
import { MAX_BORROW_CAP, MAX_SUPPLY_CAP, MAX_UNBACKED_MINT_CAP, ZERO_ADDRESS } from "../helpers/constants";

describe("PoolConfigurator: Edge cases", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("ReserveConfiguration setLiquidationBonus() threshold > MAX_VALID_LIQUIDATION_THRESHOLD", async () => {
    const { dai } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        dai,
        5,
        10,
        65535 + 1,
      ]);
    } catch (err) {
      expect(err.toString().includes("reserve: 0x41")).toBe(true);
    }
  });

  it("PoolConfigurator setReserveFactor() reserveFactor > PERCENTAGE_FACTOR (revert expected)", async () => {
    const { dai } = testEnv;
    const invalidReserveFactor = 20000;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFactorFuncAddr, [dai, invalidReserveFactor]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x43")).toBe(true);
    }
  });

  it("ReserveConfiguration setReserveFactor() reserveFactor > MAX_VALID_RESERVE_FACTOR", async () => {
    const { dai } = testEnv;
    const invalidReserveFactor = 65536;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFactorFuncAddr, [dai, invalidReserveFactor]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x43")).toBe(true);
    }
  });

  it("PoolConfigurator configureReserveAsCollateral() ltv > liquidationThreshold", async () => {
    const { dai } = testEnv;
    const [, , liquidationThreshold, liquidationBonus, , , , ,] = await View(
      aptos,
      GetReserveConfigurationDataFuncAddr,
      [dai],
    );
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        dai,
        65535 + 1,
        liquidationThreshold.toString(),
        liquidationBonus.toString(),
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x14")).toBe(true);
    }
  });

  it("PoolConfigurator configureReserveAsCollateral() liquidationBonus < 10000", async () => {
    const { dai } = testEnv;
    const [, ltv, liquidationThreshold, , , , , ,] = await View(aptos, GetReserveConfigurationDataFuncAddr, [dai]);
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        dai,
        ltv.toString(),
        liquidationThreshold.toString(),
        10000,
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x14")).toBe(true);
    }
  });

  it("PoolConfigurator configureReserveAsCollateral() liquidationThreshold.percentMul(liquidationBonus) > PercentageMath.PERCENTAGE_FACTOR", async () => {
    const { dai } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        dai,
        10001,
        10001,
        10001,
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x14")).toBe(true);
    }
  });

  it("PoolConfigurator configureReserveAsCollateral() liquidationThreshold == 0 && liquidationBonus > 0", async () => {
    const { dai } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [dai, 0, 0, 15000]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x14")).toBe(true);
    }
  });

  it("Tries to bridge protocol fee > PERCENTAGE_FACTOR (revert expected)", async () => {
    const newProtocolFee = 10001;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr, [newProtocolFee]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x16")).toBe(true);
    }
  });

  it("Tries to update flashloan premium total > PERCENTAGE_FACTOR (revert expected)", async () => {
    const newPremiumTotal = 10001;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr, [newPremiumTotal]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x13")).toBe(true);
    }
  });

  it("Tries to update flashloan premium to protocol > PERCENTAGE_FACTOR (revert expected)", async () => {
    const newPremiumToProtocol = 10001;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr, [
        newPremiumToProtocol,
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x13")).toBe(true);
    }
  });

  it("Tries to update borrowCap > MAX_BORROW_CAP (revert expected)", async () => {
    const { weth } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetBorrowCapFuncAddr, [
        weth,
        BigNumber.from(MAX_BORROW_CAP).add(1).toString(),
      ]);
    } catch (err) {
      expect(err.toString().includes("reserve: 0x44")).toBe(true);
    }
  });

  it("Tries to update supplyCap > MAX_SUPPLY_CAP (revert expected)", async () => {
    const { weth } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetSupplyCapFuncAddr, [
        weth,
        BigNumber.from(MAX_SUPPLY_CAP).add(1).toString(),
      ]);
    } catch (err) {
      expect(err.toString().includes("reserve: 0x45")).toBe(true);
    }
  });

  it("Tries to update unbackedMintCap > MAX_UNBACKED_MINT_CAP (revert expected)", async () => {
    const { weth } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetUnbackedMintCapFuncAddr, [
        weth,
        BigNumber.from(MAX_UNBACKED_MINT_CAP).add(1).toString(),
      ]);
    } catch (err) {
      expect(err.toString().includes("reserve: 0x48")).toBe(true);
    }
  });

  it("Tries to set borrowCap of MAX_BORROW_CAP an unlisted asset", async () => {
    const { users } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetBorrowCapFuncAddr, [
        users[5].accountAddress.toString(),
        10,
      ]);
    } catch (err) {
      expect(err.toString().includes("pool: 0x52")).toBe(true);
    }
  });

  it("Tries to add a category with id 0 (revert expected)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
        0,
        9800,
        9800,
        10100,
        ZERO_ADDRESS,
        "INVALID_ID_CATEGORY",
      ]);
    } catch (err) {
      expect(err.toString().includes("emode_logic: 0x10")).toBe(true);
    }
  });

  it("Tries to add an eMode category with ltv > liquidation threshold (revert expected)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
        16,
        9900,
        9800,
        10100,
        ZERO_ADDRESS,
        "STABLECOINS",
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x15")).toBe(true);
    }
  });

  it("Tries to add an eMode category with no liquidation bonus (revert expected)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
        16,
        9800,
        9800,
        10000,
        ZERO_ADDRESS,
        "STABLECOINS",
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x15")).toBe(true);
    }
  });

  it("Tries to add an eMode category with too large liquidation bonus (revert expected)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
        16,
        9800,
        9800,
        11000,
        ZERO_ADDRESS,
        "STABLECOINS",
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x15")).toBe(true);
    }
  });

  it("Tries to add an eMode category with liquidation threshold > 1 (revert expected)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
        16,
        9800,
        10100,
        10100,
        ZERO_ADDRESS,
        "STABLECOINS",
      ]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x15")).toBe(true);
    }
  });

  it("Tries to set DAI eMode category to undefined category (revert expected)", async () => {
    const { dai } = testEnv;
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetAssetEmodeCategoryFuncAddr, [dai, 100]);
    } catch (err) {
      console.log("err:", err.toString());
      expect(err.toString().includes("pool_configurator: 0x11")).toBe(true);
    }
  });

  it("Tries to set DAI eMode category to category with too low LT (revert expected)", async () => {
    const { aave } = testEnv;
    const [, ltv, liquidationThreshold, , , , , ,] = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    await Transaction(aptos, PoolManager, PoolConfiguratorSetEmodeCategoryFuncAddr, [
      100,
      ltv.toString(),
      BigNumber.from(liquidationThreshold).sub(1).toString(),
      10100,
      ZERO_ADDRESS,
      "LT_TOO_LOW_FOR_DAI",
    ]);
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetAssetEmodeCategoryFuncAddr, [aave, 100]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x11")).toBe(true);
    }
  });
});
