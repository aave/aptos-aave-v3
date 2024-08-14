import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  PoolConfiguratorSetReserveBorrowingFuncAddr,
  PoolManager,
  PoolMaxNumberReservesFuncAddr,
} from "../configs/pool";
import { FinalizeTransferFuncAddr } from "../configs/supplyBorrow";
import { ZERO_ADDRESS } from "../helpers/constants";

describe("Pool: Edge cases", () => {
  const MAX_NUMBER_RESERVES = 128;

  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("Check initialization", async () => {
    const [maxNumberReserves] = await View(aptos, PoolMaxNumberReservesFuncAddr, []);
    expect(maxNumberReserves).toBe(MAX_NUMBER_RESERVES.toString());
  });

  it("Tries to call `finalizeTransfer()` by a non-aToken address (revert expected)", async () => {
    const { dai, users } = testEnv;
    try {
      await Transaction(aptos, PoolManager, FinalizeTransferFuncAddr, [
        dai,
        users[0].accountAddress.toString(),
        users[1].accountAddress.toString(),
        0,
        0,
        0,
      ]);
    } catch (err) {
      expect(err.toString().includes("supply_logic: 0xb")).toBe(true);
    }
  });

  it("Activates the zero address reserve for borrowing via pool admin (expect revert)", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorSetReserveBorrowingFuncAddr, [ZERO_ADDRESS, true]);
    } catch (err) {
      expect(err.toString().includes("pool: 0x52")).toBe(true);
    }
  });
});
