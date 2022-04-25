/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: NONE

pragma solidity >=0.6.0 <0.8.0;
pragma solidity 0.7.0;
pragma solidity 0.7.0;
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;
pragma solidity 0.7.0;


// 
// File: @openzeppelin/contracts/math/SafeMath.sol
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

// File: interfaces/ICricStoxTreasury.sol
interface ICricStoxTreasury {
    function userWithdraw(address token_, address user_, uint256 amount_) external;
    function userDeposit(address token_, address user_, uint256 amount_) external;
}

// File: interfaces/ICricStoxCurve.sol
interface ICricStoxCurve {
    function AreaUnderCurve(uint256 ll,uint256 ul) external view returns (uint256);
}

// File: interfaces/ICricStoxOrderHistory.sol
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

// File: interfaces/IPlayerStoxToken.sol
interface IPlayerStoxToken {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function mint(address account_, uint256 amount_) external returns (bool);

  function burn(address account_, uint256 amount_) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

// File: CricStoxMaster.sol
contract CricStoxMaster {
    using SafeMath for uint256;
    enum TradeType { BUY, SELL }

    address public baseCurrency;
    address public cricStoxCurveAddress;
    address public cricStoxTreasuryAddress;
    address public cricStoxOrderHistoryAddress;

    /**
        * @dev Constructor function.
        * @param baseCurrency_ The address of base currency for all trades.
        * @param cricStoxCurveAddress_ The address of cricstox curve contract.
        * @param cricStoxTreasuryAddress_ The address of cricstox treasury contract.
        * @param cricStoxOrderHistoryAddress_ The address of order history contract.
        */
    constructor(address baseCurrency_, address cricStoxCurveAddress_, address cricStoxTreasuryAddress_, address cricStoxOrderHistoryAddress_) {
        baseCurrency = address(baseCurrency_);
        cricStoxCurveAddress = address(cricStoxCurveAddress_);
        cricStoxTreasuryAddress = address(cricStoxTreasuryAddress_);
        cricStoxOrderHistoryAddress = address(cricStoxOrderHistoryAddress_);
    }

    /**
        * @dev Get quote of stox token for a specific quantity.
        * @param stox_ The address of stox token.
        * @param quantity_ The quantity of stox to get quote for.
        * @param tradeType_ The type of trade.
        */
    function quote(address stox_, uint256 quantity_, TradeType tradeType_) public view returns (uint256) {
        uint256 totalSupply = IPlayerStoxToken(stox_).totalSupply();
        uint256 ll = 0;
        uint256 ul = 0;
        if (tradeType_ == TradeType.BUY) {
            ll = totalSupply;
            ul = totalSupply.add(quantity_);
        } else {
            ul = totalSupply;
            ll = totalSupply.sub(quantity_);
        }
        return ICricStoxCurve(cricStoxCurveAddress).AreaUnderCurve(ll, ul);
    }

    /**
        * @dev Buy exact number of stoxs (input is variable, output is fixed).
        * @param stox_ The address of stox token.
        * @param amountMax_ The maximum amount that user is willing to pay.
        * @param quantity_ The quantity of stox that user wants to buy.
        */
    function buyExactStoxForTokens(address stox_, uint amountMax_, uint256 quantity_) external returns (bool) {
        uint256 price = quote(stox_, quantity_, TradeType.BUY);
        uint256 currentAmount = price.mul(quantity_);
        if(currentAmount > amountMax_) {
            ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, currentAmount, quantity_, price, ICricStoxOrderHistory.OrderType.BUY, ICricStoxOrderHistory.OrderStatus.FAIL);
            return false;
        }
        ICricStoxTreasury(cricStoxTreasuryAddress).userDeposit(baseCurrency, msg.sender, currentAmount);
        IPlayerStoxToken token = IPlayerStoxToken(stox_);
        token.mint(msg.sender, quantity_);
        ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, currentAmount, quantity_, price, ICricStoxOrderHistory.OrderType.BUY, ICricStoxOrderHistory.OrderStatus.SUCCESS);
        return true;        
    }

    /**
        * @dev Buy stox for exact number of tokens (input is fixed, output is variable).
        * @param stox_ The address of stox token.
        * @param amount_ The amount that user is willing to pay.
        * @param quantityMin_ The minimum quantity of stox that user wants to buy.
        */
    function buyStoxForExactTokens(address stox_, uint256 amount_, uint256 quantityMin_) external returns (bool) {
        uint256 price = quote(stox_, 0, TradeType.BUY);
        uint256 quantity = amount_.div(price);
        price = quote(stox_, quantity, TradeType.BUY);
        quantity = amount_.div(price);
        if(quantity < quantityMin_) {
            ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, amount_, quantity, price, ICricStoxOrderHistory.OrderType.BUY, ICricStoxOrderHistory.OrderStatus.FAIL);
            return false;
        }
        ICricStoxTreasury(cricStoxTreasuryAddress).userDeposit(baseCurrency, msg.sender, amount_);
        IPlayerStoxToken token = IPlayerStoxToken(stox_);
        token.mint(msg.sender, quantity);
        ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, amount_, quantity, price, ICricStoxOrderHistory.OrderType.BUY, ICricStoxOrderHistory.OrderStatus.SUCCESS);
        return true;        
    }

    /**
        * @dev Sell exact number of stox (input is fixed, output is variable).
        * @param stox_ The address of stox token.
        * @param amountMin_ The minimum amount that user is willing to get.
        * @param quantity_ The quantity of stox that user wants to sell.
        */
    function sellExactStoxForTokens(address stox_, uint256 amountMin_, uint256 quantity_) external returns (bool) {
        uint256 price = quote(stox_, quantity_, TradeType.SELL);
        uint256 currentAmount = price.mul(quantity_);
        if(currentAmount < amountMin_) {
            ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, currentAmount, quantity_, price, ICricStoxOrderHistory.OrderType.SELL, ICricStoxOrderHistory.OrderStatus.FAIL);
            return false;
        }
        ICricStoxTreasury(cricStoxTreasuryAddress).userWithdraw(baseCurrency, msg.sender, currentAmount);
        IPlayerStoxToken token = IPlayerStoxToken(stox_);
        token.burn(msg.sender, quantity_);
        ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, currentAmount, quantity_, price, ICricStoxOrderHistory.OrderType.SELL, ICricStoxOrderHistory.OrderStatus.SUCCESS);
        return true;        
    }

    /**
        * @dev Sell stox to get exact number of tokens (input is variable, output is fixed).
        * @param stox_ The address of stox token.
        * @param amount_ The amount that user is willing to get.
        * @param quantityMax_ The maximum quantity of stox that user wants to sell.
        */
    function sellStoxForExactTokens(address stox_, uint256 amount_, uint256 quantityMax_) external returns (bool) {
        uint256 price = quote(stox_, 0, TradeType.SELL);
        uint256 quantity = amount_.div(price);
        price = quote(stox_, quantity, TradeType.SELL);
        quantity = amount_.div(price);
        if(quantity > quantityMax_) {
            ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, amount_, quantity, price, ICricStoxOrderHistory.OrderType.SELL, ICricStoxOrderHistory.OrderStatus.FAIL);
            return false;
        }
        ICricStoxTreasury(cricStoxTreasuryAddress).userWithdraw(baseCurrency, msg.sender, amount_);
        IPlayerStoxToken token = IPlayerStoxToken(stox_);
        token.burn(msg.sender, quantity);
        ICricStoxOrderHistory(cricStoxOrderHistoryAddress).saveOrder(msg.sender, stox_, baseCurrency, amount_, quantity, price, ICricStoxOrderHistory.OrderType.SELL, ICricStoxOrderHistory.OrderStatus.SUCCESS);
        return true;        
    }

}