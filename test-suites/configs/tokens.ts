import { Account, MoveFunctionId } from "@aptos-labs/ts-sdk";
import path from "path";
import dotenv from "dotenv";
import { View } from "../helpers/helper";
import { aptos } from "./common";
import { AptosProvider } from "../wrappers/aptosProvider";

const envPath = path.resolve(__dirname, "../../.env");
dotenv.config({ path: envPath });

// Resources Admin Account

// Underlying Token
const aptosProvider = new AptosProvider();

export const AaveTokensManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("aave_pool"),
});
export const AaveTokensManagerAccountAddress = AaveTokensManager.accountAddress.toString();

export const UnderlyingManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("underlying_tokens"),
});
export const UnderlyingManagerAccountAddress = UnderlyingManager.accountAddress.toString();

// A Token
export const ATokenManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("a_tokens"),
});
export const ATokenManagerAccountAddress = ATokenManager.accountAddress.toString();

// Variable Token
export const VariableManager = Account.fromPrivateKey({
  privateKey: aptosProvider.getProfilePrivateKeyByName("variable_tokens"),
});
export const VariableManagerAccountAddress = VariableManager.accountAddress.toString();

// Resource Func Addr
// Underlying Token
export const UnderlyingCreateTokenFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::create_token`;
export const UnderlyingGetMetadataBySymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::get_metadata_by_symbol`;
export const UnderlyingGetTokenAccountAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::get_token_account_address`;
export const UnderlyingMintFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::mint`;
export const UnderlyingSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::supply`;
export const UnderlyingMaximumFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::maximum`;
export const UnderlyingNameFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::name`;
export const UnderlyingSymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::symbol`;
export const UnderlyingDecimalsFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::decimals`;
export const UnderlyingBalanceOfFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::underlying_token_factory::balance_of`;

// A Token
export const ATokenCreateTokenFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::create_token`;
export const ATokenGetMetadataBySymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_metadata_by_symbol`;
export const ATokenGetTokenAccountAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_token_account_address`;
export const ATokenGetReserveTreasuryAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_reserve_treasury_address`;
export const ATokenMintToTreasuryAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::mint_to_treasury`;
export const ATokenGetUnderlyingAssetAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_underlying_asset_address`;
export const ATokenTransferUnderlyingToFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::transfer_underlying_to`;
export const ATokenTransferOnLiquidationFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::transfer_on_liquidation`;
export const ATokenHandleRepaymentFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::handle_repayment`;
export const ATokenSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::supply`;
export const ATokenScaleTotalSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::scale_total_supply`;
export const ATokenMaximumFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::maximum`;
export const ATokenNameFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::name`;
export const ATokenSymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::symbol`;
export const ATokenDecimalsFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::decimals`;
export const ATokenBalanceOfFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::balance_of`;
export const ATokenScaleBalanceOfFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::scale_balance_of`;
export const ATokenRescueTokensFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::rescue_tokens`;
export const ATokenGetScaledUserBalanceAndSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_scaled_user_balance_and_supply`;
export const ATokenGetGetPreviousIndexFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_previous_index`;
export const ATokenGetRevisionFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::get_revision`;
export const ATokenTokenAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::token_address`;
export const ATokenAssetMetadataFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::a_token_factory::asset_metadata`;

// Variable Token
export const VariableCreateTokenFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::create_token`;
export const VariableGetMetadataBySymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::get_metadata_by_symbol`;
export const VariableGetTokenAccountAddressFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::get_token_account_address`;
export const VariableSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::supply`;
export const VariableMaximumFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::maximum`;
export const VariableNameFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::name`;
export const VariableSymbolFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::symbol`;
export const VariableDecimalsFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::decimals`;
export const VariableBalanceOfFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::balance_of`;
export const VariableScaleBalanceOfFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::scale_balance_of`;
export const VariableScaleTotalSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::scale_total_supply`;
export const VariableGetScaledUserBalanceAndSupplyFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::get_scaled_user_balance_and_supply`;
export const VariableGetPreviousIndexFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::get_previous_index`;
export const VariableGetRevisionFuncAddr: MoveFunctionId = `${AaveTokensManagerAccountAddress}::variable_token_factory::get_revision`;

// Tokens
export const DAI = "DAI";
export const WETH = "WETH";
export const USDC = "USDC";
export const AAVE = "AAVE";

// A Tokens
export const ADAI = "ADAI";
export const AWETH = "AWETH";
export const AUSDC = "AUSDC";
export const AAAVE = "AAAVE";

// Variable Tokens
export const VDAI = "VDAI";
export const VWETH = "VWETH";
export const VUSDC = "VUSDC";
export const VAAVE = "VAAVE";

// Common Function
interface Metadata {
  inner: string;
}

// get metadata address
export async function getMetadataAddress(funcAddr: MoveFunctionId, coinName: string) {
  const res = await View(aptos, funcAddr, [coinName]);
  return (res[0] as Metadata).inner;
}

// get decimals
export async function getDecimals(funcAddr: MoveFunctionId, metadataAddr: string) {
  const res = await View(aptos, funcAddr, [metadataAddr]);
  return res[0] as number;
}

// Mock Account
