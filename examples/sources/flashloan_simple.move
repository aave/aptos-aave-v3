// @title Simple Flashloans Test Script
// @author Aave
// @notice Script to test simple flashloans functionality in the Aave protocol
script {
    // imports
    // std
    use std::signer;
    use aptos_std::debug::print;
    use aptos_std::string_utils::format1;
    use aave_pool::fungible_asset_manager::Self;
    // locals
    use aave_pool::flashloan_logic::Self;

    // Constants
    // @notice Success code for successful execution
    const SUCCESS: u64 = 1;

    // @notice Failure code for failed execution
    const FAILURE: u64 = 2;

    /// @notice Test script for executing a simple flashloan
    /// @param borrower The signer account executing the script (must be the borrower)
    /// @param asset The address of the asset to be borrowed in the flashloan
    /// @param amount The amount of the asset to be borrowed in the flashloan
    fun flashloan_simple(
        borrower: &signer, asset: address, amount: u256
    ) {

        let flashloan_borrower_address = signer::address_of(borrower);
        let flashloan_asset = asset;
        let flashloan_amount = amount;

        // check the balance of the borrower before the flashloan is taken
        let flashloaner_initial_balance =
            fungible_asset_manager::balance_of(
                flashloan_borrower_address, flashloan_asset
            );
        print(&format1(&b"Flashloaner initial balance: {}", flashloaner_initial_balance));

        // user prepares to take a flashloan
        let flashloan_receipt =
            flashloan_logic::flash_loan_simple(
                borrower,
                flashloan_borrower_address,
                flashloan_asset,
                flashloan_amount,
                0 // no referral code
            );

        // check the balance of the borrower after the flashloan
        let flashloaner_postloan_balance =
            fungible_asset_manager::balance_of(
                flashloan_borrower_address, flashloan_asset
            );
        print(
            &format1(&b"Flashloaner post-loan balance: {}", flashloaner_postloan_balance)
        );

        assert!(
            (flashloaner_postloan_balance as u256)
                == (flashloaner_initial_balance as u256) + flashloan_amount,
            SUCCESS
        );

        // do assertion to check if the flashloan was successful
        assert!(
            flashloan_logic::get_simple_flashloan_current_amount(&flashloan_receipt)
                == flashloan_amount,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_current_asset(&flashloan_receipt)
                == flashloan_asset,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_on_behalf_of(&flashloan_receipt)
                == flashloan_borrower_address,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_receipt_index(&flashloan_receipt)
                == 0,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_receipt_receiver(&flashloan_receipt)
                == flashloan_borrower_address,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_referral_code(&flashloan_receipt)
                == 0,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_simple_flashloan_receipt_sender(&flashloan_receipt)
                == flashloan_borrower_address,
            SUCCESS
        );

        print(
            &format1(
                &b"flashloan_premium_total: {}",
                flashloan_logic::get_simple_flashloan_premium_total(&flashloan_receipt)
            )
        );
        print(
            &format1(
                &b"flashloan_premium_to_protocol: {}",
                flashloan_logic::get_simple_flashloan_premium_to_protocol(
                    &flashloan_receipt
                )
            )
        );
        print(
            &format1(
                &b"flashloan_total_premium: {}",
                flashloan_logic::get_simple_flashloan_total_premium(&flashloan_receipt)
            )
        );

        // pay back the flashloan
        flashloan_logic::pay_flash_loan_simple(borrower, flashloan_receipt);

        // check the balance of the borrower after the flashloan has been paid back
        let flashloaner_postrepay_balance =
            fungible_asset_manager::balance_of(
                flashloan_borrower_address, flashloan_asset
            );
        print(
            &format1(
                &b"Flashloaner post-repay balance: {}", flashloaner_postrepay_balance
            )
        );
    }
}
