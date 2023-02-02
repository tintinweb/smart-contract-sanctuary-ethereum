// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/SafeERC20.sol";

contract BSGGPlay is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // round fun rate
    uint256 public roundFundRate;
    // token price rising up period
    uint256 public priceRisingPeriod;
    // token price rising up amount
    uint256 public priceRisingAmount;
    // base price of each round
    uint256 public basePrice;

    // current round id
    uint256 public currentRoundID;
    // latest order id
    uint256 public lastOrderID;
    // total amount of USDT available for Game
    uint256 public totalAmount;

    // Fee owner
    address public feeOwner;
    // fees
    uint256 public withdrawFee;

    // flags
    bool public isGameStarted;
    bool public initialized = false;

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 fund;
    }

    struct Order {
        uint256 id;
        address account;
        uint256 amount;
        uint256 price;
        uint256 time;
    }

    struct UserInfo {
        uint256 rewardAmount;
        uint256[] orderLists;
    }

    struct Snapshot {
        address user;
        uint256 amount;
        uint256 price;
        uint256 time;
        uint256 orderID;
        uint256 roundID;
    }

    // all users mapping : (address => userinfo)
    mapping(address => UserInfo) public users;
    // round array
    Round[] public rounds;
    // snapshot array
    Snapshot[] public snapshots;
    // orders array
    Order[] public orders;

    address public USDT = 0x2903CE865AF3E78925D2d4898552B6280361152C;
    address public aBSGG = 0x22354422655c860F354C3c8Aca2f2d22DB73Fb08;


    event Initialized(address executor, uint256 at);
    event FeeOwnerChanged(address oldOwner, address newOwner);
    event GameStatuChanged(bool started);
    event Invested(uint256 amount);
    event OrderCreated(
        address account,
        uint256 amount,
        uint256 price,
        uint256 time
    );
    event OrderUpdated(address account, uint256 amount, uint256 price);
    event OrderCompleted(address account, uint256 amount, uint256 price);
    event Withdrawed(address account, uint256 amount);
    event GameDetailsUpdated(uint256 rate, uint256 priceRisingPeriod, uint256 priceRisingAmount, uint256 _basePrice);
    event FeeUpdated(uint256 withdrawFee);
    event NewRoundStarted(uint256 roundID);

    modifier onlyFeeOwner() {
        require(feeOwner == msg.sender, "Caller should be the fee owner");
        _;
    }

    modifier notInitialized() {
        require(!initialized, "Game: already initialized");

        _;
    }

    function initialize(address _feeOwner) public notInitialized onlyOwner {
        require(_feeOwner != address(0), "Fee owner should be non-zero address");

        feeOwner = _feeOwner;

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function priceIncreasePerSecond() internal view returns (uint256) {
        require(priceRisingPeriod != 0, "Price rising up period should be non-zero value");
        require(priceRisingAmount != 0, "Price rising up amount should be non-zero value");

        return priceRisingAmount.div(priceRisingPeriod);
    }

    function proceedOrder(Order memory _order) internal returns (bool) {
        Round storage round = rounds[currentRoundID];
        uint256 rewardAmount = _order.amount.mul(_order.price);
        // check this order should be completed or not
        uint256 estimateOrderCompletedTime = round.startTime;
        uint256 orderTempPrice = basePrice;
        while (orderTempPrice < _order.price) {
            orderTempPrice = orderTempPrice.add(priceRisingAmount);
            estimateOrderCompletedTime = estimateOrderCompletedTime.add((priceRisingPeriod));
        }
        if (estimateOrderCompletedTime <= block.timestamp) {
            UserInfo storage user = users[_order.account];
            if (rewardAmount < round.fund) {
                // complete order
                user.rewardAmount = user.rewardAmount.add(rewardAmount);
                round.fund = round.fund.sub(rewardAmount);
                // add completed order to snapshot
                snapshots.push(
                    Snapshot({
                        user: _order.account,
                        amount: _order.amount,
                        price: _order.price,
                        time: estimateOrderCompletedTime,
                        orderID: _order.id,
                        roundID: currentRoundID
                    })
                );
                // remove completed order id from user's order list
                for (uint256 nI = 0; nI < user.orderLists.length; nI++) {
                    if (user.orderLists[nI] == _order.id) {
                        user.orderLists[nI] = user.orderLists[user.orderLists.length - 1];
                        user.orderLists.pop();
                        break;
                    }
                }
            } else {
                // complete sub order
                user.rewardAmount = user.rewardAmount.add(round.fund);
                round.fund = 0;
                round.endTime = estimateOrderCompletedTime;
                // add completed sub order to snapshot
                snapshots.push(
                    Snapshot({
                        user: _order.account,
                        amount: round.fund.div(_order.price),
                        price: _order.price,
                        time: estimateOrderCompletedTime,
                        orderID: _order.id,
                        roundID: currentRoundID
                    })
                );
                // update order info
                _order.amount = _order.amount.sub(round.fund.div(_order.price));
                // start new round
                newRound();
            }
        }

        return false;
    }

    function update() public {
        uint256 length = orders.length;
        for (uint256 index = 0; index < length; ++index) {
            // proceed order
            if (proceedOrder(orders[index])) {
                // remove completed order from arrary
                for (uint256 nI = index; nI < length - 1; nI++) {
                    orders[nI] = orders[nI + 1];
                }
                orders.pop();
                index--;
            } else {
                break;
            }
        }
    }

    function sort() internal {
        uint256 length = orders.length;
        Order storage temp;

        for (uint256 index; index < length - 1; index++) {
            for (uint256 subIndex = index + 1; subIndex < length; subIndex++) {
                if (orders[index].price > orders[subIndex].price) {
                    temp = orders[index];
                    orders[index] = orders[subIndex];
                    orders[subIndex] = temp;
                } else if (
                    (orders[index].price == orders[subIndex].price) &&
                    (orders[index].time < orders[subIndex].time)
                ) {
                    temp = orders[index];
                    orders[index] = orders[subIndex];
                    orders[subIndex] = temp;
                }
            }
        }
    }

    function newRound() internal {
        currentRoundID++;
        rounds.push(
            Round({
                id: currentRoundID,
                startTime: block.timestamp,
                endTime: 0,
                fund: totalAmount.mul(roundFundRate)
            })
        );

        emit NewRoundStarted(currentRoundID);
    }

    function invest(uint256 _amount) public onlyOwner() {
        require(_amount != 0, "invest amount should be non-zero value");

        IERC20(USDT).safeTransferFrom(msg.sender, address(this), _amount);
        totalAmount = totalAmount.add(_amount);

        emit Invested(_amount);
    }

    function withdraw(uint256 _amount) public {
        require(_amount != 0, "withdraw amount should be non-zero value");

        // update order status
        update();

        UserInfo storage user = users[msg.sender];
        if (user.rewardAmount < _amount) {
            _amount = user.rewardAmount;
        }

        if (_amount > 0) {
            if (withdrawFee > 0) {
                uint256 feeAmount = _amount.mul(withdrawFee).div(10000);
                IERC20(USDT).safeTransfer(feeOwner, feeAmount);
                IERC20(USDT).safeTransfer(msg.sender, _amount);
                user.rewardAmount = user.rewardAmount.sub(_amount);
            } else {
                IERC20(USDT).safeTransfer(msg.sender, _amount);
                user.rewardAmount = user.rewardAmount.sub(_amount);
            }
            emit Withdrawed(msg.sender, _amount);
        }
    }

    function createOrder(uint256 _amount, uint256 _price) public {
        require(_amount != 0, "Order amount should be non-zero value");

        UserInfo storage user = users[msg.sender];

        // update order status
        update();

        // create new order
        Order memory order = Order({
            id: lastOrderID,
            account: msg.sender,
            amount: _amount,
            price: _price,
            time: block.timestamp
        });

        // proceed order
        if (!proceedOrder(order)) {
            // add new order to order list
            orders.push(order);

            // resort order list by price and time
            sort();

            // save order id on user info
            user.orderLists.push(lastOrderID);
        }

        // increase last order id
        lastOrderID = lastOrderID++;

        emit OrderCreated(msg.sender, _amount, _price, block.timestamp);
    }

    function updateOrder(uint256 _orderID, uint256 _price) public {

        UserInfo storage user = users[msg.sender];
        // check order is user's one
        bool isValid = false;
        for (uint256 index = 0; index < user.orderLists.length; index++) {
            if (_orderID == user.orderLists[index]) {
                isValid = true;
                break;
            }
        }

        require(isValid, "User could only his order.");

        // update order status
        update();
        // update order with current timestamp
        for (uint256 index = 0; index < orders.length; index++) {
            if (orders[index].id == _orderID) {
                orders[index].price = _price;
                orders[index].time = block.timestamp;
            }
        }

        // resort order list
        sort();

        // update order status
        update();
    }

    function startGame() public onlyOwner() {
        require(!isGameStarted, "Game is current running.");

        isGameStarted = true;
        emit GameStatuChanged(isGameStarted);

        // start new round
        newRound();
        // update order status
        update();
    }

    function stopGame() public onlyOwner() {
        require(isGameStarted, "Game didn't start.");

        // update order status
        update();

        Round storage round = rounds[currentRoundID - 1];
        round.fund = 0;
        round.endTime = block.timestamp;

        isGameStarted = false;
        emit GameStatuChanged(isGameStarted);
    }

    function setGameDetails(
        uint256 _rate,
        uint256 _priceRisingPeriod,
        uint256 _priceRisingAmount,
        uint256 _basePrice
    ) public onlyOwner() {
        require(!isGameStarted, "Game is current running.");
        require(_rate != 0, "Round fund rate should be non-zero value");
        require(_rate < 10000, "Round fund rate should be less than 10000");
        require(_priceRisingPeriod != 0, "Price rising up period should be non-zero value");
        require(_priceRisingAmount != 0, "Price rising up amount should be non-zero value");

        roundFundRate = _rate;
        priceRisingPeriod = _priceRisingPeriod;
        priceRisingAmount = _priceRisingAmount;
        basePrice = _basePrice;

        emit GameDetailsUpdated(_rate, _priceRisingPeriod, _priceRisingAmount, _basePrice);
    }

    function setFee(uint256 _withdrawFee) public onlyFeeOwner() {
        require(_withdrawFee < 10000, "Withdraw fee should be less than 10000");

        withdrawFee = _withdrawFee;
        emit FeeUpdated(_withdrawFee);
    }

    function setFeeOwner(address _feeOwner) public onlyFeeOwner() {
        require(
            _feeOwner != address(0),
            "Fee owner should be non-zero address"
        );

        emit FeeOwnerChanged(feeOwner, _feeOwner);
        feeOwner = _feeOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC20.sol";

// 
/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
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
pragma solidity 0.8.17;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

    function mint(address _to, uint256 _amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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