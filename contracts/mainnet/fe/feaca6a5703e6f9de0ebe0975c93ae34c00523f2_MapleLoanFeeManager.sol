// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }      from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import {
    IMapleGlobalsLike,
    ILoanLike,
    ILoanManagerLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { IMapleLoanFeeManager } from "./interfaces/IMapleLoanFeeManager.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗    ██╗      ██████╗  █████╗ ███╗   ██╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██║     ██╔═══██╗██╔══██╗████╗  ██║
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║     ██║   ██║███████║██╔██╗ ██║
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║     ██║   ██║██╔══██║██║╚██╗██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ███████╗╚██████╔╝██║  ██║██║ ╚████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

    ███████╗███████╗███████╗    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ██╔════╝██╔════╝██╔════╝    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    █████╗  █████╗  █████╗      ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██╔══╝  ██╔══╝  ██╔══╝      ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║     ███████╗███████╗    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚══════╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

*/

contract MapleLoanFeeManager is IMapleLoanFeeManager {

    uint256 internal constant HUNDRED_PERCENT = 100_0000;

    address public override globals;

    mapping(address => uint256) public override delegateOriginationFee;
    mapping(address => uint256) public override delegateRefinanceServiceFee;
    mapping(address => uint256) public override delegateServiceFee;
    mapping(address => uint256) public override platformServiceFee;
    mapping(address => uint256) public override platformRefinanceServiceFee;

    constructor(address globals_) {
        globals = globals_;
    }

    /******************************************************************************************************************************/
    /*** Payment Functions                                                                                                      ***/
    /******************************************************************************************************************************/

    function payOriginationFees(address asset_, uint256 principalRequested_) external override returns (uint256 feePaid_) {
        uint256 delegateOriginationFee_ = delegateOriginationFee[msg.sender];
        uint256 platformOriginationFee_ = _getPlatformOriginationFee(msg.sender, principalRequested_);

        // Send origination fee to treasury, with remainder to poolDelegate.
        _transferTo(asset_, _getPoolDelegate(msg.sender), delegateOriginationFee_, "MLFM:POF:PD_TRANSFER");
        _transferTo(asset_, _getTreasury(),               platformOriginationFee_, "MLFM:POF:TREASURY_TRANSFER");

        feePaid_ = delegateOriginationFee_ + platformOriginationFee_;

        emit OriginationFeesPaid(msg.sender, delegateOriginationFee_, platformOriginationFee_);
    }

    function payServiceFees(address asset_, uint256 numberOfPayments_) external override returns (uint256 feePaid_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceServiceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceServiceFee_
        ) = getServiceFeeBreakdown(msg.sender, numberOfPayments_);

        feePaid_ = delegateServiceFee_ + delegateRefinanceServiceFee_ + platformServiceFee_ + platformRefinanceServiceFee_;

        _transferTo(asset_, _getPoolDelegate(msg.sender), delegateServiceFee_ + delegateRefinanceServiceFee_, "MLFM:PSF:PD_TRANSFER");
        _transferTo(asset_, _getTreasury(),               platformServiceFee_ + platformRefinanceServiceFee_, "MLFM:PSF:TREASURY_TRANSFER");

        // Refinance fees should be only paid once.
        delete delegateRefinanceServiceFee[msg.sender];
        delete platformRefinanceServiceFee[msg.sender];

        emit ServiceFeesPaid(msg.sender, delegateServiceFee_, delegateRefinanceServiceFee_, platformServiceFee_, platformRefinanceServiceFee_);
    }

    /******************************************************************************************************************************/
    /*** Fee Update Functions                                                                                                   ***/
    /******************************************************************************************************************************/

    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external override {
        delegateOriginationFee[msg.sender] = delegateOriginationFee_;
        delegateServiceFee[msg.sender]     = delegateServiceFee_;

        emit FeeTermsUpdated(msg.sender, delegateOriginationFee_, delegateServiceFee_);
    }

    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external override {
        uint256 platformRefinanceServiceFee_ = getPlatformServiceFeeForPeriod(msg.sender, principalRequested_, timeSinceLastDueDate_);
        uint256 delegateRefinanceServiceFee_ = getDelegateServiceFeesForPeriod(msg.sender, timeSinceLastDueDate_);

        platformRefinanceServiceFee[msg.sender] += platformRefinanceServiceFee_;
        delegateRefinanceServiceFee[msg.sender] += delegateRefinanceServiceFee_;

        emit PartialRefinanceServiceFeesUpdated(msg.sender, platformRefinanceServiceFee_, delegateRefinanceServiceFee_);
    }

    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external override {
        uint256 platformServiceFee_ = getPlatformServiceFeeForPeriod(msg.sender, principalRequested_, paymentInterval_);

        platformServiceFee[msg.sender] = platformServiceFee_;

        emit PlatformServiceFeeUpdated(msg.sender, platformServiceFee_);
    }

    /******************************************************************************************************************************/
    /***  View Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    function getDelegateServiceFeesForPeriod(address loan_, uint256 interval_) public view override returns (uint256 delegateServiceFee_) {
        uint256 paymentInterval = ILoanLike(loan_).paymentInterval();

        delegateServiceFee_ = delegateServiceFee[loan_] * interval_ / paymentInterval;
    }

    function getPlatformOriginationFee(address loan_, uint256 principalRequested_) external view override returns (uint256 platformOriginationFee_) {
        platformOriginationFee_ =  _getPlatformOriginationFee(loan_, principalRequested_);
    }

    function getPlatformServiceFeeForPeriod(address loan_, uint256 principalRequested_, uint256 interval_) public view override returns (uint256 platformServiceFee_) {
        uint256 platformServiceFeeRate_ = IMapleGlobalsLike(globals).platformServiceFeeRate(_getPoolManager(loan_));
        platformServiceFee_             = principalRequested_ * platformServiceFeeRate_ * interval_ / 365 days / HUNDRED_PERCENT;
    }

    function getServiceFees(address loan_, uint256 numberOfPayments_) external view override returns (uint256 serviceFees_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceServiceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceServiceFee_
        ) = getServiceFeeBreakdown(loan_, numberOfPayments_);

        serviceFees_ = delegateServiceFee_ + delegateRefinanceServiceFee_ + platformServiceFee_ + platformRefinanceServiceFee_;
    }

    function getServiceFeeBreakdown(address loan_, uint256 numberOfPayments_) public view override
        returns (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        )
    {
        delegateServiceFee_   = delegateServiceFee[loan_] * numberOfPayments_;
        platformServiceFee_   = platformServiceFee[loan_] * numberOfPayments_;
        delegateRefinanceFee_ = delegateRefinanceServiceFee[loan_];
        platformRefinanceFee_ = platformRefinanceServiceFee[loan_];
    }

    function getServiceFeesForPeriod(address loan_, uint256 interval_) external view override returns (uint256 serviceFee_) {
        uint256 principalRequested = ILoanLike(loan_).principalRequested();

        serviceFee_ = getDelegateServiceFeesForPeriod(loan_, interval_) + getPlatformServiceFeeForPeriod(loan_, principalRequested, interval_);
    }

    function getOriginationFees(address loan_, uint256 principalRequested_) external view override returns (uint256 originationFees_) {
        originationFees_ = _getPlatformOriginationFee(loan_, principalRequested_) + delegateOriginationFee[loan_];
    }

    /******************************************************************************************************************************/
    /*** Internal View Functions                                                                                                ***/
    /******************************************************************************************************************************/

    function _getAsset(address loan_) internal view returns (address asset_) {
        return ILoanLike(loan_).fundsAsset();
    }

    function _getPlatformOriginationFee(address loan_, uint256 principalRequested_) internal view returns (uint256 platformOriginationFee_) {
        uint256 platformOriginationFeeRate_ = IMapleGlobalsLike(globals).platformOriginationFeeRate(_getPoolManager(loan_));
        uint256 loanTermLength_             = ILoanLike(loan_).paymentInterval() * ILoanLike(loan_).paymentsRemaining();

        platformOriginationFee_ = platformOriginationFeeRate_ * principalRequested_ * loanTermLength_ / 365 days / HUNDRED_PERCENT;
    }

    function _getPoolManager(address loan_) internal view returns (address pool_) {
        return ILoanManagerLike(ILoanLike(loan_).lender()).poolManager();
    }

    function _getPoolDelegate(address loan_) internal view returns (address poolDelegate_) {
        return IPoolManagerLike(_getPoolManager(loan_)).poolDelegate();
    }

    function _getTreasury() internal view returns (address mapleTreasury_) {
        return IMapleGlobalsLike(globals).mapleTreasury();
    }

    /******************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                              ***/
    /******************************************************************************************************************************/

    function _transferTo(address asset_, address destination_, uint256 amount_, string memory errorMessage_) internal {
        require(destination_ != address(0), "MLFM:TT:ZERO_DESTINATION");
        require(ERC20Helper.transferFrom(asset_, msg.sender, destination_, amount_), errorMessage_);
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

interface IMapleGlobalsLike {

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isPoolAsset(address poolAsset_) external view returns (bool isValid_);

    function mapleTreasury() external view returns (address governor_);

    function platformOriginationFeeRate(address pool_) external view returns (uint256 platformOriginationFeeRate_);

    function platformServiceFeeRate(address pool_) external view returns (uint256 platformFee_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function securityAdmin() external view returns (address securityAdmin_);

}

interface ILenderLike {

    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external;

    function factory() external view returns (address factory_);

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

interface IMapleFeeManagerLike {

    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external;

    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external;

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface IPoolManagerLike {

    function poolDelegate() external view returns (address poolDelegate_);

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