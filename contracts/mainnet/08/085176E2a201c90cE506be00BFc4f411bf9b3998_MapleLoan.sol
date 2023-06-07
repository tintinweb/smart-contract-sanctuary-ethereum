// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleLoan } from "./interfaces/IMapleLoan.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

     ██████╗ ██████╗ ███████╗███╗   ██╗    ████████╗███████╗██████╗ ███╗   ███╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗ ██╗
    ██╔═══██╗██╔══██╗██╔════╝████╗  ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║███║
    ██║   ██║██████╔╝█████╗  ██╔██╗ ██║       ██║   █████╗  ██████╔╝██╔████╔██║    ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║╚██║
    ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║    ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝ ██║
    ╚██████╔╝██║     ███████╗██║ ╚████║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝  ██║
     ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝   ╚═╝

*/

/// @title MapleLoan implements an open term loan, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    uint256 public constant override HUNDRED_PERCENT = 1e6;

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
        require(msg.sender == pendingBorrower, "ML:AB:NOT_PENDING_BORROWER");

        delete pendingBorrower;

        emit BorrowerAccepted(borrower = msg.sender);
    }

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyBorrower returns (bytes32 refinanceCommitment_)
    {
        require(refinancer_.code.length != uint256(0), "ML:ANT:INVALID_REFINANCER");
        require(block.timestamp <= deadline_,          "ML:ANT:EXPIRED_COMMITMENT");

        // NOTE: A zero refinancer address and/or empty calls array will never (probabilistically) match a refinance commitment in storage.
        require(
            refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:ANT:COMMITMENT_MISMATCH"
        );

        uint256 previousPrincipal_ = principal;

        (
            ,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        ) = getPaymentBreakdown(block.timestamp);

        // Clear refinance commitment to prevent implications of re-acceptance of another call to `_acceptNewTerms`.
        delete refinanceCommitment;

        for (uint256 i_; i_ < calls_.length; ++i_) {
            ( bool success_, ) = refinancer_.delegatecall(calls_[i_]);
            require(success_, "ML:ANT:FAILED");
        }

        // TODO: Emit this before the refinance calls in order to adhere to the CEI pattern.
        emit NewTermsAccepted(refinanceCommitment_, refinancer_, deadline_, calls_);

        address fundsAsset_   = fundsAsset;
        uint256 newPrincipal_ = principal;

        int256 netPrincipalToReturnToLender_ = _int256(previousPrincipal_) - _int256(newPrincipal_);

        uint256 interestAndFees_ = interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        address borrower_ = borrower;

        ILenderLike lender_ = ILenderLike(lender);

        require(
            ERC20Helper.transferFrom(
                fundsAsset_,
                borrower_,
                address(lender_),
                (netPrincipalToReturnToLender_ > 0 ? _uint256(netPrincipalToReturnToLender_) : 0) + interestAndFees_
            ),
            "ML:ANT:TRANSFER_FAILED"
        );

        platformServiceFeeRate = uint64(IGlobalsLike(globals()).platformServiceFeeRate(lender_.poolManager()));

        if (newPrincipal_ == 0) {
            // NOTE: All the principal has been paid back therefore clear the loan accounting.
            _clearLoanAccounting();
        } else {
            datePaid = _uint40(block.timestamp);

            // NOTE: Accepting new terms always results in the a call and/or impairment being removed.
            delete calledPrincipal;
            delete dateCalled;
            delete dateImpaired;
        }

        lender_.claim(
            netPrincipalToReturnToLender_,
            interest_ + lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate()
        );

        // Principal has increased in the Loan, so Loan pulls funds from Lender.
        if (netPrincipalToReturnToLender_ < 0) {
            require(
                ERC20Helper.transferFrom(fundsAsset_, address(lender_), borrower_, _uint256(netPrincipalToReturnToLender_ * -1)),
                "ML:ANT:TRANSFER_FAILED"
            );
        }
    }

    function makePayment(uint256 principalToReturn_)
        external override whenNotPaused
        returns (
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        )
    {
        require(dateFunded != 0, "ML:MP:LOAN_INACTIVE");

        uint256 calledPrincipal_;

        ( calledPrincipal_, interest_, lateInterest_, delegateServiceFee_, platformServiceFee_ ) = getPaymentBreakdown(block.timestamp);

        // If the loan is called, the principal being returned must be greater than the portion called.
        require(principalToReturn_ <= principal,        "ML:MP:RETURNING_TOO_MUCH");
        require(principalToReturn_ >= calledPrincipal_, "ML:MP:INSUFFICIENT_FOR_CALL");

        uint256 total_ = principalToReturn_ + interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        if (principalToReturn_ == principal) {
            _clearLoanAccounting();
            emit PrincipalReturned(principalToReturn_, 0);
        } else {
            datePaid = _uint40(block.timestamp);

            // NOTE: Making a payment always results in the a call and/or impairment being removed.
            delete calledPrincipal;
            delete dateCalled;
            delete dateImpaired;

            if (principalToReturn_ != 0) {
                emit PrincipalReturned(principalToReturn_, principal -= principalToReturn_);
            }
        }

        address lender_         = lender;
        uint40  paymentDueDate_ = paymentDueDate();

        emit PaymentMade(
            lender_,
            principalToReturn_,
            interest_,
            lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate_,
            defaultDate()
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, lender_, total_), "ML:MP:TRANSFER_FROM_FAILED");

        ILenderLike(lender_).claim(
            _int256(principalToReturn_),
            interest_ + lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            paymentDueDate_
        );
    }

    function setPendingBorrower(address pendingBorrower_) external override whenNotPaused onlyBorrower {
        require(IGlobalsLike(globals()).isBorrower(pendingBorrower_), "ML:SPB:INVALID_BORROWER");

        emit PendingBorrowerSet(pendingBorrower = pendingBorrower_);
    }

    /**************************************************************************************************************************************/
    /*** Lend Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function acceptLender() external override whenNotPaused {
        require(msg.sender == pendingLender, "ML:AL:NOT_PENDING_LENDER");

        delete pendingLender;

        emit LenderAccepted(lender = msg.sender);
    }

    function callPrincipal(uint256 principalToReturn_)
        external override whenNotPaused onlyLender
        returns (uint40 paymentDueDate_, uint40 defaultDate_)
    {
        require(dateFunded != 0,                                            "ML:C:LOAN_INACTIVE");
        require(principalToReturn_ != 0 && principalToReturn_ <= principal, "ML:C:INVALID_AMOUNT");

        dateCalled = _uint40(block.timestamp);

        emit PrincipalCalled(
            calledPrincipal = principalToReturn_,
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function fund() external override whenNotPaused onlyLender returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateFunded == 0, "ML:F:LOAN_ACTIVE");
        require(principal != 0,  "ML:F:LOAN_CLOSED");

        dateFunded = _uint40(block.timestamp);

        emit Funded(
            fundsLent_      = principal,
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, borrower, fundsLent_), "ML:F:TRANSFER_FROM_FAILED");
    }

    function impair() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateFunded != 0, "ML:I:LOAN_INACTIVE");

        // NOTE: Impairing an already-impaired loan simply updates the `dateImpaired`, which can push the due date further.
        dateImpaired = _uint40(block.timestamp);

        emit Impaired(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function proposeNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyLender returns (bytes32 refinanceCommitment_)
    {
        require(dateFunded != 0,                                                    "ML:PNT:LOAN_INACTIVE");
        require(block.timestamp <= deadline_,                                       "ML:PNT:INVALID_DEADLINE");
        require(IGlobalsLike(globals()).isInstanceOf("OT_REFINANCER", refinancer_), "ML:PNT:INVALID_REFINANCER");
        require(calls_.length > 0,                                                  "ML:PNT:EMPTY_CALLS");

        emit NewTermsProposed(
            refinanceCommitment = refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_),
            refinancer_,
            deadline_,
            calls_
        );
    }

    function removeCall() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateCalled != 0, "ML:RC:NOT_CALLED");

        delete dateCalled;
        delete calledPrincipal;

        emit CallRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function removeImpairment() external override whenNotPaused onlyLender returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(dateImpaired != 0, "ML:RI:NOT_IMPAIRED");

        delete dateImpaired;

        emit ImpairmentRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function repossess(address destination_) external override whenNotPaused onlyLender returns (uint256 fundsRepossessed_) {
        require(isInDefault(), "ML:R:NOT_IN_DEFAULT");

        _clearLoanAccounting();

        address fundsAsset_ = fundsAsset;

        emit Repossessed(
            fundsRepossessed_ = IERC20(fundsAsset_).balanceOf(address(this)),
            destination_
        );

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require((fundsRepossessed_ == 0) || ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_), "ML:R:TRANSFER_FAILED");
    }

    function setPendingLender(address pendingLender_) external override whenNotPaused onlyLender {
        emit PendingLenderSet(pendingLender = pendingLender_);
    }

    /**************************************************************************************************************************************/
    /*** Miscellaneous Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function rejectNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused returns (bytes32 refinanceCommitment_)
    {
        require((msg.sender == borrower) || (msg.sender == lender), "ML:RNT:NO_AUTH");

        require(
            refinanceCommitment == (refinanceCommitment_ = _getRefinanceCommitment(refinancer_, deadline_, calls_)),
            "ML:RNT:COMMITMENT_MISMATCH"
        );

        delete refinanceCommitment;

        emit NewTermsRejected(refinanceCommitment_, refinancer_, deadline_, calls_);
    }

    function skim(address token_, address destination_) external override whenNotPaused returns (uint256 skimmed_) {
        require(destination_ != address(0), "ML:S:ZERO_ADDRESS");

        address governor_ = IGlobalsLike(globals()).governor();

        require(msg.sender == governor_ || msg.sender == borrower, "ML:S:NO_AUTH");

        skimmed_ = IERC20(token_).balanceOf(address(this));

        require(skimmed_ != 0, "ML:S:NO_TOKEN_TO_SKIM");

        emit Skimmed(token_, skimmed_, destination_);

        require(ERC20Helper.transfer(token_, destination_, skimmed_), "ML:S:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function defaultDate() public view override returns (uint40 paymentDefaultDate_) {
        ( uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalPaymentDueDate_ ) = _defaultDates();

        paymentDefaultDate_ = _minDate(callDefaultDate_, impairedDefaultDate_, normalPaymentDueDate_);
    }

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function getPaymentBreakdown(uint256 timestamp_)
        public view override returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        )
    {
        uint40 startDate_ = _maxDate(datePaid, dateFunded);  // Timestamp when new interest starts accruing.

        // Return all zeros if the loan has not been funded yet or if the given timestamp is not greater than the start date.
        if (startDate_ == 0 || timestamp_ <= startDate_) return ( calledPrincipal, 0, 0, 0, 0 );

        uint40 paymentDueDate_ = paymentDueDate();

        // "Current" interval and late interval respectively.
        ( uint32 interval_, uint32 lateInterval_ ) =
            ( _uint32(timestamp_ - startDate_), timestamp_ > paymentDueDate_ ? _uint32(timestamp_ - paymentDueDate_) : 0 );

        ( interest_, lateInterest_, delegateServiceFee_, platformServiceFee_ ) = _getPaymentBreakdown(
            principal,
            interestRate,
            lateInterestPremiumRate,
            lateFeeRate,
            delegateServiceFeeRate,
            platformServiceFeeRate,
            interval_,
            lateInterval_
        );

        principal_ = calledPrincipal;
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function isCalled() public view override returns (bool isCalled_) {
        isCalled_ = dateCalled != 0;
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = dateImpaired != 0;
    }

    function isInDefault() public view override returns (bool isInDefault_) {
        uint40 defaultDate_ = defaultDate();

        isInDefault_ = (defaultDate_ != 0) && (block.timestamp > defaultDate_);
    }

    function paymentDueDate() public view override returns (uint40 paymentDueDate_) {
        ( uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_ ) = _dueDates();

        paymentDueDate_ = _minDate(callDueDate_, impairedDueDate_, normalDueDate_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        delete refinanceCommitment;

        delete gracePeriod;
        delete noticePeriod;
        delete paymentInterval;

        delete dateCalled;
        delete dateFunded;
        delete dateImpaired;
        delete datePaid;

        delete calledPrincipal;
        delete principal;

        delete delegateServiceFeeRate;
        delete interestRate;
        delete lateFeeRate;
        delete lateInterestPremiumRate;
        delete platformServiceFeeRate;
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _defaultDates() internal view returns (uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalDefaultDate_) {
        ( uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_ ) = _dueDates();

        callDefaultDate_     = _getCallDefaultDate(callDueDate_);
        impairedDefaultDate_ = _getImpairedDefaultDate(impairedDueDate_, gracePeriod);
        normalDefaultDate_   = _getNormalDefaultDate(normalDueDate_, gracePeriod);
    }

    function _dueDates() internal view returns (uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_) {
        callDueDate_     = _getCallDueDate(dateCalled, noticePeriod);
        impairedDueDate_ = _getImpairedDueDate(dateImpaired);
        normalDueDate_   = _getNormalDueDate(dateFunded, datePaid, paymentInterval);
    }

    function _getRefinanceCommitment(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        internal pure returns (bytes32 refinanceCommitment_)
    {
        return keccak256(abi.encode(refinancer_, deadline_, calls_));
    }

    function _revertIfNotBorrower() internal view {
        require(msg.sender == borrower, "ML:NOT_BORROWER");
    }

    function _revertIfNotLender() internal view {
        require(msg.sender == lender, "ML:NOT_LENDER");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "ML:PAUSED");
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _getCallDefaultDate(uint40 callDueDate_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = callDueDate_;
    }

    function _getCallDueDate(uint40 dateCalled_, uint32 noticePeriod_) internal pure returns (uint40 dueDate_) {
        dueDate_ = dateCalled_ != 0 ? dateCalled_ + noticePeriod_ : 0;
    }

    function _getImpairedDefaultDate(uint40 impairedDueDate_, uint32 gracePeriod_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = impairedDueDate_ != 0 ? impairedDueDate_ + gracePeriod_ : 0;
    }

    function _getImpairedDueDate(uint40 dateImpaired_) internal pure returns (uint40 dueDate_) {
        dueDate_ = dateImpaired_ != 0 ? dateImpaired_: 0;
    }

    function _getNormalDefaultDate(uint40 normalDueDate_, uint32 gracePeriod_) internal pure returns (uint40 defaultDate_) {
        defaultDate_ = normalDueDate_ != 0 ? normalDueDate_ + gracePeriod_ : 0;
    }

    function _getNormalDueDate(uint40 dateFunded_, uint40 datePaid_, uint32 paymentInterval_) internal pure returns (uint40 dueDate_) {
        uint40 paidOrFundedDate_ = _maxDate(dateFunded_, datePaid_);

        dueDate_ = paidOrFundedDate_ != 0 ? paidOrFundedDate_ + paymentInterval_ : 0;
    }

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getPaymentBreakdown(
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremiumRate_,
        uint256 lateFeeRate_,
        uint256 delegateServiceFeeRate_,
        uint256 platformServiceFeeRate_,
        uint32  interval_,
        uint32  lateInterval_
    )
        internal pure returns (uint256 interest_, uint256 lateInterest_, uint256 delegateServiceFee_, uint256 platformServiceFee_)
    {
        interest_           = _getProRatedAmount(principal_, interestRate_,           interval_);
        delegateServiceFee_ = _getProRatedAmount(principal_, delegateServiceFeeRate_, interval_);
        platformServiceFee_ = _getProRatedAmount(principal_, platformServiceFeeRate_, interval_);

        if (lateInterval_ == 0) return (interest_, 0, delegateServiceFee_, platformServiceFee_);

        lateInterest_ =
            _getProRatedAmount(principal_, lateInterestPremiumRate_, lateInterval_) +
            ((principal_ * lateFeeRate_) / HUNDRED_PERCENT);
    }

    function _getProRatedAmount(uint256 amount_, uint256 rate_, uint32 interval_) internal pure returns (uint256 proRatedAmount_) {
        proRatedAmount_ = (amount_ * rate_ * interval_) / (365 days * HUNDRED_PERCENT);
    }

    function _int256(uint256 input_) internal pure returns (int256 output_) {
        require(input_ <= uint256(type(int256).max), "ML:UINT256_CAST");
        output_ = int256(input_);
    }

    function _maxDate(uint40 a_, uint40 b_) internal pure returns (uint40 max_) {
        max_ = a_ == 0 ? b_ : (b_ == 0 ? a_ : (a_ > b_ ? a_ : b_));
    }

    function _minDate(uint40 a_, uint40 b_) internal pure returns (uint40 min_) {
        min_ = a_ == 0 ? b_ : (b_ == 0 ? a_ : (a_ < b_ ? a_ : b_));
    }

    function _minDate(uint40 a_, uint40 b_, uint40 c_) internal pure returns (uint40 min_) {
        min_ = _minDate(a_, _minDate(b_, c_));
    }

    function _uint32(uint256 input_) internal pure returns (uint32 output_) {
        require(input_ <= type(uint32).max, "ML:UINT256_OOB_FOR_UINT32");
        output_ = uint32(input_);
    }

    function _uint40(uint256 input_) internal pure returns (uint40 output_) {
        require(input_ <= type(uint40).max, "ML:UINT256_OOB_FOR_UINT40");
        output_ = uint40(input_);
    }

    function _uint256(int256 input_) internal pure returns (uint256 output_) {
        require(input_ >= 0, "ML:INT256_CAST");
        output_ = uint256(input_);
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

import { IMapleLoanEvents }  from "./IMapleLoanEvents.sol";
import { IMapleLoanStorage } from "./IMapleLoanStorage.sol";

/// @title MapleLoan implements an open term loan, and is intended to be proxied.
interface IMapleLoan is IMapleProxied, IMapleLoanEvents, IMapleLoanStorage {

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
     *  @dev    Accept the proposed terms and trigger refinance execution.
     *  @param  refinancer_          The address of the refinancer contract.
     *  @param  deadline_            The deadline for accepting the new terms.
     *  @param  calls_               The encoded arguments to be passed to refinancer.
     *  @return refinanceCommitment_ The hash of the accepted refinance agreement.
     */
    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external returns (bytes32 refinanceCommitment_);

    /**
     *  @dev    The lender called the loan, giving the borrower a notice period within which to return principal and pro-rata interest.
     *  @param  principalToReturn_ The minimum amount of principal the borrower must return.
     *  @return paymentDueDate_    The new payment due date for returning the principal and pro-rate interest to the lender.
     *  @return defaultDate_       The date the loan will be in default.
     */
    function callPrincipal(uint256 principalToReturn_) external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Lend funds to the loan/borrower.
     *  @return fundsLent_      The amount funded.
     *  @return paymentDueDate_ The due date of the first payment.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function fund() external returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Fast forward the payment due date to the current time.
     *          This enables the pool delegate to force a payment (or default).
     *  @return paymentDueDate_ The new payment due date to result in the removal of the loan's impairment status.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function impair() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Make a payment to the loan.
     *  @param  principalToReturn_  The amount of principal to return, to the lender to reduce future interest payments.
     *  @return interest_           The portion of the amount paying interest.
     *  @return lateInterest_       The portion of the amount paying late interest.
     *  @return delegateServiceFee_ The portion of the amount paying delegate service fees.
     *  @return platformServiceFee_ The portion of the amount paying platform service fees.
     */
    function makePayment(uint256 principalToReturn_)
        external returns (
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

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
     *  @dev    Remove the loan's called status.
     *  @return paymentDueDate_ The restored payment due date.
     *  @return defaultDate_    The date the loan will be in default.
     */
    function removeCall() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Remove the loan impairment by restoring the original payment due date.
     *  @return paymentDueDate_ The restored payment due date.
     *  @return defaultDate_    The timestamp of the date the loan will be in default.
     */
    function removeImpairment() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    /**
     *  @dev    Repossess collateral, and any funds, for a loan in default.
     *  @param  destination_      The address where the collateral and funds asset is to be sent, if any.
     *  @return fundsRepossessed_ The amount of funds asset repossessed.
     */
    function repossess(address destination_) external returns (uint256 fundsRepossessed_);

    /**
     *  @dev   Set the `pendingBorrower` to a new account.
     *  @param pendingBorrower_ The address of the new pendingBorrower.
     */
    function setPendingBorrower(address pendingBorrower_) external;

    /**
     *  @dev   Set the `pendingLender` to a new account.
     *  @param pendingLender_ The address of the new pendingLender.
     */
    function setPendingLender(address pendingLender_) external;

    /**
     *  @dev    Remove all available balance of a specified token.
     *          NOTE: Open Term Loans are not designed to hold custody of tokens, so this is designed as a safety feature.
     *  @param  token_       The address of the token contract.
     *  @param  destination_ The recipient of the token.
     *  @return skimmed_     The amount of token removed from the loan.
     */
    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The timestamp of the date the loan will be in default.
     */
    function defaultDate() external view returns (uint40 defaultDate_);

    /**
     *  @dev The Maple globals address
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev The value that represents 100%, to be easily comparable with the loan rates.
     */
    function HUNDRED_PERCENT() external pure returns (uint256 hundredPercent_);

    /**
     *  @dev Whether the loan is called.
     */
    function isCalled() external view returns (bool isCalled_);

    /**
     *  @dev Whether the loan is impaired.
     */
    function isImpaired() external view returns (bool isImpaired_);

    /**
     *  @dev Whether the loan is in default.
     */
    function isInDefault() external view returns (bool isInDefault_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy the next payment installment.
     *  @param  timestamp_          The timestamp that corresponds to when the payment is to be made.
     *  @return principal_          The portion of the total amount that will go towards principal.
     *  @return interest_           The portion of the total amount that will go towards interest fees.
     *  @return lateInterest_       The portion of the total amount that will go towards late interest fees.
     *  @return delegateServiceFee_ The portion of the total amount that will go towards delegate service fees.
     *  @return platformServiceFee_ The portion of the total amount that will go towards platform service fees.
     */
    function getPaymentBreakdown(uint256 timestamp_)
        external view returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

    /**
     *  @dev The timestamp of the due date of the next payment.
     */
    function paymentDueDate() external view returns (uint40 paymentDueDate_);

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