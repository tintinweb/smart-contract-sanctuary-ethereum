// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vesting {
    using SafeMath for uint8;
    using SafeMath for uint256;

    address public token;
    address public operator;
    uint256 public start;
    uint256 public cliff;
    uint256 public duration;

    struct LockVesting {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 currentBalance;
        bool revoked;
    }

    mapping(address => LockVesting) public beneficiaries;

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not a operator");
        _;
    }

    constructor(
        address _token,
        address _operator,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration
    ) {
        require(_token != address(0), "_token address is required");
        require(_operator != address(0), "_operator address is required");
        require(_start != 0, "_start time is required");
        require(_cliff != 0, "_cliff time is required");
        require(_duration != 0, "_duration time is required");
        token = _token;
        operator = _operator;
        start = _start;
        cliff = _cliff;
        duration = _duration;
    }

    /// @notice This function it's executed by the operator and grants
    /// the vesting for the beneficiary.
    /// @param _beneficiary is the beneficiary address.
    /// @param _amount the amount of tokens that will be locked in the vesting/
    function grantVesting(address _beneficiary, uint256 _amount)
        external
        onlyOperator
    {
        require(_amount != 0, "_amount is required");
        require(_beneficiary != address(0), "_beneficiary address is required");
        require(
            beneficiaries[_beneficiary].totalAmount == 0,
            "_beneficiary already has a vesting"
        );

        beneficiaries[_beneficiary].totalAmount = _amount;
        beneficiaries[_beneficiary].currentBalance = _amount;
    }

    /// @notice This function it's executed by the beneficiaries to claim the
    /// vested tokens at a given moment in the time.
    function withdraw() external {
        require(
            beneficiaries[msg.sender].totalAmount != 0,
            "caller is not a beneficiary"
        );
        require(
            !beneficiaries[msg.sender].revoked,
            "vesting for beneficiary was revoked"
        );
        uint256 unreleased = _releasableAmount(msg.sender);
        require(
            unreleased > 0,
            "account has already withdrawn all the funds enabled for this cliff"
        );

        beneficiaries[msg.sender].releasedAmount = beneficiaries[msg.sender]
            .releasedAmount
            .add(unreleased);
        beneficiaries[msg.sender].currentBalance = beneficiaries[msg.sender]
            .currentBalance
            .sub(unreleased);

        require(
            IERC20(token).transfer(msg.sender, unreleased),
            "token transfer fail"
        );
    }

    /// @notice Allows the operator to revoke the vesting. All Tokens from the
    /// current balance of a particular beneficiary are returned to the operator.
    /// @param _beneficiary is the beneficiary address.
    function revoke(address _beneficiary) external onlyOperator {
        require(
            !beneficiaries[_beneficiary].revoked,
            "vesting is already revoked"
        );
        require(
            beneficiaries[_beneficiary].currentBalance != 0,
            "_beneficiary address has not balance"
        );

        uint256 refund = beneficiaries[_beneficiary].currentBalance;

        beneficiaries[_beneficiary].currentBalance = 0;
        beneficiaries[_beneficiary].revoked = true;

        require(
            IERC20(token).transfer(operator, refund),
            "token transfer fail"
        );
    }

    /// @notice This function it's executed by the beneficiaries to check the
    /// state of the vesting.
    /// @dev This function returns a tuple with the following values:
    ///  releasableAmount = amount of tokens available to withdraw in current
    ///  interval.
    ///  totalAmount = the total amount of the vesting.
    ///  releasedAmount = the amount of tokens that has already vested.
    function vestingDetails(address _beneficiary)
        external
        view
        returns (
            uint256 releasableAmount,
            uint256 totalAmount,
            uint256 currentBalance,
            uint256 releasedAmount,
            bool revoked
        )
    {
        releasableAmount = _releasableAmount(_beneficiary);
        totalAmount = beneficiaries[_beneficiary].totalAmount;
        releasedAmount = beneficiaries[_beneficiary].releasedAmount;
        revoked = beneficiaries[_beneficiary].revoked;
        currentBalance = beneficiaries[_beneficiary].currentBalance;
    }

    function _releasableAmount(address _beneficiary)
        internal
        view
        returns (uint256)
    {
        uint256 releasableAmount =
            _vestedAmount(_beneficiary).sub(
                beneficiaries[_beneficiary].releasedAmount
            );
        uint256 fivePercentage =
            beneficiaries[_beneficiary].totalAmount.mul(5).div(100);
        return releasableAmount.sub(releasableAmount.mod(fivePercentage));
    }

    function _vestedAmount(address _beneficiary)
        internal
        view
        returns (uint256)
    {
        LockVesting memory lock = beneficiaries[_beneficiary];
        uint256 totalBalance = lock.currentBalance.add(lock.releasedAmount);
        uint256 time = _currentTime();

        if (time < start.add(cliff)) {
            return 0;
        } else if (time >= start.add(duration) || lock.revoked) {
            return totalBalance;
        } else {
            // totalBalance * (currentTime - start) / duration
            return totalBalance.mul(time.sub(start)).div(duration);
        }
    }

    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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