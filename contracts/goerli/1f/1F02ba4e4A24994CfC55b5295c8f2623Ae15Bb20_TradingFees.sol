// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceChecker.sol";
import "./TradingFees.sol";

/// @notice Library SafeMath used to prevent overflows and underflows
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exchange is Ownable {
    using SafeMath for uint256; //for prevention of integer overflow
    PriceChecker priceChecker;
    TradingFees tradingFees;
    Wallet wallet;

    uint256 decimals = 10 ** 18;
    address public ethToken = address(0);
    address public aETH = address(0x22404B0e2a7067068AcdaDd8f9D586F834cCe2c5);

    //Token Address List available in DEX
    _tokenInfo[] public tokenList;

    //s_orderBook mappping: tokenAddress -> Side -> Order Array
    mapping(address => mapping(uint256 => _Order[])) public s_orderBook;

    mapping(address => mapping(uint256 => _filledOrder[]))
        public s_filledOrders;

    uint256 public s_orderId = 0;
    bool private s_isManual = true;

    struct _tokenInfo {
        address add;
        uint256 decimals;
    }

    struct _fillOrderValues {
        uint256 rate;
        uint256 amount;
    }

    //Structs representing an order that has unique id, user and amounts to give and get between two tokens to exchange
    struct _Order {
        uint256 id;
        Side side;
        address user;
        address tokenA;
        uint256 amountA;
        address tokenB;
        uint256 amountB;
        uint256 rate; // TokenB/TokenA = price in terms of TokenB
        uint256 originalAmountA;
        uint256 originalAmountB;
        bool waiveFees;
    }

    //For any order that is filled even if it is partially filled or fully filled
    struct _filledOrder {
        uint256 id;
        Side side;
        address user;
        address tokenA;
        address tokenB;
        uint256 amountFilled;
        uint256 fillRate;
        uint256 originalRate;
        uint256 originalAmountA;
        uint256 originalAmountB;
        bool feesWaived;
        uint256 feesPaid; //in terms of ETH
    }

    enum Side {
        BUY,
        SELL
    }

    //add events
    /// @notice Event when an order is placed on an exchange
    event Order(
        uint256 id,
        Side side,
        address user,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        uint256 rate,
        uint256 originalAmountA,
        uint256 originalAmountB,
        bool waiveFees
    );

    /// @notice Event when an order is cancelled
    event Cancel(
        uint256 id,
        Side side,
        address user,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        uint256 rate,
        uint256 originalAmountA,
        uint256 originalAmountB,
        bool waiveFees
    );

    event fillBuyOrder(
        _Order remainingOrder,
        uint256 amountBought,
        uint256 fillBuyRate,
        bool feesWaived,
        uint256 feesPaid
    );

    event fillSellOrder(
        _Order remainingOrder,
        uint256 amountSold,
        uint256 fillSellRate,
        bool feesWaived,
        uint256 feesPaid
    );

    function createLimitBuyOrder(
        // TokenA/TokenB
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB,
        uint256 _rate,
        bool _waiveFees
    ) external validToken(_tokenA) validToken(_tokenB) {
        //Amount user has deposited in the DEX must be >= value he wants to buy
        require(
            wallet.balanceOf(_tokenB, msg.sender).sub(
                wallet.getlockedFunds(msg.sender, _tokenB)
            ) >= _amountB,
            "Insufficient Funds"
        );

        wallet.updateLockedFunds(msg.sender, _tokenB, _amountB, true);

        s_orderBook[_tokenA][uint256(Side.BUY)].push(
            _Order(
                s_orderId,
                Side.BUY,
                msg.sender,
                _tokenA,
                _amountA,
                _tokenB,
                _amountB,
                _rate,
                _amountA,
                _amountB,
                _waiveFees
            )
        );

        emit Order(
            s_orderId,
            Side.BUY,
            msg.sender,
            _tokenA,
            _amountA,
            _tokenB,
            _amountB,
            _rate,
            _amountA,
            _amountB,
            _waiveFees
        );

        s_orderId = s_orderId.add(1);
    }

    function createLimitSellOrder(
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB,
        uint256 _rate,
        bool _waiveFees
    ) external validToken(_tokenA) validToken(_tokenB) {
        //Amount of tokens user deposit in DEX must be >= the amount of tokens they want to sell
        require(
            wallet.balanceOf(_tokenA, msg.sender).sub(
                wallet.getlockedFunds(msg.sender, _tokenA)
            ) >= _amountA,
            "Insufficient Funds"
        );

        //Lock the funds (tokens) in the wallet
        wallet.updateLockedFunds(msg.sender, _tokenA, _amountA, true);

        s_orderBook[_tokenA][uint256(Side.SELL)].push(
            _Order(
                s_orderId,
                Side.SELL,
                msg.sender,
                _tokenA,
                _amountA,
                _tokenB,
                _amountB,
                _rate,
                _amountA,
                _amountB,
                _waiveFees
            )
        );

        emit Order(
            s_orderId,
            Side.SELL,
            msg.sender,
            _tokenA,
            _amountA,
            _tokenB,
            _amountB,
            _rate,
            _amountA,
            _amountB,
            _waiveFees
        );

        s_orderId = s_orderId.add(1);
    }

    function cancelOrder(
        Side side,
        uint256 _id,
        address _token
    ) public validOrder(_id, side, _token) validToken(_token) {
        _Order[] storage _order = s_orderBook[_token][uint256(side)];
        uint256 size = _order.length;
        _Order memory order;

        uint256 index;
        for (uint256 i = 0; i < size; i++) {
            if (_order[i].id == _id) {
                index = i;
                order = _order[i];
                break;
            }
        }

        //Manual cancellation of orders
        if (s_isManual) {
            require(msg.sender == order.user, "Not Owner");

            //Unlock funds
            if (side == Side.BUY) {
                wallet.updateLockedFunds(
                    msg.sender,
                    order.tokenB,
                    order.amountB,
                    false
                );
            } else if (side == Side.SELL) {
                wallet.updateLockedFunds(
                    msg.sender,
                    order.tokenA,
                    order.amountA,
                    false
                );
            }
        }

        for (uint256 j = index; j < size - 1; j++) {
            _order[j] = _order[j.add(1)];
        }
        delete _order[size.sub(1)];
        _order.pop();

        s_orderBook[_token][uint256(side)] = _order;

        emit Cancel(
            _id,
            order.side,
            order.user,
            order.tokenA,
            order.amountA,
            order.tokenB,
            order.amountB,
            order.rate,
            order.originalAmountA,
            order.originalAmountB,
            order.waiveFees
        );
    }

    function fillOrder(
        Side side,
        uint256 _id,
        address _token,
        _fillOrderValues memory a
    ) internal validOrder(_id, side, _token) validToken(_token) {
        uint256 _side = uint256(side);
        (_Order memory order, uint256 index) = getOrderFromArray(
            _token,
            _side,
            _id
        );

        require(order.amountA >= a.amount, "Invalid Order Amount to fill");

        order.amountA = order.amountA.sub(a.amount);
        order.amountB = order.amountB.sub(
            order.rate.mul(a.amount).div(decimals)
        );
        s_orderBook[_token][_side][index].amountA = order.amountA;
        s_orderBook[_token][_side][index].amountB = order.amountB;

        uint256 fees = tradingFees.calculateFees(
            a.amount,
            a.rate,
            order.tokenB
        ); //fees in terms of USD value 18dp
        bool feesWaived = order.waiveFees &&
            tradingFees.checkSufficientaDAI(fees, order.user);

        if (side == Side.BUY) {
            fillBuyOrders(order, a.amount, a.rate, feesWaived, fees);
            emit fillBuyOrder(order, a.amount, a.rate, feesWaived, fees);
        } else if (side == Side.SELL) {
            fillSellOrders(order, a.amount, a.rate, feesWaived, fees);
            emit fillSellOrder(order, a.amount, a.rate, feesWaived, fees);
        }

        if (order.amountA == 0) {
            s_isManual = false;
            cancelOrder(side, order.id, order.tokenA); //remove filled orders
            s_isManual = true;
        }
    }

    function fillBuyOrders(
        _Order memory order,
        uint256 _amount,
        uint256 _rate,
        bool feesWaived,
        uint256 fees
    ) internal {
        if (feesWaived) {
            //Deduct aDAI
            uint256 aDAIToDeduct = tradingFees.amountaDAIToDeduct(fees);
            wallet.updateBalance(
                tradingFees.aDAI(),
                order.user,
                aDAIToDeduct,
                false
            );
            //Credit Bought tokens
            wallet.updateBalance(order.tokenA, order.user, _amount, true);
        } else {
            uint256 amountTokenToDeduct = tradingFees.amountTokensToDeduct(
                order.tokenA,
                fees
            );
            //Credit Bought tokens after minusing fees
            wallet.updateBalance(
                order.tokenA,
                order.user,
                _amount.sub(amountTokenToDeduct),
                true
            );
        }

        //Original Locked Funds unlocked
        wallet.updateLockedFunds(
            order.user,
            order.tokenB,
            (order.rate.mul(_amount)).div(decimals),
            false
        );

        //buyer update
        //Buyer balance deducted from what he paid
        wallet.updateBalance(
            order.tokenB,
            order.user,
            (_rate.mul(_amount)).div(decimals),
            false
        );

        s_filledOrders[order.user][0].push(
            _filledOrder(
                order.id,
                order.side,
                order.user,
                order.tokenA,
                order.tokenB,
                _amount,
                _rate,
                order.rate,
                order.originalAmountA,
                order.originalAmountB,
                feesWaived,
                fees
            )
        );
    }

    function fillSellOrders(
        _Order memory order,
        uint256 _amount,
        uint256 _rate,
        bool feesWaived,
        uint256 fees
    ) internal {
        if (feesWaived) {
            //Deduct aETH
            uint256 aDAIToDeduct = tradingFees.amountaDAIToDeduct(fees);
            wallet.updateBalance(aETH, order.user, aDAIToDeduct, false);
            //Credit Earned tokens
            wallet.updateBalance(
                order.tokenB,
                order.user,
                (_rate.mul(_amount)).div(decimals),
                true
            );
        } else {
            uint256 amountTokensToDeduct = tradingFees.amountTokensToDeduct(
                order.tokenB,
                fees
            );
            //Credit Earned tokens after minusing fees
            wallet.updateBalance(
                order.tokenB,
                order.user,
                (_rate.mul(_amount)).div(decimals).sub(amountTokensToDeduct),
                true
            );
        }

        wallet.updateLockedFunds(order.user, order.tokenA, _amount, false);
        //seller update
        wallet.updateBalance(order.tokenA, order.user, _amount, false);
    }

    function matchOrders(
        address _token,
        uint256 _id,
        Side side
    ) internal validOrder(_id, side, _token) validToken(_token) {
        uint256 saleTokenAmt;

        if (side == Side.BUY) {
            //Retrieve sell order to match
            _Order[] memory _sellOrder = s_orderBook[_token][1];
            for (uint256 i = 0; i < _sellOrder.length; i++) {
                //Retrieve buy order to be filled
                (_Order memory buyOrderToFill, ) = getOrderFromArray(
                    _token,
                    uint8(side),
                    _id
                );
                //sell order hit buyer's limit price & tokenB matches
                if (
                    _sellOrder[i].rate <= buyOrderToFill.rate &&
                    buyOrderToFill.tokenB == _sellOrder[i].tokenB
                ) {
                    _Order memory sellOrder = _sellOrder[i];
                    //if buyer's amount to buy > seller's amount to sell
                    if (buyOrderToFill.amountA > sellOrder.amountA) {
                        saleTokenAmt = sellOrder.amountA;
                    }
                    //if seller's amount to sell >= buyer's amount to buy
                    else if (buyOrderToFill.amountA <= sellOrder.amountA) {
                        saleTokenAmt = buyOrderToFill.amountA;
                    }

                    //Verify current balance
                    require(
                        wallet.balanceOf(
                            buyOrderToFill.tokenB,
                            buyOrderToFill.user
                        ) >= (saleTokenAmt.mul(sellOrder.rate)).div(decimals),
                        "Insufficient Buyer Token Balance"
                    );
                    require(
                        wallet.balanceOf(_token, sellOrder.user) >=
                            saleTokenAmt,
                        "Insufficient Seller Token Balance"
                    );

                    //update orders
                    _fillOrderValues memory fillOrderValues = _fillOrderValues(
                        sellOrder.rate,
                        saleTokenAmt
                    );
                    fillOrder(Side.BUY, _id, _token, fillOrderValues);
                    fillOrder(Side.SELL, sellOrder.id, _token, fillOrderValues);
                }

                bool orderExist = orderExists(_id, side, _token);
                if (!orderExist) break;
            }
        } else if (side == Side.SELL) {
            //Retrieve buy order to match
            _Order[] memory _buyOrder = s_orderBook[_token][0];
            for (uint256 i = 0; i < _buyOrder.length; i++) {
                //Retrieve sell order to be filled
                (_Order memory sellOrderToFill, ) = getOrderFromArray(
                    _token,
                    1,
                    _id
                );
                //sell order hit buyer's limit price
                if (
                    _buyOrder[i].rate >= sellOrderToFill.rate &&
                    _buyOrder[i].tokenB == sellOrderToFill.tokenB
                ) {
                    _Order memory order = _buyOrder[i];

                    //if seller's amount to sell > buyer's amount to buy
                    if (sellOrderToFill.amountA > order.amountA) {
                        saleTokenAmt = order.amountA;
                    }
                    //if buyer's amount to buy > seller's amount to sell
                    else if (sellOrderToFill.amountA <= order.amountA) {
                        saleTokenAmt = sellOrderToFill.amountA;
                    }
                    //Verify current balance
                    require(
                        wallet.balanceOf(_token, sellOrderToFill.user) >=
                            saleTokenAmt,
                        "Insufficient Seller Token Balance"
                    );
                    require(
                        wallet.balanceOf(order.tokenB, order.user) >=
                            (saleTokenAmt.mul(order.rate)).div(decimals),
                        "Insufficient Buyer Token Balance"
                    );

                    //update orders
                    _fillOrderValues memory fillOrderValues = _fillOrderValues(
                        order.rate,
                        saleTokenAmt
                    );
                    fillOrder(Side.SELL, _id, _token, fillOrderValues);
                    fillOrder(Side.BUY, order.id, _token, fillOrderValues);
                }
                bool orderExist = orderExists(_id, side, _token);
                if (!orderExist) break;
            }
        }
    }

    function getOrderLength(
        Side side,
        address _token
    ) public view returns (uint256) {
        return s_orderBook[_token][uint256(side)].length;
    }

    // function getOrder(
    //     address _token,
    //     uint256 index,
    //     Side side
    // )
    //     public
    //     view
    //     returns (
    //         uint256, //id
    //         uint256, //Side
    //         address, //user
    //         address, //tokenA
    //         uint256, //amountA
    //         address, //tokenB
    //         uint256, //amountB
    //         uint256, //rate -> TokenB/TokenA
    //         uint256, //originalAmountA
    //         uint256, //originalAmountB
    //         bool //feesWaived enabled
    //     )
    // {
    //     _Order memory order = s_orderBook[_token][uint256(side)][index];
    //     return (
    //         order.id,
    //         uint256(order.side),
    //         order.user,
    //         order.tokenA,
    //         order.amountA,
    //         order.tokenB,
    //         order.amountB,
    //         order.rate,
    //         order.originalAmountA,
    //         order.originalAmountB,
    //         order.waiveFees
    //     );
    // }

    function getFilledOrderLength(
        address _user,
        Side side
    ) public view returns (uint256) {
        return s_filledOrders[_user][uint256(side)].length;
    }

    // function getFilledOrder(
    //     address _user,
    //     Side side,
    //     uint256 index
    // )
    //     public
    //     view
    //     returns (
    //         uint256, //id
    //         uint256, //side
    //         address, //user
    //         address, //tokenA
    //         address, //tokenB
    //         uint256, //amountFilled
    //         uint256, //fillRate
    //         uint256, //originalRate
    //         uint256, //originalAmountA
    //         uint256, //originalAmountB
    //         bool, //feesWaived
    //         uint256 //feesPaid
    //     )
    // {
    //     _filledOrder memory filledOrder = s_filledOrders[_user][uint256(side)][
    //         index
    //     ];
    //     return (
    //         filledOrder.id,
    //         uint256(filledOrder.side),
    //         filledOrder.user,
    //         filledOrder.tokenA,
    //         filledOrder.tokenB,
    //         filledOrder.amountFilled,
    //         filledOrder.fillRate,
    //         filledOrder.originalRate,
    //         filledOrder.originalAmountA,
    //         filledOrder.originalAmountB,
    //         filledOrder.feesWaived,
    //         filledOrder.feesPaid
    //     );
    // }

    function getOrderFromArray(
        address _token,
        uint256 side,
        uint256 _id
    ) public view returns (_Order memory, uint256) {
        uint256 i = 0;
        _Order[] memory _order = s_orderBook[_token][side];
        _Order memory order;
        for (i; i < _order.length; i++) {
            if (_order[i].id == _id) {
                order = _order[i];
                break;
            }
        }
        return (order, i);
    }

    function orderExists(
        uint256 _id,
        Side side,
        address _token
    ) public view returns (bool) {
        _Order[] memory orders = s_orderBook[_token][uint256(side)];

        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function addToken(address _token, uint256 _decimals) public onlyOwner {
        require(!isVerifiedToken(_token), "Token already verified");
        tokenList.push(_tokenInfo(_token, _decimals));
    }

    function isVerifiedToken(address _token) public view returns (bool) {
        //uint256 size = tokenList.length;

        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i].add == _token) return true;
        }
        return false;
    }

    function getTokenInfo(address _token) public view returns (uint256) {
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i].add == _token) {
                return tokenList[i].decimals;
            }
        }
    }

    modifier validOrder(
        uint256 _id,
        Side side,
        address _token
    ) {
        require(orderExists(_id, side, _token), "Invalid Order ID");
        _;
    }

    modifier validToken(address _token) {
        require(isVerifiedToken(_token), "Token unavailable in DEX");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256 remaining);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(
        address spender,
        uint256 subtractedValue
    ) external returns (bool success);

    function increaseApproval(
        address spender,
        uint256 addedValue
    ) external returns (bool success);

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(
        address to,
        uint256 value
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceChecker is Ownable {
    _priceFeed[] public priceFeeds;

    struct _priceFeed {
        string name;
        address token;
        AggregatorV3Interface priceFeed;
    }

    //only using PriceFeeds pegged to USD
    function addPriceFeed(
        string memory _name,
        address _token,
        address _address
    ) external onlyOwner {
        _priceFeed[] memory pricefeed = priceFeeds;
        bool isAdded = false;
        for (uint256 i = 0; i < pricefeed.length; i++) {
            if (
                keccak256(abi.encodePacked(_name)) ==
                keccak256(abi.encodePacked(pricefeed[i].name))
            ) {
                isAdded = true;
                break;
            }
        }
        require(!isAdded, "Price Feed already added");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_address);
        priceFeeds.push(_priceFeed(_name, _token, priceFeed));
    }

    function getPriceFeed(
        address _token
    ) internal view returns (AggregatorV3Interface priceFeed) {
        _priceFeed[] memory pricefeed = priceFeeds;

        for (uint256 i = 0; i < pricefeed.length; i++) {
            if (_token == pricefeed[i].token) {
                return pricefeed[i].priceFeed;
            }
        }
    }

    function getPrice(address _address) external view returns (uint256) {
        AggregatorV3Interface priceFeed = getPriceFeed(_address);
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceChecker.sol";
import "./Wallet.sol";
import "./Exchange.sol";

/// @notice Library SafeMath used to prevent overflows and underflows
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TradingFees is Ownable {
    //This wallet holds the trading fees collected
    //When trading, have an option toggle to waive trading fees or not using deposited aETH
    //Users have to first deposit aETH tokens into the Exchange contract to waive, aETH tokens are not for trading
    //When a trade order goes through, trading fees of the trade fulfilled  = trade amount x trade price x 0.01,
    //contract checks how much aETH is deposited and what is the value of aETH, if sufficient to waive fees fully, deduct balance in deposit
    //and waive trading fees

    using SafeMath for uint256; //for prevention of integer overflow

    uint256 decimals = 10 ** 18;
    address public daiToken =
        address(0xBa8DCeD3512925e52FE67b1b5329187589072A55); //based on Aave contract
    address public aDAI = address(0xADD98B0342e4094Ec32f3b67Ccfd3242C876ff7a); //based on Aave contract
    PriceChecker priceFeed;
    Wallet wallet;
    Exchange exchange;

    function calculateFees(
        uint256 _amount,
        uint256 _rate,
        address _refToken
    ) public view returns (uint256) {
        //Calculated based on TokenB price, require actual price in 18dp
        //trading fees is 0.1% of trade = 0.001
        //moving up 18dp is 0.001 x 10**18 = 10**14
        //have to fetch tokenPrice from PriceFeed
        uint256 priceOfToken = priceFeed.getPrice(_refToken).mul(10 ** 10); //in 8dp originally
        uint256 value = (((_amount.mul(_rate)).div(decimals)).mul(priceOfToken))
            .div(decimals);
        uint256 fees = value.div(10 ** 4);

        return uint256(fees); //based on USD value
    }

    //Amount of DAI to deduct from fees
    function amountaDAIToDeduct(uint256 _fees) public view returns (uint256) {
        uint256 aDAI_Price = priceFeed.getPrice(daiToken).mul(10 ** 10); // in 8 decimals initially
        uint256 amt = _fees.mul(decimals).div(aDAI_Price);
        return uint256(amt);
    }

    //Amount of Tokens to deduct from fees
    function amountTokensToDeduct(
        address _refToken,
        uint256 _fees
    ) public view returns (uint256) {
        uint256 priceOfToken = priceFeed.getPrice(_refToken).mul(10 ** 10); //in 8decimals
        uint256 amt = _fees.mul(decimals).div(priceOfToken);
        return uint256(amt);
    }

    function checkSufficientaDAI(
        uint256 _fees,
        address _user
    ) public view returns (bool) {
        uint256 amtDAI = amountaDAIToDeduct(_fees);
        uint256 balance = wallet.s_tokens(aDAI, _user);

        return balance >= amtDAI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IERC20.sol";
import "./Exchange.sol";

/// @notice Library SafeMath used to prevent overflows and underflows
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
    using SafeMath for uint256; //for prevention of integer overflow

    address public immutable Owner;

    //For prevention of reentrancy
    bool private locked;

    address public ethToken = address(0);
    address public aETH = address(0x22404B0e2a7067068AcdaDd8f9D586F834cCe2c5);

    mapping(address => mapping(address => uint256)) public s_tokens; //tokenAdress -> msg.sender -> tokenAmt
    mapping(address => mapping(address => uint256)) public lockedFunds;

    Exchange exchange;
    IERC20 token;

    event Deposit(address token, address user, uint256 amount, uint256 balance);

    /// @notice Event when amount withdrawn exchange
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );

    constructor() {
        Owner = msg.sender;
    }

    function depositETH() external payable {
        updateBalance(ethToken, msg.sender, msg.value, true);

        emit Deposit(
            ethToken,
            msg.sender,
            msg.value,
            balanceOf(ethToken, msg.sender)
        );
    }

    function withdrawETH(uint256 _amount) external {
        require(
            balanceOf(ethToken, msg.sender).sub(
                getlockedFunds(msg.sender, ethToken)
            ) >= _amount,
            "Insufficient balance ETH to withdraw"
        );
        require(!locked, "Reentrant call detected!");
        locked = true;
        updateBalance(ethToken, msg.sender, _amount, false);
        locked = false;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "failed to send amount");

        emit Withdraw(
            ethToken,
            msg.sender,
            _amount,
            balanceOf(ethToken, msg.sender)
        );
    }

    //from and transferFrom is from ERC20 contract
    //_token should be an ERC20 token
    function depositToken(
        address _token,
        uint256 _amount,
        uint256 _decimals
    ) external {
        require(_token != ethToken);
        require(
            exchange.isVerifiedToken(_token),
            "Token not verified on Exchange"
        );
        //need to add a check to prove that it is an ERC20 token
        token = IERC20(_token);

        //Requires approval first
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "No Approval yet"
        );
        uint256 decimals = 18;
        if (_decimals == 18) {
            updateBalance(_token, msg.sender, _amount, true);
        } else
            updateBalance(
                _token,
                msg.sender,
                _amount.mul(10 ** decimals.sub(_decimals)),
                true
            );

        emit Deposit(
            _token,
            msg.sender,
            _amount,
            balanceOf(_token, msg.sender)
        );
    }

    function withdrawToken(
        address _token,
        uint256 _amount,
        uint256 _decimals
    ) external {
        require(_token != ethToken);
        require(
            exchange.isVerifiedToken(_token),
            "Token not verified on Exchange"
        );

        require(
            balanceOf(_token, msg.sender).sub(
                getlockedFunds(msg.sender, _token)
            ) >= _amount,
            "Insufficient Tokens to withdraw"
        );
        require(!locked, "Reentrant call detected!");
        locked = true;

        token = IERC20(_token);
        uint256 decimals = 18;
        if (_decimals == 18) {
            updateBalance(_token, msg.sender, _amount, false);
            require(token.transfer(msg.sender, _amount));
        } else {
            updateBalance(
                _token,
                msg.sender,
                _amount.mul(10 ** decimals.sub(_decimals)),
                false
            );
            require(
                token.transfer(
                    msg.sender,
                    _amount.div(10 ** decimals.sub(_decimals))
                )
            );
        }

        locked = false;
        emit Withdraw(
            _token,
            msg.sender,
            _amount,
            balanceOf(_token, msg.sender)
        );
    }

    function getlockedFunds(
        address _user,
        address _token
    ) public view returns (uint256) {
        return lockedFunds[_user][_token];
    }

    function updateLockedFunds(
        address _user,
        address _token,
        uint256 _amount,
        bool isAdd
    ) public isAuthorised {
        if (isAdd) {
            lockedFunds[_user][_token] = lockedFunds[_user][_token].add(
                _amount
            );
        } else if (!isAdd) {
            lockedFunds[_user][_token] = lockedFunds[_user][_token].sub(
                _amount
            );
        }
    }

    //balance of specific tokens in the dex owned by specific user
    function balanceOf(
        address _token,
        address _user
    ) public view returns (uint256) {
        return s_tokens[_token][_user];
    }

    function updateBalance(
        address _token,
        address _user,
        uint256 _amount,
        bool isAdd
    ) public isAuthorised {
        if (isAdd) {
            s_tokens[_token][_user] = s_tokens[_token][_user].add(_amount);
        } else if (!isAdd) {
            s_tokens[_token][_user] = s_tokens[_token][_user].sub(_amount);
        }
    }

    function updateExchangeAddress(
        address _exchangeAddress
    ) external onlyOwner {
        exchange = Exchange(_exchangeAddress);
    }

    modifier isAuthorised() {
        require(
            msg.sender == address(this) || msg.sender == address(exchange),
            "Unauthorised Function Call"
        );
        _;
    }
}