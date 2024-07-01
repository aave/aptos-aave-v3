import { initializeMakeSuite, testEnv } from "../configs/config";
import { Transaction, View } from "../helpers/helper";
import { aptos } from "../configs/common";
import { GetAssetPriceFuncAddr, OracleManager, SetAssetPriceFuncAddr } from "../configs/oracle";
import { oneEther } from "../helpers/constants";

describe("AaveOracle", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("Get price of asset with no asset source", async () => {
    const { weth } = testEnv;
    const sourcePrice = "100";

    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [weth, sourcePrice]);

    const [newPrice] = await View(aptos, GetAssetPriceFuncAddr, [weth]);
    expect(newPrice).toBe(sourcePrice);
  });

  it("Get price of asset with 0 price but non-zero fallback price", async () => {
    const { weth } = testEnv;
    const fallbackPrice = oneEther.toString();

    await Transaction(aptos, OracleManager, SetAssetPriceFuncAddr, [weth, fallbackPrice]);

    const [newPrice] = await View(aptos, GetAssetPriceFuncAddr, [weth]);
    expect(newPrice).toBe(fallbackPrice);
  });
});
