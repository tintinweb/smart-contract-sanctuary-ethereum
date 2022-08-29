pragma solidity ^0.8.4;

import './Order.sol';

interface IOrder {
     function initialize(uint256 _orderId, address _user, address _tokenGive, uint256 _amountGive, address _tokenGet, uint256 _amountGet) external;
     function returnDeposit() external;
     function confirmBalance() external returns (bool confirmation);
     function sendOrderAmount(address _to) external;
     function user() external returns (address);
     function getBalance() external view returns(uint256);
     function decimals() external view returns(uint8);
}

contract OrderRegistry {

    uint256 tradeCount;
    uint256 orderCount;
    mapping(address => uint256[]) public getOrdersGivenUser;
    address[] public allOrders;
    Trade[] public allTrades;

    struct Trade{
        uint256 tradeId;
        IOrder order1;
        IOrder order2;
        // @TODO are these approvals needed?
        bool approval1;
        bool approval2;
        bool complete;
    }

    // @TODO what other front end functionalities are needed?
    event TradeCreated(address indexed orderA, address indexed orderB);
    event OrderCreated(address indexed user, address indexed order);

    constructor(){
        //fill in index 0, ids will start at 1
        allOrders.push(0x000000000000000000000000000000000000dEaD);
        allTrades.push(Trade(0, IOrder(0x000000000000000000000000000000000000dEaD), IOrder(0x000000000000000000000000000000000000dEaD), false, false, false));
    }

    /**
     * @notice deploys a order contract using create2 then initializes with given data.  Should be called by owner creating the order
     */
    function createOrder(address _tokenGive, address _tokenGet, uint256 _amountGive, uint256 _amountGet) public returns(address order, uint256 orderId){
        orderCount += 1;
        orderId = orderCount;
        bytes memory bytecode = type(Order).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(orderId, msg.sender));
        assembly {
            order := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IOrder(order).initialize(orderId, msg.sender, _tokenGive, _amountGive, _tokenGet, _amountGet);
        getOrdersGivenUser[msg.sender].push(orderId);
        allOrders.push(order);
        emit OrderCreated(msg.sender, order);
    }

    /**
     * @notice creates a trade given two order IDs.  Should be called by ATS matching engine
     */
    function createTrade(uint256 _orderA, uint256 _orderB) public returns(uint256 tradeId) {
        require(_orderA != 0 && _orderB != 0, "INVALID ORDER ID (0)");
        (IOrder firstOrder, IOrder secondOrder) = allOrders[_orderA] < allOrders[_orderB] ? 
            (IOrder(allOrders[_orderA]), IOrder(allOrders[_orderB])) :
            (IOrder(allOrders[_orderB]), IOrder(allOrders[_orderA]));
        tradeCount += 1;
        tradeId = tradeCount;
        Trade memory trade = Trade(tradeId, firstOrder, secondOrder, false, false, false);
        allTrades.push(trade);
        emit TradeCreated(address(firstOrder), address(secondOrder));
    }

    function getAllOrders() public view returns (address[] memory) {
        return allOrders;
    }
    /**
     * @notice return the number of total orders
     */
    function numOrders() public view returns (uint256 orders) {
        orders = allOrders.length;
    }

    /**
     * @notice used by front end to get multiple orders specified by startIndex and endIndex offsets.
     */
    function getOrders(uint256 _startIndex, uint256 _endIndex) public view returns(address[] memory) {
        address[] memory orders = new address[](_endIndex - _startIndex);
        uint256 j = 0;
        for(uint i = _startIndex; i <= _endIndex; i++) {
            orders[j] = allOrders[i];
            j++;
        }
        return orders;
    }

    /**
     * @notice get a single order given orderId
     */
    function getOrder(uint256 _orderId) public view returns(address) {
        return allOrders[_orderId];
    }

    function numTrades() public view returns (uint256 trades) {
        trades = allTrades.length;
    }

    function getTrades(uint256 _startIndex, uint256 _endIndex) public view returns(Trade[] memory) {
        Trade[] memory trades = new Trade[](_endIndex - _startIndex);
        uint256 j = 0;
        for(uint i = _startIndex; i <= _endIndex; i++) {
            trades[j] = allTrades[i];
            j++;
        }
        return trades;
    }

    function getTrade(uint256 _tradeId) public view returns (Trade memory) {
        return allTrades[_tradeId];
    }

    function returnDepositForOrder(address _order) public {
        IOrder(_order).returnDeposit();
    }

    function executeTrade(uint256 _tradeId) public {}

    function getOrderBalance(uint256 _orderId) public view returns(uint256 balance) {
        return IOrder(allOrders[_orderId]).getBalance();
    }

    function getDecimals(uint256 _orderId) public view returns(uint8 decimals) {
        decimals = IOrder(allOrders[_orderId]).decimals();
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20 is IERC20 {
    function decimals() external view returns(uint8);
}

contract Order {

    address public registry;
    uint256 public orderId;
    address public user;
    address public tokenGive;
    address public tokenGet;
    uint256 public amountGive;
    uint256 public amountGet;
    uint256 public startTime;
    bool public traded;

    constructor() {
        registry = msg.sender;
    }

    function initialize(
        uint256 _orderId,
        address _user,
        address _tokenGive,
        uint256 _amountGive,
        address _tokenGet,
        uint256 _amountGet
    ) external {
        require(msg.sender == registry, 'Order : FORBIDDEN');
        startTime = block.timestamp;
        orderId = _orderId;
        user = _user;
        tokenGive = _tokenGive;
        amountGive = _amountGive;
        tokenGet = _tokenGet;
        amountGet = _amountGet;
    }

    /**
     * @notice this function will transfer the balance of the deposited token to the address given (only registry may call)
     */
    function transferBalanceTo(address _to) external {
        require(msg.sender == registry, "UNAUTHORIZED");
        uint256 balance = ERC20(tokenGive).balanceOf(address(this));
        ERC20(tokenGive).transfer(_to, balance);
    }

    /**
     * @notice simple verification to check if adequate balance was deposited for the order
     */
    function confirmBalance() external view returns (bool confirmation) {
        confirmation = ERC20(tokenGive).balanceOf(address(this)) >= amountGive ? true : false;
    }

    /**
     * @notice external function that returns any balance left on the order back to the user (only registry may call)
     */
    function returnDeposit() external {
        require(msg.sender == registry, "UNAUTHORIZED");
        uint256 balance = ERC20(tokenGive).balanceOf(address(this));
        require(balance > 0);
        ERC20(tokenGive).transfer(user, balance);
    }

    function sendOrderAmount(address _to) external {
        require(msg.sender == registry, "UNAUTHORIZED");
        ERC20(tokenGive).transfer(_to, amountGive);
    }

    function getBalance() public view returns (uint256) {
        return ERC20(tokenGive).balanceOf(address(this));
    }

    function balanceOf(address account) public view returns (uint256) {
        if(msg.sender == user) {
            return getBalance();
        } else {
            return 0;
        }
    }

    function name() public view returns(string memory) {
        return string(abi.encodePacked("OATSOrder", uint2str(orderId)));
    }

    function symbol() public view returns(string memory) {
        return string(abi.encodePacked("OATSORDR", uint2str(orderId)));
    }

    function decimals() public view returns(uint8) {
        return ERC20(tokenGive).decimals();
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
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