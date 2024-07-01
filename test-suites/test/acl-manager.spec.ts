import { aptos } from "../configs/common";
import { Transaction, View } from "../helpers/helper";
import {
  AclManager,
  addAssetListingAdminFuncAddr,
  addBridgeFuncAddr,
  addEmergencyAdminFuncAddr,
  addFlashBorrowerFuncAddr,
  AddPoolAdminFuncAddr,
  addRiskAdminFuncAddr,
  FLASH_BORROW_ADMIN_ROLE,
  getFlashBorrowerRoleFuncAddr,
  grantRoleFuncAddr,
  hasRoleFuncAddr,
  isAssetListingAdminFuncAddr,
  isBridgeFuncAddr,
  isEmergencyAdminFuncAddr,
  isFlashBorrowerFuncAddr,
  isPoolAdminFuncAddr,
  isRiskAdminFuncAddr,
  removeAssetListingAdminFuncAddr,
  removeBridgeFuncAddr,
  removeEmergencyAdminFuncAddr,
  removeFlashBorrowerFuncAddr,
  removePoolAdminFuncAddr,
  removeRiskAdminFuncAddr,
  revokeRoleFuncAddr,
} from "../configs/acl_manage";
import { initializeMakeSuite, testEnv } from "../configs/config";

describe("Access Control List Manager", () => {
  beforeAll(async () => {
    await initializeMakeSuite();
  });

  it("Grant FLASH_BORROW_ADMIN role", async () => {
    const {
      users: [flashBorrowAdmin],
    } = testEnv;

    const [isFlashBorrower] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(isFlashBorrower).toBe(false);

    await Transaction(aptos, AclManager, grantRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);

    const [isFlashBorrowAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(isFlashBorrowAfter).toBe(true);
  });

  it("FLASH_BORROW_ADMIN grant FLASH_BORROW_ROLE (revert expected)", async () => {
    const {
      users: [flashBorrowAdmin, flashBorrower],
    } = testEnv;

    const [isFlashBorrower] = await View(aptos, isFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);
    expect(isFlashBorrower).toBe(false);

    const [hasFlashBorrowerRole] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRole).toBe(true);
    try {
      await Transaction(aptos, flashBorrowAdmin, addFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);
    } catch (err) {
      expect(err.toString().includes("ENOT_MANAGEMENT(0x1)")).toBe(true);
    }

    const [isFlashBorrowerAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrower.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAfter).toBe(false);

    const [hasFlashBorrowerRoleAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRoleAfter).toBe(true);
  });

  it("Make FLASH_BORROW_ADMIN_ROLE admin of FLASH_BORROWER_ROLE", async () => {
    const [FLASH_BORROW_ROLE] = await View(aptos, getFlashBorrowerRoleFuncAddr, []);
    expect(FLASH_BORROW_ROLE).toBe(FLASH_BORROW_ADMIN_ROLE);
  });

  it("FLASH_BORROW_ADMIN grant FLASH_BORROW_ROLE", async () => {
    const {
      users: [flashBorrowAdmin, flashBorrower],
    } = testEnv;

    const [isFlashBorrower] = await View(aptos, isFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);
    expect(isFlashBorrower).toBe(false);

    const [hasFlashBorrowerRole] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRole).toBe(true);

    await Transaction(aptos, AclManager, addFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);

    const [isFlashBorrowerAfter] = await View(aptos, isFlashBorrowerFuncAddr, [
      flashBorrower.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAfter).toBe(true);

    const [hasFlashBorrowerRoleAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRoleAfter).toBe(true);
  });

  it("DEFAULT_ADMIN tries to revoke FLASH_BORROW_ROLE (revert expected)", async () => {
    const {
      users: [flashBorrowAdmin, flashBorrower],
    } = testEnv;
    const [isFlashBorrower] = await View(aptos, isFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);
    expect(isFlashBorrower).toBe(true);

    const [hasFlashBorrowerRole] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRole).toBe(true);

    try {
      await Transaction(aptos, flashBorrowAdmin, removeFlashBorrowerFuncAddr, [
        flashBorrower.accountAddress.toString(),
      ]);
    } catch (err) {
      expect(err.toString().includes("ENOT_MANAGEMENT(0x1)")).toBe(true);
    }

    const [isFlashBorrowerAfter] = await View(aptos, isFlashBorrowerFuncAddr, [
      flashBorrower.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAfter).toBe(true);

    const [hasFlashBorrowerRoleAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRoleAfter).toBe(true);
  });

  it("Grant POOL_ADMIN role", async () => {
    const {
      users: [, poolAdmin],
    } = testEnv;

    const [isAdmin] = await View(aptos, isPoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);
    expect(isAdmin).toBe(false);

    await Transaction(aptos, AclManager, AddPoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);

    const [isAdminAfter] = await View(aptos, isPoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);
    expect(isAdminAfter).toBe(true);
  });

  it("Grant EMERGENCY_ADMIN role", async () => {
    const {
      users: [, , emergencyAdmin],
    } = testEnv;
    const [isAdmin] = await View(aptos, isEmergencyAdminFuncAddr, [emergencyAdmin.accountAddress.toString()]);
    expect(isAdmin).toBe(false);

    await Transaction(aptos, AclManager, addEmergencyAdminFuncAddr, [emergencyAdmin.accountAddress.toString()]);

    const [isAdminAfter] = await View(aptos, isEmergencyAdminFuncAddr, [emergencyAdmin.accountAddress.toString()]);
    expect(isAdminAfter).toBe(true);
  });

  it("Grant BRIDGE role", async () => {
    const {
      users: [, , , bridgeAdmin],
    } = testEnv;
    const [isAdmin] = await View(aptos, isBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);
    expect(isAdmin).toBe(false);

    await Transaction(aptos, AclManager, addBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);

    const [isAdminAfter] = await View(aptos, isBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);
    expect(isAdminAfter).toBe(true);
  });

  it("Grant RISK_ADMIN role", async () => {
    const {
      users: [, , , , riskAdmin],
    } = testEnv;
    const [isAdmin] = await View(aptos, isRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);
    expect(isAdmin).toBe(false);

    await Transaction(aptos, AclManager, addRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);

    const [isAdminAfter] = await View(aptos, isRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);
    expect(isAdminAfter).toBe(true);
  });

  it("Grant ASSET_LISTING_ADMIN role", async () => {
    const {
      users: [, , , , , assetListingAdmin],
    } = testEnv;

    const [isAdmin] = await View(aptos, isAssetListingAdminFuncAddr, [assetListingAdmin.accountAddress.toString()]);
    expect(isAdmin).toBe(false);

    await Transaction(aptos, AclManager, addAssetListingAdminFuncAddr, [assetListingAdmin.accountAddress.toString()]);

    const [isAdminAfter] = await View(aptos, isAssetListingAdminFuncAddr, [
      assetListingAdmin.accountAddress.toString(),
    ]);
    expect(isAdminAfter).toBe(true);
  });

  it("Revoke FLASH_BORROWER", async () => {
    const {
      users: [flashBorrowAdmin, flashBorrower],
    } = testEnv;

    const [isFlashBorrower] = await View(aptos, isFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);
    expect(isFlashBorrower).toBe(true);

    const [hasFlashBorrowerRole] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRole).toBe(true);

    await Transaction(aptos, AclManager, removeFlashBorrowerFuncAddr, [flashBorrower.accountAddress.toString()]);

    const [isFlashBorrowerAfter] = await View(aptos, isFlashBorrowerFuncAddr, [
      flashBorrower.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAfter).toBe(false);

    const [hasFlashBorrowerRoleAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(hasFlashBorrowerRoleAfter).toBe(true);
  });

  it("Revoke FLASH_BORROWER_ADMIN", async () => {
    const {
      users: [flashBorrowAdmin],
    } = testEnv;

    const [isFlashBorrowerAdmin] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAdmin).toBe(true);

    await Transaction(aptos, AclManager, revokeRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);

    const [isFlashBorrowerAdminAfter] = await View(aptos, hasRoleFuncAddr, [
      FLASH_BORROW_ADMIN_ROLE,
      flashBorrowAdmin.accountAddress.toString(),
    ]);
    expect(isFlashBorrowerAdminAfter).toBe(false);
  });

  it("Revoke POOL_ADMIN", async () => {
    const {
      users: [, poolAdmin],
    } = testEnv;

    const [isPoolAdmin] = await View(aptos, isPoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);
    expect(isPoolAdmin).toBe(true);

    await Transaction(aptos, AclManager, removePoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);

    const [isPoolAdminAfter] = await View(aptos, isPoolAdminFuncAddr, [poolAdmin.accountAddress.toString()]);
    expect(isPoolAdminAfter).toBe(false);
  });

  it("Revoke EMERGENCY_ADMIN", async () => {
    const {
      users: [, , emergencyAdmin],
    } = testEnv;
    const [isEmergencyAdmin] = await View(aptos, isEmergencyAdminFuncAddr, [emergencyAdmin.accountAddress.toString()]);
    expect(isEmergencyAdmin).toBe(true);

    await Transaction(aptos, AclManager, removeEmergencyAdminFuncAddr, [emergencyAdmin.accountAddress.toString()]);

    const [isEmergencyAdminAfter] = await View(aptos, isEmergencyAdminFuncAddr, [
      emergencyAdmin.accountAddress.toString(),
    ]);
    expect(isEmergencyAdminAfter).toBe(false);
  });

  it("Revoke BRIDGE", async () => {
    const {
      users: [, , , bridgeAdmin],
    } = testEnv;
    const [isBridgeAdmin] = await View(aptos, isBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);
    expect(isBridgeAdmin).toBe(true);

    await Transaction(aptos, AclManager, removeBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);

    const [isBridgeAdminAfter] = await View(aptos, isBridgeFuncAddr, [bridgeAdmin.accountAddress.toString()]);
    expect(isBridgeAdminAfter).toBe(false);
  });

  it("Revoke RISK_ADMIN", async () => {
    const {
      users: [, , , , riskAdmin],
    } = testEnv;
    const [isRiskAdmin] = await View(aptos, isRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);
    expect(isRiskAdmin).toBe(true);

    await Transaction(aptos, AclManager, removeRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);

    const [isRiskAdminAfter] = await View(aptos, isRiskAdminFuncAddr, [riskAdmin.accountAddress.toString()]);
    expect(isRiskAdminAfter).toBe(false);
  });

  it("Revoke ASSET_LISTING_ADMIN", async () => {
    const {
      users: [, , , , , assetListingAdmin],
    } = testEnv;

    const [isAssetListingAdmin] = await View(aptos, isAssetListingAdminFuncAddr, [
      assetListingAdmin.accountAddress.toString(),
    ]);
    expect(isAssetListingAdmin).toBe(true);

    await Transaction(aptos, AclManager, removeAssetListingAdminFuncAddr, [
      assetListingAdmin.accountAddress.toString(),
    ]);

    const [isAssetListingAdminAfter] = await View(aptos, isAssetListingAdminFuncAddr, [
      assetListingAdmin.accountAddress.toString(),
    ]);
    expect(isAssetListingAdminAfter).toBe(false);
  });
});
