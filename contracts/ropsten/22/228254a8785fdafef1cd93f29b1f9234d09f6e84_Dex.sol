/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: contracts/wallet.sol


pragma solidity ^0.8.0;



contract Wallet is Ownable {

    struct Token { //token that will be tradeable on the dex
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokenMapping; //to find the token via the ticker
    bytes32[] public tokenList; //array of the token tickers which is the token list

    mapping(address => mapping(bytes32 => uint256)) public balances; //wallet address => token ticker (in bytes32) => the amount of balance

    modifier tokenExist(bytes32 ticker) {
        require(tokenMapping[ticker].tokenAddress != address(0)); //to make sure the token is not an empty token, but actually something that was deployed
        _;
    }

    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external {
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        balances[msg.sender][ticker] += amount; 
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount); //sending from the msg.sender to the smart contract
    }


    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(balances[msg.sender][ticker] >= amount, "Balance is not sufficient");

        balances[msg.sender][ticker] -= amount;
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount); //withdrawing from this smart contract to the msg.sender
    }

    function depositEth() payable external {
        balances[msg.sender][bytes32("ETH")] += msg.value;
    }
    
    function withdrawEth(uint amount) external {
        require(balances[msg.sender][bytes32("ETH")] >= amount,'Insuffient balance'); 
        balances[msg.sender][bytes32("ETH")] -= amount;
        msg.sender.call{value:amount}("");
    }



}
// File: contracts/dex.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract Dex is Wallet {

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
        if(side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= amount * price, "Balance too low");
        } //buy LINK using ETH
        else if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Balance too low");
        } //sell LINK back to ETH

        Order[] storage orders = orderBook[ticker][uint(side)]; //this is to store the orderBook mapping to orders array
        orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)); //each new Order will be stored to orders array. filled is 0 here since we don't care for limit order, only for market (check below, where filled is only used for market order function)

        //below if-elseif is for bubble sort
        uint i = orders.length > 0 ? orders.length - 1 : 0;

        if(side == Side.BUY){
            while(i > 0){
                if(orders[i - 1].price > orders[i].price) { //basically if the rightmost order is already the most expensive, then it "breaks" or stops. for example if the order[1] is $5 while order [2] is $3, it's already correct that $5 is more expensive than $3 and should be prioritized
                    break;   
                }
                Order memory orderToMove = orders[i - 1]; //these 4 lines basically "sort" the order based on which one is the most expensive (the rightmost should be the highest buy order)
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        else if (side == Side.SELL){ //same logic as side BUY but in reverse since this is about sell
            while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                    break;   
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        nextOrderId++;

    }

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
        }

        uint orderBookSide;
        if (side == Side.BUY) {
            orderBookSide = 1; //orderBookSide = 1 means sell orders, so the buy side is connected directly to sell orders
        }
        else {
            orderBookSide = 0; //this is the opposite, if sell side = will be connected to buy orders (orderBookSide = 0)
        }

        Order[] storage orders = orderBook[ticker][orderBookSide]; //this is to store the orderBook mapping to orders array but from market orders
    
        uint totalFilled = 0; //since market order might take multiple orders to fill, we need to know totalFilled that the market order takes

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount - totalFilled; 
            uint availableToFill = orders[i].amount - orders[i].filled;
            uint filled = 0; //filled order
            
            if (availableToFill > leftToFill) {
                filled = leftToFill;
            } else {
                filled = availableToFill;
            }

            totalFilled += filled;
            orders[i].filled += filled;
            uint cost = filled * orders[i].price;

            if (side == Side.BUY) {
                //verify the buyer has enough ETH
                require(balances[msg.sender]["ETH"] >= cost);
                //msg.sender is the buyer
                balances[msg.sender][ticker] += filled;
                balances[msg.sender]["ETH"] -= cost;

                balances[orders[i].trader][ticker] -= filled;
                balances[orders[i].trader]["ETH"] += cost;
            }   else if (side == Side.SELL) {
                //msg.sender is the seller
                balances[msg.sender][ticker] -= filled;
                balances[msg.sender]["ETH"] += cost;

                balances[orders[i].trader][ticker] += filled;
                balances[orders[i].trader]["ETH"] -= cost;
            }

        }

        //Loop through the orderbook and remove 100% filled orders
        while(orders.length > 0 && orders[0].filled == orders[0].amount) {

            for(uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
        //the while loop above basically removes all the orderbooks that are all filled by the market orders
        //for example, if there are 2 orders that have the price of 1 ETH per token, and market order sweep out these 2 orders at the price of 1 ETH, the while loop will "delete" these 2 orders with the pop function and move up the next orders (with more expensive price) to the top of the orderbook. the while loop stops when there is no more order that get sweeped at once at the same price
    }



}