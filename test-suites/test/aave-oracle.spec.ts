import { BigNumber } from "ethers";
import { initializeMakeSuite, testEnv } from "../configs/config";
import { OracleManager } from "../configs/oracle";
import { oneEther } from "../helpers/constants";
import { OracleClient } from "../clients/oracleClient";
import { AptosProvider } from "../wrappers/aptosProvider";

describe("AaveOracle", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("Get price of asset with no asset source", async () => {
    const { weth } = testEnv;
    const sourcePrice = "100";

    const oracleClient = new OracleClient(new AptosProvider(), OracleManager);
    await oracleClient.setAssetPrice(weth, BigNumber.from(sourcePrice));

    const newPrice = await oracleClient.getAssetPrice(weth);
    expect(newPrice.toString()).toBe(sourcePrice);
  });

  it("Get price of asset with 0 price but non-zero fallback price", async () => {
    const { weth } = testEnv;
    const fallbackPrice = oneEther.toString();

    const oracleClient = new OracleClient(new AptosProvider(), OracleManager);
    await oracleClient.setAssetPrice(weth, BigNumber.from(fallbackPrice));

    const newPrice = await oracleClient.getAssetPrice(weth);
    expect(newPrice.toString()).toBe(fallbackPrice);
  });
});
