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
    uint256 internal _interestRate;         // The annualized interest rate of the loan.
    uint256 internal _closingRate;          // The fee rate (applied to principal) to close the loan.
    uint256 internal _lateFeeRate;          // The fee rate for late payments.
    uint256 internal _lateInterestPremium;  // The amount to increase the interest rate by for late payments.

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 } from "../modules/erc20/contracts/interfaces/IERC20.sol";

import { IMapleLoanFeeManager } from "./interfaces/IMapleLoanFeeManager.sol";
import { IRefinancer }          from "./interfaces/IRefinancer.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ██████╗ ███████╗███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗
    ██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
    ██████╔╝█████╗  █████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗  ██████╔╝
    ██╔══██╗██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗
    ██║  ██║███████╗██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║
    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝

*/

/// @title Refinancer uses storage from a MapleLoan defined by MapleLoanStorage.
contract Refinancer is IRefinancer, MapleLoanStorage {

    function increasePrincipal(uint256 amount_) external override {
        // Cannot under-fund the principal increase, but over-funding results in additional funds left unaccounted for.
        require(_getUnaccountedAmount(_fundsAsset) >= amount_, "R:IP:INSUFFICIENT_AMOUNT");

        _principal          += amount_;
        _principalRequested += amount_;
        _drawableFunds      += amount_;

        emit PrincipalIncreased(amount_);
    }

    function setClosingRate(uint256 closingRate_) external override {
        emit ClosingRateSet(_closingRate = closingRate_);
    }

    function setCollateralRequired(uint256 collateralRequired_) external override {
        emit CollateralRequiredSet(_collateralRequired = collateralRequired_);
    }

    function setEndingPrincipal(uint256 endingPrincipal_) external override {
        require(endingPrincipal_ <= _principal, "R:SEP:ABOVE_CURRENT_PRINCIPAL");
        emit EndingPrincipalSet(_endingPrincipal = endingPrincipal_);
    }

    function setGracePeriod(uint256 gracePeriod_) external override {
        emit GracePeriodSet(_gracePeriod = gracePeriod_);
    }

    function setInterestRate(uint256 interestRate_) external override {
        emit InterestRateSet(_interestRate = interestRate_);
    }

    function setLateFeeRate(uint256 lateFeeRate_) external override {
        emit LateFeeRateSet(_lateFeeRate = lateFeeRate_);
    }

    function setLateInterestPremium(uint256 lateInterestPremium_) external override {
        emit LateInterestPremiumSet(_lateInterestPremium = lateInterestPremium_);
    }

    function setPaymentInterval(uint256 paymentInterval_) external override {
        require(paymentInterval_ != 0, "R:SPI:ZERO_AMOUNT");

        emit PaymentIntervalSet(_paymentInterval = paymentInterval_);
    }

    function setPaymentsRemaining(uint256 paymentsRemaining_) external override {
        require(paymentsRemaining_ != 0, "R:SPR:ZERO_AMOUNT");

        emit PaymentsRemainingSet(_paymentsRemaining = paymentsRemaining_);
    }

    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external override {
        IMapleLoanFeeManager(_feeManager).updateDelegateFeeTerms(delegateOriginationFee_, delegateServiceFee_);
    }

    /// @dev Returns the amount of an `asset_` that this contract owns, which is not currently accounted for by its state variables.
    function _getUnaccountedAmount(address asset_) internal view returns (uint256 unaccountedAmount_) {
        return IERC20(asset_).balanceOf(address(this))
            - (asset_ == _collateralAsset ? _collateral    : uint256(0))   // `_collateral` is `_collateralAsset` accounted for.
            - (asset_ == _fundsAsset      ? _drawableFunds : uint256(0));  // `_drawableFunds` are `_fundsAsset` accounted for.
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleLoanFeeManager {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_                   The address of the loan contract.
     *  @param delegateOriginationFee_ The new value for delegate origination fee.
     *  @param delegateServiceFee_     The new value for delegate service fee.
     */
    event FeeTermsUpdated(address loan_, uint256 delegateOriginationFee_, uint256 delegateServiceFee_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                   The address of the loan contract.
     *  @param delegateOriginationFee_ The amount of delegate origination fee paid.
     *  @param platformOriginationFee_ The amount of platform origination fee paid.
    */
    event OriginationFeesPaid(address loan_, uint256 delegateOriginationFee_, uint256 platformOriginationFee_);

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_               The address of the loan contract.
     *  @param platformServiceFee_ The new value for the platform service fee.
     */
    event PlatformServiceFeeUpdated(address loan_, uint256 platformServiceFee_);

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_                      The address of the loan contract.
     *  @param partialPlatformServiceFee_ The  value for the platform service fee.
     *  @param partialDelegateServiceFee_ The  value for the delegate service fee.
     */
    event PartialRefinanceServiceFeesUpdated(address loan_, uint256 partialPlatformServiceFee_, uint256 partialDelegateServiceFee_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                               The address of the loan contract.
     *  @param delegateServiceFee_                 The amount of delegate service fee paid.
     *  @param partialRefinanceDelegateServiceFee_ The amount of partial delegate service fee from refinance paid.
     *  @param platformServiceFee_                 The amount of platform service fee paid.
     *  @param partialRefinancePlatformServiceFee_ The amount of partial platform service fee from refinance paid.
    */
    event ServiceFeesPaid(address loan_, uint256 delegateServiceFee_, uint256 partialRefinanceDelegateServiceFee_, uint256 platformServiceFee_, uint256 partialRefinancePlatformServiceFee_);

    /******************************************************************************************************************************/
    /*** Payment Functions                                                                                                      ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Called during `makePayment`, performs fee payments to the pool delegate and treasury.
     *  @param asset_            The address asset in which fees were paid.
     *  @param numberOfPayments_ The number of payments for which service fees will be paid.
     */
    function payServiceFees(address asset_, uint256 numberOfPayments_) external returns (uint256 feePaid_);

    /**
     *  @dev    Called during `fundLoan`, performs fee payments to poolDelegate and treasury.
     *  @param  asset_              The address asset in which fees were paid.
     *  @param  principalRequested_ The total amount of principal requested, which will be used to calculate fees.
     *  @return feePaid_            The total amount of fees paid.
     */
    function payOriginationFees(address asset_, uint256 principalRequested_) external returns (uint256 feePaid_);

    /******************************************************************************************************************************/
    /*** Fee Update Functions                                                                                                   ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Called during loan creation or refinance, sets the fee terms.
     *  @param delegateOriginationFee_ The amount of delegate origination fee to be paid.
     *  @param delegateServiceFee_     The amount of delegate service fee to be paid.
     */
    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external;

    /**
     *  @dev   Called during loan refinance to save the partial service fees accrued.
     *  @param principalRequested_   The amount of principal pre-refinance requested.
     *  @param timeSinceLastDueDate_ The amount of time since last payment due date.
     */
    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external;

    /**
     *  @dev Function called by loans to update the saved platform service fee rate.
     */
    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external;

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Gets the delegate origination fee for the given loan.
     *  @param  loan_                   The address of the loan contract.
     *  @return delegateOriginationFee_ The amount of origination to be paid to delegate.
     */
    function delegateOriginationFee(address loan_) external view returns (uint256 delegateOriginationFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @return delegateServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateServiceFee(address loan_) external view returns (uint256 delegateServiceFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_                        The address of the loan contract.
     *  @return delegateRefinanceServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateRefinanceServiceFee(address loan_) external view returns (uint256 delegateRefinanceServiceFee_);

    /**
     *  @dev    Gets the delegate service fee for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  interval_           The time, in seconds, to get the proportional fee for
     *  @return delegateServiceFee_ The amount of delegate service fee to be paid.
     */
    function getDelegateServiceFeesForPeriod(address loan_, uint256 interval_) external view returns (uint256 delegateServiceFee_);

     /**
     *  @dev    Gets the sum of all origination fees for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  principalRequested_ The amount of principal requested in the loan.
     *  @return originationFees_    The amount of origination fees to be paid.
     */
    function getOriginationFees(address loan_, uint256 principalRequested_) external view  returns (uint256 originationFees_);

    /**
     *  @dev    Gets the platform origination fee value for the given loan.
     *  @param  loan_                   The address of the loan contract.
     *  @param  principalRequested_     The amount of principal requested in the loan.
     *  @return platformOriginationFee_ The amount of platform origination fee to be paid.
     */
    function getPlatformOriginationFee(address loan_, uint256 principalRequested_) external view returns (uint256 platformOriginationFee_);

    /**
     *  @dev    Gets the delegate service fee for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @param  principalRequested_ The amount of principal requested in the loan.
     *  @param  interval_           The time, in seconds, to get the proportional fee for
     *  @return platformServiceFee_ The amount of platform service fee to be paid.
     */
    function getPlatformServiceFeeForPeriod(address loan_, uint256 principalRequested_, uint256 interval_) external view returns (uint256 platformServiceFee_);

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_                 The address of the loan contract.
     *  @param  numberOfPayments_     The number of payments being paid.
     *  @return delegateServiceFee_   The amount of delegate service fee to be paid.
     *  @return delegateRefinanceFee_ The amount of delegate refinance fee to be paid.
     *  @return platformServiceFee_   The amount of platform service fee to be paid.
     *  @return platformRefinanceFee_ The amount of platform refinance fee to be paid.
     */
    function getServiceFeeBreakdown(address loan_, uint256 numberOfPayments_) external view returns (
        uint256 delegateServiceFee_,
        uint256 delegateRefinanceFee_,
        uint256 platformServiceFee_,
        uint256 platformRefinanceFee_
    );

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_             The address of the loan contract.
     *  @param  numberOfPayments_ The number of payments being paid.
     *  @return serviceFees_      The amount of platform service fee to be paid.
     */
    function getServiceFees(address loan_, uint256 numberOfPayments_) external view returns (uint256 serviceFees_);

    /**
     *  @dev    Gets the service fees for the given interval.
     *  @param  loan_        The address of the loan contract.
     *  @param  interval_    The time, in seconds, to get the proportional fee for
     *  @return serviceFees_ The amount of platform service fee to be paid.
     */
    function getServiceFeesForPeriod(address loan_, uint256 interval_) external view returns (uint256 serviceFees_);

    /**
     *  @dev    Gets the global contract address.
     *  @return globals_ The address of the global contract.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the platform fee rate for the given loan.
     *  @param  loan_                        The address of the loan contract.
     *  @return platformRefinanceServiceFee_ The amount of platform service fee to be paid.
     */
    function platformRefinanceServiceFee(address loan_) external view returns (uint256 platformRefinanceServiceFee_);

    /**
     *  @dev    Gets the platform fee rate for the given loan.
     *  @param  loan_              The address of the loan contract.
     *  @return platformServiceFee The amount of platform service fee to be paid.
     */
    function platformServiceFee(address loan_) external view returns (uint256 platformServiceFee);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title Refinancer uses storage from Maple Loan.
interface IRefinancer {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   A new value for closingRate has been set.
     *  @param closingRate_ The new value for closingRate.
     */
    event ClosingRateSet(uint256 closingRate_);

    /**
     *  @dev   A new value for collateralRequired has been set.
     *  @param collateralRequired_ The new value for collateralRequired.
     */
    event CollateralRequiredSet(uint256 collateralRequired_);

    /**
     *  @dev   A new value for endingPrincipal has been set.
     *  @param endingPrincipal_ The new value for endingPrincipal.
     */
    event EndingPrincipalSet(uint256 endingPrincipal_);

    /**
     *  @dev   A new value for gracePeriod has been set.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    event GracePeriodSet(uint256 gracePeriod_);

    /**
     *  @dev   A new value for interestRate has been set.
     *  @param interestRate_ The new value for interestRate.
     */
    event InterestRateSet(uint256 interestRate_);

    /**
     *  @dev   A new value for lateFeeRate has been set.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    event LateFeeRateSet(uint256 lateFeeRate_);

    /**
     *  @dev   A new value for lateInterestPremium has been set.
     *  @param lateInterestPremium_ The new value for lateInterestPremium.
     */
    event LateInterestPremiumSet(uint256 lateInterestPremium_);

    /**
     *  @dev   A new value for paymentInterval has been set.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    event PaymentIntervalSet(uint256 paymentInterval_);

    /**
     *  @dev   A new value for paymentsRemaining has been set.
     *  @param paymentsRemaining_ The new value for paymentsRemaining.
     */
    event PaymentsRemainingSet(uint256 paymentsRemaining_);

    /**
     *  @dev   The value of the principal has been increased.
     *  @param increasedBy_ The amount of which the value was increased by.
     */
    event PrincipalIncreased(uint256 increasedBy_);

    /******************************************************************************************************************************/
    /*** Functions                                                                                                              ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Function to increase the principal during a refinance.
     *  @param amount_ The amount of which the value will increase by.
     */
    function increasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to set the closingRate during a refinance.
     *  @param closingRate_ The new value for closingRate.
     */
    function setClosingRate(uint256 closingRate_) external;

    /**
     *  @dev   Function to set the collateralRequired during a refinance.
     *  @param collateralRequired_ The new value for collateralRequired.
     */
    function setCollateralRequired(uint256 collateralRequired_) external;

    /**
     *  @dev   Function to set the endingPrincipal during a refinance.
     *  @param endingPrincipal_ The new value for endingPrincipal.
     */
    function setEndingPrincipal(uint256 endingPrincipal_) external;

    /**
     *  @dev   Function to set the gracePeriod during a refinance.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    function setGracePeriod(uint256 gracePeriod_) external;

    /**
     *  @dev   Function to set the interestRate during a refinance.
               The interest rate is measured with 18 decimals of precision.
     *  @param interestRate_ The new value for interestRate.
     */
    function setInterestRate(uint256 interestRate_) external;

    /**
     *  @dev   Function to set the lateFeeRate during a refinance.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    function setLateFeeRate(uint256 lateFeeRate_) external;

    /**
     *  @dev   Function to set the lateInterestPremium during a refinance.
     *  @param lateInterestPremium_ The new value for lateInterestPremium.
     */
    function setLateInterestPremium(uint256 lateInterestPremium_) external;

    /**
     *  @dev   Function to set the paymentInterval during a refinance.
     *         The interval is denominated in seconds.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    function setPaymentInterval(uint256 paymentInterval_) external;

    /**
     *  @dev   Function to set the paymentsRemaining during a refinance.
     *  @param paymentsRemaining_ The new value for paymentsRemaining.
     */
    function setPaymentsRemaining(uint256 paymentsRemaining_) external;

    /**
     *  @dev   Updates the fee terms on the FeeManager.
     *  @param delegateOriginationFee_ The amount of delegate origination fee to be paid.
     *  @param delegateServiceFee_     The amount of delegate service fee to be paid.
     */
    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP, including EIP-2612 permit functionality.
interface IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner_   Account that tokens are approved from.
     *  @param spender_ Account that tokens are approved for.
     *  @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner_     Account that tokens have moved from.
     *  @param recipient_ Account that tokens have moved to.
     *  @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_ Account that tokens are approved for.
     *  @param  amount_  Amount of tokens that have been approved.
     *  @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_          Account that tokens are approved for.
     *  @param  subtractedAmount_ Amount to decrease approval by.
     *  @return success_          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to increase the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_     Account that tokens are approved for.
     *  @param  addedAmount_ Amount to increase approval by.
     *  @return success_     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner_     Account that tokens are moving from.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner_     Account that tokens are approved from.
     *  @param  spender_   Account that tokens are approved for.
     *  @return allowance_ Allowance that one account has given another over their tokens.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account_ Account that owns the tokens.
     *  @return balance_ Amount of tokens owned by a given account.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals_ The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator_ The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /**
     *  @dev    Returns the name of the token.
     *  @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner_  The address of the owner account.
      *  @return nonce_ The nonce for the given owner.
     */
    function nonces(address owner_) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the permit type hash.
     *  @return permitTypehash_ The permit type hash.
     */
    function PERMIT_TYPEHASH() external view returns (bytes32 permitTypehash_);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply_ The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

}