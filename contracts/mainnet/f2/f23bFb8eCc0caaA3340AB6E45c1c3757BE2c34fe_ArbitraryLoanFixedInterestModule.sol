// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "../../../../../utils/MakerDaoMath.sol";
import "../../../../../utils/MathHelpers.sol";
import "./IArbitraryLoanAccountingModule.sol";

/// @title ArbitraryLoanFixedInterestModule Contract
/// @author Enzyme Council <[email protected]>
/// @notice An accounting module for a loan to apply fixed interest tracking
contract ArbitraryLoanFixedInterestModule is
    IArbitraryLoanAccountingModule,
    MakerDaoMath,
    MathHelpers
{
    using SafeCast for uint256;
    using SafeMath for uint256;

    enum RepaymentTrackingType {None, PrincipalFirst, InterestFirst}

    event ConfigSetForLoan(
        address indexed loan,
        uint256 scaledPerSecondRatePreMaturity,
        uint256 scaledPerSecondRatePostMaturity,
        uint256 maturity,
        RepaymentTrackingType repaymentTrackingType,
        bool faceValueIsPrincipalOnly
    );

    event TotalPrincipalRepaidUpdatedForLoan(address indexed loan, uint256 totalPrincipalRepaid);

    event TotalInterestUpdatedForLoan(address indexed loan, uint256 totalInterest);

    // The scaled rate representing 99.99% is under 1e28,
    // thus `uint96` (8e28) is sufficient for any reasonable interest rate
    struct AccountingInfo {
        // Var packed
        uint128 totalInterestCached;
        uint32 totalInterestCachedTimestamp;
        uint96 scaledPerSecondRatePreMaturity;
        // Var packed
        uint96 scaledPerSecondRatePostMaturity;
        uint32 maturity;
        // Squashed to uint112 (5e33) to fit remaining vars in one slot
        uint112 totalPrincipalRepaid;
        RepaymentTrackingType repaymentTrackingType;
        bool faceValueIsPrincipalOnly;
    }

    uint256 private constant INTEREST_SCALED_PER_SECOND_RATE_BASE = 10**27;

    mapping(address => AccountingInfo) private loanToAccountingInfo;

    /////////////////////
    // CALLS FROM LOAN //
    /////////////////////

    /// @notice Calculates the canonical face value of the loan
    /// @param _totalBorrowed The total borrowed amount
    /// @param _totalRepaid The total repaid amount
    /// @return faceValue_ The face value
    function calcFaceValue(uint256 _totalBorrowed, uint256 _totalRepaid)
        external
        view
        override
        returns (uint256 faceValue_)
    {
        address loan = msg.sender;
        AccountingInfo memory accountingInfo = getAccountingInfoForLoan(loan);

        if (accountingInfo.faceValueIsPrincipalOnly) {
            return _totalBorrowed.sub(accountingInfo.totalPrincipalRepaid);
        }

        return
            __calcLoanBalance(
                _totalBorrowed,
                _totalRepaid,
                uint256(accountingInfo.totalInterestCached).add(
                    __calcUncachedInterest(loan, _totalBorrowed, _totalRepaid)
                )
            );
    }

    /// @notice Configures options per-loan
    /// @param _configData Encoded options
    function configure(bytes memory _configData) external override {
        address loan = msg.sender;
        (
            uint96 scaledPerSecondRatePreMaturity,
            uint96 scaledPerSecondRatePostMaturity,
            uint32 maturity,
            RepaymentTrackingType repaymentTrackingType,
            bool faceValueIsPrincipalOnly
        ) = abi.decode(_configData, (uint96, uint96, uint32, RepaymentTrackingType, bool));

        // Maturity should either be empty or in the future.
        // If empty, then force pre- and post-maturity rates to be the same for clarity.
        require(
            maturity > block.timestamp ||
                (maturity == 0 &&
                    scaledPerSecondRatePreMaturity == scaledPerSecondRatePostMaturity),
            "configure: Post-maturity rate without valid maturity"
        );

        // If using face value = principal only, must specify a method for tracking repayments
        require(
            !faceValueIsPrincipalOnly || repaymentTrackingType != RepaymentTrackingType.None,
            "configure: Invalid face value config"
        );

        loanToAccountingInfo[loan] = AccountingInfo({
            totalInterestCached: 0,
            totalInterestCachedTimestamp: 0,
            scaledPerSecondRatePreMaturity: scaledPerSecondRatePreMaturity,
            scaledPerSecondRatePostMaturity: scaledPerSecondRatePostMaturity,
            maturity: maturity,
            totalPrincipalRepaid: 0,
            repaymentTrackingType: repaymentTrackingType,
            faceValueIsPrincipalOnly: faceValueIsPrincipalOnly
        });

        emit ConfigSetForLoan(
            loan,
            scaledPerSecondRatePreMaturity,
            scaledPerSecondRatePostMaturity,
            maturity,
            repaymentTrackingType,
            faceValueIsPrincipalOnly
        );
    }

    /// @notice Implements logic immediately prior to effects and interactions during a borrow
    /// @param _prevTotalBorrowed The total borrowed amount not including the new borrow amount
    /// @param _totalRepaid The total repaid amount
    function preBorrow(
        uint256 _prevTotalBorrowed,
        uint256 _totalRepaid,
        uint256
    ) external override {
        __checkpointInterest(msg.sender, _prevTotalBorrowed, _totalRepaid);
    }

    /// @notice Implements logic immediately prior to effects and interactions when closing a loan
    /// @dev Unimplemented
    function preClose(uint256, uint256) external override {}

    /// @notice Implements logic immediately prior to effects and interactions during a reconciliation,
    /// and returns the formatted amount to consider as a repayment
    /// @param _totalBorrowed The total borrowed amount
    /// @param _prevTotalRepaid The total repaid amount not including the reconciled assets
    /// @param _repayableLoanAssetAmount The loanAsset amount available for repayment
    /// @return repayAmount_ The formatted amount to consider as repayment in terms of the loanAsset
    /// @dev Should not revert in case of over-repayment.
    /// Instead, it is recommended to return the full loan balance as repayAmount_ where necessary.
    function preReconcile(
        uint256 _totalBorrowed,
        uint256 _prevTotalRepaid,
        uint256 _repayableLoanAssetAmount,
        address[] calldata
    ) external override returns (uint256 repayAmount_) {
        address loan = msg.sender;

        __checkpointInterest(loan, _totalBorrowed, _prevTotalRepaid);

        uint256 loanBalance = __calcLoanBalance(
            _totalBorrowed,
            _prevTotalRepaid,
            getAccountingInfoForLoan(loan).totalInterestCached
        );

        if (_repayableLoanAssetAmount > loanBalance) {
            // Don't allow an overpayment, to keep principal-based face value sensible
            repayAmount_ = loanBalance;
        } else {
            repayAmount_ = _repayableLoanAssetAmount;
        }

        __reconcilePrincipalRepaid(loan, _totalBorrowed, _prevTotalRepaid, repayAmount_);

        return repayAmount_;
    }

    /// @notice Implements logic immediately prior to effects and interactions during a repay,
    /// and returns the formatted amount to repay (e.g., in the case of a user-input max)
    /// @param _totalBorrowed The total borrowed amount
    /// @param _prevTotalRepaid The total repaid amount not including the new repay amount
    /// @param _repayAmountInput The user-input repay amount
    /// @param repayAmount_ The formatted amount to repay
    function preRepay(
        uint256 _totalBorrowed,
        uint256 _prevTotalRepaid,
        uint256 _repayAmountInput
    ) external override returns (uint256 repayAmount_) {
        address loan = msg.sender;

        __checkpointInterest(loan, _totalBorrowed, _prevTotalRepaid);

        uint256 loanBalance = __calcLoanBalance(
            _totalBorrowed,
            _prevTotalRepaid,
            getAccountingInfoForLoan(loan).totalInterestCached
        );

        // Calc actual repay amount based on user input
        if (_repayAmountInput == type(uint256).max) {
            repayAmount_ = loanBalance;
        } else {
            // Don't allow an overpayment, to keep principal-based face value sensible
            require(_repayAmountInput <= loanBalance, "preRepay: Overpayment");

            repayAmount_ = _repayAmountInput;
        }

        __reconcilePrincipalRepaid(loan, _totalBorrowed, _prevTotalRepaid, repayAmount_);

        return repayAmount_;
    }

    /// @notice Receives and executes an arbitrary call from the loan contract
    /// @dev No actions implemented in this module
    function receiveCallFromLoan(bytes memory) external override {
        revert("receiveCallFromLoan: Invalid actionId");
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to checkpoint total interest
    function __checkpointInterest(
        address _loan,
        uint256 _totalBorrowed,
        uint256 _totalRepaid
    ) private {
        AccountingInfo storage accountingInfo = loanToAccountingInfo[_loan];

        uint256 uncachedInterest = __calcUncachedInterest(_loan, _totalBorrowed, _totalRepaid);
        if (uncachedInterest > 0) {
            uint256 totalInterest = uint256(accountingInfo.totalInterestCached).add(
                uncachedInterest
            );

            accountingInfo.totalInterestCached = totalInterest.toUint128();

            emit TotalInterestUpdatedForLoan(_loan, totalInterest);
        }

        // Always updating the cache timestamp guarantees distinct interest periods are upheld
        accountingInfo.totalInterestCachedTimestamp = uint32(block.timestamp);
    }

    /// @dev Helper to reconcile the amount of a loan's principal that has been repaid during a repayment.
    /// Called after checkpointing interest.
    function __reconcilePrincipalRepaid(
        address _loan,
        uint256 _totalBorrowed,
        uint256 _prevTotalRepaid,
        uint256 _repayAmount
    ) private {
        AccountingInfo memory accountingInfo = getAccountingInfoForLoan(_loan);

        if (accountingInfo.repaymentTrackingType == RepaymentTrackingType.None) {
            return;
        }

        uint256 principalOutstanding = _totalBorrowed.sub(accountingInfo.totalPrincipalRepaid);
        if (principalOutstanding == 0) {
            return;
        }

        uint256 nextTotalPrincipalRepaid;
        if (accountingInfo.repaymentTrackingType == RepaymentTrackingType.PrincipalFirst) {
            // Simulate the effect of repaying the principal before interest

            if (_repayAmount >= principalOutstanding) {
                nextTotalPrincipalRepaid = _totalBorrowed;
            } else {
                nextTotalPrincipalRepaid = uint256(accountingInfo.totalPrincipalRepaid).add(
                    _repayAmount
                );
            }
        } else {
            // RepaymentTrackingType.InterestFirst
            // Simulate the effect of repaying interest before the principal

            // totalInterestCached is already updated
            uint256 prevLoanBalance = __calcLoanBalance(
                _totalBorrowed,
                _prevTotalRepaid,
                accountingInfo.totalInterestCached
            );

            if (_repayAmount >= prevLoanBalance) {
                // Repayment covers full remaining balance
                nextTotalPrincipalRepaid = _totalBorrowed;
            } else {
                // Some of repayment amount is interest
                uint256 interestRemaining = prevLoanBalance.sub(principalOutstanding);

                if (_repayAmount > interestRemaining) {
                    nextTotalPrincipalRepaid = uint256(accountingInfo.totalPrincipalRepaid)
                        .add(_repayAmount)
                        .sub(interestRemaining);
                }
            }
        }

        if (nextTotalPrincipalRepaid > 0) {
            loanToAccountingInfo[_loan].totalPrincipalRepaid = __safeCastUint112(
                nextTotalPrincipalRepaid
            );

            emit TotalPrincipalRepaidUpdatedForLoan(_loan, nextTotalPrincipalRepaid);
        }
    }

    /// @dev Mimics SafeCast logic for uint112
    function __safeCastUint112(uint256 value) private pure returns (uint112 castedValue_) {
        require(value < 2**112, "__safeCastUint112: Value doesn't fit in 112 bits");

        return uint112(value);
    }

    ////////////////
    // LOAN VALUE //
    ////////////////

    /// @dev Helper to calculate continuously-compounded (per-second) interest
    function __calcContinuouslyCompoundedInterest(
        uint256 _loanBalance,
        uint256 _scaledPerSecondRate,
        uint256 _secondsSinceCheckpoint
    ) private pure returns (uint256 interest_) {
        if (_scaledPerSecondRate == 0) {
            return 0;
        }

        return
            _loanBalance
                .mul(
                __rpow(
                    _scaledPerSecondRate,
                    _secondsSinceCheckpoint,
                    INTEREST_SCALED_PER_SECOND_RATE_BASE
                )
                    .sub(INTEREST_SCALED_PER_SECOND_RATE_BASE)
            )
                .div(INTEREST_SCALED_PER_SECOND_RATE_BASE);
    }

    /// @dev Helper to calculate the total loan balance. Ignores over-repayment.
    function __calcLoanBalance(
        uint256 _totalBorrowed,
        uint256 _totalRepaid,
        uint256 _totalInterest
    ) private pure returns (uint256 balance_) {
        return __subOrZero(_totalBorrowed.add(_totalInterest), _totalRepaid);
    }

    /// @dev Helper to calculate uncached interest
    function __calcUncachedInterest(
        address _loan,
        uint256 _totalBorrowed,
        uint256 _totalRepaid
    ) private view returns (uint256 uncachedInterest_) {
        AccountingInfo memory accountingInfo = getAccountingInfoForLoan(_loan);

        if (accountingInfo.totalInterestCachedTimestamp == block.timestamp) {
            return 0;
        }

        uint256 loanBalanceAtCheckpoint = __subOrZero(
            _totalBorrowed.add(accountingInfo.totalInterestCached),
            _totalRepaid
        );
        if (loanBalanceAtCheckpoint == 0) {
            return 0;
        }

        // At this point, there is some loan balance and amount of seconds

        // Use pre-maturity rate if immature or same rates.
        // If maturity == 0, rates will be the same.
        if (
            block.timestamp <= accountingInfo.maturity ||
            accountingInfo.scaledPerSecondRatePreMaturity ==
            accountingInfo.scaledPerSecondRatePostMaturity
        ) {
            return
                __calcContinuouslyCompoundedInterest(
                    loanBalanceAtCheckpoint,
                    accountingInfo.scaledPerSecondRatePreMaturity,
                    block.timestamp.sub(accountingInfo.totalInterestCachedTimestamp)
                );
        }

        // Use post-maturity rate if last checkpoint was also beyond maturity
        if (accountingInfo.totalInterestCachedTimestamp >= accountingInfo.maturity) {
            return
                __calcContinuouslyCompoundedInterest(
                    loanBalanceAtCheckpoint,
                    accountingInfo.scaledPerSecondRatePostMaturity,
                    block.timestamp.sub(accountingInfo.totalInterestCachedTimestamp)
                );
        }

        // At this point, block.timestamp != maturity and totalInterestCachedTimestamp != maturity

        // Otherwise, we need to bifurcate interest into pre- and post-maturity chunks
        uint256 preMaturityInterest = __calcContinuouslyCompoundedInterest(
            loanBalanceAtCheckpoint,
            accountingInfo.scaledPerSecondRatePreMaturity,
            uint256(accountingInfo.maturity).sub(accountingInfo.totalInterestCachedTimestamp)
        );

        uint256 postMaturityInterest = __calcContinuouslyCompoundedInterest(
            loanBalanceAtCheckpoint.add(preMaturityInterest),
            accountingInfo.scaledPerSecondRatePostMaturity,
            block.timestamp.sub(accountingInfo.maturity)
        );

        return preMaturityInterest.add(postMaturityInterest);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the AccountingInfo for a given loan
    /// @param _loan The loan address
    /// @return accountingInfo_ The accounting info
    function getAccountingInfoForLoan(address _loan)
        public
        view
        returns (AccountingInfo memory accountingInfo_)
    {
        return loanToAccountingInfo[_loan];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IArbitraryLoanAccountingModule Interface
/// @author Enzyme Council <[email protected]>
interface IArbitraryLoanAccountingModule {
    /// @notice Calculates the canonical face value of the loan
    /// @param _totalBorrowed The total borrowed amount
    /// @param _totalRepaid The total repaid amount
    /// @return faceValue_ The face value
    function calcFaceValue(uint256 _totalBorrowed, uint256 _totalRepaid)
        external
        view
        returns (uint256 faceValue_);

    /// @notice Configures options per-loan
    /// @param _configData Encoded options
    function configure(bytes memory _configData) external;

    /// @notice Implements logic immediately prior to effects and interactions during a borrow
    /// @param _prevTotalBorrowed The total borrowed amount not including the new borrow amount
    /// @param _totalRepaid The total repaid amount
    /// @param _borrowAmount The new borrow amount
    function preBorrow(
        uint256 _prevTotalBorrowed,
        uint256 _totalRepaid,
        uint256 _borrowAmount
    ) external;

    /// @notice Implements logic immediately prior to effects and interactions when closing a loan
    /// @param _totalBorrowed The total borrowed amount
    /// @param _totalRepaid The total repaid amount
    function preClose(uint256 _totalBorrowed, uint256 _totalRepaid) external;

    /// @notice Implements logic immediately prior to effects and interactions during a reconciliation,
    /// and returns the formatted amount to consider as a repayment
    /// @param _totalBorrowed The total borrowed amount
    /// @param _prevTotalRepaid The total repaid amount not including the reconciled assets
    /// @param _repayableLoanAssetAmount The loanAsset amount available for repayment
    /// @param _extraAssets The extra assets (non-loanAsset) being swept to the VaultProxy
    /// @return repayAmount_ The formatted amount to consider as repayment in terms of the loanAsset
    /// @dev Should not revert in case of over-repayment.
    /// Instead, it is recommended to return the full loan balance as repayAmount_ where necessary.
    /// _extraAssets allows a module to use its own pricing to calculate the value of each
    /// extra asset in terms of the loanAsset, which can be included in the repayAmount_.
    function preReconcile(
        uint256 _totalBorrowed,
        uint256 _prevTotalRepaid,
        uint256 _repayableLoanAssetAmount,
        address[] calldata _extraAssets
    ) external returns (uint256 repayAmount_);

    /// @notice Implements logic immediately prior to effects and interactions during a repay,
    /// and returns the formatted amount to repay (e.g., in the case of a user-input max)
    /// @param _totalBorrowed The total borrowed amount
    /// @param _prevTotalRepaid The total repaid amount not including the new repay amount
    /// @param _repayAmountInput The user-input repay amount
    /// @return repayAmount_ The formatted amount to repay
    function preRepay(
        uint256 _totalBorrowed,
        uint256 _prevTotalRepaid,
        uint256 _repayAmountInput
    ) external returns (uint256 repayAmount_);

    /// @notice Receives and executes an arbitrary call from the loan contract
    /// @param _actionData Encoded data for the arbitrary call
    function receiveCallFromLoan(bytes memory _actionData) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

/// @title MakerDaoMath Contract
/// @author Enzyme Council <[email protected]>
/// @notice Helper functions for math operations adapted from MakerDao contracts
abstract contract MakerDaoMath {
    /// @dev Performs scaled, fixed-point exponentiation.
    /// Verbatim code, adapted to our style guide for variable naming only, see:
    /// https://github.com/makerdao/dss/blob/master/src/pot.sol#L83-L105
    // prettier-ignore
    function __rpow(uint256 _x, uint256 _n, uint256 _base) internal pure returns (uint256 z_) {
        assembly {
            switch _x case 0 {switch _n case 0 {z_ := _base} default {z_ := 0}}
            default {
                switch mod(_n, 2) case 0 { z_ := _base } default { z_ := _x }
                let half := div(_base, 2)
                for { _n := div(_n, 2) } _n { _n := div(_n,2) } {
                    let xx := mul(_x, _x)
                    if iszero(eq(div(xx, _x), _x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    _x := div(xxRound, _base)
                    if mod(_n,2) {
                        let zx := mul(z_, _x)
                        if and(iszero(iszero(_x)), iszero(eq(div(zx, _x), z_))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z_ := div(zxRound, _base)
                    }
                }
            }
        }

        return z_;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title MathHelpers Contract
/// @author Enzyme Council <[email protected]>
/// @notice Helper functions for common math operations
abstract contract MathHelpers {
    using SafeMath for uint256;

    /// @dev Calculates a proportional value relative to a known ratio.
    /// Caller is responsible as-necessary for:
    /// 1. validating _quantity1 to be non-zero
    /// 2. validating relativeQuantity2_ to be non-zero
    function __calcRelativeQuantity(
        uint256 _quantity1,
        uint256 _quantity2,
        uint256 _relativeQuantity1
    ) internal pure returns (uint256 relativeQuantity2_) {
        return _relativeQuantity1.mul(_quantity2).div(_quantity1);
    }

    /// @dev Helper to subtract uint amounts, but returning zero on underflow instead of reverting
    function __subOrZero(uint256 _amountA, uint256 _amountB) internal pure returns (uint256 res_) {
        if (_amountA > _amountB) {
            return _amountA - _amountB;
        }

        return 0;
    }
}