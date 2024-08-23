/* eslint-disable no-console */
import { ATokenManager, UnderlyingManager, VariableManager } from "../configs/tokens";
import { AclClient } from "../clients/aclClient";

import { AclManager } from "../configs/aclManage";
import { PoolManager } from "../configs/pool";
import { AptosProvider } from "../wrappers/aptosProvider";

// eslint-disable-next-line import/no-commonjs
const chalk = require("chalk");

export async function createRoles() {
  const aptosProvider = new AptosProvider();
  const aclClient = new AclClient(aptosProvider, AclManager);

  // acl manager grants itself a default admin role
  let txReceipt = await aclClient.grantDefaultRoleAdmin();
  console.log(
    chalk.yellow(
      `Added ${AclManager.accountAddress.toString()} as a default admin role with tx hash = ${txReceipt.hash}`,
    ),
  );

  // add asset listing authorities
  const assetListingAuthoritiesAddresses = [UnderlyingManager, VariableManager, ATokenManager].map(
    (auth) => auth.accountAddress,
  );
  for (const auth of assetListingAuthoritiesAddresses) {
    // eslint-disable-next-line no-await-in-loop,@typescript-eslint/no-shadow
    const txReceipt = await aclClient.addAssetListingAdmin(auth);
    console.log(chalk.yellow(`Added ${auth} as an asset listing authority with tx hash = ${txReceipt.hash}`));
  }

  // create pool admin
  txReceipt = await aclClient.addPoolAdmin(PoolManager.accountAddress);
  console.log(
    chalk.yellow(`Added ${PoolManager.accountAddress.toString()} as a pool admin with tx hash = ${txReceipt.hash}`),
  );
}
