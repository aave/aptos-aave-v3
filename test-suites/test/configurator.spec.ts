import { AccountAddress } from "@aptos-labs/ts-sdk";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  GetDebtCeilingDecimalsFuncAddr,
  GetDebtCeilingFuncAddr,
  GetFlashLoanEnabledFuncAddr,
  GetPausedFuncAddr,
  GetReserveConfigurationDataFuncAddr,
  GetReserveDataFuncAddr,
  GetSiloedBorrowingFuncAddr,
  GetUnbackedMintCapFuncAddr,
  PoolConfiguratorConfigureReserveAsCollateralFuncAddr,
  PoolConfiguratorSetBorrowCapFuncAddr,
  PoolConfiguratorSetDebtCeilingFuncAddr,
  PoolConfiguratorSetReserveActiveFuncAddr,
  PoolConfiguratorSetReserveBorrowingFuncAddr,
  PoolConfiguratorSetReserveFactorFuncAddr,
  PoolConfiguratorSetReserveFlashLoaningFuncAddr,
  PoolConfiguratorSetReserveFreezeFuncAddr,
  PoolConfiguratorSetReservePauseFuncAddr,
  PoolConfiguratorSetSiloedBorrowingFuncAddr,
  PoolConfiguratorSetSupplyCapFuncAddr,
  PoolConfiguratorSetUnbackedMintCapFuncAddr,
  PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr,
  PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr,
  PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr,
  PoolGetBridgeProtocolFeeFuncAddr,
  PoolGetFlashloanPremiumToProtocolFuncAddr,
  PoolGetFlashloanPremiumTotalFuncAddr,
  PoolManager,
  strategyAAVE,
} from "../configs/pool";
import { AclManager, addAssetListingAdminFuncAddr, isAssetListingAdminFuncAddr } from "../configs/aclManage";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { RAY } from "../helpers/constants";

type ReserveConfigurationValues = {
  reserveDecimals: string;
  baseLTVAsCollateral: string;
  liquidationThreshold: string;
  liquidationBonus: string;
  reserveFactor: string;
  usageAsCollateralEnabled: boolean;
  borrowingEnabled: boolean;
  isActive: boolean;
  isFrozen: boolean;
  isPaused: boolean;
  eModeCategory: string;
  borrowCap: string;
  supplyCap: string;
};

const expectReserveConfigurationData = async (asset: AccountAddress, values: ReserveConfigurationValues) => {
  const [decimals, , , , , , , isActive, isFrozen] = await View(aptos, GetReserveConfigurationDataFuncAddr, [asset]);
  // const [eModeCategory] = await View(aptos, GetReserveEModeCategoryFuncAddr, [asset])
  // const [borrowCap, supplyCap] = await View(aptos, GetReserveCapsFuncAddr, [asset])
  const [isPaused] = await View(aptos, GetPausedFuncAddr, [asset]);

  expect(decimals).toBe(values.reserveDecimals);
  // expect(ltv).toBe(values.baseLTVAsCollateral)
  // expect(liquidation_threshold).toBe(values.liquidationThreshold)
  // expect(liquidation_bonus).toBe(values.liquidationBonus)
  // expect(reserve_factor).toBe(values.reserveFactor)
  // expect(usage_as_collateral_enabled).toBe(values.usageAsCollateralEnabled)
  // expect(borrowing_enabled).toBe(values.borrowingEnabled)
  expect(isActive).toBe(values.isActive);
  expect(isFrozen).toBe(values.isFrozen);

  expect(isPaused).toBe(values.isPaused);

  // expect(eModeCategory).toBe(values.eModeCategory)
  // expect(borrowCap).toBe(values.borrowCap)
  // expect(supplyCap).toBe(values.supplyCap)
};

describe("PoolConfigurator", () => {
  let baseConfigValues: ReserveConfigurationValues;

  beforeAll(async () => {
    await initializeMakeSuite();
    const {
      reserveDecimals,
      baseLTVAsCollateral,
      liquidationThreshold,
      liquidationBonus,
      reserveFactor,
      borrowingEnabled,
      borrowCap,
      supplyCap,
    } = strategyAAVE;

    baseConfigValues = {
      reserveDecimals,
      baseLTVAsCollateral,
      liquidationThreshold,
      liquidationBonus,
      reserveFactor,
      usageAsCollateralEnabled: true,
      borrowingEnabled,
      isActive: true,
      isFrozen: false,
      isPaused: false,
      eModeCategory: "0",
      borrowCap,
      supplyCap,
    };
  });

  it("InitReserves via AssetListing admin", async () => {
    const { users } = testEnv;
    const assetListingAdmin = users[4];
    const [isAssetListingAdmin] = await View(aptos, isAssetListingAdminFuncAddr, [
      assetListingAdmin.accountAddress.toString(),
    ]);
    if (!isAssetListingAdmin) {
      expect(
        await Transaction(aptos, AclManager, addAssetListingAdminFuncAddr, [
          assetListingAdmin.accountAddress.toString(),
        ]),
      );
    }
  });

  it("Deactivates the ETH reserve", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, false]));
    const reserveConfigurationData = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    expect(reserveConfigurationData[7]).toBe(false);
  });

  it("Reactivates the ETH reserve", async () => {
    const { aave } = testEnv;
    await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveActiveFuncAddr, [aave, true]);

    const reserveConfigurationData = await View(aptos, GetReserveConfigurationDataFuncAddr, [aave]);
    // console.log("reserveConfigurationData:", reserveConfigurationData);

    expect(reserveConfigurationData[7]).toBe(true);
  });

  it("Pauses the ETH reserve by pool admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReservePauseFuncAddr, [aave, true]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      isPaused: true,
    });
  });

  it("Unpauses the ETH reserve by pool admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReservePauseFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
  });

  it("Pauses the ETH reserve by emergency admin", async () => {
    const { aave, emergencyAdmin } = testEnv;
    expect(await Transaction(aptos, emergencyAdmin, PoolConfiguratorSetReservePauseFuncAddr, [aave, true]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      isPaused: true,
    });
  });

  it("Unpauses the ETH reserve by emergency admin", async () => {
    const { aave, emergencyAdmin } = testEnv;
    expect(await Transaction(aptos, emergencyAdmin, PoolConfiguratorSetReservePauseFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
  });

  it("Freezes the ETH reserve by pool Admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [aave, true]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      isFrozen: true,
    });
  });

  it("Unfreezes the ETH reserve by Pool admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFreezeFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
  });

  it("Freezes the ETH reserve by Risk Admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetReserveFreezeFuncAddr, [aave, true]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      isFrozen: true,
    });
  });

  it("Unfreezes the ETH reserve by Risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetReserveFreezeFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
  });

  it("Deactivates the ETH reserve for borrowing via pool admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveBorrowingFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowingEnabled: false,
    });
  });

  it("Deactivates the ETH reserve for borrowing via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetReserveBorrowingFuncAddr, [aave, false]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowingEnabled: false,
    });
  });

  it("Activates the ETH reserve for borrowing via pool admin", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveBorrowingFuncAddr, [aave, true]));

    const reserveData = await View(aptos, GetReserveDataFuncAddr, [aave]);
    const variableBorrowIndex = reserveData[7];
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
    expect(variableBorrowIndex).toBe(RAY);
  });

  it("Activates the ETH reserve for borrowing via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetReserveBorrowingFuncAddr, [aave, true]));

    const reserveData = await View(aptos, GetReserveDataFuncAddr, [aave]);
    const variableBorrowIndex = reserveData[7];
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
    });
    expect(variableBorrowIndex).toBe(RAY);
  });

  it("Deactivates the ETH reserve as collateral via pool admin", async () => {
    const { aave } = testEnv;
    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [aave, 0, 0, 0]),
    );
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      baseLTVAsCollateral: "0",
      liquidationThreshold: "0",
      liquidationBonus: "0",
      usageAsCollateralEnabled: false,
    });
  });

  it("Activates the ETH reserve as collateral via pool admin", async () => {
    const { aave } = testEnv;
    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        aave,
        8000,
        8250,
        10500,
      ]),
    );
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      baseLTVAsCollateral: "8000",
      liquidationThreshold: "8250",
      liquidationBonus: "10500",
    });
  });

  it("Deactivates the ETH reserve as collateral via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [aave, 0, 0, 0]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      baseLTVAsCollateral: "0",
      liquidationThreshold: "0",
      liquidationBonus: "0",
      usageAsCollateralEnabled: false,
    });
  });

  it("Activates the ETH reserve as collateral via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(
      await Transaction(aptos, riskAdmin, PoolConfiguratorConfigureReserveAsCollateralFuncAddr, [
        aave,
        8000,
        8250,
        10500,
      ]),
    );
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      baseLTVAsCollateral: "8000",
      liquidationThreshold: "8250",
      liquidationBonus: "10500",
    });
  });

  it("Changes the reserve factor of aave via pool admin", async () => {
    const { aave } = testEnv;
    const newReserveFactor = "1000";
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFactorFuncAddr, [aave, newReserveFactor]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      reserveFactor: newReserveFactor,
    });
  });

  it("Changes the reserve factor of aave via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    const newReserveFactor = "1000";
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetReserveFactorFuncAddr, [aave, newReserveFactor]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      reserveFactor: newReserveFactor,
    });
  });

  it("Updates the reserve factor of aave equal to PERCENTAGE_FACTOR", async () => {
    const { aave } = testEnv;
    const newReserveFactor = "10000";
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFactorFuncAddr, [aave, newReserveFactor]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      reserveFactor: newReserveFactor,
    });
  });

  it("Updates the unbackedMintCap of aave via pool admin", async () => {
    const { aave } = testEnv;
    const newUnbackedMintCap = "10000";
    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorSetUnbackedMintCapFuncAddr, [aave, newUnbackedMintCap]),
    );
    const [newaaveUnbackedMintCap] = await View(aptos, GetUnbackedMintCapFuncAddr, [aave]);
    expect(newaaveUnbackedMintCap).toBe(newUnbackedMintCap);
  });

  it("Updates the unbackedMintCap of aave via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    const newUnbackedMintCap = "20000";
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetUnbackedMintCapFuncAddr, [aave, newUnbackedMintCap]));
    const [newaaveUnbackedMintCap] = await View(aptos, GetUnbackedMintCapFuncAddr, [aave]);
    expect(newaaveUnbackedMintCap).toBe(newUnbackedMintCap);
  });

  it("Updates the borrowCap of aave via pool admin", async () => {
    const { aave } = testEnv;
    const newBorrowCap = "3000000";
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetBorrowCapFuncAddr, [aave, newBorrowCap]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowCap: newBorrowCap,
    });
  });

  it("Updates the borrowCap of aave risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    const newBorrowCap = "3000000";
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetBorrowCapFuncAddr, [aave, newBorrowCap]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowCap: newBorrowCap,
    });
  });

  it("Updates the supplyCap of aave via pool admin", async () => {
    const { aave } = testEnv;
    const newBorrowCap = "3000000";
    const newSupplyCap = "3000000";
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetSupplyCapFuncAddr, [aave, newBorrowCap]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowCap: newBorrowCap,
      supplyCap: newSupplyCap,
    });
  });

  it("Updates the supplyCap of aave via risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    const newBorrowCap = "3000000";
    const newSupplyCap = "3000000";
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetSupplyCapFuncAddr, [aave, newBorrowCap]));
    await expectReserveConfigurationData(aave, {
      ...baseConfigValues,
      borrowCap: newBorrowCap,
      supplyCap: newSupplyCap,
    });
  });

  it("Updates bridge protocol fee equal to PERCENTAGE_FACTOR", async () => {
    const newProtocolFee = "10000";
    await Transaction(aptos, PoolManager, PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr, [newProtocolFee]);
    const [newBridgeProtocolFee] = await View(aptos, PoolGetBridgeProtocolFeeFuncAddr, []);
    expect(newBridgeProtocolFee).toBe(newProtocolFee);
  });

  it("Updates bridge protocol fee", async () => {
    const newProtocolFee = "2000";
    await Transaction(aptos, PoolManager, PoolConfiguratorUpdateBridgeProtocolFeeFuncAddr, [newProtocolFee]);
    const [newBridgeProtocolFee] = await View(aptos, PoolGetBridgeProtocolFeeFuncAddr, []);
    expect(newBridgeProtocolFee).toBe(newProtocolFee);
  });

  it("Updates flash loan premiums equal to PERCENTAGE_FACTOR: 10000 toProtocol, 10000 total", async () => {
    const newPremiumTotal = "10000";
    const newPremiumToProtocol = "10000";

    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr, [newPremiumTotal]),
    );
    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr, [
        newPremiumToProtocol,
      ]),
    );

    const [premiumTotal] = await View(aptos, PoolGetFlashloanPremiumTotalFuncAddr, []);
    const [premiumToProtocol] = await View(aptos, PoolGetFlashloanPremiumToProtocolFuncAddr, []);

    expect(premiumTotal).toBe(newPremiumTotal);
    expect(premiumToProtocol).toBe(newPremiumToProtocol);
  });

  it("Updates flash loan premiums: 10 toProtocol, 40 total", async () => {
    const newPremiumTotal = "40";
    const newPremiumToProtocol = "10";

    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumTotalFuncAddr, [newPremiumTotal]),
    );
    expect(
      await Transaction(aptos, PoolManager, PoolConfiguratorUpdateFlashloanPremiumToProtocolFuncAddr, [
        newPremiumToProtocol,
      ]),
    );

    const [premiumTotal] = await View(aptos, PoolGetFlashloanPremiumTotalFuncAddr, []);
    const [premiumToProtocol] = await View(aptos, PoolGetFlashloanPremiumToProtocolFuncAddr, []);

    expect(premiumTotal).toBe(newPremiumTotal);
    expect(premiumToProtocol).toBe(newPremiumToProtocol);
  });

  it("Sets siloed borrowing through the risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetSiloedBorrowingFuncAddr, [aave, false]));
    const [newSiloedBorrowing] = await View(aptos, GetSiloedBorrowingFuncAddr, [aave]);
    expect(newSiloedBorrowing).toBe(false);
  });

  it("Sets a debt ceiling through the pool admin", async () => {
    const { aave } = testEnv;
    const newDebtCeiling = "10";
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetDebtCeilingFuncAddr, [aave, newDebtCeiling]));
    const [newCeiling] = await View(aptos, GetDebtCeilingFuncAddr, [aave]);
    expect(newCeiling).toBe(newDebtCeiling);
  });

  it("Sets a debt ceiling through the risk admin", async () => {
    const { aave, riskAdmin } = testEnv;
    const newDebtCeiling = "10";
    expect(await Transaction(aptos, riskAdmin, PoolConfiguratorSetDebtCeilingFuncAddr, [aave, newDebtCeiling]));
    const [newCeiling] = await View(aptos, GetDebtCeilingFuncAddr, [aave]);
    expect(newCeiling).toBe(newDebtCeiling);
  });

  it("Sets a debt ceiling larger than max (revert expected)", async () => {
    const { aave } = testEnv;
    const MAX_VALID_DEBT_CEILING = 1099511627775;
    const debtCeiling = MAX_VALID_DEBT_CEILING + 1;
    const [currentCeiling] = await View(aptos, GetDebtCeilingFuncAddr, [aave]);
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetDebtCeilingFuncAddr, [aave, debtCeiling]);
    } catch (err) {
      // console.log("err:", err.toString());
      expect(err.toString().includes("reserve: 0x49")).toBe(true);
    }
    const [newCeiling] = await View(aptos, GetDebtCeilingFuncAddr, [aave]);
    expect(newCeiling).toBe(currentCeiling);
  });

  it("Read debt ceiling decimals", async () => {
    const [debtCeilingDecimals] = await View(aptos, GetDebtCeilingDecimalsFuncAddr, []);
    expect(debtCeilingDecimals).toBe("2");
  });

  it("Check that the reserves have flashloans enabled", async () => {
    const { aave, usdc, dai } = testEnv;
    const [aaveFlashLoanEnabled] = await View(aptos, GetFlashLoanEnabledFuncAddr, [aave]);
    expect(aaveFlashLoanEnabled).toBe(false);

    const [usdcFlashLoanEnabled] = await View(aptos, GetFlashLoanEnabledFuncAddr, [usdc]);
    expect(usdcFlashLoanEnabled).toBe(true);

    const [daiFlashLoanEnabled] = await View(aptos, GetFlashLoanEnabledFuncAddr, [dai]);
    expect(daiFlashLoanEnabled).toBe(true);
  });

  it("Disable aave flashloans", async () => {
    const { aave } = testEnv;
    expect(await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveFlashLoaningFuncAddr, [aave, false]));
    const [aaveFlashLoanEnabled] = await View(aptos, GetFlashLoanEnabledFuncAddr, [aave]);
    expect(aaveFlashLoanEnabled).toBe(false);
  });
});
