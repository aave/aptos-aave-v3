import { BigNumber } from "@ethersproject/bignumber";
import { BigNumberish } from "ethers";

import { HALF_PERCENTAGE, HALF_RAY, HALF_WAD, PERCENTAGE_FACTOR, RAY, WAD, WAD_RAY_RATIO } from "./constants";

declare module "@ethersproject/bignumber" {
  interface BigNumber {
    ray: () => BigNumber;
    wad: () => BigNumber;
    halfRay: () => BigNumber;
    halfWad: () => BigNumber;
    halfPercentage: () => BigNumber;
    percentageFactor: () => BigNumber;
    wadMul: (a: BigNumber) => BigNumber;
    wadDiv: (a: BigNumber) => BigNumber;
    rayMul: (a: BigNumber) => BigNumber;
    rayDiv: (a: BigNumber) => BigNumber;
    percentMul: (a: BigNumberish) => BigNumber;
    percentDiv: (a: BigNumberish) => BigNumber;
    rayToWad: () => BigNumber;
    wadToRay: () => BigNumber;
    negated: () => BigNumber;
  }
}

BigNumber.prototype.ray = (): BigNumber => BigNumber.from(RAY);
BigNumber.prototype.wad = (): BigNumber => BigNumber.from(WAD);
BigNumber.prototype.halfRay = (): BigNumber => BigNumber.from(HALF_RAY);
BigNumber.prototype.halfWad = (): BigNumber => BigNumber.from(HALF_WAD);
BigNumber.prototype.halfPercentage = (): BigNumber => BigNumber.from(HALF_PERCENTAGE);
BigNumber.prototype.percentageFactor = (): BigNumber => BigNumber.from(PERCENTAGE_FACTOR);

// eslint-disable-next-line func-names
BigNumber.prototype.wadMul = function (other: BigNumber): BigNumber {
  return this.halfWad().add(this.mul(other)).div(this.wad());
};

// eslint-disable-next-line func-names
BigNumber.prototype.wadDiv = function (other: BigNumber): BigNumber {
  const halfOther = other.div(2);
  return halfOther.add(this.mul(this.wad())).div(other);
};

// eslint-disable-next-line func-names
BigNumber.prototype.rayMul = function (other: BigNumber): BigNumber {
  return this.halfRay().add(this.mul(other)).div(this.ray());
};

// eslint-disable-next-line func-names
BigNumber.prototype.rayDiv = function (other: BigNumber): BigNumber {
  const halfOther = other.div(2);
  return halfOther.add(this.mul(this.ray())).div(other);
};

// eslint-disable-next-line func-names
BigNumber.prototype.percentMul = function (bps: BigNumberish): BigNumber {
  return this.halfPercentage().add(this.mul(bps)).div(PERCENTAGE_FACTOR);
};

// eslint-disable-next-line func-names
BigNumber.prototype.percentDiv = function (bps: BigNumberish): BigNumber {
  const halfBps = BigNumber.from(bps).div(2);
  return halfBps.add(this.mul(PERCENTAGE_FACTOR)).div(bps);
};

// eslint-disable-next-line func-names
BigNumber.prototype.rayToWad = function (): BigNumber {
  const halfRatio = BigNumber.from(WAD_RAY_RATIO).div(2);
  return halfRatio.add(this).div(WAD_RAY_RATIO);
};

// eslint-disable-next-line func-names
BigNumber.prototype.wadToRay = function (): BigNumber {
  return this.mul(WAD_RAY_RATIO);
};

// eslint-disable-next-line func-names
BigNumber.prototype.negated = function (): BigNumber {
  return this.mul(-1);
};

export class BigNumberWrapper {
  // eslint-disable-next-line class-methods-use-this
  public wad(): BigNumber {
    return BigNumber.prototype.wad();
  }

  // eslint-disable-next-line class-methods-use-this
  public halfWad(): BigNumber {
    return BigNumber.prototype.halfWad();
  }

  // eslint-disable-next-line class-methods-use-this
  public ray(): BigNumber {
    return BigNumber.prototype.ray();
  }

  // eslint-disable-next-line class-methods-use-this
  public halfRay(): BigNumber {
    return BigNumber.prototype.halfRay();
  }

  // eslint-disable-next-line class-methods-use-this
  public halfPercentage(): BigNumber {
    return BigNumber.prototype.halfPercentage();
  }

  // eslint-disable-next-line class-methods-use-this
  public percentageFactor(): BigNumber {
    return BigNumber.prototype.percentageFactor();
  }

  // eslint-disable-next-line class-methods-use-this
  public wadMul(a: BigNumber, b: BigNumber): BigNumber {
    return a.wadMul(b);
  }

  // eslint-disable-next-line class-methods-use-this
  public wadDiv(a: BigNumber, b: BigNumber): BigNumber {
    return a.wadDiv(b);
  }

  // eslint-disable-next-line class-methods-use-this
  public rayMul(a: BigNumber, b: BigNumber): BigNumber {
    return a.rayMul(b);
  }

  // eslint-disable-next-line class-methods-use-this
  public rayDiv(a: BigNumber, b: BigNumber): BigNumber {
    return a.rayDiv(b);
  }

  // eslint-disable-next-line class-methods-use-this
  public percentMul(a: BigNumber, bps: BigNumberish): BigNumber {
    return a.percentMul(bps);
  }

  // eslint-disable-next-line class-methods-use-this
  public percentDiv(a: BigNumber, bps: BigNumberish): BigNumber {
    return a.percentDiv(bps);
  }

  // eslint-disable-next-line class-methods-use-this
  public rayToWad(a: BigNumber): BigNumber {
    const halfRatio = BigNumber.from(WAD_RAY_RATIO).div(2);
    return halfRatio.add(a).div(WAD_RAY_RATIO);
  }

  // eslint-disable-next-line class-methods-use-this
  public wadToRay(a: BigNumber): BigNumber {
    return a.mul(WAD_RAY_RATIO);
  }

  // eslint-disable-next-line class-methods-use-this
  public negated(a: BigNumber): BigNumber {
    return a.negated();
  }
}
