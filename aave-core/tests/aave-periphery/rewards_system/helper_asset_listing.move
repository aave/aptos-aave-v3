#[test_only]
module aave_pool::helper_asset_listing {
    use std::error;
    use std::option;
    use std::option::Option;
    use std::string::{utf8, String};
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object;
    use aptos_framework::object::Object;

    use aave_config::reserve_config;
    use aave_oracle::oracle;
    use aave_pool::mock_coin1;
    use aave_pool::mock_coin2;
    use aave_pool::collector;
    use aave_pool::emission_manager;
    use aave_pool::pool;
    use aave_pool::pool_configurator;

    // prefixes
    const A_TOKEN_NAME_PREFIX: vector<u8> = b"AAVE_A_";
    const A_TOKEN_SYMBOL_PREFIX: vector<u8> = b"a";
    const VAR_DEBT_TOKEN_NAME_PREFIX: vector<u8> = b"AAVE_VAR_DEBT_";
    const VAR_DEBT_TOKEN_SYMBOL_PREFIX: vector<u8> = b"v";

    /// Named struct for names and symbols of created AAVE tokens
    struct NamesAndSymbols has drop {
        atoken_name: String,
        atoken_symbol: String,
        vtoken_name: String,
        vtoken_symbol: String
    }

    /// Named struct for interest rate configuration
    struct InterestRateConfig has store, copy, drop {
        optimal_usage_ratio: u256,
        base_variable_borrow_rate: u256,
        variable_rate_slope1: u256,
        variable_rate_slope2: u256
    }

    /// Named struct for the reserve configuration
    struct ReserveConfig has store, copy, drop {
        base_ltv_as_collateral: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256,
        liquidation_protocol_fee: u256,
        borrowing_enabled: bool,
        flash_loan_enabled: bool,
        reserve_factor: u256,
        supply_cap: u256,
        borrow_cap: u256,
        debt_ceiling: u256,
        borrowable_in_isolation: bool,
        siloed_borrowing: bool,
        emode_category: Option<u256>
    }

    /// Named struct for configuring the oracle
    enum OracleConfig has drop {
        Custom(u256),
        ChainLink
    }

    /// Named struct for the asset listing information
    struct AssetListingConfig has drop {
        underlying_asset: address,
        treasury: address,
        incentives_controller: Option<address>,
        id_pack: NamesAndSymbols,
        reserve_config: ReserveConfig,
        interest_rate_config: InterestRateConfig,
        oracle_config: OracleConfig
    }

    /// Utility: get the names and symbols for AAVE tokens
    fun derive_names_and_symbols(token: Object<Metadata>): NamesAndSymbols {
        let base = fungible_asset::symbol(token);

        let atoken_name = utf8(A_TOKEN_NAME_PREFIX);
        atoken_name.append(base);
        let atoken_symbol = utf8(A_TOKEN_SYMBOL_PREFIX);
        atoken_symbol.append(base);
        let vtoken_name = utf8(VAR_DEBT_TOKEN_NAME_PREFIX);
        vtoken_name.append(base);
        let vtoken_symbol = utf8(VAR_DEBT_TOKEN_SYMBOL_PREFIX);
        vtoken_symbol.append(base);

        NamesAndSymbols {
            atoken_name,
            atoken_symbol,
            vtoken_name,
            vtoken_symbol
        }
    }

    /// List asset in the protocol
    public fun list_asset(sender: &signer, config: AssetListingConfig) {
        // config vectors
        let underlying_assets = vector[config.underlying_asset];
        let treasuries = vector[config.treasury];
        let a_token_names = vector[config.id_pack.atoken_name];
        let a_token_symbols = vector[config.id_pack.atoken_symbol];
        let variable_debt_token_names = vector[config.id_pack.vtoken_name];
        let variable_debt_token_symbols = vector[config.id_pack.vtoken_symbol];
        let incentives_controllers = vector[config.incentives_controller];
        let optimal_usage_ratios = vector[config.interest_rate_config.optimal_usage_ratio];
        let base_variable_borrow_rates = vector[config.interest_rate_config.base_variable_borrow_rate];
        let variable_rate_slopes1 = vector[config.interest_rate_config.variable_rate_slope1];
        let variable_rate_slopes2 = vector[config.interest_rate_config.variable_rate_slope2];

        // create the reserve
        pool_configurator::init_reserves(
            sender,
            underlying_assets,
            treasuries,
            a_token_names,
            a_token_symbols,
            variable_debt_token_names,
            variable_debt_token_symbols,
            incentives_controllers,
            optimal_usage_ratios,
            base_variable_borrow_rates,
            variable_rate_slopes1,
            variable_rate_slopes2
        );

        // fine-tune the reserve config
        let underlying_token =
            object::address_to_object<Metadata>(config.underlying_asset);
        let underlying_decimals = fungible_asset::decimals(underlying_token) as u256;

        let reserve_config = reserve_config::init();
        reserve_config.set_decimals(underlying_decimals);
        reserve_config.set_ltv(config.reserve_config.base_ltv_as_collateral);
        reserve_config.set_liquidation_threshold(
            config.reserve_config.liquidation_threshold
        );
        reserve_config.set_liquidation_bonus(config.reserve_config.liquidation_bonus);
        reserve_config.set_liquidation_protocol_fee(
            config.reserve_config.liquidation_protocol_fee
        );
        reserve_config.set_borrowing_enabled(config.reserve_config.borrowing_enabled);
        reserve_config.set_flash_loan_enabled(config.reserve_config.flash_loan_enabled);
        reserve_config.set_reserve_factor(config.reserve_config.reserve_factor);
        reserve_config.set_supply_cap(config.reserve_config.supply_cap);
        reserve_config.set_borrow_cap(config.reserve_config.borrow_cap);
        reserve_config.set_debt_ceiling(config.reserve_config.debt_ceiling);
        reserve_config.set_borrowable_in_isolation(
            config.reserve_config.borrowable_in_isolation
        );
        reserve_config.set_siloed_borrowing(config.reserve_config.siloed_borrowing);
        reserve_config.set_emode_category(
            config.reserve_config.emode_category.destroy_with_default(0)
        );

        reserve_config.set_frozen(false);
        reserve_config.set_paused(false);
        reserve_config.set_active(true);

        pool::set_reserve_configuration_with_guard(
            sender, config.underlying_asset, reserve_config
        );

        // setup the price feed
        let reserve_data = pool::get_reserve_data(config.underlying_asset);
        let atoken_address = pool::get_reserve_a_token_address(reserve_data);
        let variable_debt_token_address =
            pool::get_reserve_variable_debt_token_address(reserve_data);

        match(&config.oracle_config) {
            OracleConfig::Custom(price) => {
                oracle::set_asset_custom_price(sender, config.underlying_asset, *price);
                oracle::set_asset_custom_price(sender, atoken_address, *price);
                oracle::set_asset_custom_price(sender, variable_debt_token_address, *price);
            },
            OracleConfig::ChainLink => {
                // feature not supported yet
                abort error::unavailable(0);
            }
        }
    }

    /// Default configuration for MockCoin1
    public fun default_mockcoin1_config(coin_creator: address): AssetListingConfig {
        let token = mock_coin1::token_metadata(coin_creator);

        AssetListingConfig {
            underlying_asset: object::object_address(&token),
            treasury: collector::collector_address(),
            incentives_controller: emission_manager::get_rewards_controller(),
            id_pack: derive_names_and_symbols(token),
            reserve_config: ReserveConfig {
                base_ltv_as_collateral: 58_00,
                liquidation_threshold: 63_00,
                liquidation_bonus: 10_00,
                liquidation_protocol_fee: 10_00,
                borrowing_enabled: true,
                flash_loan_enabled: true,
                reserve_factor: 20_00,
                supply_cap: 30_000_000,
                borrow_cap: 27_000_000,
                debt_ceiling: 0,
                borrowable_in_isolation: false,
                siloed_borrowing: false,
                emode_category: option::none()
            },
            interest_rate_config: InterestRateConfig {
                optimal_usage_ratio: 45_00,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 7_00,
                variable_rate_slope2: 300_00
            },
            oracle_config: OracleConfig::Custom(5_000_000_000_000_000_000)
        }
    }

    /// Default configuration for MockCoin2
    public fun default_mockcoin2_config(coin_creator: address): AssetListingConfig {
        let token = mock_coin2::token_metadata(coin_creator);

        AssetListingConfig {
            underlying_asset: object::object_address(&token),
            treasury: collector::collector_address(),
            incentives_controller: emission_manager::get_rewards_controller(),
            id_pack: derive_names_and_symbols(token),
            reserve_config: ReserveConfig {
                base_ltv_as_collateral: 75_00,
                liquidation_threshold: 78_00,
                liquidation_bonus: 5_00,
                liquidation_protocol_fee: 10_00,
                borrowing_enabled: true,
                flash_loan_enabled: true,
                reserve_factor: 10_00,
                supply_cap: 25_000_000,
                borrow_cap: 23_000_000,
                debt_ceiling: 0,
                borrowable_in_isolation: true,
                siloed_borrowing: false,
                emode_category: option::none()
            },
            interest_rate_config: InterestRateConfig {
                optimal_usage_ratio: 90_00,
                base_variable_borrow_rate: 0,
                variable_rate_slope1: 6_00,
                variable_rate_slope2: 40_00
            },
            oracle_config: OracleConfig::Custom(1_000_000_000_000_000_000)
        }
    }
}
