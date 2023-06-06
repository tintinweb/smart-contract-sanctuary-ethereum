// SPDX-License-Identifier: UNLICENSED
// Uruloki DEX is NOT LICENSED FOR COPYING.
// Uruloki DEX (C) 2022. All Rights Reserved.

pragma solidity ^0.8.4;

contract UrulokOrderManager {
    //// Define enums
    enum OrderType {
        TargetPrice,
        PriceRange
    }
    enum OrderStatus {
        Active,
        Cancelled,
        OutOfFunds,
        Completed
    }

    //// Define structs
    // One time order, it's a base order struct
    struct OrderBase {
        address userAddress;
        address pairedTokenAddress;
        address tokenAddress;
        OrderType orderType;
        uint256 targetPrice;
        bool isBuy;
        uint256 maxPrice;
        uint256 minPrice;
        OrderStatus status;
        uint256 amount;
        bool isContinuous;
    }

    // Continuous Order, it's an extended order struct, including the base order struct
    struct Order {
        OrderBase orderBase;
        uint256 numExecutions;
        uint256 resetPercentage;
        bool hasPriceReset;
    }

    address public dexAddress;
    mapping(uint256 => Order) public orders;
    uint256 public orderCounter;

    constructor(address _dexAddress) {
        require(_dexAddress != address(0), "Error zero address");
        dexAddress = _dexAddress;
    }

    modifier onlyDex() {
        require(msg.sender == dexAddress, "Caller not allowed");
        _;
    }

    modifier isExistOrder(uint256 orderId) {
        require(orderId != 0, "isExistOrder: invalid order id");
        require(
            orders[orderId].orderBase.userAddress != address(0),
            "isExistOrder: not exist"
        );
        _;
    }

    function createOneTimeOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount
    ) external onlyDex returns (uint256) {
        require(userAddress != address(0), "zero user address");
        require(amount > 0, "Amount must be greater than zero");
        // Check if the token and pair addresses are valid
        require(
            pairedTokenAddress != tokenAddress,
            "Token and pair addresses must be different"
        );
        if (targetPrice > 0) {
            require(
                minPrice == 0 && maxPrice == 0,
                "validateOrder: not target price order"
            );
        } else {
            require(
                minPrice > 0 && minPrice < maxPrice,
                "validateOrder: not price range order"
            );
        }
        OrderBase memory orderBase = OrderBase({
            userAddress: userAddress,
            pairedTokenAddress: pairedTokenAddress,
            tokenAddress: tokenAddress,
            orderType: targetPrice > 0
                ? OrderType.TargetPrice
                : OrderType.PriceRange,
            targetPrice: targetPrice,
            isBuy: isBuy,
            minPrice: minPrice,
            maxPrice: maxPrice,
            status: OrderStatus.Active,
            amount: amount,
            isContinuous: false
        });
        Order memory order = Order({
            orderBase: orderBase,
            numExecutions: 0,
            resetPercentage: 0,
            hasPriceReset: true
        });

        // Add the ContinuousOrder to the orders mapping
        orders[++orderCounter] = order;
        return orderCounter;
    }

    function createContinuousOrder(
        address userAddress,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external onlyDex returns (uint256) {
        require(userAddress != address(0), "zero user address");
        require(amount > 0, "Amount must be greater than zero");
        // Check if the token and pair addresses are valid
        require(
            pairedTokenAddress != tokenAddress,
            "Token and pair addresses must be different"
        );
        if (targetPrice > 0) {
            require(
                minPrice == 0 && maxPrice == 0,
                "validateOrder: not target price order"
            );
        } else {
            require(
                minPrice > 0 && minPrice < maxPrice,
                "validateOrder: not price range order"
            );
        }
        // Validate inputs
        require(
            resetPercentage > 0 && resetPercentage < 100,
            "Invalid reset percentage"
        );

        // Create the ContinuousOrder struct
        OrderBase memory orderBase = OrderBase({
            userAddress: userAddress,
            pairedTokenAddress: pairedTokenAddress,
            tokenAddress: tokenAddress,
            orderType: targetPrice > 0
                ? OrderType.TargetPrice
                : OrderType.PriceRange,
            targetPrice: targetPrice,
            isBuy: isBuy,
            minPrice: minPrice,
            maxPrice: maxPrice,
            status: OrderStatus.Active,
            amount: amount,
            isContinuous: true
        });
        Order memory order = Order({
            orderBase: orderBase,
            numExecutions: 0,
            resetPercentage: resetPercentage,
            hasPriceReset: true
        });

        // Add the ContinuousOrder to the orders mapping
        orders[++orderCounter] = order;
        return orderCounter;
    }

    function updateOrder(
        uint256 orderId,
        address pairedTokenAddress,
        address tokenAddress,
        bool isBuy,
        uint256 targetPrice,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 amount,
        uint256 resetPercentage
    ) external onlyDex isExistOrder(orderId) {
        require(amount > 0, "Amount must be greater than zero");
        // Check if the token and pair addresses are valid
        require(
            pairedTokenAddress != tokenAddress,
            "Token and pair addresses must be different"
        );
        if (targetPrice > 0) {
            require(
                minPrice == 0 && maxPrice == 0,
                "validateOrder: not target price order"
            );
        } else {
            require(
                minPrice > 0 && minPrice < maxPrice,
                "validateOrder: not price range order"
            );
        }
        if (orders[orderId].orderBase.isContinuous) {
            require(
                resetPercentage > 0 && resetPercentage < 100,
                "Invalid reset percentage"
            );
        }

        orders[orderId].orderBase.pairedTokenAddress = pairedTokenAddress;
        orders[orderId].orderBase.tokenAddress = tokenAddress;
        orders[orderId].orderBase.isBuy = isBuy;
        orders[orderId].orderBase.orderType = targetPrice > 0
            ? OrderType.TargetPrice
            : OrderType.PriceRange;
        orders[orderId].orderBase.targetPrice = targetPrice;
        orders[orderId].orderBase.minPrice = minPrice;
        orders[orderId].orderBase.maxPrice = maxPrice;
        orders[orderId].orderBase.amount = amount;
        orders[orderId].resetPercentage = resetPercentage;
    }

    /**
     * @dev cancel exist order
     * @param orderId order id
     * @return orderId
     */
    function cancelOrder(
        uint256 orderId
    ) external onlyDex isExistOrder(orderId) returns (uint256) {
        Order memory order = orders[orderId];
        if (order.orderBase.isContinuous == false) {
            require(
                order.orderBase.status == OrderStatus.Active,
                "cancelOrder: order not active"
            );
        } else {
            require(
                order.orderBase.status != OrderStatus.Cancelled,
                "cancelOrder: order already cancelled"
            );
        }
        orders[orderId].orderBase.status = OrderStatus.Cancelled;
        return orderId;
    }

    function getOrder(
        uint256 orderId
    ) external view isExistOrder(orderId) returns (Order memory) {
        return orders[orderId];
    }

    function setOrderStatus(
        uint256 orderId,
        OrderStatus status
    ) external onlyDex isExistOrder(orderId) {
        orders[orderId].orderBase.status = status;
    }

    function incNumExecutions(
        uint256 orderId
    ) external onlyDex isExistOrder(orderId) {
        orders[orderId].numExecutions++;
    }

    function setHasPriceReset(
        uint256 orderId,
        bool flag
    ) external onlyDex isExistOrder(orderId) {
        orders[orderId].hasPriceReset = flag;
    }
}