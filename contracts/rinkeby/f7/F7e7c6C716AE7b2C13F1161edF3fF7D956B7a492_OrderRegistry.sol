pragma solidity ^0.8.4;

import './Order.sol';

interface IOrder {
     function initialize(uint256 _orderId, address _user, address _tokenGive, uint256 _amountGive, address _tokenGet, uint256 _amountGet) external;
     function returnDeposit() external;
     function confirmBalance() external returns (bool confirmation);
     function sendOrderAmount(address _to) external;
     function transferBalanceTo(address _to) external;
     function user() external returns (address);
     function balanceOf() external view returns(uint256);
     function decimals() external view returns(uint8);
     function isActive() external view returns(bool);
     function toggleActive() external;
}

contract OrderRegistry {

    uint256 internal tradeCount;
    uint256 internal orderCount;
    mapping(address => uint256[]) internal getOrdersGivenUser;
    mapping(uint256 => address[]) internal getUsersGivenTrade;
    mapping(address => address) internal getUserGivenOrder;
    address[] public allOrders;
    Trade[] public allTrades;

    struct Trade{
        uint256 tradeId;
        address order1;
        address order2;
        // @TODO are these approvals needed?
        bool approval1;
        bool approval2;
        bool settled;
    }

    // @TODO what other front end functionalities are needed?
    event TradeCreated(uint256 tradeId, address indexed orderA, address indexed orderB);
    event OrderCreated(uint256 orderId, address indexed user, address indexed order);
    event TradeSettled(uint256 tradeId, address indexed orderA, address indexed orderB);

    constructor(){
        //fill in index 0, ids will start at 1
        allOrders.push(0x000000000000000000000000000000000000dEaD);
        allTrades.push(Trade(0, 0x000000000000000000000000000000000000dEaD, 0x000000000000000000000000000000000000dEaD, false, false, false));
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
        getUserGivenOrder[order] = msg.sender;
        allOrders.push(order);
        emit OrderCreated(orderId, msg.sender, order);
    }

    /**
     * @notice creates a trade given two order IDs.  Should be called by ATS matching engine
     */
    function createTrade(uint256 _orderA, uint256 _orderB) public returns(uint256 tradeId) {
        require(IOrder(allOrders[_orderA]).isActive() && IOrder(allOrders[_orderB]).isActive(), "Order is not active");
        (address firstOrder, address secondOrder) = allOrders[_orderA] < allOrders[_orderB] ? 
            (allOrders[_orderA], allOrders[_orderB]) :
            (allOrders[_orderB], allOrders[_orderA]);
        tradeCount += 1;
        tradeId = tradeCount;
        Trade memory trade = Trade(tradeId, firstOrder, secondOrder, false, false, false);
        allTrades.push(trade);
        getUsersGivenTrade[tradeId].push(getUserGivenOrder[firstOrder]);
        getUsersGivenTrade[tradeId].push(getUserGivenOrder[secondOrder]);
        emit TradeCreated(tradeId, address(firstOrder), address(secondOrder));
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

    function approveTrade(uint256 _tradeId) public {
        require(_tradeId <= tradeCount, "Invalid trade");
        Trade storage trade = allTrades[_tradeId];
        require(!trade.settled, "Trade is settled");
        address[] memory users = getUsersGivenTrade[_tradeId];
        if(msg.sender == users[0]){
            if(!trade.approval1) {
                trade.approval1 = true;
            } else {
                revert("already approved");
            }   
        } else if (msg.sender == users[1]) {
            if(!trade.approval2) {
                trade.approval2 = true;
            } else {
                revert("already approved");
            }
        } else {
            revert("invalid user");
        }
        if(trade.approval1 && trade.approval2) {
            settleTrade(_tradeId);
        }
    }

    function settleTrade(uint256 _tradeId) internal {
        Trade storage trade = allTrades[_tradeId];
        (IOrder order1, IOrder order2) = (IOrder(trade.order1), IOrder(trade.order2));
        order1.sendOrderAmount(getUserGivenOrder[trade.order2]);
        order2.sendOrderAmount(getUserGivenOrder[trade.order1]);
        order1.toggleActive();
        order2.toggleActive();
        trade.settled = true;
        emit TradeSettled(_tradeId, address(order1), address(order2));
    }

    function getOrderBalance(uint256 _orderId) public view returns(uint256 balance) {
        return IOrder(allOrders[_orderId]).balanceOf();
    }

    function getDecimals(uint256 _orderId) public view returns(uint8 decimals) {
        decimals = IOrder(allOrders[_orderId]).decimals();
    }
}

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20 is IERC20 {
    function decimals() external view returns(uint8);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
}

contract Order {

    address public registry;
    uint256 private orderId;
    address private user;
    address private tokenGive;
    address private tokenGet;
    uint256 private amountGive;
    uint256 private amountGet;
    uint256 private startTime;
    bool private active;

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
        active = true;
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

    function balanceOf(address account) public view returns (uint256) {
        return ERC20(tokenGive).balanceOf(address(this));
    }

    function name() public view returns(string memory) {
        return string(abi.encodePacked("OATSOrder", uint2str(orderId), " ", ERC20(tokenGive).name()));
    }

    function symbol() public view returns(string memory) {
        return string(abi.encodePacked("OATSORDR", uint2str(orderId), " ", ERC20(tokenGive).symbol()));
    }

    function decimals() public view returns(uint8) {
        return ERC20(tokenGive).decimals();
    }

    function isActive() public view returns(bool) {
        return active;
    }
    
    function toggleActive() external {
        require(msg.sender == registry, "UNAUTHORIZED");
        active = !active;
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