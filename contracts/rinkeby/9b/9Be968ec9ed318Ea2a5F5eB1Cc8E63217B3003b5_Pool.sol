/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/Pool3.sol


pragma solidity ^0.8.7;



contract Pool {
    using SafeMath for uint256;

    uint256 public DUMMY_MUL = 100000;
    mapping(address => mapping(address => uint256)) public rates;

    function setDummyMul(uint256 dummy_mul) public {
        DUMMY_MUL = dummy_mul;
    }

    // rate was multiple with DUMMY_MUL
    function setRating(
        address token1,
        address token2,
        uint256 rate
    ) public {
        rates[token1][token2] = rate;
        rates[token2][token1] = (DUMMY_MUL * DUMMY_MUL) / rate;
    }

    function _safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) private {
        bool sent = token.transfer(to, amount);
        require(sent, "Token transfer failed");
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance less than amount");
        bool sent = token.transferFrom(from, to, amount);
        require(sent, "Token transfer failed");
    }

    // user transfer native token -> Pool -> transfer other token to user
    function addNativeTokenToPool() public payable {
        require(msg.value > 0, "You need to send some ether");
    }

    // user transfer token -> Pool -> transfer other token to user
    function swapToken(
        address _token1,
        address _token2,
        uint256 amountIn
    ) public {
        require(rates[_token1][_token2] > 0, "You must set rate before swap");
        require(amountIn > 0, "You need to put some tokens to swap");
        IERC20 token1 = IERC20(address(_token1));
        IERC20 token2 = IERC20(address(_token2));

        uint256 amountOut = (amountIn * rates[_token1][_token2]) / DUMMY_MUL;

        uint256 balanceOfSender = token1.balanceOf(msg.sender);
        require(balanceOfSender >= amountIn, "Your balance not enough");
        _safeTransferFrom(token1, msg.sender, address(this), amountIn);

        uint256 balanceOfPool = token2.balanceOf(address(this));
        require(balanceOfPool >= amountOut, "Pool not enough token to swap");
        _safeTransfer(token2, msg.sender, amountOut);
    }

    // user transfer native token -> Pool -> transfer other token to user
    function swapNative2Other(address token1, address token2) public payable {
        require(rates[token1][token2] > 0, "You must set rate before swap");
        require(msg.value > 0, "You need to send some ether");
        IERC20 outputToken = IERC20(address(token2));

        uint256 amountOut = (msg.value * rates[token1][token2]) / DUMMY_MUL;
        uint256 poolBalance = outputToken.balanceOf(address(this));
        require(amountOut <= poolBalance, "Pool not enough token to swap");

        // transfer token to sender
        _safeTransfer(outputToken, msg.sender, amountOut);
    }

    // user transfer token -> Pool -> transfer native token to user
    function swapOther2Native(
        address token1,
        address token2,
        uint256 amountIn
    ) public {
        require(rates[token1][token2] > 0, "You must set rate before swap");
        require(amountIn > 0, "You need to put some tokens to swap");
        IERC20 outputToken = IERC20(address(token1));

        uint256 amountOut = (amountIn * rates[token1][token2]) / DUMMY_MUL;
        uint256 poolBalance = address(this).balance;
        require(amountOut <= poolBalance, "Pool not enough token to swap");

        _safeTransferFrom(outputToken, msg.sender, address(this), amountIn);
        // transfer native token to sender
        payable(msg.sender).transfer(amountOut);
    }
}

/*
OwnerA
0x026C63f4741242E7ac1C83fc9669C52E93cd7D50
TokenA
0x7Ed605AAe8f05B7d981683b2dF7F801197C18EC8

OwnerB
0x837eA6F9c1dbfE0e2EaE30c6630dE5217a66aFdD
TokenB
0x7fEb5812613163AD8ecDa9b31737b749BCD6fbCe

OwnerC
0xd97938F88576eff812191c6177bDBBD265048685
TokenC
0x3b1C0DB67D119AcEc9D2888963677BD59BB8E41B

TokenSwap
0x5D7C29aE376eC8cdbDF1CE60B27fCCF801184ee1
        address _token1,
        address _token2,
        uint256 amountIn,
0x7Ed605AAe8f05B7d981683b2dF7F801197C18EC8, 0x7fEb5812613163AD8ecDa9b31737b749BCD6fbCe, 1000000000000000000, 1500000000000000000  (1 Token)

swap 10 TokenA to 20 Token B
10000000000000000000, 20000000000000000000

setRate for TokenA and TokenB
0x7Ed605AAe8f05B7d981683b2dF7F801197C18EC8, 0x7fEb5812613163AD8ecDa9b31737b749BCD6fbCe, 1.5
*/