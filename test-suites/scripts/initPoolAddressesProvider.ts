/* eslint-disable no-console */
/* eslint-disable no-await-in-loop */
import { AptosProvider } from "../wrappers/aptosProvider";
import { PoolAddressesProviderClient } from "../clients/poolAddressesProviderClient";
import { PoolManager } from "../configs/pool";
import { AclManager } from "../configs/aclManage";
import { OracleManager } from "../configs/oracle";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function initPoolAddressesProvider() {
  // global aptos provider
  const aptosProvider = new AptosProvider();
  const poolAddressesProviderClient = new PoolAddressesProviderClient(aptosProvider, PoolManager);

  let txReceipt = await poolAddressesProviderClient.setAclAdmin(AclManager.accountAddress);
  console.log(
    chalk.yellow(`Acl admin set to ${AclManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`),
  );

  txReceipt = await poolAddressesProviderClient.setAclManager(AclManager.accountAddress);
  console.log(
    chalk.yellow(`Acl maanger set to ${AclManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`),
  );

  txReceipt = await poolAddressesProviderClient.setPoolConfigurator(PoolManager.accountAddress);
  console.log(
    chalk.yellow(`Pool configurator set to ${PoolManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`),
  );

  txReceipt = await poolAddressesProviderClient.setPoolDataProvider(PoolManager.accountAddress);
  console.log(
    chalk.yellow(`Pool data provider set to ${PoolManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`),
  );

  txReceipt = await poolAddressesProviderClient.setPoolImpl(PoolManager.accountAddress);
  console.log(
    chalk.yellow(
      `Pool implementation set to ${PoolManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`,
    ),
  );

  txReceipt = await poolAddressesProviderClient.setPriceOracle(OracleManager.accountAddress);
  console.log(
    chalk.yellow(`Price Oracle set to ${OracleManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`),
  );

  txReceipt = await poolAddressesProviderClient.setPriceOracleSentinel(OracleManager.accountAddress);
  console.log(
    chalk.yellow(
      `Price Oracle Sentinel set to ${OracleManager.accountAddress.toString()} with tx hash = ${txReceipt.hash}`,
    ),
  );
}
