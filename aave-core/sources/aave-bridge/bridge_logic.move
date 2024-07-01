module aave_pool::bridge_logic {
    use std::signer;
    use aptos_framework::event;

    use aave_acl::acl_manage;
    use aave_config::error as error_config;
    use aave_config::reserve as reserve_config;
    use aave_config::user as user_config;
    use aave_math::math_utils;
    use aave_math::wad_ray_math;

    use aave_pool::a_token_factory;
    use aave_pool::pool::Self;
    use aave_pool::pool_validation;
    use aave_pool::underlying_token_factory;
    use aave_pool::validation_logic;

    #[event]
    struct ReserveUsedAsCollateralEnabled has store, drop {
        reserve: address,
        user: address
    }

    #[event]
    struct MintUnbacked has store, drop {
        reserve: address,
        user: address,
        on_behalf_of: address,
        amount: u256,
        referral_code: u16
    }

    #[event]
    struct BackUnbacked has store, drop {
        reserve: address,
        backer: address,
        amount: u256,
        fee: u256
    }

    public entry fun mint_unbacked(
        account: &signer,
        asset: address,
        amount: u256,
        on_behalf_of: address,
        referral_code: u16
    ) {
        let account_address = signer::address_of(account);
        assert!(only_brigde(account_address), error_config::get_ecaller_not_bridge());
        let reserve_data = pool::get_reserve_data(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);
        // validate supply
        validation_logic::validate_supply(&reserve_data, amount);

        // validate unbacked mint cap
        let reserve_config_map = pool::get_reserve_configuration_by_reserve_data(&reserve_data);
        let unbacked_mint_cap =
            reserve_config::get_unbacked_mint_cap(&reserve_config_map);
        let reserve_decimals = reserve_config::get_decimals(&reserve_config_map);
        let unbacked = (pool::get_reserve_unbacked(&reserve_data) as u256) + amount;
        // update pool unbacked
        pool::set_reserve_unbacked(asset, (unbacked as u128));

        assert!(unbacked <= unbacked_mint_cap * (math_utils::pow(10, reserve_decimals)),
            error_config::get_eunbacked_mint_cap_exceeded());

        let token_a_address = pool::get_reserve_a_token_address(&reserve_data);
        // update pool interest rates
        pool::update_interest_rates(&mut reserve_data, asset, 0, 0);
        let is_first_supply: bool =
            a_token_factory::scale_balance_of(on_behalf_of, token_a_address) == 0;

        a_token_factory::mint(account_address,
            on_behalf_of,
            amount,
            (pool::get_reserve_liquidity_index(&reserve_data) as u256),
            token_a_address);

        if (is_first_supply) {
            let user_config_map = pool::get_user_configuration(on_behalf_of);
            let reserve_id = pool::get_reserve_id(&reserve_data);
            if (pool_validation::validate_automatic_use_as_collateral(account_address, &user_config_map, &reserve_config_map)) {
                user_config::set_using_as_collateral(&mut user_config_map, (reserve_id as u256), true);
                pool::set_user_configuration(on_behalf_of, user_config_map);
                event::emit(ReserveUsedAsCollateralEnabled {
                        reserve: asset,
                        user: on_behalf_of
                    });
            }
        };
        event::emit(MintUnbacked {
                reserve: asset,
                user: account_address,
                on_behalf_of,
                amount,
                referral_code
            });
    }

    public entry fun back_unbacked(
        account: &signer,
        asset: address,
        amount: u256,
        fee: u256,
        protocol_fee_bps: u256
    ) {
        let account_address = signer::address_of(account);
        assert!(only_brigde(account_address), error_config::get_ecaller_not_bridge());
        let reserve_data = pool::get_reserve_data(asset);
        // update pool state
        pool::update_state(asset, &mut reserve_data);

        let unbacked = (pool::get_reserve_unbacked(&reserve_data) as u256);
        let backing_amount = if (amount < unbacked) { amount }
        else { unbacked };

        let fee_to_protocol = math_utils::percent_mul(fee, protocol_fee_bps);
        let fee_to_lp = fee - fee_to_protocol;
        let added = backing_amount + fee;

        let token_a_address = pool::get_reserve_a_token_address(&reserve_data);
        let accrued_to_treasury = pool::get_reserve_accrued_to_treasury(&reserve_data);
        let token_a_supply_and_treasury = pool::scale_a_token_total_supply(token_a_address) + wad_ray_math::ray_mul(
                accrued_to_treasury, (pool::get_reserve_liquidity_index(&reserve_data) as u256));
        let next_liquidity_index =
            pool::cumulate_to_liquidity_index(asset, &mut reserve_data,
                token_a_supply_and_treasury, fee_to_lp);

        let accrued_to_treasury_amount =
            accrued_to_treasury + wad_ray_math::ray_div(fee_to_protocol,
                next_liquidity_index);

        // update pool accrue to treasury
        pool::set_reserve_accrued_to_treasury(asset, accrued_to_treasury_amount);

        // update pool unbacked
        pool::set_reserve_unbacked(asset, ((unbacked - backing_amount) as u128));
        // update pool interest rates
        pool::update_interest_rates(&mut reserve_data, asset, added, 0);

        underlying_token_factory::transfer_from(account_address,
            a_token_factory::get_token_account_address(token_a_address),
            (added as u64),
            asset);

        event::emit(BackUnbacked {
                reserve: asset,
                backer: account_address,
                amount: backing_amount,
                fee,
            })
    }

    fun only_brigde(brigde: address): bool {
        acl_manage::is_bridge(brigde)
    }
}