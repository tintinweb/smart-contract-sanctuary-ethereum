// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/// @title MapleLoanV5Migrator is to adjust all the rates to 1e6 precision.
contract MapleLoanV5Migrator is MapleLoanStorage {
    
    uint256 private constant HUNDRED_PERCENT = 1e6;
    uint256 private constant SCALED_ONE      = 1e18;
    
    fallback() external {
        _interestRate            /= (SCALED_ONE / HUNDRED_PERCENT);             
        _closingRate             /= (SCALED_ONE / HUNDRED_PERCENT);              
        _lateFeeRate             /= (SCALED_ONE / HUNDRED_PERCENT);             
        _lateInterestPremiumRate /= (SCALED_ONE / HUNDRED_PERCENT);  
    }  

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleLoanStorage defines the storage layout of MapleLoan.
abstract contract MapleLoanStorage {

    // Roles
    address internal _borrower;         // The address of the borrower.
    address internal _lender;           // The address of the lender.
    address internal _pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address internal _pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    // Assets
    address internal _collateralAsset;  // The address of the asset used as collateral.
    address internal _fundsAsset;       // The address of the asset used as funds.

    // Loan Term Parameters
    uint256 internal _gracePeriod;      // The number of seconds a payment can be late.
    uint256 internal _paymentInterval;  // The number of seconds between payments.

    // Rates
    uint256 internal _interestRate;             // The annualized interest rate of the loan.
    uint256 internal _closingRate;              // The fee rate (applied to principal) to close the loan.
    uint256 internal _lateFeeRate;              // The fee rate for late payments.
    uint256 internal _lateInterestPremiumRate;  // The amount to increase the interest rate by for late payments.

    // Requested Amounts
    uint256 internal _collateralRequired;  // The collateral the borrower is expected to put up to draw down all _principalRequested.
    uint256 internal _principalRequested;  // The funds the borrowers wants to borrow.
    uint256 internal _endingPrincipal;     // The principal to remain at end of loan.

    // State
    uint256 internal _drawableFunds;               // The amount of funds that can be drawn down.
    uint256 internal __deprecated_claimableFunds;  // Deprecated storage slot for `claimableFunds`.
    uint256 internal _collateral;                  // The amount of collateral, in collateral asset, that is currently posted.
    uint256 internal _nextPaymentDueDate;          // The timestamp of due date of next payment.
    uint256 internal _paymentsRemaining;           // The number of payments remaining.
    uint256 internal _principal;                   // The amount of principal yet to be paid down.

    // Refinance
    bytes32 internal _refinanceCommitment;  // Keccak-256 hash of the parameters of proposed terms of a refinance: `refinancer_`, `deadline_`, and `calls_`.

    uint256 internal _refinanceInterest;  // Amount of accrued interest between the last payment on a loan and the time the refinance takes effect.

    // Establishment fees
    uint256 internal __deprecated_delegateFee;  // Deprecated storage slot for `delegateFee`.
    uint256 internal __deprecated_treasuryFee;  // Deprecated storage slot for `treasuryFee`.

    // Pool V2 dependencies
    address internal _feeManager;  // Address responsible for calculating and handling fees

    // Triggered defaults
    uint256 internal _originalNextPaymentDueDate;  // Stores the original `nextPaymentDueDate` in order to allow triggered defaults to be reverted.

}