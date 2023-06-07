// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ILoanManagerInitializer }                                from "./interfaces/ILoanManagerInitializer.sol";
import { IGlobalsLike, IMapleProxyFactoryLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";

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

        address factory_ = IPoolManagerLike(poolManager_).factory();
        address globals_ = IMapleProxyFactoryLike(msg.sender).mapleGlobals();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_MANAGER_FACTORY", factory_), "LMI:I:INVALID_PM_FACTORY");
        require(IMapleProxyFactoryLike(factory_).isInstance(poolManager_),             "LMI:I:INVALID_PM_INSTANCE");

        // Since `poolManager` is a valid instance, `fundsAsset` must also be valid due to the pool manager initializer.
        fundsAsset = IPoolManagerLike(
            poolManager = poolManager_
        ).asset();

        emit Initialized(poolManager);
    }

    fallback() external {
        _initialize(decodeArguments(msg.data));
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ILoanManagerInitializer {

    event Initialized(address indexed poolManager_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address poolManager_);

    function encodeArguments(address poolManager_) external pure returns (bytes memory calldata_);

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