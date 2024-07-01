import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";
import { PoolConfiguratorDropReserveFuncAddr, PoolManager } from "../configs/pool";
import { ZERO_ADDRESS } from "../helpers/constants";
import { initializeMakeSuite, testEnv } from "../configs/config";

describe("Pool: Drop Reserve", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("Drop an asset that is not pool admin", async () => {
    const {
      users: [, , , , user],
    } = testEnv;
    try {
      await Transaction(aptos, user, PoolConfiguratorDropReserveFuncAddr, [user.accountAddress.toString()]);
    } catch (err) {
      expect(err.toString().includes("pool_configurator: 0x1")).toBe(true);
    }
  });

  it("Drop an asset that is not a listed reserve should fail", async () => {
    try {
      await Transaction(aptos, PoolManager, PoolConfiguratorDropReserveFuncAddr, [ZERO_ADDRESS]);
    } catch (err) {
      expect(err.toString().includes("pool: 0x4d")).toBe(true);
    }
  });
});
