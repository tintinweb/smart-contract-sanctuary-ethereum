// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Exchange is Ownable {

//    State Variables
bytes32[] public tokenList;
address payable private immutable i_owner;
uint256 private s_nextOrderId;
uint256 private s_nextTradeId;
bytes32 private constant c_DAI = bytes32("DAI");
uint256 private balance;

// Mapping
mapping(bytes32 => Token) private tokens;
mapping(bytes32 => mapping(uint256 => Order[])) private s_orderBook;
mapping(address => mapping(bytes32 => uint256)) private s_traderBalances;

// Modifiers
modifier tokenIsNotDai(bytes32 ticker) {
    require(ticker != c_DAI, "cannot trade DAI");
    _;
}

modifier tokenExist(bytes32 ticker) { 
    require(tokens[ticker].tickerAddress != address(0), "Token does not exist");
    _;
}

// Events
event TransferReceived(address _from, uint256 _amount);
event NewTrade(
                uint tradeId,
                uint orderId,
                bytes32 indexed ticker,
                address indexed trader1,
                address indexed trader2,                
                uint amount,
                uint price,
                uint date
            );

// Enums
enum Status {
    BUY,
    SELL
}

// Struct
struct Token {
    bytes32 ticker;
    address tickerAddress;
}

struct Order {
    uint256 id;
    address trader;
    Status status;
    bytes32 ticker;
    uint256 amount;
    uint256 filled;
    uint256 price;
    uint256 date;
}

// constructor
constructor() {
    i_owner = payable(msg.sender);
}

/**
* @dev receive ETH to this contract
*/
receive() external payable {
    balance += msg.value;
    emit TransferReceived(msg.sender, msg.value);
}

fallback() external payable {}

/**
* @dev add ERC20 Token to this contract
*/
function addToken(bytes32 ticker, address tickerAddress) external onlyOwner() {
    tokens[ticker] = Token(ticker, tickerAddress);
    tokenList.push(ticker);
}

/**
* @dev deposit ERC20 Token to this contract
*/
function deposit(bytes32 ticker, uint256 amount) external tokenExist(ticker) {
    IERC20(tokens[ticker].tickerAddress).transferFrom(payable(msg.sender), address(this), amount);
    s_traderBalances[msg.sender][ticker] += amount;
}

function withdraw(bytes32 ticker, uint amount) external tokenExist(ticker) {   
    require(s_traderBalances[msg.sender][ticker] >= amount, "balance too low");
    s_traderBalances[msg.sender][ticker] -= amount;
    IERC20(tokens[ticker].tickerAddress).transfer(payable(msg.sender), amount);
}

/**
* @dev createLimitOrder - buy token at a queue price
* Order[] - array for the queue ticker and set by status(0-BUY/1-SELL)
*/
function createLimitOrder(
    bytes32 ticker, 
    uint256 amount, 
    uint256 price, 
    Status status) 
    external 
    tokenExist(ticker) 
    tokenIsNotDai(ticker) 
    {
        if(status == Status.SELL) {
            require(s_traderBalances[msg.sender][ticker] >= amount, "balance too low"); 
        }
        else {
            require(s_traderBalances[msg.sender][c_DAI] >= amount, "Dai balance too low");
        }
        Order[] storage orders = s_orderBook[ticker][uint(status)];
        orders.push(Order(
            s_nextOrderId,
            msg.sender,
            status,
            ticker,
            amount,
            0,
            price,
            block.timestamp
        ));

        uint i = orders.length > 0 ? orders.length - 1 : 0;
        while (i > 0) {
            if(status == Status.BUY && orders[i - 1].price > orders[i].price) {
                break;
            }
            if(status == Status.SELL && orders[i - 1].price < orders[i].price) {
                break;
            }

            Order memory order = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = order;
            i--;
        }
        s_nextOrderId++;
    }

/**
* @dev createMarketOrder - buy token at available market price
* available - the amount that are available at selling price
* matched - the selling price
* remaining - the remaining amount at the matched price
* while (j) - the array of order that need to remove the last element after the order has been filled
*/
function createMarketOrder(
    bytes32 ticker, 
    uint256 amount, 
    Status status) 
    tokenExist(ticker) 
    tokenIsNotDai(ticker) 
    external 
    {
        if(status == Status.SELL) {
            require(s_traderBalances[msg.sender][ticker] >= amount, "balance too low");
        }
        Order[] storage orders = s_orderBook[ticker][uint(status == Status.BUY ? Status.SELL : Status.BUY)];
        uint256 i;
        uint256 remaining = amount;

        while(i < orders.length && remaining > 0) {
            uint256 available = orders[i].amount - orders[i].filled;
            uint matched = (remaining > available) ? available : remaining;
            remaining -= matched;
            orders[i].filled += matched;
            emit NewTrade(
                s_nextOrderId,
                orders[i].id,
                ticker,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                block.timestamp
            );

            if(status == Status.SELL) {
                s_traderBalances[msg.sender][ticker] -= matched;
                s_traderBalances[msg.sender][c_DAI] += matched * orders[i].price;
                s_traderBalances[orders[i].trader][ticker] += matched;
                s_traderBalances[orders[i].trader][c_DAI] -= matched * orders[i].price;
            }

            if(status == Status.BUY) {
                require(s_traderBalances[msg.sender][c_DAI] >= matched * orders[i].price, "Dai balance too low");
                s_traderBalances[msg.sender][ticker] += matched;
                s_traderBalances[msg.sender][c_DAI] -= matched * orders[i].price;
                s_traderBalances[orders[i].trader][ticker] -= matched;
                s_traderBalances[orders[i].trader][c_DAI] += matched * orders[i].price;
            }
            s_nextTradeId++;
            i++;
        }
        i = 0;
        while(i < orders.length && orders[i].filled == orders[i].amount) {
            for(uint j = i; j < orders.length - 1; j++) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }

    }


function getBalance(bytes32 ticker) external view returns(uint256) {
    return s_traderBalances[msg.sender][ticker];
}

/**
* @dev getOrders - the of orders of the orderbook
*/
function getOrders(bytes32 ticker, Status status) external view returns(Order[] memory) {
    return s_orderBook[ticker][uint(status)];
}

/**
* @dev getTokens - the frontend will need to get the list of tokens that can be traded
*/
function getTokens() external view returns (Token[] memory) {
    Token[] memory _tokens = new Token[](tokenList.length);
    for(uint i = 0; i < tokenList.length; i++) {
        _tokens[i] = Token(
            tokens[tokenList[i]].ticker,
            tokens[tokenList[i]].tickerAddress
        );
    }
    return _tokens;
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