// @title Complex Flashloans Test Script
// @author Aave
// @notice Script to test complex flashloans functionality in the Aave protocol
script {
    // imports
    // std
    use std::signer;
    use std::vector;
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

    /// @notice Test script for executing a complex flashloan
    /// @param borrower The signer account executing the script (must be the borrower)
    /// @param asset The address of the asset to be borrowed in the flashloan
    /// @param amount The amount of the asset to be borrowed in the flashloan
    fun flashloan_complex(
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
        let flashloan_receipts =
            flashloan_logic::flash_loan(
                borrower,
                flashloan_borrower_address,
                vector[flashloan_asset],
                vector[flashloan_amount],
                vector[2],
                flashloan_borrower_address,
                0 // no referral code
            );

        // assert that the flashloan receipts is not empty and it has only 1 item
        assert!(vector::length(&flashloan_receipts) == 1, SUCCESS);

        let first_flashloan_receipt = vector::borrow(&flashloan_receipts, 0);

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
            flashloan_logic::get_complex_flashloan_current_amount(first_flashloan_receipt) ==
            flashloan_amount,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_current_asset(first_flashloan_receipt) ==
            flashloan_asset,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_on_behalf_of(first_flashloan_receipt)
                == flashloan_borrower_address,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_receipt_index(first_flashloan_receipt) ==
            0,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_receipt_receiver(
                first_flashloan_receipt
            ) == flashloan_borrower_address,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_referral_code(first_flashloan_receipt) ==
            0,
            SUCCESS
        );
        assert!(
            flashloan_logic::get_complex_flashloan_receipt_sender(first_flashloan_receipt) ==
            flashloan_borrower_address,
            SUCCESS
        );

        print(
            &format1(
                &b"flashloan_premium_total: {}",
                flashloan_logic::get_complex_flashloan_premium_total(
                    first_flashloan_receipt
                )
            )
        );
        print(
            &format1(
                &b"flashloan_premium_to_protocol: {}",
                flashloan_logic::get_complex_flashloan_premium_to_protocol(
                    first_flashloan_receipt
                )
            )
        );
        print(
            &format1(
                &b"flashloan_total_premium: {}",
                flashloan_logic::get_complex_flashloan_total_premium(
                    first_flashloan_receipt
                )
            )
        );

        // pay back the flashloans
        flashloan_logic::pay_flash_loan_complex(borrower, flashloan_receipts);

        // check the balance of the borrower after the flashloans have been paid back
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
