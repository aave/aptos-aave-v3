export const stringToUint8Array = (data: string): Uint8Array => new Uint8Array(Buffer.from(data, "utf8"));

export const stringToHex = (data: string): string => Buffer.from(data).toString("hex");

export const uint8ArrayToString = (data: Uint8Array): string => Buffer.from(data).toString("utf8");
