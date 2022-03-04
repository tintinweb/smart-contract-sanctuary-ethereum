/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.0;


// 
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

    function tokenOrdersLength(address token_) external view returns (uint256) {
        return tokenOrders[token_].length;
    }

    function userOrdersLength(address user_) external view returns (uint256) {
        return userOrders[user_].length;
    }

    function initMaster(address cricStoxMasterAddress_) external {
        require(cricStoxMasterAddress == address(0), "Master already initialized");
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
    }

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