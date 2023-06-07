// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 } from "../modules/erc20/contracts/interfaces/IERC20.sol";

import { IMapleRefinancer } from "./interfaces/IMapleRefinancer.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗    ██████╗ ███████╗███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██████╔╝█████╗  █████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██╔══██╗██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ██║  ██║███████╗██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝

*/

/// @title Refinancer uses storage from a MapleLoan defined by MapleLoanStorage.
contract MapleRefinancer is IMapleRefinancer, MapleLoanStorage {

    function decreasePrincipal(uint256 amount_) external override {
        principal -= amount_;

        emit PrincipalDecreased(amount_);
    }

    function increasePrincipal(uint256 amount_) external override {
        principal += amount_;

        emit PrincipalIncreased(amount_);
    }

    function setDelegateServiceFeeRate(uint64 delegateServiceFeeRate_) external override {
        emit DelegateServiceFeeRateSet(delegateServiceFeeRate = delegateServiceFeeRate_);
    }

    function setGracePeriod(uint32 gracePeriod_) external override {
        emit GracePeriodSet(gracePeriod = gracePeriod_);
    }

    function setInterestRate(uint64 interestRate_) external override {
        emit InterestRateSet(interestRate = interestRate_);
    }

    function setLateFeeRate(uint64 lateFeeRate_) external override {
        emit LateFeeRateSet(lateFeeRate = lateFeeRate_);
    }

    function setLateInterestPremiumRate(uint64 lateInterestPremiumRate_) external override {
        emit LateInterestPremiumRateSet(lateInterestPremiumRate = lateInterestPremiumRate_);
    }

    function setNoticePeriod(uint32 noticePeriod_) external override {
        emit NoticePeriodSet(noticePeriod = noticePeriod_);
    }

    function setPaymentInterval(uint32 paymentInterval_) external override {
        require(paymentInterval_ != 0, "R:SPI:ZERO_AMOUNT");

        emit PaymentIntervalSet(paymentInterval = paymentInterval_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP, including EIP-2612 permit functionality.
interface IERC20 {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleRefinancer uses storage from Maple Loan.
interface IMapleRefinancer {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   The value for the service fee rate for the PoolDelegate (1e18 units).
     *  @param delegateServiceFeeRate_ The new value for delegateServiceFeeRate.
     */
    event DelegateServiceFeeRateSet(uint64 delegateServiceFeeRate_);

    /**
     *  @dev   A new value for gracePeriod has been set.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    event GracePeriodSet(uint256 gracePeriod_);

    /**
     *  @dev   A new value for interestRate has been set.
     *  @param interestRate_ The new value for interestRate.
     */
    event InterestRateSet(uint64 interestRate_);

    /**
     *  @dev   A new value for lateFeeRate has been set.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    event LateFeeRateSet(uint64 lateFeeRate_);

    /**
     *  @dev   A new value for lateInterestPremiumRate has been set.
     *  @param lateInterestPremiumRate_ The new value for lateInterestPremiumRate.
     */
    event LateInterestPremiumRateSet(uint64 lateInterestPremiumRate_);

    /**
     *  @dev   A new value for noticePeriod has been set.
     *  @param noticePeriod_ The new value for noticedPeriod.
     */
    event NoticePeriodSet(uint256 noticePeriod_);

    /**
     *  @dev   A new value for paymentInterval has been set.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    event PaymentIntervalSet(uint256 paymentInterval_);

    /**
     *  @dev   The value of the principal has been decreased.
     *  @param decreasedBy_ The amount of which the value was decreased by.
     */
    event PrincipalDecreased(uint256 decreasedBy_);

    /**
     *  @dev   The value of the principal has been increased.
     *  @param increasedBy_ The amount of which the value was increased by.
     */
    event PrincipalIncreased(uint256 increasedBy_);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Function to decrease the principal during a refinance.
     *  @param amount_ The amount of which the value will decrease by.
     */
    function decreasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to increase the principal during a refinance.
     *  @param amount_ The amount of which the value will increase by.
     */
    function increasePrincipal(uint256 amount_) external;

    /**
     *  @dev   Function to set the delegateServiceFeeRate during a refinance.
     *         The rate is denominated in 1e18 units.
     *  @param delegateServiceFeeRate_ The new value for delegateServiceFeeRate.
     */
    function setDelegateServiceFeeRate(uint64 delegateServiceFeeRate_) external;

    /**
     *  @dev   Function to set the gracePeriod during a refinance.
     *  @param gracePeriod_ The new value for gracePeriod.
     */
    function setGracePeriod(uint32 gracePeriod_) external;

    /**
     *  @dev   Function to set the interestRate during a refinance.
               The interest rate is measured with 18 decimals of precision.
     *  @param interestRate_ The new value for interestRate.
     */
    function setInterestRate(uint64 interestRate_) external;

    /**
     *  @dev   Function to set the lateFeeRate during a refinance.
     *  @param lateFeeRate_ The new value for lateFeeRate.
     */
    function setLateFeeRate(uint64 lateFeeRate_) external;

    /**
     *  @dev   Function to set the lateInterestPremiumRate during a refinance.
     *  @param lateInterestPremiumRate_ The new value for lateInterestPremiumRate.
     */
    function setLateInterestPremiumRate(uint64 lateInterestPremiumRate_) external;

    /**
     *  @dev   Function to set the noticePeriod during a refinance.
     *  @param noticePeriod_ The new value for noticePeriod.
     */
    function setNoticePeriod(uint32 noticePeriod_) external;

    /**
     *  @dev   Function to set the paymentInterval during a refinance.
     *         The interval is denominated in seconds.
     *  @param paymentInterval_ The new value for paymentInterval.
     */
    function setPaymentInterval(uint32 paymentInterval_) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanStorage } from "./interfaces/IMapleLoanStorage.sol";

/// @title MapleLoanStorage defines the storage layout of MapleLoan.
abstract contract MapleLoanStorage is IMapleLoanStorage {

    address public override fundsAsset;       // The address of the asset used as funds.
    address public override borrower;         // The address of the borrower.
    address public override lender;           // The address of the lender.
    address public override pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address public override pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    bytes32 public override refinanceCommitment;  // The commitment hash of the refinance proposal.

    uint32 public override gracePeriod;      // The number of seconds a payment can be late.
    uint32 public override noticePeriod;     // The number of seconds after a loan is called after which the borrower can be considered in default.
    uint32 public override paymentInterval;  // The number of seconds between payments.

    uint40 public override dateCalled;    // The date the loan was called.
    uint40 public override dateFunded;    // The date the loan was funded.
    uint40 public override dateImpaired;  // The date the loan was impaired.
    uint40 public override datePaid;      // The date the loan was paid.

    uint256 public override calledPrincipal;  // The amount of principal yet to be returned to satisfy the loan call.
    uint256 public override principal;        // The amount of principal yet to be paid down.

    uint64 public override delegateServiceFeeRate;   // The annualized delegate service fee rate.
    uint64 public override interestRate;             // The annualized interest rate of the loan.
    uint64 public override lateFeeRate;              // The fee rate for late payments.
    uint64 public override lateInterestPremiumRate;  // The amount to increase the interest rate by for late payments.
    uint64 public override platformServiceFeeRate;   // The annualized platform service fee rate.

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleLoanStorage define the storage slots for MapleLoan, which is intended to be proxied.
interface IMapleLoanStorage {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The borrower of the loan, responsible for repayments.
     */
    function borrower() external view returns (address borrower_);

    /**
     *  @dev The amount of principal yet to be returned to satisfy the loan call.
     */
    function calledPrincipal() external view returns (uint256 calledPrincipal_);

    /**
     *  @dev The timestamp of the date the loan was called.
     */
    function dateCalled() external view returns (uint40 dateCalled_);

    /**
     *  @dev The timestamp of the date the loan was funded.
     */
    function dateFunded() external view returns (uint40 dateFunded_);

    /**
     *  @dev The timestamp of the date the loan was impaired.
     */
    function dateImpaired() external view returns (uint40 dateImpaired_);

    /**
     *  @dev The timestamp of the date the loan was last paid.
     */
    function datePaid() external view returns (uint40 datePaid_);

    /**
     *  @dev The annualized delegate service fee rate.
     */
    function delegateServiceFeeRate() external view returns (uint64 delegateServiceFeeRate_);

    /**
     *  @dev The address of the fundsAsset funding the loan.
     */
    function fundsAsset() external view returns (address asset_);

    /**
     *  @dev The amount of time the borrower has, after a payment is due, to make a payment before being in default.
     */
    function gracePeriod() external view returns (uint32 gracePeriod_);

    /**
     *  @dev The annualized interest rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function interestRate() external view returns (uint64 interestRate_);

    /**
     *  @dev The rate charged at late payments.
     */
    function lateFeeRate() external view returns (uint64 lateFeeRate_);

    /**
     *  @dev The premium over the regular interest rate applied when paying late.
     */
    function lateInterestPremiumRate() external view returns (uint64 lateInterestPremiumRate_);

    /**
     *  @dev The lender of the Loan.
     */
    function lender() external view returns (address lender_);

    /**
     *  @dev The amount of time the borrower has, after the loan is called, to make a payment, paying back the called principal.
     */
    function noticePeriod() external view returns (uint32 noticePeriod_);

    /**
     *  @dev The specified time between loan payments.
     */
    function paymentInterval() external view returns (uint32 paymentInterval_);

    /**
     *  @dev The address of the pending borrower.
     */
    function pendingBorrower() external view returns (address pendingBorrower_);

    /**
     *  @dev The address of the pending lender.
     */
    function pendingLender() external view returns (address pendingLender_);

    /**
     *  @dev The annualized platform service fee rate.
     */
    function platformServiceFeeRate() external view returns (uint64 platformServiceFeeRate_);

    /**
     *  @dev The amount of principal owed (initially, the requested amount), which needs to be paid back.
     */
    function principal() external view returns (uint256 principal_);

    /**
     *  @dev The hash of the proposed refinance agreement.
     */
    function refinanceCommitment() external view returns (bytes32 refinanceCommitment_);

}