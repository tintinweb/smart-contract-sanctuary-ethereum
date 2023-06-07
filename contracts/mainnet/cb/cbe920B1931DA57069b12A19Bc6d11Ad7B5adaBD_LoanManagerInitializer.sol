// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerInitializer } from "../interfaces/ILoanManagerInitializer.sol";
import { IPoolManagerLike }        from "../interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";

contract LoanManagerInitializer is ILoanManagerInitializer, LoanManagerStorage {

    function decodeArguments(bytes calldata calldata_) public pure override returns (address poolManager_) {
        poolManager_ = abi.decode(calldata_, (address));
    }

    function encodeArguments(address poolManager_) external pure override returns (bytes memory calldata_) {
        calldata_ = abi.encode(poolManager_);
    }

    function _initialize(address poolManager_) internal {
        _locked = 1;

        poolManager = poolManager_;

        fundsAsset = IPoolManagerLike(poolManager_).asset();

        emit Initialized(poolManager);
    }

    fallback() external {
        _initialize({ poolManager_: decodeArguments(msg.data) });
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerInitializer {

    /**
     *  @dev   Emitted when the loan manager is initialized.
     *  @param poolManager_ Address of the associated pool manager.
     */
    event Initialized(address indexed poolManager_);

    /**
     *  @dev    Decodes the initialization arguments of a loan manager.
     *  @param  calldata_    ABI encoded address of the pool manager.
     *  @return poolManager_ Address of the pool manager.
     */
    function decodeArguments(bytes calldata calldata_) external pure returns (address poolManager_);

    /**
     *  @dev    Encodes the initialization arguments of a loan manager.
     *  @param  poolManager_ Address of the pool manager.
     *  @return calldata_    ABI encoded address of the pool manager.
     */
    function encodeArguments(address poolManager_) external pure returns (bytes memory calldata_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

}

interface ILiquidatorLike {

    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    function pullFunds(address token_, address destination_, uint256 amount_) external;

    function setCollateralRemaining(uint256 collateralAmount_) external;

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleLoanLike {

    function acceptLender() external;

    function acceptNewTerms(
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function borrower() external view returns (address borrower_);

    function collateralAsset() external view returns(address asset_);

    function factory() external view returns (address factory_);

    function fundLoan() external returns (uint256 fundsLent_);

    function getNextPaymentDetailedBreakdown() external view returns (
        uint256           principal_,
        uint256[3] memory interest_,
        uint256[2] memory fees_
    );

    function getUnaccountedAmount(address asset_) external returns (uint256 unaccountedAmount_);

    function impairLoan() external;

    function isImpaired() external view returns (bool isImpaired_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principal_);

    function rejectNewTerms(
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function removeLoanImpairment() external;

    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    function skim(address token_, address destination_) external returns (uint256 skimmed_);

}

interface IMapleProxyFactoryLike {

    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

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

    address internal __deprecated_loanTransferAdmin;
    address internal __deprecated_pool;

    address public override poolManager;

    mapping(address => uint24) public override paymentIdOf;

    mapping(address => uint256) public override allowedSlippageFor;
    mapping(address => uint256) public override minRatioFor;

    mapping(address => LiquidationInfo) public override liquidationInfo;

    mapping(uint256 => PaymentInfo) public override payments;

    mapping(uint256 => SortedPayment) public override sortedPayments;

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