// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanInitializer } from "./interfaces/IMapleLoanInitializer.sol";
import { IMapleLoanFeeManager }  from "./interfaces/IMapleLoanFeeManager.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

contract MapleLoanInitializer is IMapleLoanInitializer, MapleLoanStorage {

    function encodeArguments(
        address           borrower_,
        address           lender_,
        address           feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_
    ) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);
    }

    function decodeArguments(bytes calldata encodedArguments_)
        public pure override returns (
            address           borrower_,
            address           lender_,
            address           feeManager_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_,
            uint256[2] memory fees_
        )
    {
        (
            borrower_,
            lender_,
            feeManager_,
            assets_,
            termDetails_,
            amounts_,
            rates_,
            fees_
        ) = abi.decode(encodedArguments_, (address, address, address, address[2], uint256[3], uint256[3], uint256[4], uint256[2]));
    }

    fallback() external {
        (
            address           borrower_,
            address           lender_,
            address           feeManager_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_,
            uint256[2] memory fees_
        ) = decodeArguments(msg.data);

        _initialize(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);

        emit Initialized(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);
    }

    /**
     *  @dev   Initializes the loan.
     *  @param borrower_    The address of the borrower.
     *  @param feeManager_  The address of the entity responsible for calculating fees
     *  @param assets_      Array of asset addresses.
     *                       [0]: collateralAsset,
     *                       [1]: fundsAsset
     *  @param termDetails_ Array of loan parameters:
     *                       [0]: gracePeriod,
     *                       [1]: paymentInterval,
     *                       [2]: payments
     *  @param amounts_     Requested amounts:
     *                       [0]: collateralRequired,
     *                       [1]: principalRequested,
     *                       [2]: endingPrincipal
     *  @param rates_       Rates parameters:
     *                       [0]: interestRate,
     *                       [1]: closingFeeRate,
     *                       [2]: lateFeeRate,
     *                       [3]: lateInterestPremiumRate,
     *  @param fees_        Array of fees:
     *                       [0]: delegateOriginationFee,
     *                       [1]: delegateServiceFee
     */
    function _initialize(
        address           borrower_,
        address           lender_,
        address           feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
        require(amounts_[1] > uint256(0), "MLI:I:INVALID_PRINCIPAL");

        // Ending principal needs to be less than or equal to principal requested.
        require(amounts_[2] <= amounts_[1], "MLI:I:INVALID_ENDING_PRINCIPAL");

        // Payment interval and payments remaining need to be non-zero.
        require(termDetails_[0] >= 12 hours, "MLI:I:INVALID_GRACE_PERIOD");
        require(termDetails_[1] > 0,         "MLI:I:INVALID_PAYMENT_INTERVAL");
        require(termDetails_[2] > 0,         "MLI:I:INVALID_PAYMENTS_REMAINING");

        uint256 maxOriginationFee_ = amounts_[1] * 0.025e6 / 1e6;  // 2.5% of principal

        require(fees_[0] <= maxOriginationFee_, "MLI:I:INVALID_ORIGINATION_FEE");

        IGlobalsLike globals_ = IGlobalsLike(IMapleProxyFactoryLike(msg.sender).mapleGlobals());

        require((_borrower = borrower_) != address(0),  "MLI:I:ZERO_BORROWER");
        require(globals_.isBorrower(borrower_),         "MLI:I:INVALID_BORROWER");
        require(globals_.isPoolAsset(assets_[1]),       "MLI:I:INVALID_FUNDS_ASSET");
        require(globals_.isCollateralAsset(assets_[0]), "MLI:I:INVALID_COLLATERAL_ASSET");

        require((_lender = lender_) != address(0), "MLI:I:ZERO_LENDER");

        address loanManagerFactory_ = ILenderLike(lender_).factory();

        require(ILenderLike(lender_).fundsAsset() == assets_[1],                       "MLI:I:DIFFERENT_FUNDS_ASSET");
        require(globals_.isInstanceOf("FT_LOAN_MANAGER_FACTORY", loanManagerFactory_), "MLI:I:INVALID_FACTORY");
        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(lender_),       "MLI:I:INVALID_INSTANCE");

        require((_feeManager = feeManager_) != address(0),         "MLI:I:INVALID_MANAGER");
        require(globals_.isInstanceOf("FEE_MANAGER", feeManager_), "MLI:I:INVALID_FEE_MANAGER");

        _collateralAsset = assets_[0];
        _fundsAsset      = assets_[1];

        _gracePeriod       = termDetails_[0];
        _paymentInterval   = termDetails_[1];
        _paymentsRemaining = termDetails_[2];

        _collateralRequired = amounts_[0];
        _principalRequested = amounts_[1];
        _endingPrincipal    = amounts_[2];

        _interestRate            = rates_[0];
        _closingRate             = rates_[1];
        _lateFeeRate             = rates_[2];
        _lateInterestPremiumRate = rates_[3];

        // Set fees for the loan.
        IMapleLoanFeeManager(feeManager_).updateDelegateFeeTerms(fees_[0], fees_[1]);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanEvents } from "./IMapleLoanEvents.sol";

interface IMapleLoanInitializer is IMapleLoanEvents {

    /**
     *  @dev   Encodes the initialization arguments for a MapleLoan.
     *  @param borrower_    The address of the borrower.
     *  @param lender_      The address of the lender.
     *  @param feeManager_  The address of the entity responsible for calculating fees.
     *  @param assets_      Array of asset addresses.
     *                       [0]: collateralAsset,
     *                       [1]: fundsAsset
     *  @param termDetails_ Array of loan parameters:
     *                       [0]: gracePeriod,
     *                       [1]: paymentInterval,
     *                       [2]: payments
     *  @param amounts_     Requested amounts:
     *                       [0]: collateralRequired,
     *                       [1]: principalRequested,
     *                       [2]: endingPrincipal
     *  @param rates_       Rates parameters:
     *                       [0]: interestRate,
     *                       [1]: closingFeeRate,
     *                       [2]: lateFeeRate,
     *                       [3]: lateInterestPremiumRate,
     *  @param fees_        Array of fees:
     *                       [0]: delegateOriginationFee,
     *                       [1]: delegateServiceFee
     */
    function encodeArguments(
        address           borrower_,
        address           lender_,
        address           feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_
    ) external pure returns (bytes memory encodedArguments_);

    /**
     *  @dev   Decodes the initialization arguments for a MapleLoan.
     *  @return borrower_    The address of the borrower.
     *  @return lender_      The address of the lender.
     *  @return feeManager_  The address of the entity responsible for calculating fees.
     *  @return assets_      Array of asset addresses.
     *                        [0]: collateralAsset,
     *                        [1]: fundsAsset
     *  @return termDetails_ Array of loan parameters:
     *                        [0]: gracePeriod,
     *                        [1]: paymentInterval,
     *                        [2]: payments
     *  @return amounts_     Requested amounts:
     *                        [0]: collateralRequired,
     *                        [1]: principalRequested,
     *                        [2]: endingPrincipal
     *  @return rates_       Rates parameters:
     *                        [0]: interestRate,
     *                        [1]: closingFeeRate,
     *                        [2]: lateFeeRate,
     *                        [3]: lateInterestPremiumRate,
     *  @return fees_        Array of fees:
     *                        [0]: delegateOriginationFee,
     *                        [1]: delegateServiceFee
     */
    function decodeArguments(bytes calldata encodedArguments_) external pure
        returns (
            address           borrower_,
            address           lender_,
            address           feeManager_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_,
            uint256[2] memory fees_
        );

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleLoanFeeManager {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

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
     *  @param loan_                      The address of the loan contract.
     *  @param partialPlatformServiceFee_ The  value for the platform service fee.
     *  @param partialDelegateServiceFee_ The  value for the delegate service fee.
     */
    event PartialRefinanceServiceFeesUpdated(address loan_, uint256 partialPlatformServiceFee_, uint256 partialDelegateServiceFee_);

    /**
     *  @dev   New fee terms have been set.
     *  @param loan_               The address of the loan contract.
     *  @param platformServiceFee_ The new value for the platform service fee.
     */
    event PlatformServiceFeeUpdated(address loan_, uint256 platformServiceFee_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                               The address of the loan contract.
     *  @param delegateServiceFee_                 The amount of delegate service fee paid.
     *  @param partialRefinanceDelegateServiceFee_ The amount of partial delegate service fee from refinance paid.
     *  @param platformServiceFee_                 The amount of platform service fee paid.
     *  @param partialRefinancePlatformServiceFee_ The amount of partial platform service fee from refinance paid.
     */
    event ServiceFeesPaid(
        address loan_,
        uint256 delegateServiceFee_,
        uint256 partialRefinanceDelegateServiceFee_,
        uint256 platformServiceFee_,
        uint256 partialRefinancePlatformServiceFee_
    );

    /**************************************************************************************************************************************/
    /*** Payment Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

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

    /**************************************************************************************************************************************/
    /*** Fee Update Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Called during loan creation or refinance, sets the fee terms.
     *  @param delegateOriginationFee_ The amount of delegate origination fee to be paid.
     *  @param delegateServiceFee_     The amount of delegate service fee to be paid.
     */
    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external;

    /**
     *  @dev Function called by loans to update the saved platform service fee rate.
     */
    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external;

    /**
     *  @dev   Called during loan refinance to save the partial service fees accrued.
     *  @param principalRequested_   The amount of principal pre-refinance requested.
     *  @param timeSinceLastDueDate_ The amount of time since last payment due date.
     */
    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Gets the delegate origination fee for the given loan.
     *  @param  loan_                   The address of the loan contract.
     *  @return delegateOriginationFee_ The amount of origination to be paid to delegate.
     */
    function delegateOriginationFee(address loan_) external view returns (uint256 delegateOriginationFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_                        The address of the loan contract.
     *  @return delegateRefinanceServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateRefinanceServiceFee(address loan_) external view returns (uint256 delegateRefinanceServiceFee_);

    /**
     *  @dev    Gets the delegate service fee rate for the given loan.
     *  @param  loan_               The address of the loan contract.
     *  @return delegateServiceFee_ The amount of delegate service fee to be paid.
     */
    function delegateServiceFee(address loan_) external view returns (uint256 delegateServiceFee_);

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
    function getOriginationFees(address loan_, uint256 principalRequested_) external view returns (uint256 originationFees_);

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
    function getPlatformServiceFeeForPeriod(
        address loan_,
        uint256 principalRequested_,
        uint256 interval_
    ) external view returns (uint256 platformServiceFee_);

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

interface IGlobalsLike {

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address poolAsset_) external view returns (bool isValid_);

    function mapleTreasury() external view returns (address governor_);

    function platformOriginationFeeRate(address pool_) external view returns (uint256 platformOriginationFeeRate_);

    function platformServiceFeeRate(address pool_) external view returns (uint256 platformFee_);

    function securityAdmin() external view returns (address securityAdmin_);

}

interface ILenderLike {

    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external;

    function factory() external view returns (address factory_);

    function fundsAsset() external view returns (address fundsAsset_);

}

interface ILoanLike {

    function factory() external view returns (address factory_);

    function fundsAsset() external view returns (address asset_);

    function lender() external view returns (address lender_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

}

interface ILoanManagerLike {

    function owner() external view returns (address owner_);

    function poolManager() external view returns (address poolManager_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface IPoolManagerLike {

    function poolDelegate() external view returns (address poolDelegate_);

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
     *  @dev   Collateral was posted.
     *  @param amount_ The amount of collateral posted.
     */
    event CollateralPosted(uint256 amount_);

    /**
     *  @dev   Collateral was removed.
     *  @param amount_      The amount of collateral removed.
     *  @param destination_ The recipient of the collateral removed.
     */
    event CollateralRemoved(uint256 amount_, address indexed destination_);

    /**
     *  @dev   The loan was funded.
     *  @param lender_             The address of the lender.
     *  @param amount_             The amount funded.
     *  @param nextPaymentDueDate_ The due date of the next payment.
     */
    event Funded(address indexed lender_, uint256 amount_, uint256 nextPaymentDueDate_);

    /**
     *  @dev   Funds were claimed.
     *  @param amount_      The amount of funds claimed.
     *  @param destination_ The recipient of the funds claimed.
     */
    event FundsClaimed(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were drawn.
     *  @param amount_      The amount of funds drawn.
     *  @param destination_ The recipient of the funds drawn down.
     */
    event FundsDrawnDown(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were returned.
     *  @param amount_ The amount of funds returned.
     */
    event FundsReturned(uint256 amount_);

    /**
     *  @dev   The loan impairment was explicitly removed (i.e. not the result of a payment or new terms acceptance).
     *  @param nextPaymentDueDate_ The new next payment due date.
     */
    event ImpairmentRemoved(uint256 nextPaymentDueDate_);

    /**
     *  @dev   Loan was initialized.
     *  @param borrower_    The address of the borrower.
     *  @param lender_      The address of the lender.
     *  @param feeManager_  The address of the entity responsible for calculating fees.
     *  @param assets_      Array of asset addresses.
     *                       [0]: collateralAsset,
     *                       [1]: fundsAsset.
     *  @param termDetails_ Array of loan parameters:
     *                       [0]: gracePeriod,
     *                       [1]: paymentInterval,
     *                       [2]: payments,
     *  @param amounts_     Requested amounts:
     *                       [0]: collateralRequired,
     *                       [1]: principalRequested,
     *                       [2]: endingPrincipal.
     *  @param rates_       Fee parameters:
     *                       [0]: interestRate,
     *                       [1]: closingFeeRate,
     *                       [2]: lateFeeRate,
     *                       [3]: lateInterestPremiumRate
     *  @param fees_        Array of fees:
     *                       [0]: delegateOriginationFee,
     *                       [1]: delegateServiceFee
     */
    event Initialized(
        address    indexed borrower_,
        address    indexed lender_,
        address    indexed feeManager_,
        address[2]         assets_,
        uint256[3]         termDetails_,
        uint256[3]         amounts_,
        uint256[4]         rates_,
        uint256[2]         fees_
    );

    /**
     *  @dev   Lender was accepted, and set to a new account.
     *  @param lender_ The address of the new lender.
     */
    event LenderAccepted(address indexed lender_);

    /**
     *  @dev   The next payment due date was fast forwarded to the current time, activating the grace period.
     *         This is emitted when the pool delegate wants to force a payment (or default).
     *  @param nextPaymentDueDate_ The new next payment due date.
     */
    event LoanImpaired(uint256 nextPaymentDueDate_);

    /**
     *  @dev   Loan was repaid early and closed.
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest.
     *  @param feesPaid_      The portion of the total amount that went towards fees.
     */
    event LoanClosed(uint256 principalPaid_, uint256 interestPaid_, uint256 feesPaid_);

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
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest.
     *  @param fees_          The portion of the total amount that went towards fees.
     */
    event PaymentMade(uint256 principalPaid_, uint256 interestPaid_, uint256 fees_);

    /**
     *  @dev   Pending borrower was set.
     *  @param pendingBorrower_ Address that can accept the borrower role.
     */
    event PendingBorrowerSet(address pendingBorrower_);

    /**
     *  @dev   Pending lender was set.
     *  @param pendingLender_ Address that can accept the lender role.
     */
    event PendingLenderSet(address pendingLender_);

    /**
     *  @dev   The loan was in default and funds and collateral was repossessed by the lender.
     *  @param collateralRepossessed_ The amount of collateral asset repossessed.
     *  @param fundsRepossessed_      The amount of funds asset repossessed.
     *  @param destination_           The recipient of the collateral and funds, if any.
     */
    event Repossessed(uint256 collateralRepossessed_, uint256 fundsRepossessed_, address indexed destination_);

    /**
     *  @dev   Some token (neither fundsAsset nor collateralAsset) was removed from the loan.
     *  @param token_       The address of the token contract.
     *  @param amount_      The amount of token remove from the loan.
     *  @param destination_ The recipient of the token.
     */
    event Skimmed(address indexed token_, uint256 amount_, address indexed destination_);

}