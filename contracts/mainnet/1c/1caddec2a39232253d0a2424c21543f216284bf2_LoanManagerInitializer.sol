// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerInitializer {

    event Initialized(address indexed pool_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_);

    function encodeArguments(address pool_) external pure returns (bytes memory calldata_);

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

import { ILoanManagerInitializer } from "../interfaces/ILoanManagerInitializer.sol";
import { IPoolLike }               from "../interfaces/Interfaces.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";

contract LoanManagerInitializer is ILoanManagerInitializer, LoanManagerStorage {

    function decodeArguments(bytes calldata calldata_) public pure override returns (address pool_) {
        pool_ = abi.decode(calldata_, (address));
    }

    function encodeArguments(address pool_) external pure override returns (bytes memory calldata_) {
        calldata_ = abi.encode(pool_);
    }

    fallback() external {
        _locked = 1;

        address pool_ = decodeArguments(msg.data);

        pool        = pool_;
        fundsAsset  = IPoolLike(pool_).asset();
        poolManager = IPoolLike(pool_).manager();

        emit Initialized(pool_);
    }

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