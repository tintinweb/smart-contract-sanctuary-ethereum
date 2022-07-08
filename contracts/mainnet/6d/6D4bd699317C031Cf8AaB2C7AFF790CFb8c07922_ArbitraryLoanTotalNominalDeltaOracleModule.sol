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
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
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

/// @title IArbitraryValueOracle Interface
/// @author Enzyme Council <[email protected]>
interface IArbitraryValueOracle {
    function getLastUpdated() external view returns (uint256 lastUpdated_);

    function getValue() external view returns (int256 value_);

    function getValueWithTimestamp() external view returns (int256 value_, uint256 lastUpdated_);
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
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "./IArbitraryLoanAccountingModule.sol";
import "../../../../../../persistent/arbitrary-value-oracles/IArbitraryValueOracle.sol";

/// @title ArbitraryLoanTotalNominalDeltaOracleModule Contract
/// @author Enzyme Council <[email protected]>
/// @notice An accounting module for a loan to apply gains or losses,
/// via an oracle that reports the nominal delta of the total amount borrowed (ignores repayments)
/// @dev This method of reporting value helps to prevent an oracle getting out-of-sync,
/// e.g., when new amounts are borrowed or repaid to the loan
contract ArbitraryLoanTotalNominalDeltaOracleModule is IArbitraryLoanAccountingModule {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    event OracleSetForLoan(
        address indexed loan,
        address indexed oracle,
        uint32 stalenessThreshold
    );

    struct OracleInfo {
        address oracle;
        uint32 stalenessThreshold;
    }

    mapping(address => OracleInfo) private loanToOracleInfo;

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
        return __calcLoanBalance(msg.sender, _totalBorrowed, _totalRepaid);
    }

    /// @notice Configures options per-loan
    /// @param _configData Encoded options
    function configure(bytes memory _configData) external override {
        address loan = msg.sender;
        (address oracle, uint32 stalenessThreshold) = abi.decode(_configData, (address, uint32));
        require(oracle != address(0), "configure: Empty oracle");

        loanToOracleInfo[loan] = OracleInfo({
            oracle: oracle,
            stalenessThreshold: stalenessThreshold
        });

        emit OracleSetForLoan(loan, oracle, stalenessThreshold);
    }

    /// @notice Implements logic immediately prior to effects and interactions during a borrow
    /// @dev Unimplemented
    function preBorrow(
        uint256,
        uint256,
        uint256
    ) external override {}

    /// @notice Implements logic immediately prior to effects and interactions when closing a loan
    /// @dev Unimplemented
    function preClose(uint256, uint256) external override {}

    /// @notice Implements logic immediately prior to effects and interactions during a reconciliation,
    /// and returns the formatted amount to consider as a repayment
    /// @param _repayableLoanAssetAmount The loanAsset amount available for repayment
    /// @return repayAmount_ The formatted amount to consider as repayment in terms of the loanAsset
    /// @dev Should not revert in case of over-repayment.
    /// Instead, it is recommended to return the full loan balance as repayAmount_ where necessary.
    function preReconcile(
        uint256,
        uint256,
        uint256 _repayableLoanAssetAmount,
        address[] calldata
    ) external override returns (uint256 repayAmount_) {
        return _repayableLoanAssetAmount;
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
        // Calc actual repay amount based on user input
        if (_repayAmountInput == type(uint256).max) {
            return __calcLoanBalance(msg.sender, _totalBorrowed, _prevTotalRepaid);
        }

        return _repayAmountInput;
    }

    /// @notice Receives and executes an arbitrary call from the loan contract
    /// @dev No actions implemented in this module
    function receiveCallFromLoan(bytes memory) external override {
        revert("receiveCallFromLoan: Invalid actionId");
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to calculate the loan balance
    function __calcLoanBalance(
        address _loan,
        uint256 _totalBorrowed,
        uint256 _totalRepaid
    ) private view returns (uint256 balance_) {
        OracleInfo memory oracleInfo = getOracleInfoForLoan(_loan);
        int256 oracleValue;

        // Query value and handle staleness threshold as-necessary
        if (oracleInfo.stalenessThreshold > 0) {
            uint256 lastUpdated;
            (oracleValue, lastUpdated) = IArbitraryValueOracle(oracleInfo.oracle)
                .getValueWithTimestamp();

            // Does not assert the staleness threshold if the oracle value is 0
            require(
                oracleInfo.stalenessThreshold >= block.timestamp.sub(lastUpdated) ||
                    oracleValue == 0,
                "calcFaceValue: Stale oracle"
            );
        } else {
            oracleValue = IArbitraryValueOracle(oracleInfo.oracle).getValue();
        }

        int256 totalBalanceInt = int256(_totalBorrowed).add(oracleValue).sub(int256(_totalRepaid));
        if (totalBalanceInt > 0) {
            return uint256(totalBalanceInt);
        }

        return 0;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the OracleInfo for a given loan
    /// @param _loan The loan address
    /// @return oracleInfo_ The oracle info
    function getOracleInfoForLoan(address _loan)
        public
        view
        returns (OracleInfo memory oracleInfo_)
    {
        return loanToOracleInfo[_loan];
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