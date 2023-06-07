// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleLoan }           from "./interfaces/IMapleLoan.sol";
import { IMapleLoanFeeManager } from "./interfaces/IMapleLoanFeeManager.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║███████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝╚════██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝ ███████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝  ╚══════╝

*/

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    uint256 public constant override HUNDRED_PERCENT = 1e6;

    uint256 private constant SCALED_ONE = 1e18;

    modifier limitDrawableUse() {
        if (msg.sender == _borrower) {
            _;
            return;
        }

        uint256 drawableFundsBeforePayment = _drawableFunds;

        _;

        // Either the caller is the borrower or `_drawableFunds` has not decreased.
        require(_drawableFunds >= drawableFundsBeforePayment, "ML:CANNOT_USE_DRAWABLE");
    }

    modifier onlyBorrower() {
        _revertIfNotBorrower();
        _;
    }

    modifier onlyLender() {
        _revertIfNotLender();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == _factory(),        "ML:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "ML:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override whenNotPaused {
        require(msg.sender == _factory(),               "ML:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "ML:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == IGlobalsLike(globals()).securityAdmin(), "ML:U:NO_AUTH");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Borrow Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function acceptBorrower() external override whenNotPaused {
        require(msg.sender == _pendingBorrower, "ML:AB:NOT_PENDING_BORROWER");

        _pendingBorrower = address(0);

        emit BorrowerAccepted(_borrower = msg.sender);
    }

    function closeLoan(uint256 amount_)
        external override whenNotPaused limitDrawableUse returns (uint256 principal_, uint256 interest_, uint256 fees_)
    {
        // The amount specified is an optional amount to be transferred from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:CL:TRANSFER_FROM_FAILED"
        );

        uint256 paymentDueDate_ = _nextPaymentDueDate;

        require(block.timestamp <= paymentDueDate_, "ML:CL:PAYMENT_IS_LATE");


        ( principal_, interest_, ) = getClosingPaymentBreakdown();

        _refinanceInterest = uint256(0);

        uint256 principalAndInterest_ = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + getUnaccountedAmount(_fundsAsset)) - principalAndInterest_;

        fees_ = _handleServiceFeePayment(_paymentsRemaining);

        // NOTE: Closing a loan always results in the an impairment being removed.
        _clearLoanAccounting();

        emit LoanClosed(principal_, interest_, fees_);

        require(ERC20Helper.transfer(_fundsAsset, _lender, principalAndInterest_), "ML:MP:TRANSFER_FAILED");

        ILenderLike(_lender).claim(principal_, interest_, paymentDueDate_, 0);

        emit FundsClaimed(principalAndInterest_, _lender);
    }

    function drawdownFunds(uint256 amount_, address destination_) external override whenNotPaused onlyBorrower returns (uint256 collateralPosted_) {
        emit FundsDrawnDown(amount_, destination_);

        // Post additional collateral required to facilitate this drawdown, if needed.
        uint256 additionalCollateralRequired_ = getAdditionalCollateralRequiredFor(amount_);

        if (additionalCollateralRequired_ > uint256(0)) {
            // Determine collateral currently unaccounted for.
            uint256 unaccountedCollateral_ = getUnaccountedAmount(_collateralAsset);

            // Post required collateral, specifying then amount lacking as the optional amount to be transferred from.
            collateralPosted_ = postCollateral(
                additionalCollateralRequired_ > unaccountedCollateral_ ? additionalCollateralRequired_ - unaccountedCollateral_ : uint256(0)
            );
        }

        _drawableFunds -= amount_;

        require(ERC20Helper.transfer(_fundsAsset, destination_, amount_), "ML:DF:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                "ML:DF:INSUFFICIENT_COLLATERAL");
    }

    function makePayment(uint256 amount_)
        external override whenNotPaused limitDrawableUse returns (uint256 principal_, uint256 interest_, uint256 fees_)
    {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:MP:TRANSFER_FROM_FAILED"
        );

        ( principal_, interest_, ) = getNextPaymentBreakdown();

        _refinanceInterest = uint256(0);

        uint256 principalAndInterest_ = principal_ + interest_;

        // The drawable funds are increased by the extra funds in the contract, minus the total needed for payment.
        // NOTE: This line will revert if not enough funds were added for the full payment amount.
        _drawableFunds = (_drawableFunds + getUnaccountedAmount(_fundsAsset)) - principalAndInterest_;

        fees_ = _handleServiceFeePayment(1);

        uint256 paymentsRemaining_      = _paymentsRemaining;
        uint256 previousPaymentDueDate_ = _nextPaymentDueDate;
        uint256 nextPaymentDueDate_;

        // NOTE: Making a payment always results in the impairment being removed.
        if (paymentsRemaining_ == uint256(1)) {
            _clearLoanAccounting();  // Assumes `getNextPaymentBreakdown` returns a `principal_` that is `_principal`.
        } else {
            _nextPaymentDueDate  = nextPaymentDueDate_ = previousPaymentDueDate_ + _paymentInterval;
            _principal          -= principal_;
            _paymentsRemaining   = paymentsRemaining_ - uint256(1);

            delete _originalNextPaymentDueDate;
        }

        emit PaymentMade(principal_, interest_, fees_);

        require(ERC20Helper.transfer(_fundsAsset, _lender, principalAndInterest_), "ML:MP:TRANSFER_FAILED");

        ILenderLike(_lender).claim(principal_, interest_, previousPaymentDueDate_, nextPaymentDueDate_);

        emit FundsClaimed(principalAndInterest_, _lender);

        require(_isCollateralMaintained(), "ML:MP:INSUFFICIENT_COLLATERAL");
    }

    function postCollateral(uint256 amount_) public override whenNotPaused returns (uint256 collateralPosted_) {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_collateralAsset, msg.sender, address(this), amount_),
            "ML:PC:TRANSFER_FROM_FAILED"
        );

        _collateral += (collateralPosted_ = getUnaccountedAmount(_collateralAsset));

        emit CollateralPosted(collateralPosted_);
    }

    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyBorrower returns (bytes32 refinanceCommitment_)
    {
        require(deadline_ >= block.timestamp,                                       "ML:PNT:INVALID_DEADLINE");
        require(IGlobalsLike(globals()).isInstanceOf("FT_REFINANCER", refinancer_), "ML:PNT:INVALID_REFINANCER");
        require(calls_.length > uint256(0),                                         "ML:PNT:EMPTY_CALLS");

        emit NewTermsProposed(
            _refinanceCommitment = refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_),
            refinancer_,
            deadline_,
            calls_
        );
    }

    function removeCollateral(uint256 amount_, address destination_) external override whenNotPaused onlyBorrower {
        emit CollateralRemoved(amount_, destination_);

        _collateral -= amount_;

        require(ERC20Helper.transfer(_collateralAsset, destination_, amount_), "ML:RC:TRANSFER_FAILED");
        require(_isCollateralMaintained(),                                     "ML:RC:INSUFFICIENT_COLLATERAL");
    }

    function returnFunds(uint256 amount_) external override whenNotPaused returns (uint256 fundsReturned_) {
        // The amount specified is an optional amount to be transfer from the caller, as a convenience for EOAs.
        // NOTE: FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
        require(
            amount_ == uint256(0) || ERC20Helper.transferFrom(_fundsAsset, msg.sender, address(this), amount_),
            "ML:RF:TRANSFER_FROM_FAILED"
        );

        _drawableFunds += (fundsReturned_ = getUnaccountedAmount(_fundsAsset));

        emit FundsReturned(fundsReturned_);
    }

    function setPendingBorrower(address pendingBorrower_) external override whenNotPaused onlyBorrower {
        require(IGlobalsLike(globals()).isBorrower(pendingBorrower_), "ML:SPB:INVALID_BORROWER");

        emit PendingBorrowerSet(_pendingBorrower = pendingBorrower_);
    }

    /**************************************************************************************************************************************/
    /*** Lend Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function acceptLender() external override whenNotPaused {
        require(msg.sender == _pendingLender, "ML:AL:NOT_PENDING_LENDER");

        _pendingLender = address(0);

        emit LenderAccepted(_lender = msg.sender);
    }

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyLender returns (bytes32 refinanceCommitment_)
    {
        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(
            _refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:ANT:COMMITMENT_MISMATCH"
        );

        require(refinancer_.code.length != uint256(0), "ML:ANT:INVALID_REFINANCER");

        require(block.timestamp <= deadline_, "ML:ANT:EXPIRED_COMMITMENT");

        uint256 paymentInterval_           = _paymentInterval;
        uint256 nextPaymentDueDate_        = _nextPaymentDueDate;
        uint256 previousPrincipalRequested = _principalRequested;

        uint256 timeSinceLastDueDate_ = block.timestamp + paymentInterval_ < nextPaymentDueDate_
            ? 0
            : block.timestamp - (nextPaymentDueDate_ - paymentInterval_);

        // Not ideal for checks-effects-interactions,
        // but the feeManager is a trusted contract and it's needed to save the fee before refinance.
        IMapleLoanFeeManager feeManager_ = IMapleLoanFeeManager(_feeManager);
        feeManager_.updateRefinanceServiceFees(previousPrincipalRequested, timeSinceLastDueDate_);

        // Get the amount of interest owed since the last payment due date, as well as the time since the last due date
        uint256 proRataInterest_ = getRefinanceInterest(block.timestamp);

        // In case there is still a refinance interest, just increment it instead of setting it.
        _refinanceInterest += proRataInterest_;

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        delete _refinanceCommitment;

        // NOTE: Accepting new terms always results in the an impairment being removed.
        delete _originalNextPaymentDueDate;

        for (uint256 i_; i_ < calls_.length; ++i_) {
            ( bool success_, ) = refinancer_.delegatecall(calls_[i_]);
            require(success_, "ML:ANT:FAILED");
        }

        // TODO: Emit this before the refinance calls in order to adhere to the CEI pattern.
        emit NewTermsAccepted(refinanceCommitment_, refinancer_, deadline_, calls_);

        address fundsAsset_         = _fundsAsset;
        uint256 principalRequested_ = _principalRequested;

        paymentInterval_ = _paymentInterval;

        // Increment the due date to be one full payment interval from now, to restart the payment schedule with new terms.
        // NOTE: `_paymentInterval` here is possibly newly set via the above delegate calls, so cache it.
        _nextPaymentDueDate = block.timestamp + paymentInterval_;

        // Update Platform Fees and pay originations.
        feeManager_.updatePlatformServiceFee(principalRequested_, paymentInterval_);

        _drawableFunds -= feeManager_.payOriginationFees(fundsAsset_, principalRequested_);

        // Ensure that collateral is maintained after changes made.
        require(_isCollateralMaintained(),                       "ML:ANT:INSUFFICIENT_COLLATERAL");
        require(getUnaccountedAmount(fundsAsset_) == uint256(0), "ML:ANT:UNEXPECTED_FUNDS");
    }

    function fundLoan() external override whenNotPaused onlyLender returns (uint256 fundsLent_) {
        address lender_ = _lender;

        // Can only fund loan if there are payments remaining (defined in the initialization) and no payment is due (as set by a funding).
        require((_nextPaymentDueDate == uint256(0)) && (_paymentsRemaining != uint256(0)), "ML:FL:LOAN_ACTIVE");

        address fundsAsset_         = _fundsAsset;
        uint256 paymentInterval_    = _paymentInterval;
        uint256 principalRequested_ = _principalRequested;

        require(ERC20Helper.approve(fundsAsset_, _feeManager, type(uint256).max), "ML:FL:APPROVE_FAIL");

        // Saves the platform service fee rate for future payments.
        IMapleLoanFeeManager(_feeManager).updatePlatformServiceFee(principalRequested_, paymentInterval_);

        uint256 originationFees_ = IMapleLoanFeeManager(_feeManager).payOriginationFees(fundsAsset_, principalRequested_);

        _drawableFunds += (principalRequested_ - originationFees_);

        require(getUnaccountedAmount(fundsAsset_) == uint256(0), "ML:FL:UNEXPECTED_FUNDS");

        emit Funded(
            lender_,
            fundsLent_ = _principal = principalRequested_,
            _nextPaymentDueDate = block.timestamp + paymentInterval_
        );
    }

    function impairLoan() external override whenNotPaused onlyLender {
        uint256 originalNextPaymentDueDate_ = _nextPaymentDueDate;

        // If the loan is late, do not change the payment due date.
        uint256 newPaymentDueDate_ = block.timestamp > originalNextPaymentDueDate_ ? originalNextPaymentDueDate_ : block.timestamp;

        emit LoanImpaired(newPaymentDueDate_);

        _nextPaymentDueDate         = newPaymentDueDate_;
        _originalNextPaymentDueDate = originalNextPaymentDueDate_;  // Store the existing payment due date to enable reversion.
    }

    function removeLoanImpairment() external override whenNotPaused onlyLender {
        uint256 originalNextPaymentDueDate_ = _originalNextPaymentDueDate;

        require(originalNextPaymentDueDate_ != 0,               "ML:RLI:NOT_IMPAIRED");
        require(block.timestamp <= originalNextPaymentDueDate_, "ML:RLI:PAST_DATE");

        _nextPaymentDueDate = originalNextPaymentDueDate_;
        delete _originalNextPaymentDueDate;

        emit ImpairmentRemoved(originalNextPaymentDueDate_);
    }

    function repossess(address destination_)
        external override whenNotPaused onlyLender returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_)
    {
        uint256 nextPaymentDueDate_ = _nextPaymentDueDate;

        require(
            nextPaymentDueDate_ != uint256(0) && (block.timestamp > nextPaymentDueDate_ + _gracePeriod),
            "ML:R:NOT_IN_DEFAULT"
        );

        _clearLoanAccounting();

        // Uniquely in `_repossess`, stop accounting for all funds so that they can be swept.
        _collateral    = uint256(0);
        _drawableFunds = uint256(0);

        address collateralAsset_ = _collateralAsset;

        // Either there is no collateral to repossess, or the transfer of the collateral succeeds.
        require(
            (collateralRepossessed_ = getUnaccountedAmount(collateralAsset_)) == uint256(0) ||
            ERC20Helper.transfer(collateralAsset_, destination_, collateralRepossessed_),
            "ML:R:C_TRANSFER_FAILED"
        );

        address fundsAsset_ = _fundsAsset;

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(
            (fundsRepossessed_ = getUnaccountedAmount(fundsAsset_)) == uint256(0) ||
            ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_),
            "ML:R:F_TRANSFER_FAILED"
        );

        emit Repossessed(collateralRepossessed_, fundsRepossessed_, destination_);
    }

    function setPendingLender(address pendingLender_) external override whenNotPaused onlyLender {
        emit PendingLenderSet(_pendingLender = pendingLender_);
    }

    /**************************************************************************************************************************************/
    /*** Miscellaneous Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused returns (bytes32 refinanceCommitment_)
    {
        require((msg.sender == _borrower) || (msg.sender == _lender), "ML:RNT:NO_AUTH");

        require(
            _refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:RNT:COMMITMENT_MISMATCH"
        );

        _refinanceCommitment = bytes32(0);

        emit NewTermsRejected(refinanceCommitment_, refinancer_, deadline_, calls_);
    }

    function skim(address token_, address destination_) external override whenNotPaused returns (uint256 skimmed_) {
        emit Skimmed(token_, skimmed_ = getUnaccountedAmount(token_), destination_);
        require(ERC20Helper.transfer(token_, destination_, skimmed_), "ML:S:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function getAdditionalCollateralRequiredFor(uint256 drawdown_) public view override returns (uint256 collateral_) {
        // Determine the collateral needed in the contract for a reduced drawable funds amount.
        uint256 collateralNeeded_  = _getCollateralRequiredFor(_principal, _drawableFunds - drawdown_, _principalRequested, _collateralRequired);
        uint256 currentCollateral_ = _collateral;

        collateral_ = collateralNeeded_ > currentCollateral_ ? collateralNeeded_ - currentCollateral_ : uint256(0);
    }

    function getClosingPaymentBreakdown() public view override returns (uint256 principal_, uint256 interest_, uint256 fees_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        ) = IMapleLoanFeeManager(_feeManager).getServiceFeeBreakdown(address(this), _paymentsRemaining);

        fees_ = delegateServiceFee_ + platformServiceFee_ + delegateRefinanceFee_ + platformRefinanceFee_;

        // Compute interest and include any uncaptured interest from refinance.
        interest_ = (((principal_ = _principal) * _closingRate) / HUNDRED_PERCENT) + _refinanceInterest;
    }

    function getNextPaymentDetailedBreakdown()
        public view override returns (uint256 principal_, uint256[3] memory interest_, uint256[2] memory fees_)
    {
        ( principal_, interest_, fees_ )
            = _getPaymentBreakdown(
                block.timestamp,
                _nextPaymentDueDate,
                _paymentInterval,
                _principal,
                _endingPrincipal,
                _paymentsRemaining,
                _interestRate,
                _lateFeeRate,
                _lateInterestPremiumRate
            );
    }

    function getNextPaymentBreakdown() public view override returns (uint256 principal_, uint256 interest_, uint256 fees_) {
        uint256[3] memory interestArray_;
        uint256[2] memory feesArray_;

        ( principal_, interestArray_, feesArray_ ) = _getPaymentBreakdown(
            block.timestamp,
            _nextPaymentDueDate,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _paymentsRemaining,
            _interestRate,
            _lateFeeRate,
            _lateInterestPremiumRate
        );

        interest_ = interestArray_[0] + interestArray_[1] + interestArray_[2];
        fees_     = feesArray_[0]     + feesArray_[1];
    }

    function getRefinanceInterest(uint256 timestamp_) public view override returns (uint256 proRataInterest_) {
        proRataInterest_ = _getRefinanceInterest(
            timestamp_,
            _paymentInterval,
            _principal,
            _endingPrincipal,
            _interestRate,
            _paymentsRemaining,
            _nextPaymentDueDate,
            _lateFeeRate,
            _lateInterestPremiumRate
        );
    }

    function getUnaccountedAmount(address asset_) public view override returns (uint256 unaccountedAmount_) {
        unaccountedAmount_ = IERC20(asset_).balanceOf(address(this))
            - (asset_ == _collateralAsset ? _collateral    : uint256(0))   // `_collateral` is `_collateralAsset` accounted for.
            - (asset_ == _fundsAsset      ? _drawableFunds : uint256(0));  // `_drawableFunds` is `_fundsAsset` accounted for.
    }

    /**************************************************************************************************************************************/
    /*** State View Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function borrower() external view override returns (address borrower_) {
        borrower_ = _borrower;
    }

    function closingRate() external view override returns (uint256 closingRate_) {
        closingRate_ = _closingRate;
    }

    function collateral() external view override returns (uint256 collateral_) {
        collateral_ = _collateral;
    }

    function collateralAsset() external view override returns (address collateralAsset_) {
        collateralAsset_ = _collateralAsset;
    }

    function collateralRequired() external view override returns (uint256 collateralRequired_) {
        collateralRequired_ = _collateralRequired;
    }

    function drawableFunds() external view override returns (uint256 drawableFunds_) {
        drawableFunds_ = _drawableFunds;
    }

    function endingPrincipal() external view override returns (uint256 endingPrincipal_) {
        endingPrincipal_ = _endingPrincipal;
    }

    function excessCollateral() external view override returns (uint256 excessCollateral_) {
        uint256 collateralNeeded_  = _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
        uint256 currentCollateral_ = _collateral;

        excessCollateral_ = currentCollateral_ > collateralNeeded_ ? currentCollateral_ - collateralNeeded_ : uint256(0);
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function feeManager() external view override returns (address feeManager_) {
        feeManager_ = _feeManager;
    }

    function fundsAsset() external view override returns (address fundsAsset_) {
        fundsAsset_ = _fundsAsset;
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function gracePeriod() external view override returns (uint256 gracePeriod_) {
        gracePeriod_ = _gracePeriod;
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function interestRate() external view override returns (uint256 interestRate_) {
        interestRate_ = _interestRate;
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = _originalNextPaymentDueDate != uint256(0);
    }

    function lateFeeRate() external view override returns (uint256 lateFeeRate_) {
        lateFeeRate_ = _lateFeeRate;
    }

    function lateInterestPremiumRate() external view override returns (uint256 lateInterestPremiumRate_) {
        lateInterestPremiumRate_ = _lateInterestPremiumRate;
    }

    function lender() external view override returns (address lender_) {
        lender_ = _lender;
    }

    function nextPaymentDueDate() external view override returns (uint256 nextPaymentDueDate_) {
        nextPaymentDueDate_ = _nextPaymentDueDate;
    }

    function originalNextPaymentDueDate() external view override returns (uint256 originalNextPaymentDueDate_) {
        originalNextPaymentDueDate_ = _originalNextPaymentDueDate;
    }

    function paymentInterval() external view override returns (uint256 paymentInterval_) {
        paymentInterval_ = _paymentInterval;
    }

    function paymentsRemaining() external view override returns (uint256 paymentsRemaining_) {
        paymentsRemaining_ = _paymentsRemaining;
    }

    function pendingBorrower() external view override returns (address pendingBorrower_) {
        pendingBorrower_ = _pendingBorrower;
    }

    function pendingLender() external view override returns (address pendingLender_) {
        pendingLender_ = _pendingLender;
    }

    function principal() external view override returns (uint256 principal_) {
        principal_ = _principal;
    }

    function principalRequested() external view override returns (uint256 principalRequested_) {
        principalRequested_ = _principalRequested;
    }

    function refinanceCommitment() external view override returns (bytes32 refinanceCommitment_) {
        refinanceCommitment_ = _refinanceCommitment;
    }

    function refinanceInterest() external view override returns (uint256 refinanceInterest_) {
        refinanceInterest_ = _refinanceInterest;
    }

    /**************************************************************************************************************************************/
    /*** Internal General Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        _refinanceCommitment = bytes32(0);

        _gracePeriod     = uint256(0);
        _paymentInterval = uint256(0);

        _interestRate            = uint256(0);
        _closingRate             = uint256(0);
        _lateFeeRate             = uint256(0);
        _lateInterestPremiumRate = uint256(0);

        _endingPrincipal = uint256(0);

        _nextPaymentDueDate = uint256(0);
        _paymentsRemaining  = uint256(0);
        _principal          = uint256(0);

        _refinanceInterest = uint256(0);

        _originalNextPaymentDueDate = uint256(0);
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure/View Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    /// @dev Returns the total collateral to be posted for some drawn down (outstanding) principal and overall collateral ratio requirement.
    function _getCollateralRequiredFor(
        uint256 principal_,
        uint256 drawableFunds_,
        uint256 principalRequested_,
        uint256 collateralRequired_
    )
        internal pure returns (uint256 collateral_)
    {
        // Where (collateral / outstandingPrincipal) should be greater or equal to (collateralRequired / principalRequested).
        // NOTE: principalRequested_ cannot be 0, which is reasonable, since it means this was never a loan.
        collateral_ = principal_ <= drawableFunds_
            ? uint256(0)
            : (collateralRequired_ * (principal_ - drawableFunds_) + principalRequested_ - 1) / principalRequested_;
    }

    /// @dev Returns principal and interest portions of a payment instalment, given generic, stateless loan parameters.
    function _getInstallment(
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 interestRate_,
        uint256 paymentInterval_,
        uint256 totalPayments_
    )
        internal pure returns (uint256 principalAmount_, uint256 interestAmount_)
    {
        /*************************************************************************************************\
         *                             |                                                                 *
         * A = installment amount      |      /                         \     /           R           \  *
         * P = principal remaining     |     |  /                 \      |   | ----------------------- | *
         * R = interest rate           | A = | | P * ( 1 + R ) ^ N | - E | * |   /             \       | *
         * N = payments remaining      |     |  \                 /      |   |  | ( 1 + R ) ^ N | - 1  | *
         * E = ending principal target |      \                         /     \  \             /      /  *
         *                             |                                                                 *
         *                             |---------------------------------------------------------------- *
         *                                                                                               *
         * - Where R           is `periodicRate`                                                         *
         * - Where (1 + R) ^ N is `raisedRate`                                                           *
         * - Both of these rates are scaled by 1e18 (e.g., 12% => 0.12 * 10 ** 18)                       *
        \*************************************************************************************************/

        uint256 periodicRate_ = _getPeriodicInterestRate(interestRate_, paymentInterval_);              // 1e18 decimal precision
        uint256 raisedRate_   = _scaledExponent(SCALED_ONE + periodicRate_, totalPayments_, SCALED_ONE); // 1e18 decimal precision

        // NOTE: If a lack of precision in `_scaledExponent` results in a `raisedRate_` smaller than one,
        //       assume it to be one and simplify the equation.
        if (raisedRate_ <= SCALED_ONE) return ((principal_ - endingPrincipal_) / totalPayments_, uint256(0));

        uint256 total_ = ((((principal_ * raisedRate_) / SCALED_ONE) - endingPrincipal_) * periodicRate_) / (raisedRate_ - SCALED_ONE);

        interestAmount_  = _getInterest(principal_, interestRate_, paymentInterval_);
        principalAmount_ = total_ >= interestAmount_ ? total_ - interestAmount_ : uint256(0);
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getInterest(uint256 principal_, uint256 interestRate_, uint256 interval_) internal pure returns (uint256 interest_) {
        interest_ = (principal_ * _getPeriodicInterestRate(interestRate_, interval_)) / SCALED_ONE;
    }

    function _getLateInterest(
        uint256 currentTime_,
        uint256 principal_,
        uint256 interestRate_,
        uint256 nextPaymentDueDate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal pure returns (uint256 lateInterest_)
    {
        if (currentTime_ <= nextPaymentDueDate_) return 0;

        // Calculates the number of full days late in seconds (will always be multiples of 86,400).
        // Rounds up and is inclusive so that if a payment is 1s late or 24h0m0s late it is 1 full day late.
        // 24h0m1s late would be two full days late.
        // ((86400n - 0n + (86400n - 1n)) / 86400n) * 86400n = 86400n
        // ((86401n - 0n + (86400n - 1n)) / 86400n) * 86400n = 172800n
        uint256 fullDaysLate_ = ((currentTime_ - nextPaymentDueDate_ + (1 days - 1)) / 1 days) * 1 days;

        lateInterest_ += _getInterest(principal_, interestRate_ + lateInterestPremiumRate_, fullDaysLate_);
        lateInterest_ += (lateFeeRate_ * principal_) / HUNDRED_PERCENT;
    }

    /// @dev Returns total principal and interest portion of a number of payments, given generic, stateless loan parameters and loan state.
    function _getPaymentBreakdown(
        uint256 currentTime_,
        uint256 nextPaymentDueDate_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 paymentsRemaining_,
        uint256 interestRate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal view
        returns (
            uint256           principalAmount_,
            uint256[3] memory interest_,
            uint256[2] memory fees_
        )
    {
        ( principalAmount_, interest_[0] ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            paymentInterval_,
            paymentsRemaining_
        );

        principalAmount_ = paymentsRemaining_ == uint256(1) ? principal_ : principalAmount_;

        interest_[1] = _getLateInterest(
            currentTime_,
            principal_,
            interestRate_,
            nextPaymentDueDate_,
            lateFeeRate_,
            lateInterestPremiumRate_
        );

        interest_[2] = _refinanceInterest;

        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        ) = IMapleLoanFeeManager(_feeManager).getServiceFeeBreakdown(address(this), 1);

        fees_[0] = delegateServiceFee_ + delegateRefinanceFee_;
        fees_[1] = platformServiceFee_ + platformRefinanceFee_;
    }

    /// @dev Returns the interest rate over an interval, given an annualized interest rate, scaled to 1e18.
    function _getPeriodicInterestRate(uint256 interestRate_, uint256 interval_) internal pure returns (uint256 periodicInterestRate_) {
        periodicInterestRate_ = (interestRate_ * (SCALED_ONE / HUNDRED_PERCENT) * interval_) / uint256(365 days);
    }

    /// @dev Returns refinance commitment given refinance parameters.
    function _getRefinanceCommitment(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        internal pure returns (bytes32 refinanceCommitment_)
    {
        refinanceCommitment_ = keccak256(abi.encode(refinancer_, deadline_, calls_));
    }

    function _getRefinanceInterest(
        uint256 currentTime_,
        uint256 paymentInterval_,
        uint256 principal_,
        uint256 endingPrincipal_,
        uint256 interestRate_,
        uint256 paymentsRemaining_,
        uint256 nextPaymentDueDate_,
        uint256 lateFeeRate_,
        uint256 lateInterestPremiumRate_
    )
        internal pure returns (uint256 refinanceInterest_)
    {
        // If the user has made an early payment, there is no refinance interest owed.
        if (currentTime_ + paymentInterval_ < nextPaymentDueDate_) return 0;

        uint256 refinanceInterestInterval_ = _min(currentTime_ - (nextPaymentDueDate_ - paymentInterval_), paymentInterval_);

        ( , refinanceInterest_ ) = _getInstallment(
            principal_,
            endingPrincipal_,
            interestRate_,
            refinanceInterestInterval_,
            paymentsRemaining_
        );

        refinanceInterest_ += _getLateInterest(
            currentTime_,
            principal_,
            interestRate_,
            nextPaymentDueDate_,
            lateFeeRate_,
            lateInterestPremiumRate_
        );
    }

    function _handleServiceFeePayment(uint256 numberOfPayments_) internal returns (uint256 fees_) {
        uint256 balanceBeforeServiceFees_ = IERC20(_fundsAsset).balanceOf(address(this));

        IMapleLoanFeeManager(_feeManager).payServiceFees(_fundsAsset, numberOfPayments_);

        uint256 balanceAfterServiceFees_ = IERC20(_fundsAsset).balanceOf(address(this));

        if (balanceBeforeServiceFees_ > balanceAfterServiceFees_) {
            _drawableFunds -= (fees_ = balanceBeforeServiceFees_ - balanceAfterServiceFees_);
        } else {
            _drawableFunds += balanceAfterServiceFees_ - balanceBeforeServiceFees_;
        }
    }

    /// @dev Returns whether the amount of collateral posted is commensurate with the amount of drawn down (outstanding) principal.
    function _isCollateralMaintained() internal view returns (bool isMaintained_) {
        isMaintained_ = _collateral >= _getCollateralRequiredFor(_principal, _drawableFunds, _principalRequested, _collateralRequired);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _revertIfNotBorrower() internal view {
        require(msg.sender == _borrower, "ML:NOT_BORROWER");
    }

    function _revertIfNotLender() internal view {
        require(msg.sender == _lender, "ML:NOT_LENDER");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "L:PAUSED");
    }

    /**
     *  @dev Returns exponentiation of a scaled base value.
     *
     *       Walk through example:
     *       LINE  |  base_          |  exponent_  |  one_  |  result_
     *             |  3_00           |  18         |  1_00  |  0_00
     *        A    |  3_00           |  18         |  1_00  |  1_00
     *        B    |  3_00           |  9          |  1_00  |  1_00
     *        C    |  9_00           |  9          |  1_00  |  1_00
     *        D    |  9_00           |  9          |  1_00  |  9_00
     *        B    |  9_00           |  4          |  1_00  |  9_00
     *        C    |  81_00          |  4          |  1_00  |  9_00
     *        B    |  81_00          |  2          |  1_00  |  9_00
     *        C    |  6_561_00       |  2          |  1_00  |  9_00
     *        B    |  6_561_00       |  1          |  1_00  |  9_00
     *        C    |  43_046_721_00  |  1          |  1_00  |  9_00
     *        D    |  43_046_721_00  |  1          |  1_00  |  387_420_489_00
     *        B    |  43_046_721_00  |  0          |  1_00  |  387_420_489_00
     *
     * Another implementation of this algorithm can be found in Dapphub's DSMath contract:
     * https://github.com/dapphub/ds-math/blob/ce67c0fa9f8262ecd3d76b9e4c026cda6045e96c/src/math.sol#L77
     */
    function _scaledExponent(uint256 base_, uint256 exponent_, uint256 one_) internal pure returns (uint256 result_) {
        // If exponent_ is odd, set result_ to base_, else set to one_.
        result_ = exponent_ & uint256(1) != uint256(0) ? base_ : one_;          // A

        // Divide exponent_ by 2 (overwriting itself) and proceed if not zero.
        while ((exponent_ >>= uint256(1)) != uint256(0)) {                      // B
            base_ = (base_ * base_) / one_;                                     // C

            // If exponent_ is even, go back to top.
            if (exponent_ & uint256(1) == uint256(0)) continue;

            // If exponent_ is odd, multiply result_ is multiplied by base_.
            result_ = (result_ * base_) / one_;                                 // D
        }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   A default version was set.
     *  @param version_ The default version.
     */
    event DefaultVersionSet(uint256 indexed version_);

    /**
     *  @dev   A version of an implementation, at some address, was registered, with an optional initializer.
     *  @param version_               The version registered.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    event ImplementationRegistered(uint256 indexed version_, address indexed implementationAddress_, address indexed initializer_);

    /**
     *  @dev   A proxy contract was deployed with some initialization arguments.
     *  @param version_                 The version of the implementation being proxied by the deployed proxy contract.
     *  @param instance_                The address of the proxy contract deployed.
     *  @param initializationArguments_ The arguments used to initialize the proxy contract, if any.
     */
    event InstanceDeployed(uint256 indexed version_, address indexed instance_, bytes initializationArguments_);

    /**
     *  @dev   A instance has upgraded by proxying to a new implementation, with some migration arguments.
     *  @param instance_           The address of the proxy contract.
     *  @param fromVersion_        The initial implementation version being proxied.
     *  @param toVersion_          The new implementation version being proxied.
     *  @param migrationArguments_ The arguments used to migrate, if any.
     */
    event InstanceUpgraded(address indexed instance_, uint256 indexed fromVersion_, uint256 indexed toVersion_, bytes migrationArguments_);

    /**
     *  @dev   The MapleGlobals was set.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    event MapleGlobalsSet(address indexed mapleGlobals_);

    /**
     *  @dev   An upgrade path was disabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    event UpgradePathDisabled(uint256 indexed fromVersion_, uint256 indexed toVersion_);

    /**
     *  @dev   An upgrade path was enabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    event UpgradePathEnabled(uint256 indexed fromVersion_, uint256 indexed toVersion_, address indexed migrator_);

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The default version.
     */
    function defaultVersion() external view returns (uint256 defaultVersion_);

    /**
     *  @dev The address of the MapleGlobals contract.
     */
    function mapleGlobals() external view returns (address mapleGlobals_);

    /**
     *  @dev    Whether the upgrade is enabled for a path from a version to another version.
     *  @param  toVersion_   The initial version.
     *  @param  fromVersion_ The destination version.
     *  @return allowed_     Whether the upgrade is enabled.
     */
    function upgradeEnabledForPath(uint256 toVersion_, uint256 fromVersion_) external view returns (bool allowed_);

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Deploys a new instance proxying the default implementation version, with some initialization arguments.
     *          Uses a nonce and `msg.sender` as a salt for the CREATE2 opcode during instantiation to produce deterministic addresses.
     *  @param  arguments_ The initialization arguments to use for the instance deployment, if any.
     *  @param  salt_      The salt to use in the contract creation process.
     *  @return instance_  The address of the deployed proxy contract.
     */
    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    /**
     *  @dev   Enables upgrading from a version to a version of an implementation, with an optional migrator.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) external;

    /**
     *  @dev   Disables upgrading from a version to a version of a implementation.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) external;

    /**
     *  @dev   Registers the address of an implementation contract as a version, with an optional initializer.
     *         Only the Governor can call this function.
     *  @param version_               The version to register.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) external;

    /**
     *  @dev   Sets the default version.
     *         Only the Governor can call this function.
     *  @param version_ The implementation version to set as the default.
     */
    function setDefaultVersion(uint256 version_) external;

    /**
     *  @dev   Sets the Maple Globals contract.
     *         Only the Governor can call this function.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    function setGlobals(address mapleGlobals_) external;

    /**
     *  @dev   Upgrades the calling proxy contract's implementation, with some migration arguments.
     *  @param toVersion_ The implementation version to upgrade the proxy contract to.
     *  @param arguments_ The migration arguments, if any.
     */
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the deterministic address of a potential proxy, given some arguments and salt.
     *  @param  arguments_       The initialization arguments to be used when deploying the proxy.
     *  @param  salt_            The salt to be used when deploying the proxy.
     *  @return instanceAddress_ The deterministic address of a potential proxy.
     */
    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_) external view returns (address instanceAddress_);

    /**
     *  @dev    Returns the address of an implementation version.
     *  @param  version_        The implementation version.
     *  @return implementation_ The address of the implementation.
     */
    function implementationOf(uint256 version_) external view returns (address implementation_);

    /**
     *  @dev    Returns if a given address has been deployed by this factory/
     *  @param  instance_   The address to check.
     *  @return isInstance_ A boolean indication if the address has been deployed by this factory.
     */
    function isInstance(address instance_) external view returns (bool isInstance_);

    /**
     *  @dev    Returns the address of a migrator contract for a migration path (from version, to version).
     *          If oldVersion_ == newVersion_, the migrator is an initializer.
     *  @param  oldVersion_ The old version.
     *  @param  newVersion_ The new version.
     *  @return migrator_   The address of a migrator contract.
     */
    function migratorForPath(uint256 oldVersion_, uint256 newVersion_) external view returns (address migrator_);

    /**
     *  @dev    Returns the version of an implementation contract.
     *  @param  implementation_ The address of an implementation contract.
     *  @return version_        The version of the implementation contract.
     */
    function versionOf(address implementation_) external view returns (uint256 version_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ProxiedInternals } from "../modules/proxy-factory/contracts/ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals { }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IMapleLoanEvents } from "./IMapleLoanEvents.sol";

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
interface IMapleLoan is IMapleProxied, IMapleLoanEvents {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The borrower of the loan, responsible for repayments.
     */
    function borrower() external view returns (address borrower_);

    /**
     *  @dev The fee rate (applied to principal) to close the loan.
     *       This value should be configured so that it is less expensive to close a loan with more than one payment remaining, but
     *       more expensive to close it if on the last payment.
     */
    function closingRate() external view returns (uint256 closingRate_);

    /**
     *  @dev The amount of collateral posted against outstanding (drawn down) principal.
     */
    function collateral() external view returns (uint256 collateral_);

    /**
     *  @dev The address of the asset deposited by the borrower as collateral, if needed.
     */
    function collateralAsset() external view returns (address collateralAsset_);

    /**
     *  @dev The amount of collateral required if all of the principal required is drawn down.
     */
    function collateralRequired() external view returns (uint256 collateralRequired_);

    /**
     *  @dev The amount of funds that have yet to be drawn down by the borrower.
     */
    function drawableFunds() external view returns (uint256 drawableFunds_);

    /**
     *  @dev The portion of principal to not be paid down as part of payment installments,
     *       which would need to be paid back upon final payment.
     *       If endingPrincipal = principal, loan is interest-only.
     */
    function endingPrincipal() external view returns (uint256 endingPrincipal_);

    /**
     *  @dev The address of the contract that handles payments of fees on behalf of the loan.
     */
    function feeManager() external view returns (address feeManager_);

    /**
     *  @dev The asset deposited by the lender to fund the loan.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev The Maple globals address
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev The address of the Maple Governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev The amount of time the borrower has, after a payment is due, to make a payment before being in default.
     */
    function gracePeriod() external view returns (uint256 gracePeriod_);

    /**
     *  @dev The annualized interest rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function interestRate() external view returns (uint256 interestRate_);

    /**
     *  @dev The rate charged at late payments.
     */
    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    /**
     *  @dev The premium over the regular interest rate applied when paying late.
     */
    function lateInterestPremiumRate() external view returns (uint256 lateInterestPremiumRate_);

    /**
     *  @dev The lender of the Loan.
     */
    function lender() external view returns (address lender_);

    /**
     *  @dev The timestamp due date of the next payment.
     */
    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    /**
     *  @dev The saved original payment due date from a loan impairment.
     */
    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    /**
     *  @dev The specified time between loan payments.
     */
    function paymentInterval() external view returns (uint256 paymentInterval_);

    /**
     *  @dev The number of payment installments remaining for the loan.
     */
    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    /**
     *  @dev The address of the pending borrower.
     */
    function pendingBorrower() external view returns (address pendingBorrower_);

    /**
     *  @dev The address of the pending lender.
     */
    function pendingLender() external view returns (address pendingLender_);

    /**
     *  @dev The amount of principal owed (initially, the requested amount), which needs to be paid back.
     */
    function principal() external view returns (uint256 principal_);

    /**
     *  @dev The initial principal amount requested by the borrower.
     */
    function principalRequested() external view returns (uint256 principalRequested_);

    /**
     *  @dev The hash of the proposed refinance agreement.
     */
    function refinanceCommitment() external view returns (bytes32 refinanceCommitment_);

    /**
     *  @dev Amount of unpaid interest that has accrued before a refinance was accepted.
     */
    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Accept the borrower role, must be called by pendingBorrower.
     */
    function acceptBorrower() external;

    /**
     *  @dev Accept the lender role, must be called by pendingLender.
     */
    function acceptLender() external;

    /**
     *  @dev    Accept the proposed terms ans trigger refinance execution
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the accepted refinance agreement.
     */
    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    Repay all principal and interest and close a loan.
     *          FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
     *  @param  amount_    An amount to pull from the caller, if any.
     *  @return principal_ The portion of the amount paying back principal.
     *  @return interest_  The portion of the amount paying interest.
     *  @return fees_      The portion of the amount paying service fees.
     */
    function closeLoan(uint256 amount_) external returns (uint256 principal_, uint256 interest_, uint256 fees_);

    /**
     *  @dev    Draw down funds from the loan.
     *  @param  amount_           The amount to draw down.
     *  @param  destination_      The address to send the funds.
     *  @return collateralPosted_ The amount of additional collateral posted, if any.
     */
    function drawdownFunds(uint256 amount_, address destination_) external returns (uint256 collateralPosted_);

    /**
     *  @dev    Lend funds to the loan/borrower.
     *  @return fundsLent_ The amount funded.
     */
    function fundLoan() external returns (uint256 fundsLent_);

    /**
     *  @dev Fast forward the next payment due date to the current time.
     *       This enables the pool delegate to force a payment (or default).
     */
    function impairLoan() external;

    /**
     *  @dev    Make a payment to the loan.
     *          FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
     *  @param  amount_    An amount to pull from the caller, if any.
     *  @return principal_ The portion of the amount paying back principal.
     *  @return interest_  The portion of the amount paying interest fees.
     *  @return fees_      The portion of the amount paying service fees.
     */
    function makePayment(uint256 amount_) external returns (uint256 principal_, uint256 interest_, uint256 fees_);

    /**
     *  @dev    Post collateral to the loan.
     *          FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
     *  @param  amount_           An amount to pull from the caller, if any.
     *  @return collateralPosted_ The amount posted.
     */
    function postCollateral(uint256 amount_) external returns (uint256 collateralPosted_);

    /**
     *  @dev    Propose new terms for refinance.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the proposed refinance agreement.
     */
    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    Nullify the current proposed terms.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the rejected refinance agreement.
     */
    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev   Remove collateral from the loan (opposite of posting collateral).
     *  @param amount_      The amount removed.
     *  @param destination_ The destination to send the removed collateral.
     */
    function removeCollateral(uint256 amount_, address destination_) external;

    /**
     *  @dev Remove the loan impairment by restoring the original payment due date.
     */
    function removeLoanImpairment() external;

    /**
     *  @dev    Repossess collateral, and any funds, for a loan in default.
     *  @param  destination_           The address where the collateral and funds asset is to be sent, if any.
     *  @return collateralRepossessed_ The amount of collateral asset repossessed.
     *  @return fundsRepossessed_      The amount of funds asset repossessed.
     */
    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    /**
     *  @dev    Return funds to the loan (opposite of drawing down).
     *          FUNDS SHOULD NOT BE TRANSFERRED TO THIS CONTRACT NON-ATOMICALLY. IF THEY ARE, THE BALANCE MAY BE STOLEN USING `skim`.
     *  @param  amount_        An amount to pull from the caller, if any.
     *  @return fundsReturned_ The amount returned.
     */
    function returnFunds(uint256 amount_) external returns (uint256 fundsReturned_);

    /**
     *  @dev   Set the pendingBorrower to a new account.
     *  @param pendingBorrower_ The address of the new pendingBorrower.
     */
    function setPendingBorrower(address pendingBorrower_) external;

    /**
     *  @dev   Set the pendingLender to a new account.
     *  @param pendingLender_ The address of the new pendingLender.
     */
    function setPendingLender(address pendingLender_) external;

    /**
     *  @dev    Remove all token that is not accounted for by the loan (i.e. not `collateral` or `drawableFunds`).
     *  @param  token_       The address of the token contract.
     *  @param  destination_ The recipient of the token.
     *  @return skimmed_     The amount of token removed from the loan.
     */
    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the excess collateral that can be removed.
     *  @return excessCollateral_ The excess collateral that can be removed, if any.
     */
    function excessCollateral() external view returns (uint256 excessCollateral_);

    /**
     *  @dev    Get the additional collateral to be posted to drawdown some amount.
     *  @param  drawdown_             The amount desired to be drawn down.
     *  @return additionalCollateral_ The additional collateral that must be posted, if any.
     */
    function getAdditionalCollateralRequiredFor(uint256 drawdown_) external view returns (uint256 additionalCollateral_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy an early repayment to close the loan.
     *  @return principal_ The portion of the total amount that will go towards principal.
     *  @return interest_  The portion of the total amount that will go towards interest fees.
     *  @return fees_      The portion of the total amount that will go towards fees.
     */
    function getClosingPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 fees_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy the next payment installment.
     *  @return principal_ The portion of the total amount that will go towards principal.
     *  @return interest_  The portion of the total amount that will go towards interest fees.
     *  @return fees_      The portion of the total amount that will go towards paying administrative fees.
     */
    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256 fees_);

    /**
     *  @dev    Get the detailed breakdown of the total payment needed to satisfy the next payment installment.
     *  @return principal_ The portion of the total amount that will go towards principal.
     *  @return interest_  The portion of the total amount that will go towards interest fees.
     *                      [0] Interest from the payment interval.
     *                      [1] Late interest.
     *                      [2] Refinance interest.
     *  @return fees_      The portion of the total amount that will go towards paying administrative fees.
     *                      [0] Delegate fees.
     *                      [1] Platform fees.
     */
    function getNextPaymentDetailedBreakdown()
        external view returns (uint256 principal_, uint256[3] memory interest_, uint256[2] memory fees_);

    /**
     *  @dev    Get the extra interest that will be charged according to loan terms before refinance, based on a given timestamp.
     *  @param  timestamp_       The timestamp when the new terms will be accepted.
     *  @return proRataInterest_ The interest portion to be added in the next payment.
     */
    function getRefinanceInterest(uint256 timestamp_) external view returns (uint256 proRataInterest_);

    /**
     *  @dev    Get the amount on an asset that in not accounted for by the accounting variables (and thus can be skimmed).
     *  @param  asset_             The address of a asset contract.
     *  @return unaccountedAmount_ The amount that is not accounted for.
     */
    function getUnaccountedAmount(address asset_) external view returns (uint256 unaccountedAmount_);

    /**
     *  @dev The value that represents 100%, to be easily comparable with the loan rates.
     */
    function HUNDRED_PERCENT() external pure returns (uint256 hundredPercent_);

    /**
     *  @dev    Return if the loan has been impaired.
     *  @return isImpaired_ Is the loan impaired or not.
     */
    function isImpaired() external view returns (bool isImpaired_);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title An implementation that is to be proxied, will need ProxiedInternals.
abstract contract ProxiedInternals is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an initialization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        uint256 size;

        assembly {
            size := extcodesize(migrator_)
        }

        if (size == uint256(0)) return false;

        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));
        return true;
    }

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation_))));
        return true;
    }

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IProxied } from "../../modules/proxy-factory/contracts/interfaces/IProxied.sol";

/// @title A Maple implementation that is to be proxied, must implement IMapleProxied.
interface IMapleProxied is IProxied {

    /**
     *  @dev   The instance was upgraded.
     *  @param toVersion_ The new version of the loan.
     *  @param arguments_ The upgrade arguments, if any.
     */
    event Upgraded(uint256 toVersion_, bytes arguments_);

    /**
     *  @dev   Upgrades a contract implementation to a specific version.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param toVersion_ The version to upgrade to.
     *  @param arguments_ Some encoded arguments to use for the upgrade.
     */
    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An implementation that is to be proxied, must implement IProxied.
interface IProxied {

    /**
     *  @dev The address of the proxy factory.
     */
    function factory() external view returns (address factory_);

    /**
     *  @dev The address of the implementation contract being proxied.
     */
    function implementation() external view returns (address implementation_);

    /**
     *  @dev   Modifies the proxy's implementation address.
     *  @param newImplementation_ The address of an implementation contract.
     */
    function setImplementation(address newImplementation_) external;

    /**
     *  @dev   Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param migrator_  The address of a migrator contract.
     *  @param arguments_ Some encoded arguments to use for the migration.
     */
    function migrate(address migrator_, bytes calldata arguments_) external;

}