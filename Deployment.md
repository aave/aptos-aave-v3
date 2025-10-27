## Deployment Script

### Pre-requisite

You need to have an account on Aptos testnet/mainnet that

1. is sufficiently funded for package publishing and transaction execution,
2. you know the name of this account in your Aptos profile,
   which can be typically found in a file named `.aptos/config.yaml`
3. is one of the active owners of the `PoolAdmin` multi-sig account

In the rest of this document, we will use `<deployer_profile_name>` to represent
the name of this account in your Aptos profile.

### Publish Packages

```bash
# the following commands publishes all packages on the object account
./deploy.py testnet --deployer "<deployer_profile_name>" publish-config
./deploy.py testnet --deployer "<deployer_profile_name>" publish-acl
./deploy.py testnet --deployer "<deployer_profile_name>" publish-math
./deploy.py testnet --deployer "<deployer_profile_name>" publish-mock-underlyings
./deploy.py testnet --deployer "<deployer_profile_name>" publish-oracle
./deploy.py testnet --deployer "<deployer_profile_name>" publish-core
./deploy.py testnet --deployer "<deployer_profile_name>" publish-data
```

The addresses of published packages can be found at `deploy-*-object.txt`
files, respectively. For example, the address where `aave_pool` is published
will be stored in `deploy-aave_pool-object.txt`.

### Run Setup Scripts

The first thing to do is to configure the Access Control List via:

```bash
./deploy.py testnet --deployer "<deployer_profile_name>" configure-acl
```

This will grant necessary roles to known accounts addresses and will transfer
the super-admin role to the `AaveACL` multisig account. After this step, the
deployer no longer has the super-admin role, and every role change will need to
go through the `AaveACL` multisig account.

The rest of the configuration steps involve the `PoolAdmin` multisig account.
Running the following commands will only submit transactions to the `PoolAdmin`
multisig account for approval. The final execution of the proposed payload will
be triggered by a second transaction that executes the approved proposal.

```bash
./deploy.py testnet --deployer "<deployer_profile_name>" setup-configure-emodes
./deploy.py testnet --deployer "<deployer_profile_name>" setup-create-reserves
./deploy.py testnet --deployer "<deployer_profile_name>" setup-configure-reserves
./deploy.py testnet --deployer "<deployer_profile_name>" setup-configure-interest-rates
./deploy.py testnet --deployer "<deployer_profile_name>" setup-configure-price-feeds

(optional if gho reserve is to be configured too)
./deploy.py testnet --deployer "<deployer_profile_name>" setup-gho-reserve
```

### Transfer Package Ownerships

Once deployed, the ownership of the objects that host the published packages can
be transferred to corresponding multisig accounts using the following commands:

```bash
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-config
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-acl
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-math
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-mock-underlyings
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-oracle
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-core
./deploy.py testnet --deployer "<deployer_profile_name>" change-owner-data
```

### Upgrade Packages

If package upgrading is needed, use one of the following command to upgrade
the package that must be already published on the object account (with address
stored at the `deploy-*-object.txt`). This will use the multisig upgrading
procedure as the packages are now assumed to have been transferred to the
corresponding multisig accounts (and hence, are no longer owned by the deployer).

```bash
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-config
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-acl
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-math
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-mock-underlyings
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-oracle
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-core
./deploy.py testnet --deployer "<deployer_profile_name>" upgrade-data
```

### Local Testnet (localnet) Simulation

You can also simulate the whole deployment process on a locally spawn testnet
(localnet), using the following command:

```bash
./deploy.py localnet
```

You will be greeted with

> Press Enter when localnet is deployed (i.e., until "Setup is complete"):

So wait around 30 seconds, and hit "Enter" when you see

> Setup is complete, you can now use the localnet!

It will prompt you with either creating a new `<deployer_profile_name>` profile
or reusing an existing one.

After that, package publishing and the setup steps will be executed by
themselves. Setup also goes through a multisig account on localnet, but no
additional approval is needed and the proposal execution is automated as well.
