// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

contract FruitShop {
    // Define the prices of each fruit
    uint256 public applePrice;
    uint256 public bananaPrice;
    uint256 public strawberryPrice;
    uint256 public mangoPrice;

    constructor(uint256 _cost) {
        setCost(_cost);
    }

    // Events to notify when a fruit is sold
    event AppleSold(address buyer);
    event BananaSold(address buyer);
    event StrawberrySold(address buyer);
    event MangoSold(address buyer);

    // Functions to buy each fruit
    function buyApple(uint256 quantity) public payable {
        require(msg.value > 0 && msg.value >= applePrice * quantity, "Insufficient Funds");
        emit AppleSold(msg.sender);
    }

    function setCost(uint256 _cost) public {
        applePrice = _cost;
    }

}