import { getMetadataAddress, UnderlyingGetMetadataBySymbolFuncAddr, WETH } from "../configs/tokens";
import { View } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  PoolGetReserveAddressByIdFuncAddr,
  PoolGetReserveDataFuncAddr,
  PoolMaxNumberReservesFuncAddr,
  ReserveData,
} from "../configs/pool";

describe("Pool: getReservesList", () => {
  it("User gets address of reserve by id", async () => {
    const wethAddress = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);

    const reserveData = await View(aptos, PoolGetReserveDataFuncAddr, [wethAddress]);
    const { id } = reserveData[0] as ReserveData;
    const [reserveAddress] = await View(aptos, PoolGetReserveAddressByIdFuncAddr, [id.toString()]);

    await expect(reserveAddress).toBe(wethAddress);
  });

  it("User calls `getReservesList` with a wrong id (id > reservesCount)", async () => {
    // MAX_NUMBER_RESERVES is always greater than reservesCount
    const [maxNumberOfReserves] = await View(aptos, PoolMaxNumberReservesFuncAddr, []);

    const [reserveAddress] = await View(aptos, PoolGetReserveAddressByIdFuncAddr, [
      ((maxNumberOfReserves as number) + 1).toString(),
    ]);

    await expect(reserveAddress).toBe("0x0");
  });
});
