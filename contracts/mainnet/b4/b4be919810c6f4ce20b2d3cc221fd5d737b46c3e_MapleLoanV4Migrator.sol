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
    uint256 internal _interestRate;         // The annualized interest rate of the loan.
    uint256 internal _closingRate;          // The fee rate (applied to principal) to close the loan.
    uint256 internal _lateFeeRate;          // The fee rate for late payments.
    uint256 internal _lateInterestPremium;  // The amount to increase the interest rate by for late payments.

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

import { IERC20 } from "../modules/erc20/contracts/interfaces/IERC20.sol";

import { IMapleFeeManagerLike } from "./interfaces/Interfaces.sol";
import { IMapleLoanV4Migrator } from "./interfaces/IMapleLoanV4Migrator.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/// @title DebtLockerV4Migrator is intended to initialize the storage of a DebtLocker proxy.
contract MapleLoanV4Migrator is IMapleLoanV4Migrator, MapleLoanStorage {

    function encodeArguments(address feeManager_) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(feeManager_);
    }

    function decodeArguments(bytes calldata encodedArguments_) public pure override returns (address feeManager_) {
        ( feeManager_ ) = abi.decode(encodedArguments_, (address));
    }

    fallback() external {

        // Taking the feeManager_ address as argument for now, but ideally this would be hardcoded in the debtLocker migrator registered in the factory
        ( address feeManager_ ) = decodeArguments(msg.data);

        _feeManager = feeManager_;

        IMapleFeeManagerLike(feeManager_).updateDelegateFeeTerms(0, __deprecated_delegateFee);
        IMapleFeeManagerLike(feeManager_).updatePlatformServiceFee(_principalRequested, _paymentInterval);

        IERC20(_fundsAsset).approve(_feeManager, type(uint256).max);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleLoanV4Migrator {

    function encodeArguments(address feeManager_) external returns (bytes memory encodedArguments_);

    function decodeArguments(bytes calldata encodedArguments_) external returns (address feeManager_);

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