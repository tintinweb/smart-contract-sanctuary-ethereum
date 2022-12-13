// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { ILoanManager } from "./interfaces/ILoanManager.sol";

import {
    IERC20Like,
    ILiquidatorLike,
    IMapleGlobalsLike,
    IMapleLoanLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./proxy/LoanManagerStorage.sol";

/*

    ██╗      ██████╗  █████╗ ███╗   ██╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██║     ██║   ██║███████║██╔██╗ ██║    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║     ██║   ██║██╔══██║██║╚██╗██║    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ███████╗╚██████╔╝██║  ██║██║ ╚████║    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract LoanManager is ILoanManager, MapleProxiedInternals, LoanManagerStorage {

    uint256 public override constant PRECISION       = 1e30;
    uint256 public override constant HUNDRED_PERCENT = 1e6;  // 100.0000%

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier nonReentrant() {
        require(_locked == 1, "LM:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /******************************************************************************************************************************/
    /*** Upgradeability Functions                                                                                               ***/
    /******************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "LM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "LM:M:FAILED");
    }

    function setImplementation(address implementation_) external override {
        require(msg.sender == _factory(), "LM:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override {
        address poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();

        require(msg.sender == poolDelegate_ || msg.sender == governor(), "LM:U:NO_AUTH");

        IMapleGlobalsLike mapleGlobals = IMapleGlobalsLike(globals());

        if (msg.sender == poolDelegate_) {
            require(mapleGlobals.isValidScheduledCall(msg.sender, address(this), "LM:UPGRADE", msg.data), "LM:U:INVALID_SCHED_CALL");

            mapleGlobals.unscheduleCall(msg.sender, "LM:UPGRADE", msg.data);
        }

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /******************************************************************************************************************************/
    /*** Loan Ownership Functions                                                                                               ***/
    /******************************************************************************************************************************/

    function setLoanTransferAdmin(address newLoanTransferAdmin_) external override {
        require(msg.sender == IPoolManagerLike(poolManager).poolDelegate());
        emit LoanTransferAdminSet(loanTransferAdmin = newLoanTransferAdmin_);
    }

    function setOwnershipTo(address[] calldata loans_, address[] calldata newLenders_) external override {
        require(msg.sender == loanTransferAdmin);

        require(loans_.length == newLenders_.length);

        uint256 length_ = loans_.length;

        for (uint256 i_; i_ < length_;) {
            IMapleLoanLike(loans_[i_]).setPendingLender(newLenders_[i_]);
            unchecked{ i_++; }
        }
    }

    function takeOwnership(address[] calldata loans_) external override {
        require(msg.sender == loanTransferAdmin);

        uint256 length_ = loans_.length;

        for (uint256 i_; i_ < length_;) {
            IMapleLoanLike(loans_[i_]).acceptLender();
            unchecked{ i_++; }
        }
    }

    /******************************************************************************************************************************/
    /*** Collateral Liquidation Administrative Functions                                                                        ***/
    /******************************************************************************************************************************/

    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external override {
        require(msg.sender == poolManager,           "LM:SAS:NOT_PM");
        require(allowedSlippage_ <= HUNDRED_PERCENT, "LM:SAS:INVALID_SLIPPAGE");

        emit AllowedSlippageSet(collateralAsset_, allowedSlippageFor[collateralAsset_] = allowedSlippage_);
    }

    function setMinRatio(address collateralAsset_, uint256 minRatio_) external override {
        require(msg.sender == poolManager, "LM:SMR:NOT_PM");
        emit MinRatioSet(collateralAsset_, minRatioFor[collateralAsset_] = minRatio_);
    }

    /******************************************************************************************************************************/
    /*** Manual Accounting Update Function                                                                                      ***/
    /******************************************************************************************************************************/

    function updateAccounting() external override {
        require(!IMapleGlobalsLike(globals()).protocolPaused(),           "LM:UA:PAUSED");
        require(msg.sender == poolDelegate() || msg.sender == governor(), "LM:UA:NO_AUTH");

        _advanceGlobalPaymentAccounting();

        _updateIssuanceParams(issuanceRate, accountedInterest);
    }

    /******************************************************************************************************************************/
    /*** Loan Funding and Refinancing Functions                                                                                 ***/
    /******************************************************************************************************************************/

    function acceptNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external override nonReentrant {
        require(msg.sender == poolManager, "LM:ANT:NOT_ADMIN");

        _advanceGlobalPaymentAccounting();

        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:ANT:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        uint256 previousRate_      = _handlePreviousPaymentAccounting(loan_, block.timestamp <= paymentInfo_.paymentDueDate);
        uint256 previousPrincipal_ = IMapleLoanLike(loan_).principal();

        // Perform the refinancing, updating the loan state.
        IMapleLoanLike(loan_).acceptNewTerms(refinancer_, deadline_, calls_);

        emit PrincipalOutUpdated(principalOut = principalOut + _uint128(IMapleLoanLike(loan_).principal()) - _uint128(previousPrincipal_));

        uint256 newRate_ = _queueNextPayment(loan_, block.timestamp, IMapleLoanLike(loan_).nextPaymentDueDate());

        // NOTE: Since acceptNewTerms starts the payment interval from block.timestamp, no logic is needed to account for interest in the incoming interval.
        // Update the vesting state an then set the new issuance rate take into account the cessation of the previous rate
        // and the commencement of the new rate for this payment.
        _updateIssuanceParams(issuanceRate + newRate_ - previousRate_, accountedInterest);
    }

    function fund(address loan_) external override nonReentrant {
        require(msg.sender == poolManager, "LM:F:NOT_PM");

        _advanceGlobalPaymentAccounting();

        IMapleLoanLike(loan_).fundLoan(address(this));

        emit PrincipalOutUpdated(principalOut += _uint128(IMapleLoanLike(loan_).principal()));

        // Add new issuance rate from queued payment to aggregate issuance rate.
        _updateIssuanceParams(
            issuanceRate + _queueNextPayment(loan_, block.timestamp, IMapleLoanLike(loan_).nextPaymentDueDate()),
            accountedInterest
        );
    }

    /******************************************************************************************************************************/
    /*** Loan Payment Claim Function                                                                                            ***/
    /******************************************************************************************************************************/

    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external override nonReentrant {
        require(paymentIdOf[msg.sender] != 0, "LM:C:NOT_LOAN");

        // 1. Advance the global accounting.
        //    - Update `domainStart` to the current `block.timestamp`.
        //    - Update `accountedInterest` to account all accrued interest since last update.
        _advanceGlobalPaymentAccounting();

        // 2. Transfer the funds from the loan to the `pool`, `poolDelegate`, and `mapleTreasury`.
        _distributeClaimedFunds(msg.sender, principal_, interest_);

        // 3. If principal has been paid back, decrement `principalOut`.
        if (principal_ != 0) {
            emit PrincipalOutUpdated(principalOut -= _uint128(principal_));
        }

        // 4. Update the accounting based on the payment that was just made.
        bool    onTimePayment_ = block.timestamp <= previousPaymentDueDate_;
        uint256 previousRate_  = _handlePreviousPaymentAccounting(msg.sender, onTimePayment_);

        // 5. If there is no next payment for this loan, update the global accounting and exit.
        //    - Delete the paymentId from the `paymentIdOf` mapping since there is no next payment.
        if (nextPaymentDueDate_ == 0) {
            delete paymentIdOf[msg.sender];
            return _updateIssuanceParams(issuanceRate - previousRate_, accountedInterest);
        }

        // 6. Calculate the start date of the next loan payment.
        //    - If the previous payment is on time or early, the start date is the current `block.timestamp`,
        //      and the `issuanceRate` will be calculated over the interval from `block.timestamp` to the next payment due date.
        //    - If the payment is late, the start date will be the previous payment due date,
        //      and the `issuanceRate` will be calculated over the loan's exact payment interval.
        uint256 nextStartDate_ = _min(block.timestamp, previousPaymentDueDate_);

        // 7. Queue the next payment for the loan.
        //    - Add the payment to the sorted list.
        //    - Update the `paymentIdOf` mapping.
        //    - Update the `payments` mapping with all of the relevant new payment info.
        uint256 newRate_ = _queueNextPayment(msg.sender, nextStartDate_, nextPaymentDueDate_);

        // 8a. If the payment is early, the `accountedInterest` is already fully up to date.
        //      In this case, the `issuanceRate` is the only variable that needs to be updated.
        if (onTimePayment_) {
            return _updateIssuanceParams(issuanceRate + newRate_ - previousRate_, accountedInterest);
        }

        // 8b. If the payment is late, the `issuanceRate` from the previous payment has already been removed from the global `issuanceRate`.
        //     - Update the global `issuanceRate` to account for the new payments `issuanceRate`.
        //     - Update the `accountedInterest` to represent the interest that has accrued from the `previousPaymentDueDate` to the current `block.timestamp`.
        //     Payment `issuanceRate` is used for this calculation as the issuance has occurred in isolation and entirely in the past.
        //     All interest from the aggregate issuance rate has already been accounted for in `_advanceGlobalPaymentAccounting`.
        if (block.timestamp <= nextPaymentDueDate_) {
            return _updateIssuanceParams(
                issuanceRate + newRate_,
                accountedInterest + _uint112((block.timestamp - previousPaymentDueDate_) * newRate_ / PRECISION)
            );
        }

        // 8c. If the current timestamp is greater than the RESULTING `nextPaymentDueDate`, then the next payment must be
        //     FULLY accounted for, and the new payment must be removed from the sorted list.
        //     Payment `issuanceRate` is used for this calculation as the issuance has occurred in isolation and entirely in the past.
        //     All interest from the aggregate issuance rate has already been accounted for in `_advanceGlobalPaymentAccounting`.
        else {
            ( uint256 accountedInterestIncrease_, ) = _accountToEndOfPayment(paymentIdOf[msg.sender], newRate_, previousPaymentDueDate_, nextPaymentDueDate_);

            return _updateIssuanceParams(
                issuanceRate,
                accountedInterest + _uint112(accountedInterestIncrease_)
            );
        }
    }

    /******************************************************************************************************************************/
    /*** Loan Impairment Functions                                                                                              ***/
    /******************************************************************************************************************************/

    function impairLoan(address loan_, bool isGovernor_) external override {
        require(msg.sender == poolManager,           "LM:IL:NOT_PM");
        require(!IMapleLoanLike(loan_).isImpaired(), "LM:IL:IMPAIRED");

        // NOTE: Must get payment info prior to advancing payment accounting, because that will set issuance rate to 0.
        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:IL:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        _advanceGlobalPaymentAccounting();

        _removePaymentFromList(paymentId_);

        // NOTE: Use issuance rate from payment info in storage, because it would have been set to zero and accounted for already if late.
        _updateIssuanceParams(issuanceRate - payments[paymentId_].issuanceRate, accountedInterest);

        ( uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_ ) = _getDefaultInterestAndFees(loan_, paymentInfo_);

        uint256 principal_ = IMapleLoanLike(loan_).principal();

        liquidationInfo[loan_] = LiquidationInfo({
            triggeredByGovernor: isGovernor_,
            principal:           _uint128(principal_),
            interest:            _uint120(netInterest_),
            lateInterest:        netLateInterest_,
            platformFees:        _uint96(platformFees_),
            liquidator:          address(0)
        });

        emit UnrealizedLossesUpdated(unrealizedLosses += _uint128(principal_ + netInterest_));

        IMapleLoanLike(loan_).impairLoan();
    }

    function removeLoanImpairment(address loan_, bool isCalledByGovernor_) external override nonReentrant {
        require(msg.sender == poolManager, "LM:RLI:NOT_PM");

        require(block.timestamp <= IMapleLoanLike(loan_).originalNextPaymentDueDate(), "LM:RLI:PAST_DATE");

        _advanceGlobalPaymentAccounting();

        IMapleLoanLike(loan_).removeLoanImpairment();

        uint24 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:RLI:NOT_LOAN");

        PaymentInfo memory paymentInfo_         = payments[paymentId_];
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        require(!liquidationInfo_.triggeredByGovernor || isCalledByGovernor_, "LM:RLI:NO_AUTH");

        _revertLoanImpairment(liquidationInfo_);

        delete liquidationInfo[loan_];
        delete payments[paymentId_];

        payments[paymentIdOf[loan_] = _addPaymentToList(paymentInfo_.paymentDueDate)] = paymentInfo_;

        // Discretely update missing interest as if payment was always part of the list.
        _updateIssuanceParams(
            issuanceRate + paymentInfo_.issuanceRate,
            accountedInterest + _uint112(_getPaymentAccruedInterest(paymentInfo_.startDate, block.timestamp, paymentInfo_.issuanceRate, paymentInfo_.refinanceInterest))
        );
    }

    /******************************************************************************************************************************/
    /*** Loan Default Functions                                                                                                 ***/
    /******************************************************************************************************************************/

    function finishCollateralLiquidation(address loan_) external override nonReentrant returns (uint256 remainingLosses_, uint256 platformFees_) {
        require(msg.sender == poolManager,   "LM:FCL:NOT_PM");
        require(!isLiquidationActive(loan_), "LM:FCL:LIQ_ACTIVE");

        _advanceGlobalPaymentAccounting();

        // Philosophy for this function is triggerDefault should figure out all the details,
        // and finish should use that info and execute the liquidation and accounting updates.
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        // Reduce principal out, since it has been accounted for in the liquidation.
        emit PrincipalOutUpdated(principalOut -= liquidationInfo_.principal);

        remainingLosses_ = liquidationInfo_.principal + liquidationInfo_.interest + liquidationInfo_.lateInterest;
        platformFees_    = liquidationInfo_.platformFees;

        // Realize the loss following the liquidation.
        emit UnrealizedLossesUpdated(unrealizedLosses -= _uint128(liquidationInfo_.principal + liquidationInfo_.interest));

        address fundsAsset_     = fundsAsset;
        uint256 recoveredFunds_ = IERC20Like(fundsAsset_).balanceOf(liquidationInfo_.liquidator);

        delete liquidationInfo[loan_];

        _compareAndSubtractAccountedInterest(liquidationInfo_.interest);

        // Reduce accounted interest by the interest portion of the shortfall, as the loss has been realized, and therefore this interest has been accounted for.
        // Don't reduce by late interest, since we never account for this interest in the issuance rate, only via discrete updates.
        _updateIssuanceParams(issuanceRate, accountedInterest);

        if (recoveredFunds_ == 0) return (remainingLosses_, platformFees_);

        ILiquidatorLike(liquidationInfo_.liquidator).pullFunds(fundsAsset_, address(this), recoveredFunds_);

        ( remainingLosses_, platformFees_ ) = _disburseLiquidationFunds(loan_, recoveredFunds_, platformFees_, remainingLosses_);
    }

    function triggerDefault(address loan_, address liquidatorFactory_) external override
        returns (
            bool    liquidationComplete_,
            uint256 remainingLosses_,
            uint256 platformFees_
        )
    {
        require(msg.sender == poolManager, "LM:TD:NOT_PM");

        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:TD:NOT_LOAN");

        // NOTE: Must get payment info prior to advancing payment accounting, because that will set issuance rate to 0.
        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        // NOTE: This will cause this payment to be removed from the list, so no need to remove it explicitly afterwards.
        _advanceGlobalPaymentAccounting();

        uint256 netInterest_;
        uint256 netLateInterest_;

        bool isImpaired = IMapleLoanLike(loan_).isImpaired();

        ( netInterest_, netLateInterest_, platformFees_ ) = isImpaired
            ? _getInterestAndFeesFromLiquidationInfo(loan_)
            : _getDefaultInterestAndFees(loan_, paymentInfo_);

        address collateralAsset_ = IMapleLoanLike(loan_).collateralAsset();

        if (IERC20Like(collateralAsset_ ).balanceOf(loan_) == 0 || collateralAsset_ == fundsAsset) {
            ( remainingLosses_, platformFees_ ) = _handleNonLiquidatingRepossession(loan_, platformFees_, netInterest_, netLateInterest_);
            return (true, remainingLosses_, platformFees_);
        }

        ( address liquidator_, uint256 principal_ ) = _handleLiquidatingRepossession(loan_, liquidatorFactory_, netInterest_);

        if (isImpaired) {
            liquidationInfo[loan_].liquidator = liquidator_;
        } else {
            liquidationInfo[loan_] = LiquidationInfo({
                triggeredByGovernor: false,
                principal:           _uint128(principal_),
                interest:            _uint120(netInterest_),
                lateInterest:        netLateInterest_,
                platformFees:        _uint96(platformFees_),
                liquidator:          liquidator_
            });
        }
    }

    /******************************************************************************************************************************/
    /*** Internal Payment Accounting Functions                                                                                  ***/
    /******************************************************************************************************************************/

    // Advance payments in previous domains to "catch up" to current state.
    function _accountToEndOfPayment(
        uint256 paymentId_,
        uint256 issuanceRate_,
        uint256 intervalStart_,
        uint256 intervalEnd_
    )
        internal returns (uint256 accountedInterestIncrease_, uint256 issuanceRateReduction_)
    {
        PaymentInfo memory payment_ = payments[paymentId_];

        // Remove the payment from the linked list so the next payment can be used as the shortest timestamp.
        // NOTE: This keeps the payment accounting info intact so it can be accounted for when the payment is claimed.
        _removePaymentFromList(paymentId_);

        issuanceRateReduction_ = payment_.issuanceRate;

        // Update accounting between timestamps and set last updated to the domainEnd.
        // Reduce the issuanceRate for the payment.
        accountedInterestIncrease_ = (intervalEnd_ - intervalStart_) * issuanceRate_ / PRECISION;

        // Remove issuanceRate as it is deducted from global issuanceRate.
        payments[paymentId_].issuanceRate = 0;
    }

    function _handlePreviousPaymentAccounting(address loan_, bool onTimePayment_) internal returns (uint256 previousRate_) {
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:IL:NOT_LOAN");

        PaymentInfo memory paymentInfo_ = payments[paymentId_];

        // Remove the payment from the mapping once cached to memory.
        delete payments[paymentId_];

        emit PaymentRemoved(loan_, paymentId_);

        // If a payment has been made against a loan that was impaired, reverse the impairment accounting.
        if (liquidationInfo_.principal != 0) {
            _revertLoanImpairment(liquidationInfo_);  // NOTE: Don't set the previous rate since it will always be zero.
            delete liquidationInfo[loan_];
            return 0;
        }

        // If a payment has been made late, its interest has already been fully accounted through `_advanceGlobalPaymentAccounting` logic.
        // It also has been removed from the sorted list, and its `issuanceRate` has been removed from the global `issuanceRate`.
        // The only accounting that must be done is to update the `accountedInterest` to account for the payment being made.
        if (!onTimePayment_) {
            _compareAndSubtractAccountedInterest(paymentInfo_.incomingNetInterest + paymentInfo_.refinanceInterest);
            return 0;
        }

        // If a payment has been made on time, handle the payment accounting.
        // - Remove the payment from the sorted list.
        // - Reduce the `accountedInterest` by the value represented by the payment info.
        _removePaymentFromList(paymentId_);

        previousRate_ = paymentInfo_.issuanceRate;

        // If the amount of interest claimed is greater than the amount accounted for, set to zero.
        // Discrepancy between accounted and actual is always captured by balance change in the pool from the claimed interest.
        uint256 paymentAccruedInterest_ = (block.timestamp - paymentInfo_.startDate) * previousRate_ / PRECISION;

        // Reduce the AUM by the amount of interest that was represented for this payment.
        _compareAndSubtractAccountedInterest(paymentAccruedInterest_ + paymentInfo_.refinanceInterest);
    }

    function _queueNextPayment(address loan_, uint256 startDate_, uint256 nextPaymentDueDate_) internal returns (uint256 newRate_) {
        uint256 platformManagementFeeRate_ = IMapleGlobalsLike(globals()).platformManagementFeeRate(poolManager);
        uint256 delegateManagementFeeRate_ = IPoolManagerLike(poolManager).delegateManagementFeeRate();
        uint256 managementFeeRate_         = platformManagementFeeRate_ + delegateManagementFeeRate_;

        // NOTE: If combined fee is greater than 100%, then cap delegate fee and clamp management fee.
        if (managementFeeRate_ > HUNDRED_PERCENT) {
            delegateManagementFeeRate_ = HUNDRED_PERCENT - platformManagementFeeRate_;
            managementFeeRate_         = HUNDRED_PERCENT;
        }

        ( , uint256[3] memory interest_, ) = IMapleLoanLike(loan_).getNextPaymentDetailedBreakdown();

        newRate_ = (_getNetInterest(interest_[0], managementFeeRate_) * PRECISION) / (nextPaymentDueDate_ - startDate_);

        uint256 incomingNetInterest_ = newRate_ * (nextPaymentDueDate_ - startDate_) / PRECISION;  // NOTE: Use issuanceRate to capture rounding errors.

        uint256 paymentId_ = paymentIdOf[loan_] = _addPaymentToList(_uint48(nextPaymentDueDate_));  // Add the payment to the sorted list.

        uint256 netRefinanceInterest_ = _getNetInterest(interest_[2], managementFeeRate_);

        payments[paymentId_] = PaymentInfo({
            platformManagementFeeRate: _uint24(platformManagementFeeRate_),
            delegateManagementFeeRate: _uint24(delegateManagementFeeRate_),
            startDate:                 _uint48(startDate_),
            paymentDueDate:            _uint48(nextPaymentDueDate_),
            incomingNetInterest:       _uint128(incomingNetInterest_),
            refinanceInterest:         _uint128(netRefinanceInterest_),
            issuanceRate:              newRate_
        });

        // Update the accounted interest to reflect what is present in the loan.
        accountedInterest += _uint112(netRefinanceInterest_);

        emit PaymentAdded(
            loan_,
            paymentId_,
            platformManagementFeeRate_,
            delegateManagementFeeRate_,
            startDate_,
            nextPaymentDueDate_,
            netRefinanceInterest_,
            newRate_
        );
    }

    function _revertLoanImpairment(LiquidationInfo memory liquidationInfo_) internal {
        _compareAndSubtractAccountedInterest(liquidationInfo_.interest);
        unrealizedLosses -= _uint128(liquidationInfo_.principal + liquidationInfo_.interest);

        emit UnrealizedLossesUpdated(unrealizedLosses);
    }

    /******************************************************************************************************************************/
    /*** Internal Loan Repossession Functions                                                                                   ***/
    /******************************************************************************************************************************/

    function _handleLiquidatingRepossession(
        address loan_,
        address liquidatorFactory_,
        uint256 netInterest_
    )
        internal returns (address liquidator_, uint256 principal_)
    {
        principal_ = IMapleLoanLike(loan_).principal();

        address collateralAsset_ = IMapleLoanLike(loan_).collateralAsset();
        uint256 collateral_      = IERC20Like(collateralAsset_).balanceOf(loan_);

        liquidator_ = IMapleProxyFactory(liquidatorFactory_).createInstance(
            abi.encode(address(this), collateralAsset_, fundsAsset), bytes32(bytes20(address(loan_)))
        );

        _updateIssuanceParams(issuanceRate, accountedInterest);

        if (!IMapleLoanLike(loan_).isImpaired()) {
            // Impair the pool with the default amount.
            // NOTE: Don't include fees in unrealized losses, because this is not to be passed onto the LPs. Only collateral and cover can cover the fees.
            emit UnrealizedLossesUpdated(unrealizedLosses += _uint128(principal_ + netInterest_));
        }

        // NOTE: Need to to this after the `isImpaired` check, since `repossess` will unset it.
        IMapleLoanLike(loan_).repossess(liquidator_);

        ILiquidatorLike(liquidator_).setCollateralRemaining(collateral_);

        delete payments[paymentIdOf[loan_]];
        delete paymentIdOf[loan_];
    }

    function _handleNonLiquidatingRepossession(
        address loan_,
        uint256 platformFees_,
        uint256 netInterest_,
        uint256 netLateInterest_
    )
        internal returns (uint256 remainingLosses_, uint256 updatedPlatformFees_)
    {
        uint256 principal_ = IMapleLoanLike(loan_).principal();

        // Reduce principal out, since it has been accounted for in the liquidation.
        emit PrincipalOutUpdated(principalOut -= _uint128(principal_));

        // Calculate the late interest if a late payment was made.
        remainingLosses_ = principal_ + netInterest_ + netLateInterest_;

        // NOTE: Need to cache this here because `repossess` will unset it.
        bool isImpaired_ = IMapleLoanLike(loan_).isImpaired();

        // Pull any fundsAsset in loan into LM.
        ( uint256 recoveredCollateral_, uint256 recoveredFundsAsset_ ) = IMapleLoanLike(loan_).repossess(address(this));

        // If there's collateral, it must be equal to funds asset, so we just sum them.
        uint256 recoveredFunds_ = recoveredCollateral_ + recoveredFundsAsset_;

        // If any funds recovered, disburse them to relevant accounts and update return variables.
        ( remainingLosses_, updatedPlatformFees_ ) = recoveredFunds_ == 0
            ? (remainingLosses_, platformFees_)
            : _disburseLiquidationFunds(loan_, recoveredFunds_, platformFees_, remainingLosses_);

        if (isImpaired_) {
            // Remove unrealized losses that `impairLoan` previously accounted for.
            emit UnrealizedLossesUpdated(unrealizedLosses -= _uint128(principal_ + netInterest_));
            delete liquidationInfo[loan_];
        }

        _compareAndSubtractAccountedInterest(netInterest_);

        // Reduce accounted interest by the interest portion of the shortfall, as the loss has been realized, and therefore this interest has been accounted for.
        // Don't reduce by late interest, since we never account for this interest in the issuance rate, only via discrete updates.
        // NOTE: Don't reduce issuance rate by payments's issuance rate since it was done in `_advanceGlobalPaymentAccounting`.
        _updateIssuanceParams(issuanceRate, accountedInterest);

        delete payments[paymentIdOf[loan_]];
        delete paymentIdOf[loan_];
    }

    /******************************************************************************************************************************/
    /*** Internal Funds Distribution Functions                                                                                  ***/
    /******************************************************************************************************************************/

    function _disburseLiquidationFunds(address loan_, uint256 recoveredFunds_, uint256 platformFees_, uint256 remainingLosses_) internal returns (uint256 updatedRemainingLosses_, uint256 updatedPlatformFees_) {
        uint256 toTreasury_ = _min(recoveredFunds_, platformFees_);

        recoveredFunds_ -= toTreasury_;

        updatedPlatformFees_ = (platformFees_ -= toTreasury_);

        uint256 toPool_ = _min(recoveredFunds_, remainingLosses_);

        recoveredFunds_ -= toPool_;

        updatedRemainingLosses_ = (remainingLosses_ -= toPool_);

        address fundsAsset_    = fundsAsset;
        address mapleTreasury_ = mapleTreasury();

        require(mapleTreasury_ != address(0), "LM:DLF:ZERO_ADDRESS");

        require(toTreasury_     == 0 || ERC20Helper.transfer(fundsAsset_, mapleTreasury_,                   toTreasury_),     "LM:DLF:TRANSFER_MT");
        require(toPool_         == 0 || ERC20Helper.transfer(fundsAsset_, pool,                             toPool_),         "LM:DLF:TRANSFER_POOL");
        require(recoveredFunds_ == 0 || ERC20Helper.transfer(fundsAsset_, IMapleLoanLike(loan_).borrower(), recoveredFunds_), "LM:DLF:TRANSFER_B");
    }

    function _distributeClaimedFunds(address loan_, uint256 principal_, uint256 interest_) internal {
        uint256 paymentId_ = paymentIdOf[loan_];

        require(paymentId_ != 0, "LM:DCF:NOT_LOAN");

        uint256 platformFee_ = interest_ * payments[paymentId_].platformManagementFeeRate / HUNDRED_PERCENT;

        uint256 delegateFee_ = IPoolManagerLike(poolManager).hasSufficientCover()
            ? interest_ * payments[paymentId_].delegateManagementFeeRate / HUNDRED_PERCENT
            : 0;

        address mapleTreasury_ = mapleTreasury();

        require(mapleTreasury_ != address(0), "LM:DCF:ZERO_ADDRESS");

        uint256 netInterest_ = interest_ - platformFee_ - delegateFee_;

        require(ERC20Helper.transfer(fundsAsset, pool,           principal_ + netInterest_), "LM:DCF:POOL_TRANSFER");
        require(ERC20Helper.transfer(fundsAsset, mapleTreasury_, platformFee_),              "LM:DCF:MT_TRANSFER");

        require(delegateFee_ == 0 || ERC20Helper.transfer(fundsAsset, poolDelegate(), delegateFee_), "LM:DCF:PD_TRANSFER");

        emit ManagementFeesPaid(loan_, delegateFee_, platformFee_);
        emit FundsDistributed(loan_, principal_, netInterest_);
    }

    /******************************************************************************************************************************/
    /*** Internal Standard Procedure Update Functions                                                                           ***/
    /******************************************************************************************************************************/

    function _advanceGlobalPaymentAccounting() internal {
        uint256 domainEnd_ = domainEnd;

        uint256 accountedInterest_;

        // If the earliest payment in the list is in the past, then the payment accounting must be retroactively updated.
        if (domainEnd_ != 0 && block.timestamp > domainEnd_) {

            uint256 paymentId_ = paymentWithEarliestDueDate;

            // Cache variables for looping.
            uint256 domainStart_  = domainStart;
            uint256 issuanceRate_ = issuanceRate;

            // Advance payment accounting in previous domains to "catch up" to current state.
            while (block.timestamp > domainEnd_) {
                uint256 next_ = sortedPayments[paymentId_].next;

                // 1. Calculate the interest that has accrued over the domain period in the past (domainEnd - domainStart).
                // 2. Remove the earliest payment from the list
                // 3. Return the `issuanceRate` reduction (the payment's `issuanceRate`).
                // 4. Return the `accountedInterest` increase (the amount of interest accrued over the domain).
                ( uint256 accountedInterestIncrease_, uint256 issuanceRateReduction_ ) = _accountToEndOfPayment(paymentId_, issuanceRate_, domainStart_, domainEnd_);

                // Update cached aggregate values for updating the global state.
                accountedInterest_ += accountedInterestIncrease_;
                issuanceRate_      -= issuanceRateReduction_;

                // Update the domain start and end.
                // - Set the domain start to the previous domain end.
                // - Set the domain end to the next earliest payment.
                //   - If this value is still in the past, this loop will continue.
                domainStart_ = domainEnd_;
                domainEnd_ = paymentWithEarliestDueDate == 0
                    ? _uint48(block.timestamp)
                    : payments[paymentWithEarliestDueDate].paymentDueDate;

                // If the end of the list has been reached, exit the loop.
                if ((paymentId_ = next_) == 0) break;
            }

            // Update global accounting to reflect the changes made in the loop.
            domainStart  = _uint48(domainStart_);
            domainEnd    = _uint48(domainEnd_);
            issuanceRate = issuanceRate_;
        }

        // Update the accounted interest to the current timestamp, and update the domainStart to the current timestamp.
        accountedInterest += _uint112(accountedInterest_ + getAccruedInterest());
        domainStart        = _uint48(block.timestamp);
    }

    function _updateIssuanceParams(uint256 issuanceRate_, uint112 accountedInterest_) internal {
        // If there are no more payments in the list, set domain end to block.timestamp, otherwise, set it to the next upcoming payment.
        uint48 domainEnd_ = paymentWithEarliestDueDate == 0
            ? _uint48(block.timestamp)
            : payments[paymentWithEarliestDueDate].paymentDueDate;

        emit IssuanceParamsUpdated(
            domainEnd         = domainEnd_,
            issuanceRate      = issuanceRate_,
            accountedInterest = accountedInterest_
        );
    }

    /******************************************************************************************************************************/
    /*** Internal Loan Accounting Helper Functions                                                                              ***/
    /******************************************************************************************************************************/

    function _compareAndSubtractAccountedInterest(uint256 amount_) internal {
        // Rounding errors accrue in `accountedInterest` when loans are late and the issuance rate is used to calculate
        // the interest more often to increment than to decrement.
        // When this is the case, the underflow is prevented on the last decrement by using the minimum of the two values below.
        accountedInterest -= _uint112(_min(accountedInterest, amount_));
    }

    function _getAccruedAmount(uint256 totalAccruingAmount_, uint256 startTime_, uint256 endTime_, uint256 currentTime_) internal pure returns (uint256 accruedAmount_) {
        accruedAmount_ = totalAccruingAmount_ * (currentTime_ - startTime_) / (endTime_ - startTime_);
    }

    function _getDefaultInterestAndFees(address loan_, PaymentInfo memory paymentInfo_) internal view returns (uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_) {
        // Calculate the accrued interest on the payment using IR to capture rounding errors.
        // Accrue the interest only up to the current time if the payment due date has not been reached yet.
        netInterest_ =
            paymentInfo_.issuanceRate == 0
                ? paymentInfo_.incomingNetInterest + paymentInfo_.refinanceInterest
                : _getPaymentAccruedInterest({
                    startTime_:           paymentInfo_.startDate,
                    endTime_:             _min(paymentInfo_.paymentDueDate, block.timestamp),
                    paymentIssuanceRate_: paymentInfo_.issuanceRate,
                    refinanceInterest_:   paymentInfo_.refinanceInterest
                });

        ( , uint256[3] memory grossInterest_, uint256[2] memory serviceFees_ ) = IMapleLoanLike(loan_).getNextPaymentDetailedBreakdown();

        uint256 grossLateInterest_ = grossInterest_[1];

        netLateInterest_ = _getNetInterest(grossLateInterest_, paymentInfo_.platformManagementFeeRate + paymentInfo_.delegateManagementFeeRate);

        // Calculate the platform management and service fees.
        uint256 platformManagementFees_ = ((grossInterest_[0] + grossLateInterest_ + grossInterest_[2]) * paymentInfo_.platformManagementFeeRate) / HUNDRED_PERCENT;

        // If the payment is early, scale back the management fees pro-rata based on the current timestamp.
        if (grossLateInterest_ == 0) {
            platformManagementFees_ = _getAccruedAmount(platformManagementFees_, paymentInfo_.startDate, paymentInfo_.paymentDueDate, block.timestamp);
        }

        platformFees_ = platformManagementFees_ + serviceFees_[1];
    }

    function _getPaymentAccruedInterest(uint256 startTime_, uint256 endTime_, uint256 paymentIssuanceRate_, uint256 refinanceInterest_) internal pure returns (uint256 accruedInterest_) {
        accruedInterest_ = (endTime_ - startTime_) * paymentIssuanceRate_ / PRECISION + refinanceInterest_;
    }

    function _getInterestAndFeesFromLiquidationInfo(address loan_) internal view returns (uint256 netInterest_, uint256 netLateInterest_, uint256 platformFees_) {
        LiquidationInfo memory liquidationInfo_ = liquidationInfo[loan_];

        netInterest_     = liquidationInfo_.interest;
        netLateInterest_ = liquidationInfo_.lateInterest;
        platformFees_    = liquidationInfo_.platformFees;
    }

    function _getNetInterest(uint256 interest_, uint256 feeRate_) internal pure returns (uint256 netInterest_) {
        netInterest_ = interest_ * (HUNDRED_PERCENT - feeRate_) / HUNDRED_PERCENT;
    }

    /******************************************************************************************************************************/
    /*** Internal Payment Sorting Functions                                                                                     ***/
    /******************************************************************************************************************************/

    function _addPaymentToList(uint48 paymentDueDate_) internal returns (uint24 paymentId_) {
        paymentId_ = ++paymentCounter;

        uint24 current_ = uint24(0);
        uint24 next_    = paymentWithEarliestDueDate;

        // Starting from the earliest payment, while the paymentDueDate is greater than the next payment in the list, keep iterating.
        while (next_ != 0 && paymentDueDate_ >= sortedPayments[next_].paymentDueDate) {
            current_ = next_;
            next_    = sortedPayments[current_].next;
        }

        // If the result is that this is the earliest payment, update the earliest payment pointer. Else set the next pointer of the previous payment to the new id.
        if (current_ != 0) {
            sortedPayments[current_].next = paymentId_;
        } else {
            paymentWithEarliestDueDate = paymentId_;
        }

        // If the result is that this isn't the latest payment, update the previous pointer of the next payment to the new id.
        if (next_ != 0) {
            sortedPayments[next_].previous = paymentId_;
        }

        sortedPayments[paymentId_] = SortedPayment({ previous: current_, next: next_, paymentDueDate: paymentDueDate_ });
    }

    function _removePaymentFromList(uint256 paymentId_) internal {
        SortedPayment memory sortedPayment_ = sortedPayments[paymentId_];

        uint24 previous_ = sortedPayment_.previous;
        uint24 next_     = sortedPayment_.next;

        // If removing the earliest payment, update the earliest payment pointer.
        if (paymentWithEarliestDueDate == paymentId_) {
            paymentWithEarliestDueDate = next_;
        }

        // If not the last payment, update the previous pointer of the next payment.
        if (next_ != 0) {
            sortedPayments[next_].previous = previous_;
        }

        // If not the first payment, update the next pointer of the previous payment.
        if (previous_ != 0) {
            sortedPayments[previous_].next = next_;
        }

        delete sortedPayments[paymentId_];
    }

    /******************************************************************************************************************************/
    /*** Loan Manager View Functions                                                                                            ***/
    /******************************************************************************************************************************/

    function assetsUnderManagement() public view virtual override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + getAccruedInterest();
    }

    function getAccruedInterest() public view override returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;

        if (issuanceRate_ == 0) return uint256(0);

        // If before domain end, use current timestamp.
        accruedInterest_ = issuanceRate_ * (_min(block.timestamp, domainEnd) - domainStart) / PRECISION;
    }

    function getExpectedAmount(address collateralAsset_, uint256 swapAmount_) public view override returns (uint256 returnAmount_) {
        address globals_ = globals();

        uint256 collateralAssetDecimals_ = uint256(10) ** uint256(IERC20Like(collateralAsset_).decimals());

        uint256 oracleAmount =
            swapAmount_
                * IMapleGlobalsLike(globals_).getLatestPrice(collateralAsset_)  // Convert from `fromAsset` value.
                * uint256(10) ** uint256(IERC20Like(fundsAsset).decimals())     // Convert to `toAsset` decimal precision.
                * (HUNDRED_PERCENT - allowedSlippageFor[collateralAsset_])      // Multiply by allowed slippage basis points
                / IMapleGlobalsLike(globals_).getLatestPrice(fundsAsset)        // Convert to `toAsset` value.
                / collateralAssetDecimals_                                      // Convert from `fromAsset` decimal precision.
                / HUNDRED_PERCENT;                                              // Divide basis points for slippage.

        uint256 minRatioAmount = (swapAmount_ * minRatioFor[collateralAsset_]) / collateralAssetDecimals_;

        returnAmount_ = oracleAmount > minRatioAmount ? oracleAmount : minRatioAmount;
    }

    function isLiquidationActive(address loan_) public view override returns (bool isActive_) {
        address liquidatorAddress_ = liquidationInfo[loan_].liquidator;

        isActive_ = (liquidatorAddress_ != address(0)) && (ILiquidatorLike(liquidatorAddress_).collateralRemaining() != uint256(0));
    }

    /******************************************************************************************************************************/
    /*** Protocol Address View Functions                                                                                        ***/
    /******************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IMapleGlobalsLike(globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function mapleTreasury() public view override returns (address treasury_) {
        treasury_ = IMapleGlobalsLike(globals()).mapleTreasury();
    }

    function poolDelegate() public view override returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    /******************************************************************************************************************************/
    /*** Internal Pure Utility Functions                                                                                        ***/
    /******************************************************************************************************************************/

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }

    function _uint24(uint256 input_) internal pure returns (uint24 output_) {
        require(input_ <= type(uint24).max, "LM:UINT24_CAST");
        output_ = uint24(input_);
    }

    function _uint48(uint256 input_) internal pure returns (uint48 output_) {
        require(input_ <= type(uint48).max, "LM:UINT48_CAST");
        output_ = uint48(input_);
    }

    function _uint96(uint256 input_) internal pure returns (uint96 output_) {
        require(input_ <= type(uint96).max, "LM:UINT96_CAST");
        output_ = uint96(input_);
    }

    function _uint112(uint256 input_) internal pure returns (uint112 output_) {
        require(input_ <= type(uint112).max, "LM:UINT112_CAST");
        output_ = uint112(input_);
    }

    function _uint120(uint256 input_) internal pure returns (uint120 output_) {
        require(input_ <= type(uint120).max, "LM:UINT120_CAST");
        output_ = uint120(input_);
    }

    function _uint128(uint256 input_) internal pure returns (uint128 output_) {
        require(input_ <= type(uint128).max, "LM:UINT128_CAST");
        output_ = uint128(input_);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

interface ILoanManager is IMapleProxied, ILoanManagerStorage {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Emitted when `setAllowedSlippage` is called.
     *  @param collateralAsset_ Address of a collateral asset.
     *  @param newSlippage_     New value for `allowedSlippage`.
     */
    event AllowedSlippageSet(address collateralAsset_, uint256 newSlippage_);

    /**
     *  @dev   Funds have been claimed and distributed into the Pool.
     *  @param loan_        The address of the loan contract.
     *  @param principal_   The amount of principal paid.
     *  @param netInterest_ The amount of net interest paid.
     */
    event FundsDistributed(address indexed loan_, uint256 principal_, uint256 netInterest_);

    /**
     *  @dev   Emitted when the issuance parameters are changed.
     *  @param domainEnd_         The timestamp of the domain end.
     *  @param issuanceRate_      New value for the issuance rate.
     *  @param accountedInterest_ The amount of accounted interest.
     */
    event IssuanceParamsUpdated(uint48 domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);

    /**
     *  @dev   Emitted when the loanTransferAdmin is set by the PoolDelegate.
     *  @param loanTransferAdmin_ The address of the admin that can transfer loans.
     */
    event LoanTransferAdminSet(address indexed loanTransferAdmin_);

    /**
     *  @dev   A fee payment was made.
     *  @param loan_                  The address of the loan contract.
     *  @param delegateManagementFee_ The amount of delegate management fee paid.
     *  @param platformManagementFee_ The amount of platform management fee paid.
    */
    event ManagementFeesPaid(address indexed loan_, uint256 delegateManagementFee_, uint256 platformManagementFee_);

    /**
     *  @dev   Emitted when `setMinRatio` is called.
     *  @param collateralAsset_ Address of a collateral asset.
     *  @param newMinRatio_     New value for `minRatio`.
     */
    event MinRatioSet(address collateralAsset_, uint256 newMinRatio_);

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments array.
     *  @param loan_      The address of the loan.
     *  @param paymentId_ The payment ID of the payment that was removed.
     */
    event PaymentAdded(
        address indexed loan_,
        uint256 indexed paymentId_,
        uint256 platformManagementFeeRate_,
        uint256 delegateManagementFeeRate_,
        uint256 startDate_,
        uint256 nextPaymentDueDate_,
        uint256 netRefinanceInterest_,
        uint256 newRate_
    );

    /**
     *  @dev   Emitted when a payment is removed from the LoanManager payments array.
     *  @param loan_      The address of the loan.
     *  @param paymentId_ The payment ID of the payment that was removed.
     */
    event PaymentRemoved(address indexed loan_, uint256 indexed paymentId_);

    /**
     *  @dev   Emitted when principal out is updated
     *  @param principalOut_ The new value for principal out.
     */
    event PrincipalOutUpdated(uint128 principalOut_);

    /**
     *  @dev   Emitted when unrealized losses is updated.
     *  @param unrealizedLosses_ The new value for unrealized losses.
     */
    event UnrealizedLossesUpdated(uint256 unrealizedLosses_);

    /******************************************************************************************************************************/
    /*** External Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Accepts new loan terms triggering a loan refinance.
     *  @param loan_       Loan to be refinanced.
     *  @param refinancer_ The address of the refinancer.
     *  @param deadline_   The new deadline to execute the refinance.
     *  @param calls_      The encoded calls to set new loan terms.
     */
    function acceptNewTerms(address loan_, address refinancer_, uint256 deadline_, bytes[] calldata calls_) external;

    /**
     *  @dev   Called by loans when payments are made, updating the accounting.
     *  @param principal_              The amount of principal paid.
     *  @param interest_               The amount of interest paid.
     *  @param previousPaymentDueDate_ The previous payment due date.
     *  @param nextPaymentDueDate_     The new payment due date.
     */
    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external;

    /**
     *  @dev    Finishes the collateral liquidation.
     *  @param  loan_            Loan that had its collateral liquidated.
     *  @return remainingLosses_ The amount of remaining losses.
     *  @return platformFees_    The amount of platform fees.
     */
    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 platformFees_);

    /**
     *  @dev   Funds a new loan.
     *  @param loan_ Loan to be funded.
     */
    function fund(address loan_) external;

    /**
     *  @dev   Triggers the loan impairment for a loan.
     *  @param loan_       Loan to trigger the loan impairment.
     *  @param isGovernor_ True if called by the governor.
     */
    function impairLoan(address loan_, bool isGovernor_) external;

    /**
     *  @dev   Removes the loan impairment for a loan.
     *  @param loan_               Loan to remove the loan impairment.
     *  @param isCalledByGovernor_ True if `impairLoan` was called by the governor.
     */
    function removeLoanImpairment(address loan_, bool isCalledByGovernor_) external;

    /**
     *  @dev   Sets the allowed slippage for a collateral asset liquidation.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param allowedSlippage_  New value for `allowedSlippage`.
     */
    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external;

    /**
     *  @dev   Sets the address of the account that is able to call `setOwnershipTo` and `takeOwnership` for multiple loans.
     *  @param newLoanTransferAdmin_ Address of the new admin.
     */
    function setLoanTransferAdmin(address newLoanTransferAdmin_) external;

    /**
     *  @dev   Sets the minimum ratio for a collateral asset liquidation.
     *         This ratio is expressed as a decimal representation of units of fundsAsset
     *         per unit collateralAsset in fundsAsset decimal precision.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param minRatio_         New value for `minRatio`.
     */
    function setMinRatio(address collateralAsset_, uint256 minRatio_) external;

    /**
     *  @dev   Sets the ownership of loans to an address.
     *  @param loans_      An array of loan addresses.
     *  @param newLenders_ An array of lenders to set pending ownership to.
     */
    function setOwnershipTo(address[] calldata loans_, address[] calldata newLenders_) external;

    /**
     *  @dev   Takes the ownership of the loans.
     *  @param loans_ An array with multiple loan addresses.
     */
    function takeOwnership(address[] calldata loans_) external;

    /**
     *  @dev    Triggers the default of a loan.
     *  @param  loan_                Loan to trigger the default.
     *  @param  liquidatorFactory_   Factory that will be used to deploy the liquidator.
     *  @return liquidationComplete_ True if the liquidation is completed in the same transaction (uncollateralized).
     *  @return remainingLosses_     The amount of remaining losses.
     *  @return platformFees_        The amount of platform fees.
     */
    function triggerDefault(address loan_, address liquidatorFactory_) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    /**
     *  @dev Updates the issuance parameters of the LoanManager, callable by the Governor and the PoolDelegate.
     *       Useful to call when `block.timestamp` is greater than `domainEnd` and the LoanManager is not accruing interest.
     */
    function updateAccounting() external;

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Returns the precision used for the contract.
     *  @return precision_ The precision used for the contract.
     */
    function PRECISION() external returns (uint256 precision_);

    /**
     *  @dev    Returns the value considered as the hundred percent.
     *  @return hundredPercent_ The value considered as the hundred percent.
     */
    function HUNDRED_PERCENT() external returns (uint256 hundredPercent_);

    /**
     *  @dev    Gets the amount of assets under the management of the contract.
     *  @return assetsUnderManagement_ The amount of assets under the management of the contract.
     */
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    /**
     *  @dev    Gets the amount of accrued interest up until this point in time.
     *  @return accruedInterest_ The amount of accrued interest up until this point in time.
     */
    function getAccruedInterest() external view returns (uint256 accruedInterest_);

    /**
     *  @dev    Gets the expected amount of an asset given the input amount.
     *  @param  collateralAsset_ The collateral asset that is being liquidated.
     *  @param  swapAmount_      The swap amount of collateral asset.
     *  @return returnAmount_    The desired return amount of funds asset.
     */
    function getExpectedAmount(address collateralAsset_, uint256 swapAmount_) external view returns (uint256 returnAmount_);

    /**
     *  @dev    Gets the address of the Maple globals contract.
     *  @return globals_ The address of the Maple globals contract.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the address of the governor contract.
     *  @return governor_ The address of the governor contract.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Returns whether or not a liquidation is in progress.
     *  @param  loan_     The address of the loan contract.
     *  @return isActive_ True if a liquidation is in progress.
     */
    function isLiquidationActive(address loan_) external view returns (bool isActive_);

    /**
     *  @dev    Gets the address of the pool delegate.
     *  @return poolDelegate_ The address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     *  @dev    Gets the address of the Maple treasury.
     *  @return treasury_ The address of the Maple treasury.
     */
    function mapleTreasury() external view returns (address treasury_);

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
     *  @dev    Gets allowed slippage for a give collateral asset.
     *  @param  collateralAsset_ Address of a collateral asset.
     *  @return allowedSlippage_ The allowed slippage for the collateral asset.
     */
    function allowedSlippageFor(address collateralAsset_) external view returns (uint256 allowedSlippage_);

    /**
     *  @dev    Gets the timestamp of the domain end.
     *  @return domainEnd_ The timestamp of the domain end.
     */
    function domainEnd() external view returns (uint48 domainEnd_);

    /**
     *  @dev    Gets the timestamp of the domain start.
     *  @return domainStart_ The timestamp of the domain start.
     */
    function domainStart() external view returns (uint48 domainStart_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return fundsAsset_ The address of the funds asset.
     */
    function fundsAsset() external view returns (address fundsAsset_);

    /**
     *  @dev    Gets the current issuance rate.
     *  @return issuanceRate_ The value for the issuance rate.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev    Gets the information for a liquidation.
     *  @param  loan_               The address of the loan.
     *  @return triggeredByGovernor True if the liquidation was triggered by the governor.
     *  @return principal           The amount of principal to be recovered.
     *  @return interest            The amount of interest to be recovered.
     *  @return lateInterest        The amount of late interest to be recovered.
     *  @return platformFees        The amount of platform fees owed.
     *  @return liquidator          The address of the liquidator.
     */
    function liquidationInfo(address loan_) external view returns (
        bool    triggeredByGovernor,
        uint128 principal,
        uint120 interest,
        uint256 lateInterest,
        uint96  platformFees,
        address liquidator
    );

    /**
     *  @dev    Returns the current `loanTransferAdmin` address.
     *  @return loanTransferAdmin_ The payment counter.
     */
    function loanTransferAdmin() external view returns (address loanTransferAdmin_);

    /**
     *  @dev   Gets the minimum ratio for a collateral asset.
     *  @param collateralAsset_  Address of a collateral asset.
     *  @param minRatio_         The value for minRatio.
     */
    function minRatioFor(address collateralAsset_) external view returns (uint256 minRatio_);

    /**
     *  @dev    Gets the payment counter.
     *  @return paymentCounter_ The payment counter.
     */
    function paymentCounter() external view returns (uint24 paymentCounter_);

    /**
     *  @dev    Gets the payment if for the given loan.
     *  @param  loan_      The address of the loan.
     *  @return paymentId_ The id of the payment information.
     */
    function paymentIdOf(address loan_) external view returns (uint24 paymentId_);

    /**
     *  @dev    Gets the information for a payment.
     *  @param  paymentId_                The id of the payment information.
     *  @return platformManagementFeeRate The value for the platform management fee rate.
     *  @return delegateManagementFeeRate The value for the delegate management fee rate.
     *  @return startDate                 The start date of the payment.
     *  @return paymentDueDate            The timestamp of the payment due date.
     *  @return incomingNetInterest       The amount of incoming net interest.
     *  @return refinanceInterest         The amount of refinance interest.
     *  @return issuanceRate              The issuance rate for the loan.
     */
    function payments(uint256 paymentId_) external view returns (
        uint24  platformManagementFeeRate,
        uint24  delegateManagementFeeRate,
        uint48  startDate,
        uint48  paymentDueDate,
        uint128 incomingNetInterest,
        uint128 refinanceInterest,
        uint256 issuanceRate
    );

    /**
     *  @dev    Gets the payment id with the earliest due date.
     *  @return paymentWithEarliestDueDate_ The payment id with the earliest due date.
     */
    function paymentWithEarliestDueDate() external view returns (uint24 paymentWithEarliestDueDate_);

    /**
     *  @dev    Gets the address of the pool.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

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
     *  @dev   Gets the information of the sorted list.
     *  @param previous       The id of the item before on the list.
     *  @param next           The id of the item after on the list.
     *  @param paymentDueDate The value for the payment due date.
     */
    function sortedPayments(uint256 paymentId_) external view returns (
        uint24 previous,
        uint24 next,
        uint48 paymentDueDate
    );

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface ILoanManagerLike {

    function acceptNewTerms(
        address loan_,
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external;

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    function claim(address loan_, bool hasSufficientCover_) external;

    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 serviceFee_);

    function fund(address loan_) external;

    function removeLoanImpairment(address loan_, bool isGovernor_) external;

    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external;

    function setMinRatio(address collateralAsset_, uint256 minRatio_) external;

    function impairLoan(address loan_, bool isGovernor_) external;

    function triggerDefault(address loan_, address liquidatorFactory_) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface ILoanManagerInitializerLike {

    function encodeArguments(address pool_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_);

}

interface ILiquidatorLike {

    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

    function pullFunds(address token_, address destination_, uint256 amount_) external;

    function setCollateralRemaining(uint256 collateralAmount_) external;

}

interface IMapleGlobalsLike {

    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    function migrationAdmin() external view returns (address migrationAdmin_);

    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function ownedPoolManager(address poolDelegate_) external view returns (address poolManager_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleLoanLike {

    function acceptLender() external;

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_) external returns (bytes32 refinanceCommitment_);

    function batchClaimFunds(uint256[] memory amounts_, address[] memory destinations_) external;

    function borrower() external view returns (address borrower_);

    function claimFunds(uint256 amount_, address destination_) external;

    function collateral() external view returns (uint256 collateral);

    function collateralAsset() external view returns(address asset_);

    function feeManager() external view returns (address feeManager_);

    function fundsAsset() external view returns (address asset_);

    function fundLoan(address lender_) external returns (uint256 fundsLent_);

    function getClosingPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_
    );

    function getNextPaymentDetailedBreakdown() external view returns (
        uint256 principal_,
        uint256[3] memory interest_,
        uint256[2] memory fees_
    );

    function getNextPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 fees_
    );

    function getUnaccountedAmount(address asset_) external view returns (uint256 unaccountedAmount_);

    function gracePeriod() external view returns (uint256 gracePeriod_);

    function interestRate() external view returns (uint256 interestRate_);

    function isImpaired() external view returns (bool isImpaired_);

    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    function lender() external view returns (address lender_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function removeLoanImpairment() external;

    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    function setPendingLender(address pendingLender_) external;

    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    function impairLoan() external;

    function unimpairedPaymentDueDate() external view returns (uint256 unimpairedPaymentDueDate_);

}

interface IMapleLoanV3Like {

    function acceptLender() external;

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256, uint256);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function principal() external view returns (uint256 principal_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function setPendingLender(address pendingLender_) external;

}

interface IMapleProxyFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface IPoolDelegateCoverLike {

    function moveFunds(uint256 amount_, address recipient_) external;

}

interface IPoolLike is IERC20Like {

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function asset() external view returns (address asset_);

    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function manager() external view returns (address manager_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    function processExit(uint256 shares_, uint256 assets_, address receiver_, address owner_) external;

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

}

interface IPoolManagerLike {

    function addLoanManager(address loanManager_) external;

    function canCall(bytes32 functionId_, address caller_, bytes memory data_) external view returns (bool canCall_, string memory errorMessage_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function claim(address loan_) external;

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function fund(uint256 principalAmount_, address loan_, address loanManager_) external;

    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address escrow_);

    function globals() external view returns (address globals_);

    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    function loanManager() external view returns (address loanManager_);

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    function processRedeem(uint256 shares_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function processWithdraw(uint256 assets_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function poolDelegate() external view returns (address poolDelegate_);

    function poolDelegateCover() external view returns (address poolDelegateCover_);

    function removeLoanManager(address loanManager_) external;

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    function setWithdrawalManager(address withdrawalManager_) external;

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

    function withdrawalManager() external view returns (address withdrawalManager_);

}

interface IWithdrawalManagerInitializerLike {

    function encodeArguments(address pool_, uint256 cycleDuration_, uint256 windowDuration_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_, uint256 cycleDuration_, uint256 windowDuration_);

}

interface IWithdrawalManagerLike {

    function addShares(uint256 shares_, address owner_) external;

    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    function lockedShares(address owner_) external view returns (uint256 lockedShares_);

    function previewRedeem(address owner_, uint256 shares) external view returns (uint256 redeemableShares, uint256 resultingAssets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

    function processExit(uint256 shares_, address account_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerStorage } from "../interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {

    struct LiquidationInfo {
        bool    triggeredByGovernor;  // Slot 1: bool    -  1 bytes
        uint128 principal;            //         uint128 - 16 bytes: max = 3.4e38
        uint120 interest;             //         uint120 - 15 bytes: max = 1.7e38
        uint256 lateInterest;         // Slot 2: uint256 - 32 bytes: max = 1.1e77
        uint96  platformFees;         // Slot 3: uint96  - 12 bytes: max = 7.9e28 (>79b units at 1e18)
        address liquidator;           //         address - 20 bytes
    }

    struct PaymentInfo {
        uint24  platformManagementFeeRate;  // Slot 1: uint24  -  3 bytes: max = 1.6e7  (1600%)
        uint24  delegateManagementFeeRate;  //         uint24  -  3 bytes: max = 1.6e7  (1600%)
        uint48  startDate;                  //         uint48  -  6 bytes: max = 2.8e14 (>8m years)
        uint48  paymentDueDate;             //         uint48  -  6 bytes: max = 2.8e14 (>8m years)
        uint128 incomingNetInterest;        // Slot 2: uint128 - 16 bytes: max = 3.4e38
        uint128 refinanceInterest;          //         uint128 - 16 bytes: max = 3.4e38
        uint256 issuanceRate;               // Slot 3: uint256 - 32 bytes: max = 1.1e77
    }

    struct SortedPayment {
        uint24 previous;        // uint24 - 3 bytes: max = 1.6e7
        uint24 next;            // uint24 - 3 bytes: max = 1.6e7
        uint48 paymentDueDate;  // uint48 - 6 bytes: max = 2.8e14 (>8m years)
    }

    uint256 internal _locked;  // Used when checking for reentrancy.

    uint24  public override paymentCounter;              // Slot 1: uint24  -  3 bytes: max = 1.6e7
    uint24  public override paymentWithEarliestDueDate;  //         uint24  -  3 bytes: max = 1.6e7
    uint48  public override domainStart;                 //         uint48  -  6 bytes: max = 2.8e14  (>8m years)
    uint48  public override domainEnd;                   //         uint48  -  6 bytes: max = 2.8e14  (>8m years)
    uint112 public override accountedInterest;           //         uint112 - 14 bytes: max = 5.19e33
    uint128 public override principalOut;                // Slot 2: uint128 - 16 bytes: max = 3.4e38
    uint128 public override unrealizedLosses;            //         uint128 - 16 bytes: max = 3.4e38
    uint256 public override issuanceRate;                // Slot 3: uint256 - 32 bytes: max = 1.1e77

    // NOTE: Addresses below uints to preserve full storage slots
    address public override fundsAsset;
    address public override loanTransferAdmin;
    address public override pool;
    address public override poolManager;

    mapping(address => uint24) public override paymentIdOf;

    mapping(address => uint256) public override allowedSlippageFor;
    mapping(address => uint256) public override minRatioFor;

    mapping(address => LiquidationInfo) public override liquidationInfo;

    mapping(uint256 => PaymentInfo) public override payments;

    mapping(uint256 => SortedPayment) public override sortedPayments;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ProxiedInternals } from "../modules/proxy-factory/contracts/ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals { }

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                  ***/
    /******************************************************************************************************************************/

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

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

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

    /******************************************************************************************************************************/
    /*** State Changing Functions                                                                                               ***/
    /******************************************************************************************************************************/

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

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

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

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

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