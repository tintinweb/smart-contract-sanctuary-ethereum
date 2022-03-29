/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: NONE

pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;


// 
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

// 
interface ICricStoxFactory {
    function getPlayerStox(address playerStox_) external view returns (bool);
    function playerStoxsLength() external view returns (uint256);
    function playerStoxAtIndex(uint256 index_) external view returns (address);
}

// 
interface ICricStoxMaster {
    enum TradeType {
        BUY,
        SELL
    }

    function quote(
        address stox_,
        uint256 quantity_,
        TradeType tradeType_
    ) external view returns (uint256);

    function buyExactStoxForTokens(
        address stox_,
        address token_,
        uint256 amountMax_,
        uint256 quantity_
    ) external returns (bool);

    function buyStoxForExactTokens(
        address stox_,
        address token_,
        uint256 amount_,
        uint256 quantityMin_
    ) external returns (bool);

    function sellExactStoxForTokens(
        address stox_,
        address token_,
        uint256 amountMin_,
        uint256 quantity_
    ) external returns (bool);

    function sellStoxForExactTokens(
        address stox_,
        address token_,
        uint256 amount_,
        uint256 quantityMax_
    ) external returns (bool);
}

// 
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

// 
interface ICricStoxOrderHistory {
    enum OrderStatus { SUCCESS, FAIL }
    enum OrderType { BUY, SELL }

    struct OrderInfo {
        address user;
        address stox;
        address token;
        uint256 amount;
        uint256 quantity;
        uint256 timestamp;
        uint256 priceAfter;
        OrderType orderType;
        OrderStatus orderStatus;
    }

    function saveOrder(address user_, address stox_, address token_, uint256 amount_, uint256 quantity_, uint256 priceAfter_, OrderType orderType_, OrderStatus orderStatus_) external;
    function userOrdersLength(address user_) external view returns (uint256);
    function tokenOrderAtIndex(address token_, uint256 index_) external view returns (OrderInfo memory);
    function userOrderAtIndex(address user_, uint256 index_) external view returns (OrderInfo memory);
}

// 
contract CricStoxHelper {
    using SafeMath for uint256;

    address public cricStoxFactoryAddress;
    address public cricStoxMasterAddress;
    address public cricStoxOrderHistoryAddress;

    constructor(address cricStoxFactoryAddress_, address cricStoxMasterAddress_, address cricStoxOrderHistoryAddress_) {
        cricStoxFactoryAddress = cricStoxFactoryAddress_;
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
        cricStoxOrderHistoryAddress = address(cricStoxOrderHistoryAddress_);
    }

    function getUserOrders(address user_) public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 numOfOrders = ICricStoxOrderHistory(cricStoxOrderHistoryAddress)
            .userOrdersLength(user_);
        address[] memory stox = new address[](numOfOrders);
        uint256[] memory amount = new uint256[](numOfOrders);
        uint256[] memory quantity = new uint256[](numOfOrders);
        for (uint256 i = 0; i < numOfOrders; i++) {
            ICricStoxOrderHistory.OrderInfo memory currentOrder = ICricStoxOrderHistory(cricStoxOrderHistoryAddress).userOrderAtIndex(user_, i);
            stox[i] = currentOrder.stox;
            amount[i] = currentOrder.amount;
            quantity[i] = currentOrder.quantity;
        }
        return (stox, amount, quantity);
    }

    function getUserOrdersDetails(address user_) public view returns (uint256[] memory, uint256[] memory, ICricStoxOrderHistory.OrderType[] memory, ICricStoxOrderHistory.OrderStatus[] memory) {
        uint256 numOfOrders = ICricStoxOrderHistory(cricStoxOrderHistoryAddress)
            .userOrdersLength(user_);
        uint256[] memory priceAfter = new uint256[](numOfOrders);
        uint256[] memory timestamp = new uint256[](numOfOrders);
        ICricStoxOrderHistory.OrderType[] memory orderType = new ICricStoxOrderHistory.OrderType[](numOfOrders);
        ICricStoxOrderHistory.OrderStatus[] memory orderStatus = new ICricStoxOrderHistory.OrderStatus[](numOfOrders);
        for (uint256 i = 0; i < numOfOrders; i++) {
            ICricStoxOrderHistory.OrderInfo memory currentOrder = ICricStoxOrderHistory(cricStoxOrderHistoryAddress).userOrderAtIndex(user_, i);
            priceAfter[i] = currentOrder.priceAfter;
            timestamp[i] = currentOrder.timestamp;
            orderType[i] = currentOrder.orderType;
            orderStatus[i] = currentOrder.orderStatus;
        }
        return (priceAfter, timestamp, orderType, orderStatus);
    }

    function getUserStoxsHoldings(address user_) public view returns (address[] memory, uint256[] memory) {
        uint256 numOfStoxs = ICricStoxFactory(cricStoxFactoryAddress)
            .playerStoxsLength();
        address[] memory stoxs = new address[](numOfStoxs);
        uint256[] memory balances = new uint256[](numOfStoxs);
        uint256 count = 0;
        for (uint256 i = 0; i < numOfStoxs; i++) {
            address currentStox = ICricStoxFactory(cricStoxFactoryAddress).playerStoxAtIndex(i);
            uint256 blnc = IERC20(currentStox).balanceOf(user_);
            if (blnc > 0) {
                stoxs[count] = currentStox;
                balances[count] = blnc;
                count = count + 1;
            }
        }
        return (stoxs, balances);
    }
}