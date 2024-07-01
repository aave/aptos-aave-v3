/* eslint-disable no-await-in-loop */
import dotenv from "dotenv";
import path from "path";
import { Account, AccountAddress } from "@aptos-labs/ts-sdk";
import { BigNumber } from "ethers";
import { AclClient } from "../clients/aclClient";
import { ATokensClient } from "../clients/aTokensClient";
import { UnderlyingTokensClient } from "../clients/underlyingTokensClient";
import { VariableTokensClient } from "../clients/variableTokensClient";
import { PoolClient } from "../clients/poolClient";
import { CoreClient } from "../clients/coreClient";
import { AptosProvider } from "../wrappers/aptosProvider";
import { getAccounts } from "../configs/config";
import { AAVE_REFERRAL } from "../helpers/constants";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

(async () => {
  // global aptos provider
  const aptosProvider = new AptosProvider();

  // all atokens-related operations client
  const AclManager = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("aave_acl") });
  const aclClient = new AclClient(aptosProvider, AclManager);

  // all atokens-related operations client
  const ATokenManager = Account.fromPrivateKey({
    privateKey: aptosProvider.getProfilePrivateKeyByName("a_tokens"),
  });
  const aTokensClient = new ATokensClient(aptosProvider, ATokenManager);

  // all underlying-tokens-related operations client
  const UnderlyingManager = Account.fromPrivateKey({
    privateKey: aptosProvider.getProfilePrivateKeyByName("underlying_tokens"),
  });
  const underlyingTokensClient = new UnderlyingTokensClient(aptosProvider, UnderlyingManager);

  // all variable-tokens-related operations client
  const VariableManager = Account.fromPrivateKey({
    privateKey: aptosProvider.getProfilePrivateKeyByName("variable_tokens"),
  });
  const variableTokensClient = new VariableTokensClient(aptosProvider, VariableManager);

  // all pool-related operations client
  const PoolManager = Account.fromPrivateKey({
    privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
  });
  const poolClient = new PoolClient(aptosProvider, PoolManager);

  // all core-related operations client (supply, borrow, withdraw, repay)
  const SupplyBorrowManager = Account.fromPrivateKey({
    privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
  });
  const coreClient = new CoreClient(aptosProvider, SupplyBorrowManager);

  try {
    // ==============================MINT UNDERLYINGS FOR A TEST USER ===============================================
    console.log(chalk.yellow("---------------------------------------------"));
    console.log(chalk.cyan("Minting underlyings for test user..."));
    // get all reserve underlying tokens
    const allReserveUnderlyingTokens = await poolClient.getAllReservesTokens();
    const supplier = (await getAccounts()).at(0);
    const baseMintAmount = 1000;

    for (const reserveUnderlyingToken of allReserveUnderlyingTokens) {
      const underlyingSymbol = await underlyingTokensClient.symbol(reserveUnderlyingToken.tokenAddress);
      const underlyingDecimals = await underlyingTokensClient.decimals(reserveUnderlyingToken.tokenAddress);
      const mintAmount = BigNumber.from(10).pow(underlyingDecimals).mul(baseMintAmount);
      const txReceipt = await underlyingTokensClient.mint(
        supplier.accountAddress,
        mintAmount,
        reserveUnderlyingToken.tokenAddress,
      );
      console.log(
        chalk.green(`Minted ${mintAmount.toString()} ${underlyingSymbol.toUpperCase()} to user account ${supplier.accountAddress.toString()}.
        Tx hash = ${txReceipt.hash}`),
      );
    }
    console.log(chalk.green("Minting underlyings for test user finished successfully!"));

    // ==============================USER SUPPLIES UNDERLYING AND GETS ATOKENS===============================================
    console.log(chalk.yellow("---------------------------------------------"));
    console.log(chalk.cyan("Supplying assets..."));
    coreClient.setSigner(supplier);
    for (const reserveUnderlyingToken of allReserveUnderlyingTokens) {
      const underlyingSymbol = await underlyingTokensClient.symbol(reserveUnderlyingToken.tokenAddress);
      const underlyingDecimals = await underlyingTokensClient.decimals(reserveUnderlyingToken.tokenAddress);
      const depositAmount = BigNumber.from(10).pow(underlyingDecimals).mul(baseMintAmount).div(2);
      // set the supplier to be the signer
      const txReceipt = await coreClient.supply(
        reserveUnderlyingToken.tokenAddress,
        depositAmount,
        supplier.accountAddress,
        AAVE_REFERRAL,
      );
      console.log(
        chalk.green(`User ${supplier.accountAddress.toString()} supplied ${depositAmount.toString()} ${underlyingSymbol.toUpperCase()} to the pool.
        Tx hash = ${txReceipt.hash}`),
      );
    }
    console.log(chalk.green("Supplying assets for test user finished successfully!"));

    // ==============================USER BORROWS SOME ASSETS FROM POOL===============================================
    console.log(chalk.yellow("---------------------------------------------"));
    console.log(chalk.cyan("Borrowing assets..."));
    const underlyingsToBorrowSymbol = ["DAI", "WETH"];
    coreClient.setSigner(supplier);
    const borrowedAssetsWithAmounts = new Map<string, BigNumber>();
    for (const underlyingToBorrowSymbol of underlyingsToBorrowSymbol) {
      const underlyingToBorrow = await underlyingTokensClient.getMetadataBySymbol(underlyingToBorrowSymbol);
      const underlyingToBorrowAccAddress = AccountAddress.fromString(underlyingToBorrow);
      const underlyingToBorrowDecimals = await underlyingTokensClient.decimals(underlyingToBorrowAccAddress);
      const borrowAmount = BigNumber.from(10).pow(underlyingToBorrowDecimals).mul(baseMintAmount).div(5);
      borrowedAssetsWithAmounts.set(underlyingToBorrowSymbol, borrowAmount);
      const txReceipt = await coreClient.borrow(
        underlyingToBorrowAccAddress,
        supplier.accountAddress,
        borrowAmount,
        1,
        AAVE_REFERRAL,
        true,
      );
      console.log(
        chalk.green(`User ${supplier.accountAddress.toString()} borrowed ${borrowAmount.toString()} ${underlyingToBorrowSymbol.toUpperCase()} from the pool.
        Tx hash = ${txReceipt.hash}`),
      );
    }
    console.log(chalk.green("Borrowing assets for test user finished successfully!"));

    // ==============================USER WITHDRAWS SOME HIS BORROWED ASSET FROM POOL===============================================
    console.log(chalk.yellow("---------------------------------------------"));
    console.log(chalk.cyan("Withdrawing assets..."));
    const underlyingsToWithdrawSymbols = ["AAVE", "USDC"];
    coreClient.setSigner(supplier);

    for (const underlyingToWithdrawSymbol of underlyingsToWithdrawSymbols) {
      const underlyingToWithdraw = await underlyingTokensClient.getMetadataBySymbol(underlyingToWithdrawSymbol);
      const underlyingToWithdrawAccAddress = AccountAddress.fromString(underlyingToWithdraw);
      const underlyingToWithdrawDecimals = await underlyingTokensClient.decimals(underlyingToWithdrawAccAddress);
      const withdrawAmount = BigNumber.from(10).pow(underlyingToWithdrawDecimals).mul(baseMintAmount).div(5);

      const txReceipt = await coreClient.withdraw(
        underlyingToWithdrawAccAddress,
        withdrawAmount,
        supplier.accountAddress,
      );
      console.log(
        chalk.green(`User ${supplier.accountAddress.toString()} withdrew ${withdrawAmount.toString()} ${underlyingToWithdrawSymbol.toUpperCase()} from the pool.
        Tx hash = ${txReceipt.hash}`),
      );
    }
    console.log(chalk.green("Withdrawing assets for test user finished successfully!"));

    // ==============================USER REPAYS THE HE BORROWED FROM POOL USING THE SAME TOKENS ===============================================
    console.log(chalk.yellow("---------------------------------------------"));
    console.log(chalk.cyan("Repaying assets..."));
    coreClient.setSigner(supplier);

    for (const [key, borrowedValue] of borrowedAssetsWithAmounts.entries()) {
      const underlyingToRepay = await underlyingTokensClient.getMetadataBySymbol(key);
      const underlyingToRepayAccAddress = AccountAddress.fromString(underlyingToRepay);

      const txReceipt = await coreClient.repay(
        underlyingToRepayAccAddress,
        borrowedValue,
        1,
        supplier.accountAddress,
        false,
      );
      console.log(
        chalk.green(`User ${supplier.accountAddress.toString()} repayed ${borrowedValue.toString()} ${key.toUpperCase()} from the pool.
        Tx hash = ${txReceipt.hash}`),
      );
    }
    console.log(chalk.green("Repaying assets for test user finished successfully!"));
  } catch (ex) {
    console.error("Exception = ", ex);
  }
})();
