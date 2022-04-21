/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: NONE

pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;


// 
// File: contracts/CricStoxOrderHistory.sol
contract CricStoxOrderHistory {
    enum OrderType { BUY, SELL }
    enum OrderStatus { SUCCESS, FAIL }

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

    uint256 public ordersLength = 0;
    mapping(uint256 => OrderInfo) public orders;
    mapping(address => OrderInfo[]) public tokenOrders;
    mapping(address => OrderInfo[]) public userOrders;
    address public cricStoxMasterAddress;

    event orderCreated(bool success);

    /**
        * @dev Returns the number of orders for a particular stox token.
        * @return count of orders.
        */
    function tokenOrdersLength(address token_) external view returns (uint256) {
        return tokenOrders[token_].length;
    }

    /**
        * @dev Returns the number of orders for a particular user.
        * @return count of orders.
        */
    function userOrdersLength(address user_) external view returns (uint256) {
        return userOrders[user_].length;
    }

    /**
        * @dev Get order at a particular index.
        * @param token_ The address of stox token.
        * @param index_ The index to get order.
        * @return OrderInfo of order.
        */
    function tokenOrderAtIndex(address token_, uint256 index_) external view returns (OrderInfo memory) {
        return tokenOrders[token_][index_];
    }

    /**
        * @dev Get order at a particular index.
        * @param user_ The address of the user.
        * @param index_ The index to get order.
        * @return OrderInfo of order.
        */
    function userOrderAtIndex(address user_, uint256 index_) external view returns (OrderInfo memory) {
        return userOrders[user_][index_];
    }

    /**
        * @dev Initializes cricStoxMasterAddress.
        * @param cricStoxMasterAddress_ The address of CricStox Master contract.
        */
    function initMaster(address cricStoxMasterAddress_) external {
        require(cricStoxMasterAddress == address(0), "Master already initialized");
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
    }

    /**
        * @dev Initializes cricStoxMasterAddress.
        * @param user_ The address of user.
        * @param stox_ The address of stox token.
        * @param token_ The address of base currency token.
        * @param amount_ The amount of base currency token.
        * @param quantity_ The quantity of player stox token.
        * @param priceAfter_ The price of stox token after this purchase.
        * @param orderType_ The type of order.
        * @param orderStatus_ The status of order.
        */
    function saveOrder(address user_, address stox_, address token_, uint256 amount_, uint256 quantity_, uint256 priceAfter_, OrderType orderType_, OrderStatus orderStatus_) external {
        require(msg.sender == cricStoxMasterAddress, "Callable only by master.");
        OrderInfo memory order;
        order.user = address(user_);
        order.stox = address(stox_);
        order.amount = amount_;
        order.token = address(token_);
        order.orderType = orderType_;
        order.orderStatus = orderStatus_;
        order.quantity = quantity_;
        order.priceAfter = priceAfter_;
        order.timestamp = block.timestamp;
        orders[ordersLength] = order;
        ordersLength = ordersLength + 1;
        tokenOrders[stox_].push(order);
        userOrders[user_].push(order);
        if (orderStatus_ == OrderStatus.SUCCESS) {
            emit orderCreated(true);
        } else {
            emit orderCreated(false);
        }
    }
}