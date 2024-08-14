import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account
const aptosProvider = new AptosProvider();
export const AclManager = Account.fromPrivateKey({ privateKey: aptosProvider.getProfilePrivateKeyByName("aave_acl") });
export const AclManagerAccountAddress = AclManager.accountAddress.toString();

// Resource Func Addr
export const hasRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::has_role`;
export const grantRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::grant_role`;
export const renounceRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::renounce_role`;
export const revokeRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::revoke_role`;
export const addPoolAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_pool_admin`;
export const removePoolAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_pool_admin`;
export const isPoolAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_pool_admin`;
export const addEmergencyAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_emergency_admin`;
export const removeEmergencyAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_emergency_admin`;
export const isEmergencyAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_emergency_admin`;
export const addRiskAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_risk_admin`;
export const removeRiskAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_risk_admin`;
export const isRiskAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_risk_admin`;
export const addFlashBorrowerFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_flash_borrower`;
export const removeFlashBorrowerFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_flash_borrower`;
export const isFlashBorrowerFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_flash_borrower`;
export const addBridgeFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_bridge`;
export const removeBridgeFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_bridge`;
export const isBridgeFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_bridge`;
export const addAssetListingAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::add_asset_listing_admin`;
export const removeAssetListingAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::remove_asset_listing_admin`;
export const isAssetListingAdminFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::is_asset_listing_admin`;
export const getPoolAdminRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_pool_admin_role`;
export const getEmergencyAdminRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_emergency_admin_role`;
export const getRiskAdminRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_risk_admin_role`;
export const getFlashBorrowerRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_flash_borrower_role`;
export const getBridgeRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_bridge_role`;
export const getAssetListingAdminRoleFuncAddr: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_asset_listing_admin_role`;
export const grantDefaultAdminRole: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::grant_default_admin_role`;
export const defaultAdminRole: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::default_admin_role`;
export const getRoleAdmin: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::get_role_admin`;
export const setRoleAdmin: MoveFunctionId = `${AclManagerAccountAddress}::acl_manage::set_role_admin`;

// Mock Account
export const FLASH_BORROW_ADMIN_ROLE = "FLASH_BORROWER";
