/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyTrading {
    struct Order {
        address trader;
        uint256 energyAmount;
        uint256 price;
        bool isBuyOrder;
    }

    mapping(uint256 => Order) public buyOrders;
    mapping(uint256 => Order) public sellOrders;
    uint256 public numBuyOrders;
    uint256 public numSellOrders;
    mapping(address => uint256) public energyBalances;
    address public energyToken;

    constructor(address _energyToken) {
        energyToken = _energyToken;
    }

    function buyEnergy(uint256 _energyAmount, uint256 _price) external {
        require(
            energyBalances[msg.sender] >= _energyAmount,
            "Insufficient energy balance"
        );
        energyBalances[msg.sender] -= _energyAmount;
        buyOrders[numBuyOrders] = Order(
            msg.sender,
            _energyAmount,
            _price,
            true
        );
        numBuyOrders++;
    }

    function sellEnergy(uint256 _energyAmount, uint256 _price) external {
        require(
            energyBalances[msg.sender] >= _energyAmount,
            "Insufficient energy balance"
        );
        energyBalances[msg.sender] -= _energyAmount;
        sellOrders[numSellOrders] = Order(
            msg.sender,
            _energyAmount,
            _price,
            false
        );
        numSellOrders++;
    }

    function executeTrade(
        uint256 _buyOrderId,
        uint256 _sellOrderId,
        uint256 _amount
    ) external {
        require(
            buyOrders[_buyOrderId].trader != address(0),
            "Buy order does not exist"
        );
        require(
            sellOrders[_sellOrderId].trader != address(0),
            "Sell order does not exist"
        );
        require(
            buyOrders[_buyOrderId].price >= sellOrders[_sellOrderId].price,
            "Price mismatch"
        );
        require(
            buyOrders[_buyOrderId].energyAmount >= _amount,
            "Insufficient energy amount in buy order"
        );
        require(
            sellOrders[_sellOrderId].energyAmount >= _amount,
            "Insufficient energy amount in sell order"
        );

        uint256 totalEnergyCost = _amount * sellOrders[_sellOrderId].price;
        energyBalances[buyOrders[_buyOrderId].trader] += _amount;
        energyBalances[sellOrders[_sellOrderId].trader] -= totalEnergyCost;

        buyOrders[_buyOrderId].energyAmount -= _amount;
        sellOrders[_sellOrderId].energyAmount -= _amount;
    }
}