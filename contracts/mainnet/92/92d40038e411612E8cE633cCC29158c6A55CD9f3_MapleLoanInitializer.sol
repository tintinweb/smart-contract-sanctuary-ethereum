// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanInitializer } from "./interfaces/IMapleLoanInitializer.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

contract MapleLoanInitializer is IMapleLoanInitializer, MapleLoanStorage {

    function encodeArguments(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    ) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

    function decodeArguments(bytes calldata encodedArguments_)
        public pure override returns (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        )
    {
        (
            borrower_,
            lender_,
            fundsAsset_,
            principalRequested_,
            termDetails_,
            rates_
        ) = abi.decode(encodedArguments_, (address, address, address, uint256, uint32[3], uint64[4]));
    }

    fallback() external {
        (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        ) = decodeArguments(msg.data);

        _initialize(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

    function _initialize(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
	    require(principalRequested_ != 0, "MLI:I:INVALID_PRINCIPAL");

        // Payment interval and notice period to be non-zero.
        require(termDetails_[1] != 0, "MLI:I:INVALID_NOTICE_PERIOD");
        require(termDetails_[2] != 0, "MLI:I:INVALID_PAYMENT_INTERVAL");

        address globals_ = IMapleProxyFactoryLike(msg.sender).mapleGlobals();

        require((borrower = borrower_) != address(0),            "MLI:I:ZERO_BORROWER");
        require(IGlobalsLike(globals_).isBorrower(borrower_),    "MLI:I:INVALID_BORROWER");
        require(IGlobalsLike(globals_).isPoolAsset(fundsAsset_), "MLI:I:INVALID_FUNDS_ASSET");

        require((lender = lender_) != address(0), "MLI:I:ZERO_LENDER");

        address loanManagerFactory_ = ILenderLike(lender_).factory();

        require(ILenderLike(lender_).fundsAsset() == fundsAsset_,                                    "MLI:I:DIFFERENT_ASSET");
        require(IGlobalsLike(globals_).isInstanceOf("OT_LOAN_MANAGER_FACTORY", loanManagerFactory_), "MLI:I:INVALID_FACTORY");
        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(lender_),                     "MLI:I:INVALID_INSTANCE");

        fundsAsset = fundsAsset_;

        principal = principalRequested_;

        gracePeriod     = termDetails_[0];
        noticePeriod    = termDetails_[1];
        paymentInterval = termDetails_[2];

        delegateServiceFeeRate  = rates_[0];
        interestRate            = rates_[1];
        lateFeeRate             = rates_[2];
        lateInterestPremiumRate = rates_[3];

        platformServiceFeeRate = uint64(IGlobalsLike(globals_).platformServiceFeeRate(ILenderLike(lender_).poolManager()));

        emit Initialized(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanEvents } from "./IMapleLoanEvents.sol";

interface IMapleLoanInitializer is IMapleLoanEvents {

    /**
     *  @dev    Encodes the initialization arguments for a MapleLoan.
     *  @param  borrower_           The address of the borrower.
     *  @param  lender_             The address of the lender.
     *  @param  fundsAsset_         The address of the lent asset.
     *  @param  principalRequested_ The amount of principal requested.
     *  @param  termDetails_        Array of loan parameters:
     *                                  [0]: gracePeriod,
     *                                  [1]: noticePeriod,
     *                                  [2]: paymentInterval
     *  @param  rates_              Array of rate parameters:
     *                                  [0]: delegateServiceFeeRate,
     *                                  [1]: interestRate,
     *                                  [2]: lateFeeRate,
     *                                  [3]: lateInterestPremiumRate
     *  @return encodedArguments_  The encoded arguments for initializing a loan.
     */
    function encodeArguments(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    ) external pure returns (bytes memory encodedArguments_);

    /**
     *  @dev    Decodes the initialization arguments for a MapleLoan.
     *  @param  encodedArguments_   The encoded arguments for initializing a loan.
     *  @return borrower_           The address of the borrower.
     *  @return lender_             The address of the lender.
     *  @return fundsAsset_         The address of the lent asset.
     *  @return principalRequested_ The amount of principal requested.
     *  @return termDetails_        Array of loan parameters:
     *                                  [0]: gracePeriod,
     *                                  [1]: noticePeriod,
     *                                  [2]: paymentInterval
     *  @return rates_              Array of rate parameters:
     *                                  [0]: delegateServiceFeeRate,
     *                                  [1]: interestRate,
     *                                  [2]: lateFeeRate,
     *                                  [3]: lateInterestPremiumRate
     */
    function decodeArguments(bytes calldata encodedArguments_) external pure
        returns (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        );

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IGlobalsLike {

    function canDeploy(address caller_) external view returns (bool canDeploy_);

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    function platformServiceFeeRate(address poolManager) external view returns (uint256 platformServiceFeeRate_);

    function securityAdmin() external view returns (address securityAdmin_);

}

interface ILenderLike {

    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  paymentDueDate_
    ) external;

    function factory() external view returns (address factory_);

    function fundsAsset() external view returns (address fundsAsset_);

    function poolManager() external view returns (address poolManager_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

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

/// @title IMapleLoanEvents defines the events for a MapleLoan.
interface IMapleLoanEvents {

    /**
     *  @dev   Borrower was accepted, and set to a new account.
     *  @param borrower_ The address of the new borrower.
     */
    event BorrowerAccepted(address indexed borrower_);

    /**
     *  @dev   The lender reverted the action of the loan being called and the payment due date was restored to it's original value.
     *  @param paymentDueDate_ The restored payment due date.
     *  @param defaultDate_    The date the loan will be in default.
     */
    event CallRemoved(uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev   The loan was funded.
     *  @param amount_         The amount funded.
     *  @param paymentDueDate_ The due date of the first payment.
     *  @param defaultDate_    The date the loan will be in default.
     */
    event Funded(uint256 amount_, uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev   The payment due date was fast forwarded to the current time, activating the grace period.
     *         This is emitted when the pool delegate wants to force a payment (or default).
     *  @param paymentDueDate_ The new payment due date.
     *  @param defaultDate_    The date the loan will be in default.
     */
    event Impaired(uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev   The payment due date was restored to it's original value, reverting the action of loan impairment.
     *  @param paymentDueDate_ The restored payment due date.
     *  @param defaultDate_    The date the loan will be in default.
     */
    event ImpairmentRemoved(uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev   Loan was initialized.
     *  @param borrower_           The address of the borrower.
     *  @param lender_             The address of the lender.
     *  @param fundsAsset_         The address of the lent asset.
     *  @param principalRequested_ The amount of principal requested.
     *  @param termDetails_        Array of loan parameters:
     *                                 [0]: gracePeriod,
     *                                 [1]: noticePeriod,
     *                                 [2]: paymentInterval
     *  @param rates_              Array of rate parameters:
     *                                 [0]: delegateServiceFeeRate,
     *                                 [1]: interestRate,
     *                                 [2]: lateFeeRate,
     *                                 [3]: lateInterestPremiumRate
     */
    event Initialized(
        address   indexed borrower_,
        address   indexed lender_,
        address   indexed fundsAsset_,
        uint256           principalRequested_,
        uint32[3]         termDetails_,
        uint64[4]         rates_
    );

    /**
     *  @dev   Lender was accepted, and set to a new account.
     *  @param lender_ The address of the new lender.
     */
    event LenderAccepted(address indexed lender_);

    /**
     *  @dev   The terms of the refinance proposal were accepted.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsAccepted(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   A refinance was proposed.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsProposed(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   The terms of the refinance proposal were rejected.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsRejected(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   Payments were made.
     *  @param lender_             The address of the lender the payment was made to.
     *  @param principalPaid_      The portion of the total amount that went towards paying down principal.
     *  @param interestPaid_       The portion of the total amount that went towards interest.
     *  @param lateInterestPaid_   The portion of the total amount that went towards late interest.
     *  @param delegateServiceFee_ The portion of the total amount that went towards delegate service fees.
     *  @param platformServiceFee_ The portion of the total amount that went towards platform service fee.
     *  @param paymentDueDate_     The new payment due date.
     *  @param defaultDate_        The date the loan will be in default.
     */
    event PaymentMade(
        address indexed lender_,
        uint256         principalPaid_,
        uint256         interestPaid_,
        uint256         lateInterestPaid_,
        uint256         delegateServiceFee_,
        uint256         platformServiceFee_,
        uint40          paymentDueDate_,
        uint40          defaultDate_
    );

    /**
     *  @dev   Pending borrower was set.
     *  @param pendingBorrower_ Address that can accept the borrower role.
     */
    event PendingBorrowerSet(address indexed pendingBorrower_);

    /**
     *  @dev   Pending lender was set.
     *  @param pendingLender_ The address that can accept the lender role.
     */
    event PendingLenderSet(address indexed pendingLender_);

    /**
     *  @dev   The lender called the loan, giving the borrower a notice period within which to return principal and pro-rata interest.
     *  @param principalToReturn_ The minimum amount of principal the borrower must return.
     *  @param paymentDueDate_    The new payment due date.
     *  @param defaultDate_       The date the loan will be in default.
     */
    event PrincipalCalled(uint256 principalToReturn_, uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev   Principal was returned to lender, to close the loan or return future interest payments.
     *  @param principalReturned_  The amount of principal returned.
     *  @param principalRemaining_ The amount of principal remaining on the loan.
     */
    event PrincipalReturned(uint256 principalReturned_, uint256 principalRemaining_);

    /**
     *  @dev   The loan was in default and funds and collateral was repossessed by the lender.
     *  @param fundsRepossessed_ The amount of funds asset repossessed.
     *  @param destination_      The address of the recipient of the funds, if any.
     */
    event Repossessed(uint256 fundsRepossessed_, address indexed destination_);

    /**
     *  @dev   Some token was removed from the loan.
     *  @param token_       The address of the token contract.
     *  @param amount_      The amount of token remove from the loan.
     *  @param destination_ The recipient of the token.
     */
    event Skimmed(address indexed token_, uint256 amount_, address indexed destination_);

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