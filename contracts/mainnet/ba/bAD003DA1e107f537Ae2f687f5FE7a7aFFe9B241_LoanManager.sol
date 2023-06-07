// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { ILoanManager }                                                from "./interfaces/ILoanManager.sol";
import { IGlobalsLike, ILoanFactoryLike, ILoanLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";

/*

    ██╗      ██████╗  █████╗ ███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██║     ██║   ██║███████║██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║     ██║   ██║██╔══██║██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ███████╗╚██████╔╝██║  ██║██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract LoanManager is ILoanManager, MapleProxiedInternals, LoanManagerStorage {

    uint256 public override constant HUNDRED_PERCENT = 1e6;   // 100.0000%
    uint256 public override constant PRECISION       = 1e27;

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier isLoan(address loan_) {
        _revertIfNotLoan(loan_);
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier onlyPoolDelegate() {
        _revertIfNotPoolDelegate();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /**************************************************************************************************************************************/
    /*** Upgradeability Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override whenNotPaused {
        require(msg.sender == _factory(),        "LM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "LM:M:FAILED");
    }

    function setImplementation(address implementation_) external override whenNotPaused {
        require(msg.sender == _factory(), "LM:SI:NOT_FACTORY");

        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override whenNotPaused {
        IGlobalsLike globals_ = IGlobalsLike(_globals());

        if (msg.sender == _poolDelegate()) {
            require(globals_.isValidScheduledCall(msg.sender, address(this), "LM:UPGRADE", msg.data), "LM:U:INVALID_SCHED_CALL");

            globals_.unscheduleCall(msg.sender, "LM:UPGRADE", msg.data);
        } else {
            require(msg.sender == globals_.securityAdmin(), "LM:U:NO_AUTH");
        }

        emit Upgraded(version_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Loan Funding and Refinancing Functions                                                                                         ***/
    /**************************************************************************************************************************************/

    function fund(address loan_) external override whenNotPaused nonReentrant onlyPoolDelegate {
        address      factory_ = ILoanLike(loan_).factory();
        IGlobalsLike globals_ = IGlobalsLike(_globals());

        require(globals_.isInstanceOf("OT_LOAN_FACTORY", factory_),    "LM:F:INVALID_LOAN_FACTORY");
        require(ILoanFactoryLike(factory_).isLoan(loan_),              "LM:F:INVALID_LOAN_INSTANCE");
        require(globals_.isBorrower(ILoanLike(loan_).borrower()), "LM:F:INVALID_BORROWER");

        uint256 principal_ = ILoanLike(loan_).principal();

        require(principal_ != 0, "LM:F:LOAN_NOT_ACTIVE");

        _prepareFundsForLoan(loan_, principal_);

        ( uint256 fundsLent_, , ) = ILoanLike(loan_).fund();

        require(fundsLent_ == principal_, "LM:F:FUNDING_MISMATCH");

        _updatePrincipalOut(_int256(fundsLent_));

        Payment memory payment_ = _addPayment(loan_);

        _updateInterestAccounting(0, _int256(payment_.issuanceRate));
    }

    function proposeNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyPoolDelegate isLoan(loan_)
    {
        ILoanLike(loan_).proposeNewTerms(refinancer_, deadline_, calls_);
    }

    function rejectNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_)
        external override whenNotPaused onlyPoolDelegate isLoan(loan_)
    {
        ILoanLike(loan_).rejectNewTerms(refinancer_, deadline_, calls_);
    }

    /**************************************************************************************************************************************/
    /*** Loan Payment Claim Function                                                                                                    ***/
    /**************************************************************************************************************************************/

    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  nextPaymentDueDate_
    )
        external override whenNotPaused isLoan(msg.sender) nonReentrant
    {
        uint256 principalRemaining_ = ILoanLike(msg.sender).principal();

        // Either a next payment and remaining principal exists, or neither exist and principal is returned.
        require(
            (nextPaymentDueDate_ > 0 && principalRemaining_ > 0) ||                          // First given it's most likely.
            ((nextPaymentDueDate_ == 0) && (principalRemaining_ == 0) && (principal_ > 0)),
            "LM:C:INVALID"
        );

        // Calculate the original principal to correctly account for removing `unrealizedLosses` when removing the impairment.
        uint256 originalPrincipal_ = uint256(_int256(principalRemaining_) + principal_);

        _accountForLoanImpairmentRemoval(msg.sender, originalPrincipal_);

        // Transfer the funds from the loan to the `pool`, `poolDelegate`, and `mapleTreasury`.
        _distributeClaimedFunds(msg.sender, principal_, interest_, delegateServiceFee_, platformServiceFee_);

        // If principal is changing, update `principalOut`.
        // If principal is positive, it is being repaid, so `principalOut` is decremented.
        // If principal is negative, it is being taken from the Pool, so `principalOut` is incremented.
        if (principal_ != 0) {
            _updatePrincipalOut(-principal_);
        }

        // Remove the payment and cache the struct.
        Payment memory claimedPayment_ = _removePayment(msg.sender);

        int256 accountedInterestAdjustment_
            = -_int256(_getIssuance(claimedPayment_.issuanceRate, block.timestamp - claimedPayment_.startDate));

        // If no new payment to track, update accounting and account for discrepancies in paid interest vs accrued interest since the
        // payment's start date, and exit.
        if (nextPaymentDueDate_ == 0) {
            return _updateInterestAccounting(accountedInterestAdjustment_, -_int256(claimedPayment_.issuanceRate));
        }

        if (principal_ < 0) {
            address borrower_ = ILoanLike(msg.sender).borrower();

            require(IGlobalsLike(_globals()).isBorrower(borrower_), "LM:C:INVALID_BORROWER");

            _prepareFundsForLoan(msg.sender, _uint256(-principal_));
        }

        // Track the new payment.
        Payment memory nextPayment_ = _addPayment(msg.sender);

        // Update accounting and account for discrepancies in paid interest vs accrued interest since the payment's start date, and exit.
        _updateInterestAccounting(accountedInterestAdjustment_, _int256(nextPayment_.issuanceRate) - _int256(claimedPayment_.issuanceRate));
    }

    /**************************************************************************************************************************************/
    /*** Loan Call Functions                                                                                                            ***/
    /**************************************************************************************************************************************/

    function callPrincipal(address loan_, uint256 principal_) external override whenNotPaused onlyPoolDelegate isLoan(loan_) {
        ILoanLike(loan_).callPrincipal(principal_);
    }

    function removeCall(address loan_) external override whenNotPaused onlyPoolDelegate isLoan(loan_) {
        ILoanLike(loan_).removeCall();
    }

    /**************************************************************************************************************************************/
    /*** Loan Impairment Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    function impairLoan(address loan_) external override whenNotPaused isLoan(loan_) {
        bool isGovernor_ = msg.sender == _governor();

        require(isGovernor_ || msg.sender == _poolDelegate(), "LM:IL:NO_AUTH");

        ILoanLike(loan_).impair();

        if (isGovernor_) {
            _accountForLoanImpairmentAsGovernor(loan_);
        } else {
            _accountForLoanImpairment(loan_);
        }
    }

    function removeLoanImpairment(address loan_) external override whenNotPaused isLoan(loan_) {
        ( , bool impairedByGovernor_ ) = _accountForLoanImpairmentRemoval(loan_, ILoanLike(loan_).principal());

        require(msg.sender == _governor() || (!impairedByGovernor_ && msg.sender == _poolDelegate()), "LM:RLI:NO_AUTH");

        ILoanLike(loan_).removeImpairment();
    }

    /**************************************************************************************************************************************/
    /*** Loan Default Functions                                                                                                         ***/
    /**************************************************************************************************************************************/

    function triggerDefault(address loan_, address liquidatorFactory_)
        external override returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        liquidatorFactory_;  // Silence compiler warning.

        ( remainingLosses_, unrecoveredPlatformFees_ ) = triggerDefault(loan_);

        liquidationComplete_ = true;
    }

    function triggerDefault(address loan_)
        public override whenNotPaused isLoan(loan_) returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        require(msg.sender == poolManager, "LM:TD:NOT_PM");

        // Note: Always impair before proceeding, this ensures a consistent approach to reduce the `accountedInterest` for the Loan.
        //       If the Loan is already impaired, this will be a no-op and just return the `impairedDate`.
        //       If the Loan is not impaired, the accountedInterest will be updated to block.timestamp,
        //       which will include the total interest due for the Loan.
        uint40 impairedDate_ = _accountForLoanImpairment(loan_);

        ( , uint256 interest_, uint256 lateInterest_, , uint256 platformServiceFee_ ) = ILoanLike(loan_).getPaymentBreakdown(impairedDate_);

        uint256 principal_ = ILoanLike(loan_).principal();

        interest_ += lateInterest_;

        // Pull any `fundsAsset` in loan into LM.
        uint256 recoveredFunds_ = ILoanLike(loan_).repossess(address(this));

        // Distribute the recovered funds (to treasury, pool, and borrower) and determine the losses, if any, that must still be realized.
        (
            remainingLosses_,
            unrecoveredPlatformFees_
        ) = _distributeLiquidationFunds(loan_, principal_, interest_, platformServiceFee_, recoveredFunds_);

        // Remove the payment and cache the struct.
        Payment memory payment_ = _removePayment(loan_);

        // NOTE: This is the amount of interest accounted for, before the loan's impairment,
        //       that is still in the aggregate `accountedInterest` and offset in `unrealizedLosses`
        //       The original `impairedDate` is always used over the current `impairedDate` on the Loan,
        //       this ensures the interest calculated for `unrealizedLosses` matches the original impairment calculation.
        uint256 accountedImpairedInterest_ = _getIssuance(payment_.issuanceRate, impairedDate_ - payment_.startDate);

        // The payment's interest until the `impairedDate` must be deducted from `accountedInterest`, thus realizing the interest loss.
        // The unrealized losses incurred due to the impairment must be deducted from the global `unrealizedLosses`.
        // The loan's principal must be deducted from `principalOut`, thus realizing the principal loss.
        _updateInterestAccounting(-_int256(accountedImpairedInterest_), 0);
        _updateUnrealizedLosses(-_int256(principal_ + accountedImpairedInterest_));
        _updatePrincipalOut(-_int256(principal_));

        delete impairmentFor[loan_];
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _addPayment(address loan_) internal returns (Payment memory payment_) {
        uint256 platformManagementFeeRate_ = IGlobalsLike(_globals()).platformManagementFeeRate(poolManager);
        uint256 delegateManagementFeeRate_ = IPoolManagerLike(poolManager).delegateManagementFeeRate();
        uint256 managementFeeRate_         = platformManagementFeeRate_ + delegateManagementFeeRate_;

        // NOTE: If combined fee is greater than 100%, then cap delegate fee and clamp management fee.
        if (managementFeeRate_ > HUNDRED_PERCENT) {
            delegateManagementFeeRate_ = HUNDRED_PERCENT - platformManagementFeeRate_;
            managementFeeRate_         = HUNDRED_PERCENT;
        }

        uint256 paymentDueDate_ = ILoanLike(loan_).paymentDueDate();
        uint256 dueInterest_    = _getNetInterest(loan_, paymentDueDate_, managementFeeRate_);

        // NOTE: Can assume `paymentDueDate_ > block.timestamp` and interest at `block.timestamp` is 0 because payments are only added when
        //         - loans are funded, or
        //         - payments are claimed, resulting in a new payment.
        uint256 paymentIssuanceRate_ = (dueInterest_ * PRECISION) / (paymentDueDate_ - block.timestamp);

        paymentFor[loan_] = payment_ = Payment({
            platformManagementFeeRate: _uint24(platformManagementFeeRate_),
            delegateManagementFeeRate: _uint24(delegateManagementFeeRate_),
            startDate:                 _uint40(block.timestamp),
            issuanceRate:              _uint168(paymentIssuanceRate_)
        });

        emit PaymentAdded(
            loan_,
            platformManagementFeeRate_,
            delegateManagementFeeRate_,
            paymentDueDate_,
            paymentIssuanceRate_
        );
    }

    function _accountForLoanImpairment(address loan_, bool isGovernor_) internal returns (uint40 impairedDate_) {
        impairedDate_ = impairmentFor[loan_].impairedDate;

        // NOTE: Impairing an already-impaired loan simply updates the `dateImpaired` of the loan, which can push the due date further,
        //       however, the `impairedDate` in the struct should not be updated since it defines the moment when accounting for the loan's
        //       payment was paused, and is needed to restore accounting for the eventual removal of the impairment, or the default.
        if (impairedDate_ != 0) return impairedDate_;

        Payment memory payment_ = paymentFor[loan_];

        impairmentFor[loan_] = Impairment(impairedDate_ = _uint40(block.timestamp), isGovernor_);

        // Account for all interest until now (including this payment's), then remove payment's `issuanceRate` from global `issuanceRate`.
        _updateInterestAccounting(0, -_int256(payment_.issuanceRate));

        uint256 principal_ = ILoanLike(loan_).principal();

        // Add the payment's entire interest until now (negating above), and the loan's principal, to unrealized losses.
        _updateUnrealizedLosses(_int256(principal_ + _getIssuance(payment_.issuanceRate, block.timestamp - payment_.startDate)));
    }

    function _accountForLoanImpairment(address loan_) internal returns (uint40 impairedDate_) {
        impairedDate_ = _accountForLoanImpairment(loan_, false);
    }

    function _accountForLoanImpairmentAsGovernor(address loan_) internal returns (uint40 impairedDate_) {
        impairedDate_ = _accountForLoanImpairment(loan_, true);
    }

    function _accountForLoanImpairmentRemoval(address loan_, uint256 originalPrincipal_) internal returns (uint40 impairedDate_, bool impairedByGovernor_) {
        Impairment memory impairment_ = impairmentFor[loan_];

        impairedDate_       = impairment_.impairedDate;
        impairedByGovernor_ = impairment_.impairedByGovernor;

        if (impairedDate_ == 0) return ( impairedDate_, impairedByGovernor_ );

        delete impairmentFor[loan_];

        Payment memory payment_ = paymentFor[loan_];

        // Subtract the payment's entire interest until it's impairment date, and the loan's principal, from unrealized losses.
        _updateUnrealizedLosses(-_int256(originalPrincipal_ + _getIssuance(payment_.issuanceRate, impairedDate_ - payment_.startDate)));

        // Account for all interest until now, adjusting for payment's interest between its impairment date and now,
        // then add payment's `issuanceRate` to the global `issuanceRate`.
        // NOTE: Upon impairment, for payment's interest between its start date and its impairment date were accounted for.
        _updateInterestAccounting(
            _int256(_getIssuance(payment_.issuanceRate, block.timestamp - impairedDate_)),
            _int256(payment_.issuanceRate)
        );
    }

    function _removePayment(address loan_) internal returns (Payment memory payment_) {
        payment_ = paymentFor[loan_];

        delete paymentFor[loan_];

        emit PaymentRemoved(loan_);
    }

    function _updateInterestAccounting(int256 accountedInterestAdjustment_, int256 issuanceRateAdjustment_) internal {
        // NOTE: Order of operations is important as `accruedInterest()` depends on the pre-adjusted `issuanceRate` and `domainStart`.
        accountedInterest = _uint112(_max(_int256(accountedInterest + accruedInterest()) + accountedInterestAdjustment_, 0));
        domainStart       = _uint40(block.timestamp);
        issuanceRate      = _uint256(_max(_int256(issuanceRate) + issuanceRateAdjustment_, 0));

        emit AccountingStateUpdated(issuanceRate, accountedInterest);
    }

    function _updatePrincipalOut(int256 principalOutAdjustment_) internal {
        emit PrincipalOutUpdated(principalOut = _uint128(_max(_int256(principalOut) + principalOutAdjustment_, 0)));
    }

    function _updateUnrealizedLosses(int256 lossesAdjustment_) internal {
        emit UnrealizedLossesUpdated(unrealizedLosses = _uint128(_max(_int256(unrealizedLosses) + lossesAdjustment_, 0)));
    }

    /**************************************************************************************************************************************/
    /*** Funds Distribution Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    function _distributeClaimedFunds(
        address loan_,
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_
    )
        internal
    {
        Payment memory payment_ = paymentFor[loan_];

        uint256 delegateManagementFee_ = _getRatedAmount(interest_, payment_.delegateManagementFeeRate);
        uint256 platformManagementFee_ = _getRatedAmount(interest_, payment_.platformManagementFeeRate);

        // If the coverage is not sufficient move the delegate service fee to the platform and remove the delegate management fee.
        if (!IPoolManagerLike(poolManager).hasSufficientCover()) {
            platformServiceFee_ += delegateServiceFee_;

            delegateServiceFee_    = 0;
            delegateManagementFee_ = 0;
        }

        uint256 netInterest_ = interest_ - (platformManagementFee_ + delegateManagementFee_);

        principal_ = principal_ > int256(0) ? principal_ : int256(0);

        emit ClaimedFundsDistributed(
            loan_,
            uint256(principal_),
            interest_,
            delegateManagementFee_,
            delegateServiceFee_,
            platformManagementFee_,
            platformServiceFee_
        );

        address fundsAsset_ = fundsAsset;

        require(_transfer(fundsAsset_, _pool(),         uint256(principal_) + netInterest_),           "LM:DCF:TRANSFER_P");
        require(_transfer(fundsAsset_, _poolDelegate(), delegateServiceFee_ + delegateManagementFee_), "LM:DCF:TRANSFER_PD");
        require(_transfer(fundsAsset_, _treasury(),     platformServiceFee_ + platformManagementFee_), "LM:DCF:TRANSFER_MT");
    }

    function _distributeLiquidationFunds(
        address loan_,
        uint256 principal_,
        uint256 interest_,
        uint256 platformServiceFee_,
        uint256 recoveredFunds_
    )
        internal returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_)
    {
        Payment memory payment_ = paymentFor[loan_];

        uint256 platformManagementFee_ = _getRatedAmount(interest_, payment_.platformManagementFeeRate);
        uint256 delegateManagementFee_ = _getRatedAmount(interest_, payment_.delegateManagementFeeRate);

        uint256 netInterest_ = interest_ - (platformManagementFee_ + delegateManagementFee_);
        uint256 platformFee_ = platformServiceFee_ + platformManagementFee_;

        uint256 toTreasury_ = _min(recoveredFunds_, platformFee_);

        unrecoveredPlatformFees_ = platformFee_ - toTreasury_;

        recoveredFunds_ -= toTreasury_;

        uint256 toPool_ = _min(recoveredFunds_, principal_ + netInterest_);

        remainingLosses_ = principal_ + netInterest_ - toPool_;

        recoveredFunds_ -= toPool_;

        emit ExpectedClaim(loan_, principal_, netInterest_, platformManagementFee_, platformServiceFee_);

        emit LiquidatedFundsDistributed(loan_, recoveredFunds_, toPool_, toTreasury_);

        // NOTE: Cannot cache `fundsAsset` due to "Stack too deep" issue.
        require(_transfer(fundsAsset, ILoanLike(loan_).borrower(), recoveredFunds_), "LM:DLF:TRANSFER_B");
        require(_transfer(fundsAsset, _pool(),                     toPool_),         "LM:DLF:TRANSFER_P");
        require(_transfer(fundsAsset, _treasury(),                 toTreasury_),     "LM:DLF:TRANSFER_MT");
    }

    function _prepareFundsForLoan(address loan_, uint256 amount_) internal {
        // Request funds from pool manager.
        IPoolManagerLike(poolManager).requestFunds(address(this), amount_);

        // Approve the loan to use these funds.
        require(ERC20Helper.approve(fundsAsset, loan_, amount_), "LM:PFFL:APPROVE_FAILED");
    }

    function _transfer(address asset_, address to_, uint256 amount_) internal returns (bool success_) {
        success_ = (to_ != address(0)) && ((amount_ == 0) || ERC20Helper.transfer(asset_, to_, amount_));
    }

    /**************************************************************************************************************************************/
    /*** Internal Loan Accounting Helper Functions                                                                                      ***/
    /**************************************************************************************************************************************/

    function _getIssuance(uint256 issuanceRate_, uint256 interval_) internal pure returns (uint256 issuance_) {
        issuance_ = (issuanceRate_ * interval_) / PRECISION;
    }

    function _getNetInterest(address loan_, uint256 timestamp_, uint256 managementFeeRate_) internal view returns (uint256 netInterest_) {
        ( , uint256 interest_, , , ) = ILoanLike(loan_).getPaymentBreakdown(timestamp_);

        netInterest_ = _getNetInterest(interest_, managementFeeRate_);
    }

    function _getNetInterest(uint256 interest_, uint256 feeRate_) internal pure returns (uint256 netInterest_) {
        // NOTE: This ensures that `netInterest_ == interest_ - fee_`, since absolutes are subtracted, not rates.
        netInterest_ = interest_ - _getRatedAmount(interest_, feeRate_);
    }

    function _getRatedAmount(uint256 amount_, uint256 rate_) internal pure returns (uint256 ratedAmount_) {
        ratedAmount_ = (amount_ * rate_) / HUNDRED_PERCENT;
    }

    /**************************************************************************************************************************************/
    /*** Loan Manager View Functions                                                                                                    ***/
    /**************************************************************************************************************************************/

    function accruedInterest() public view override returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;

        accruedInterest_ = issuanceRate_ == 0 ? 0 : _getIssuance(issuanceRate_, block.timestamp - domainStart);
    }

    function assetsUnderManagement() public view virtual override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + accruedInterest();
    }

    /**************************************************************************************************************************************/
    /*** Protocol Address View Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _globals() internal view returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function _governor() internal view returns (address governor_) {
        governor_ = IGlobalsLike(_globals()).governor();
    }

    function _pool() internal view returns (address pool_) {
        pool_ = IPoolManagerLike(poolManager).pool();
    }

    function _poolDelegate() internal view returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function _revertIfNotLoan(address loan_) internal view {
        require(paymentFor[loan_].startDate != 0, "LM:NOT_LOAN");
    }

    function _revertIfNotPoolDelegate() internal view {
        require(msg.sender == _poolDelegate(), "LM:NOT_PD");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(_globals()).isFunctionPaused(msg.sig), "LM:PAUSED");
    }

    function _treasury() internal view returns (address treasury_) {
        treasury_ = IGlobalsLike(_globals()).mapleTreasury();
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Utility Functions                                                                                                ***/
    /**************************************************************************************************************************************/

    function _int256(uint256 input_) internal pure returns (int256 output_) {
        require(input_ <= uint256(type(int256).max), "LM:UINT256_OOB_FOR_INT256");
        output_ = int256(input_);
    }

    function _max(int256 a_, int256 b_) internal pure returns (int256 maximum_) {
        maximum_ = a_ > b_ ? a_ : b_;
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _uint24(uint256 input_) internal pure returns (uint24 output_) {
        require(input_ <= type(uint24).max, "LM:UINT256_OOB_FOR_UINT24");
        output_ = uint24(input_);
    }

    function _uint40(uint256 input_) internal pure returns (uint40 output_) {
        require(input_ <= type(uint40).max, "LM:UINT256_OOB_FOR_UINT40");
        output_ = uint40(input_);
    }

    function _uint112(int256 input_) internal pure returns (uint112 output_) {
        require(input_ <= int256(uint256(type(uint112).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT112");
        output_ = uint112(uint256(input_));
    }

    function _uint128(int256 input_) internal pure returns (uint128 output_) {
        require(input_ <= int256(uint256(type(uint128).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT128");
        output_ = uint128(uint256(input_));
    }

    function _uint168(uint256 input_) internal pure returns (uint168 output_) {
        require(input_ <= type(uint168).max, "LM:UINT256_OOB_FOR_UINT168");
        output_ = uint168(input_);
    }

    function _uint168(int256 input_) internal pure returns (uint168 output_) {
        require(input_ <= int256(uint256(type(uint168).max)) && input_ >= 0, "LM:INT256_OOB_FOR_UINT168");
        output_ = uint168(uint256(input_));
    }

    function _uint256(int256 input_) internal pure returns (uint256 output_) {
        require(input_ >= 0, "LM:INT256_OOB_FOR_UINT256");
        output_ = uint256(input_);
    }

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

import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

interface ILoanManager is IMapleProxied, ILoanManagerStorage {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when the accounting state of the loan manager is updated.
     *  @param issuanceRate_      New value for the issuance rate.
     *  @param accountedInterest_ The amount of accounted interest.
     */
    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);

    /**
     *  @dev   Funds have been claimed and distributed to the Pool, Pool Delegate, and Maple Treasury.
     *  @param loan_                  The address of the loan contract.
     *  @param principal_             The amount of principal paid.
     *  @param netInterest_           The amount of net interest paid.
     *  @param delegateManagementFee_ The amount of delegate management fees paid.
     *  @param delegateServiceFee_    The amount of delegate service fees paid.
     *  @param platformManagementFee_ The amount of platform management fees paid.
     *  @param platformServiceFee_    The amount of platform service fees paid.
     */
    event ClaimedFundsDistributed(
        address indexed loan_,
        uint256 principal_,
        uint256 netInterest_,
        uint256 delegateManagementFee_,
        uint256 delegateServiceFee_,
        uint256 platformManagementFee_,
        uint256 platformServiceFee_
    );

    /**
     *  @dev   Funds that were expected to be claimed and distributed to the Pool and Maple Treasury.
     *  @param loan_                  The address of the loan contract.
     *  @param principal_             The amount of principal that was expected to be paid.
     *  @param netInterest_           The amount of net interest that was expected to be paid.
     *  @param platformManagementFee_ The amount of platform management fees that were expected to be paid.
     *  @param platformServiceFee_    The amount of platform service fees that were expected to paid.
     */
    event ExpectedClaim(
        address indexed loan_,
        uint256 principal_,
        uint256 netInterest_,
        uint256 platformManagementFee_,
        uint256 platformServiceFee_
    );

    /**
     *  @dev   Funds that were liquidated and distributed to the Pool, Maple Treasury, and Borrower.
     *  @param loan_       The address of the loan contract that defaulted and was liquidated.
     *  @param toBorrower_ The amount of recovered funds transferred to the Borrower.
     *  @param toPool_     The amount of recovered funds transferred to the Pool.
     *  @param toTreasury_ The amount of recovered funds transferred to the Treasury.
     */
    event LiquidatedFundsDistributed(address indexed loan_, uint256 toBorrower_, uint256 toPool_, uint256 toTreasury_);

    /**
     *  @dev   Emitted when a payment is added to the LoanManager payments mapping.
     *  @param loan_                      The address of the loan.
     *  @param platformManagementFeeRate_ The amount of platform management rate that will be used for the payment distribution.
     *  @param delegateManagementFeeRate_ The amount of delegate management rate that will be used for the payment distribution.
     *  @param paymentDueDate_            The due date of the payment.
     *  @param issuanceRate_              The issuance of the payment, 1e27 precision.
     */
    event PaymentAdded(
        address indexed loan_,
        uint256 platformManagementFeeRate_,
        uint256 delegateManagementFeeRate_,
        uint256 paymentDueDate_,
        uint256 issuanceRate_
    );

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments mapping.
     *  @param loan_ The address of the loan.
     */
    event PaymentRemoved(address indexed loan_);

    /**
     *  @dev   Emitted when principal out is updated
     *  @param principalOut_ The new value for principal out.
     */
    event PrincipalOutUpdated(uint128 principalOut_);

    /**
     *  @dev   Emitted when unrealized losses is updated.
     *  @param unrealizedLosses_ The new value for unrealized losses.
     */
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // NOTE: setPendingLender and acceptPendingLender were not implemented in the LoanManager even though they exist on the Loan
    //       contract. This is because the Loan will support this functionality always, but it was not deemed necessary for the
    //       LoanManager to support this functionality.

    /**
     *  @dev   Calls a loan.
     *  @param loan_      Loan to be called.
     *  @param principal_ Amount of principal to call the Loan with.
     */
    function callPrincipal(address loan_, uint256 principal_) external;

    /**
     *  @dev   Called by loans when payments are made, updating the accounting.
     *  @param principal_          The difference in principal. Positive if net principal change moves funds into pool, negative if it moves
     *                             funds out of pool.
     *  @param interest_           The amount of interest paid.
     *  @param platformServiceFee_ The amount of platform service fee paid.
     *  @param delegateServiceFee_ The amount of delegate service fee paid.
     *  @param paymentDueDate_     The new payment due date.
     */
    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  paymentDueDate_
    ) external;

    /**
     *  @dev   Funds a new loan.
     *  @param loan_ Loan to be funded.
     */
    function fund(address loan_) external;

    /**
     *  @dev   Triggers the impairment of a loan.
     *  @param loan_ Loan to trigger the loan impairment.
     */
    function impairLoan(address loan_) external;

    /**
     *  @dev   Proposes new terms for a loan.
     *  @param loan_       The loan to propose new changes to.
     *  @param refinancer_ The refinancer to use in the refinance.
     *  @param deadline_   The deadline by which the borrower must accept the new terms.
     *  @param calls_      The array of calls to be made to the refinancer.
     */
    function proposeNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Reject/cancel proposed new terms for a loan.
     *  @param loan_       The loan with the proposed new changes.
     *  @param refinancer_ The refinancer to use in the refinance.
     *  @param deadline_   The deadline by which the borrower must accept the new terms.
     *  @param calls_      The array of calls to be made to the refinancer.
     */
    function rejectNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Removes a loan call.
     *  @param loan_ Loan to remove call for.
     */
    function removeCall(address loan_) external;

    /**
     *  @dev   Removes the loan impairment for a loan.
     *  @param loan_ Loan to remove the loan impairment.
     */
    function removeLoanImpairment(address loan_) external;

    /**
     *  @dev    Triggers the default of a loan. Different interface for PM to accommodate vs FT-LM.
     *  @param  loan_                    Loan to trigger the default.
     *  @param  liquidatorFactory_       Address of the liquidator factory (ignored for open-term loans).
     *  @return liquidationComplete_     If the liquidation is complete (always true for open-term loans)
     *  @return remainingLosses_         The amount of un-recovered principal and interest (net of management fees).
     *  @return unrecoveredPlatformFees_ The amount of un-recovered platform fees.
     */
    function triggerDefault(
        address loan_,
        address liquidatorFactory_
    ) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 unrecoveredPlatformFees_);

    /**
     *  @dev    Triggers the default of a loan.
     *  @param  loan_                    Loan to trigger the default.
     *  @return remainingLosses_         The amount of un-recovered principal and interest (net of management fees).
     *  @return unrecoveredPlatformFees_ The amount of un-recovered platform fees.
     */
    function triggerDefault(address loan_) external returns (uint256 remainingLosses_, uint256 unrecoveredPlatformFees_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the value considered as the hundred percent.
     *  @return hundredPercent_ The value considered as the hundred percent.
     */
    function HUNDRED_PERCENT() external returns (uint256 hundredPercent_);

    /**
     *  @dev    Returns the precision used for the contract.
     *  @return precision_ The precision used for the contract.
     */
    function PRECISION() external returns (uint256 precision_);

    /**
     *  @dev    Gets the amount of accrued interest up until this point in time.
     *  @return accruedInterest_ The amount of accrued interest up until this point in time.
     */
    function accruedInterest() external view returns (uint256 accruedInterest_);

    /**
     *  @dev    Gets the amount of assets under the management of the contract.
     *  @return assetsUnderManagement_ The amount of assets under the management of the contract.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IGlobalsLike {

    function canDeploy(address caller_) external view returns (bool canDeploy_);

    function governor() external view returns (address governor_);

    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external returns (bool isInstance_);

    function mapleGlobals() external returns (address globals_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface ILoanLike {

    function borrower() external view returns (address borrower_);

    function callPrincipal(uint256 principalToReturn_) external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function factory() external view returns (address factory_);

    function fund() external returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_);

    function impair() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function paymentDueDate() external view returns (uint40 paymentDueDate_);

    function getPaymentBreakdown(uint256 paymentTimestamp_)
        external view
        returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

    function principal() external view returns (uint256 principal_);

    function proposeNewTerms(
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function rejectNewTerms(
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function removeCall() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function removeImpairment() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function repossess(address destination_) external returns (uint256 fundsRepossessed_);

}

interface IPoolManagerLike {

    function asset() external view returns (address asset_);

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function factory() external view returns (address factory_);

    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function requestFunds(address destination_, uint256 principal_) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerStorage } from "./interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {

    struct Impairment {
        uint40 impairedDate;        // Slot 1: uint40 - Until year 36,812.
        bool   impairedByGovernor;  //         bool
    }

    struct Payment {
        uint24  platformManagementFeeRate;  // Slot 1: uint24  - max = 1.6e7 (1600%)
        uint24  delegateManagementFeeRate;  //         uint24  - max = 1.6e7 (1600%)
        uint40  startDate;                  //         uint40  - Until year 36,812.
        uint168 issuanceRate;               //         uint168 - max = 3.7e50 (3.2e10 * 1e18 / day)
    }

    uint256 internal _locked;  // Used when checking for reentrancy.

    uint40  public override domainStart;        // Slot 1: uint40  - Until year 36,812.
    uint112 public override accountedInterest;  //         uint112 - max = 5.1e33
    uint128 public override principalOut;       // Slot 2: uint128 - max = 3.4e38
    uint128 public override unrealizedLosses;   //         uint128 - max = 3.4e38
    uint256 public override issuanceRate;       // Slot 3: uint256 - max = 1.1e77

    // NOTE: Addresses below uints to preserve full storage slots
    address public override fundsAsset;
    address public override poolManager;

    mapping(address => Impairment) public override impairmentFor;

    mapping(address => Payment) public override paymentFor;

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

interface ILoanManagerStorage {

    /**
     *  @dev    Gets the amount of accounted interest.
     *  @return accountedInterest_ The amount of accounted interest.
     */
    function accountedInterest() external view returns (uint112 accountedInterest_);

    /**
     *  @dev    Gets the timestamp of the domain start.
     *  @return domainStart_ The timestamp of the domain start.
     */
    function domainStart() external view returns (uint40 domainStart_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return fundsAsset_ The address of the funds asset.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev    Gets the information for an impairment.
     *  @param  loan_              The address of the loan.
     *  @return impairedDate       The date the impairment was triggered.
     *  @return impairedByGovernor True if the impairment was triggered by the governor.
     */
    function impairmentFor(address loan_) external view returns (uint40 impairedDate, bool impairedByGovernor);

    /**
     *  @dev    Gets the current issuance rate.
     *  @return issuanceRate_ The value for the issuance rate.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev    Gets the information for a payment.
     *  @param  loan_                     The address of the loan.
     *  @return platformManagementFeeRate The value for the platform management fee rate.
     *  @return delegateManagementFeeRate The value for the delegate management fee rate.
     *  @return startDate                 The start date of the payment.
     *  @return issuanceRate              The issuance rate for the loan.
     */
    function paymentFor(address loan_) external view returns (
        uint24  platformManagementFeeRate,
        uint24  delegateManagementFeeRate,
        uint40  startDate,
        uint168 issuanceRate
    );

    /**
     *  @dev    Gets the address of the pool manager.
     *  @return poolManager_ The address of the pool manager.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the amount of principal out.
     *  @return principalOut_ The amount of principal out.
     */
    function principalOut() external view returns (uint128 principalOut_);

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);

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