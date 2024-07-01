import { BigNumber } from "ethers";
import { expect, test, describe } from "@jest/globals";
import { BigNumberWrapper } from "../helpers/wadraymath";
import { HALF_WAD, RAY, WAD, HALF_RAY, MAX_UINT_AMOUNT } from "../helpers/constants";

describe("WadRayMath", () => {
  let wrapper: BigNumberWrapper;

  beforeAll(async () => {
    wrapper = new BigNumberWrapper();
  });

  test("Plain getters", async () => {
    expect(wrapper.wad().eq(WAD)).toBeTruthy();
    expect(wrapper.halfWad().eq(HALF_WAD)).toBeTruthy();
    expect(wrapper.ray().eq(RAY)).toBeTruthy();
    expect(wrapper.halfRay().eq(HALF_RAY)).toBeTruthy();
  });

  test("wadMul()", async () => {
    const a = BigNumber.from("134534543232342353231234");
    const b = BigNumber.from("13265462389132757665657");

    expect(wrapper.wadMul(a, b).eq(a.wadMul(b))).toBeTruthy();
    expect(wrapper.wadMul(BigNumber.from(0), b).toString()).toEqual("0");
    expect(wrapper.wadMul(a, BigNumber.from(0)).toString()).toEqual("0");

    const tooLargeA = BigNumber.from(MAX_UINT_AMOUNT).sub(HALF_WAD).div(b).add(1);
    expect(() => {
      const result = wrapper.wadMul(tooLargeA, b).toNumber();
    }).toThrow();
  });

  test("wadDiv()", async () => {
    const a = BigNumber.from("134534543232342353231234");
    const b = BigNumber.from("13265462389132757665657");

    expect(wrapper.wadDiv(a, b).eq(a.wadDiv(b))).toBeTruthy();

    const halfB = b.div(2);
    const tooLargeA = BigNumber.from(MAX_UINT_AMOUNT).sub(halfB).div(WAD).add(1);

    expect(() => {
      const result = wrapper.wadDiv(tooLargeA, b).toNumber();
    }).toThrow();

    expect(() => {
      const result = wrapper.wadDiv(a, BigNumber.from(0)).toNumber();
    }).toThrow();
  });

  test("rayMul()", async () => {
    const a = BigNumber.from("134534543232342353231234");
    const b = BigNumber.from("13265462389132757665657");

    expect(wrapper.rayMul(a, b).eq(a.rayMul(b))).toBeTruthy();
    expect(wrapper.rayMul(BigNumber.from(0), b).eq(BigNumber.from(0))).toBeTruthy();
    expect(wrapper.rayMul(a, BigNumber.from(0)).eq(BigNumber.from(0))).toBeTruthy();

    const tooLargeA = BigNumber.from(MAX_UINT_AMOUNT).sub(HALF_RAY).div(b).add(1);
    expect(() => {
      const result = wrapper.rayMul(tooLargeA, b).toNumber();
    }).toThrow();
  });

  test("rayDiv()", async () => {
    const a = BigNumber.from("134534543232342353231234");
    const b = BigNumber.from("13265462389132757665657");

    expect(wrapper.rayDiv(a, b).eq(a.rayDiv(b))).toBeTruthy();

    const halfB = b.div(2);
    const tooLargeA = BigNumber.from(MAX_UINT_AMOUNT).sub(halfB).div(RAY).add(1);
    expect(() => {
      const result = wrapper.rayDiv(tooLargeA, b).toNumber();
    }).toThrow();
    expect(() => {
      const result = wrapper.rayDiv(a, BigNumber.from(0)).toNumber();
    }).toThrow();
  });

  test("rayToWad()", async () => {
    const half = BigNumber.from(10).pow(9).div(2);

    const a = BigNumber.from("10").pow(27);
    expect(wrapper.rayToWad(a).eq(a.rayToWad())).toBeTruthy();

    const roundDown = BigNumber.from("10").pow(27).add(half.sub(1));
    expect(wrapper.rayToWad(roundDown).eq(roundDown.rayToWad())).toBeTruthy();

    const roundUp = BigNumber.from("10").pow(27).add(half);
    expect(wrapper.rayToWad(roundUp).eq(roundUp.rayToWad())).toBeTruthy();

    const tooLarge = BigNumber.from(MAX_UINT_AMOUNT).sub(half).add(1);
    expect(wrapper.rayToWad(tooLarge).eq(tooLarge.rayToWad())).toBeTruthy();
  });

  test("rayToWad()", async () => {
    const a = BigNumber.from("10").pow(18);
    expect(wrapper.wadToRay(a).eq(a.wadToRay())).toBeTruthy();

    const ratio = BigNumber.from(10).pow(9);
    const tooLarge = BigNumber.from(MAX_UINT_AMOUNT).div(ratio).add(1);
    expect(() => {
      const result = wrapper.wadToRay(tooLarge).toNumber();
    }).toThrow();
  });
});
