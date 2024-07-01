import { Transaction } from "../helpers/helper";
import { aptos } from "../configs/common";
import {
  AAAVE,
  AAVE,
  ADAI,
  ATokenCreateTokenFuncAddr,
  ATokenGetMetadataBySymbolFuncAddr,
  ATokenManager,
  AUSDC,
  AWETH,
  DAI,
  getMetadataAddress,
  UnderlyingCreateTokenFuncAddr,
  UnderlyingGetMetadataBySymbolFuncAddr,
  UnderlyingManager,
  USDC,
  VAAVE,
  VariableCreateTokenFuncAddr,
  VariableGetMetadataBySymbolFuncAddr,
  VariableManager,
  VDAI,
  VUSDC,
  VWETH,
  WETH,
} from "../configs/tokens";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

async function createDai() {
  // create underling token
  let txReceipt = await Transaction(aptos, UnderlyingManager, UnderlyingCreateTokenFuncAddr, [
    "100000000000000000",
    "Dai",
    DAI,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
  ]);
  console.log(chalk.green(`Deployed DAI underlying token with tx hash = ${txReceipt.hash}`));

  // get underling token metadata
  const underlingMetadata = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, DAI);
  console.log("DAI underlying metadata address: ", underlingMetadata);

  // create a token
  txReceipt = await Transaction(aptos, ATokenManager, ATokenCreateTokenFuncAddr, [
    "100000000000000000",
    "aDai",
    ADAI,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed ADAI token with tx hash = ${txReceipt.hash}`));

  // get a token metadata
  const aTokenMetadata = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, ADAI);
  console.log("ADAI metadata address: ", aTokenMetadata);

  // create v token
  txReceipt = await Transaction(aptos, VariableManager, VariableCreateTokenFuncAddr, [
    "100000000000000000",
    "vDai",
    VDAI,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed VDAI token with tx hash = ${txReceipt.hash}`));

  const vTokenMetadata = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VDAI);
  console.log("VDAI metadata address:", vTokenMetadata);
}

async function createWeth() {
  // create underlying token
  let txReceipt = await Transaction(aptos, UnderlyingManager, UnderlyingCreateTokenFuncAddr, [
    "100000000000000000",
    "Weth",
    WETH,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
  ]);
  console.log(chalk.green(`Deployed WETH underlying token with tx hash = ${txReceipt.hash}`));

  // get underling token metadata
  const underlingMetadata = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, WETH);
  console.log("WETH underlying metadata address:", underlingMetadata);

  // create a token
  txReceipt = await Transaction(aptos, ATokenManager, ATokenCreateTokenFuncAddr, [
    "100000000000000000",
    "aWeth",
    AWETH,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed AWETH with tx hash = ${txReceipt.hash}`));

  // get a token metadata
  const aTokenMetadata = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AWETH);
  console.log("AWETH metadata address:", aTokenMetadata);

  // create v token
  txReceipt = await Transaction(aptos, VariableManager, VariableCreateTokenFuncAddr, [
    "100000000000000000",
    "vWeth",
    VWETH,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed VWETH with tx hash = ${txReceipt.hash}`));

  const vTokenMetadata = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VWETH);
  console.log("VWETH metadata address:", vTokenMetadata);
}

async function createUsdc() {
  // create underling token
  let txReceipt = await Transaction(aptos, UnderlyingManager, UnderlyingCreateTokenFuncAddr, [
    "100000000000000000",
    "Usdc",
    USDC,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
  ]);
  console.log(chalk.green(`Deployed USDC with tx hash = ${txReceipt.hash}`));

  // get underling token metadata
  const underlingMetadata = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, USDC);
  console.log("USDC underlying metadata address:", underlingMetadata);

  // create a token
  txReceipt = await Transaction(aptos, ATokenManager, ATokenCreateTokenFuncAddr, [
    "100000000000000000",
    "aUsdc",
    AUSDC,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed AUSDC with tx hash = ${txReceipt.hash}`));

  // get a token metadata
  const aTokenMetadata = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AUSDC);
  console.log("AUSDC metadata address:", aTokenMetadata);

  // create v token
  txReceipt = await Transaction(aptos, VariableManager, VariableCreateTokenFuncAddr, [
    "100000000000000000",
    "vUsdc",
    VUSDC,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed VUSDC with tx hash = ${txReceipt.hash}`));

  const vTokenMetadata = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VUSDC);
  console.log("VUSDC metadata address:", vTokenMetadata);
}

async function createAave() {
  // create underling token
  let txReceipt = await Transaction(aptos, UnderlyingManager, UnderlyingCreateTokenFuncAddr, [
    "100000000000000000",
    "Aave",
    AAVE,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
  ]);
  console.log(chalk.green(`Deployed AAVE with tx hash = ${txReceipt.hash}`));

  // get underling token metadata
  const underlingMetadata = await getMetadataAddress(UnderlyingGetMetadataBySymbolFuncAddr, AAVE);
  console.log("AAVE underlying metadata address:", underlingMetadata);

  // create a token
  txReceipt = await Transaction(aptos, ATokenManager, ATokenCreateTokenFuncAddr, [
    "100000000000000000",
    "aAave",
    AAAVE,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed AAAVE with tx hash = ${txReceipt.hash}`));

  // get a token metadata
  const aTokenMetadata = await getMetadataAddress(ATokenGetMetadataBySymbolFuncAddr, AAAVE);
  console.log("AAAVE metadata address:", aTokenMetadata);

  // create v token
  txReceipt = await Transaction(aptos, VariableManager, VariableCreateTokenFuncAddr, [
    "100000000000000000",
    "vAave",
    VAAVE,
    8,
    "https://aptoscan.com/images/empty-coin.svg",
    "https://aptoscan.com",
    underlingMetadata,
    UnderlyingManager.accountAddress.toString(),
  ]);
  console.log(chalk.green(`Deployed VAAVE with tx hash = ${txReceipt.hash}`));

  const vTokenMetadata = await getMetadataAddress(VariableGetMetadataBySymbolFuncAddr, VAAVE);
  console.log("VAAVE metadata address:", vTokenMetadata);
}

export async function createTokens() {
  await createDai();
  await createWeth();
  await createUsdc();
  await createAave();
}
