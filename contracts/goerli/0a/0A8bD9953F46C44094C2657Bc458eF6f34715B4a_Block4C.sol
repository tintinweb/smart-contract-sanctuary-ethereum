/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;


contract Block4C {
    mapping (address => int) public currencyBalance;
    address[] coffeeProvider;
    address public owner;
    uint private coffeePrice = 1 * (1 gwei);
    uint private coffeeQuantity;

    constructor() {
        owner = msg.sender;
        coffeeProvider.push(msg.sender);
    }

    function sendMoney() external payable {
        currencyBalance[msg.sender] += int(msg.value);
    }

    function getMoneyBack() external {
        require(currencyBalance[msg.sender] > 0);
        int currencyBalanceTmp = currencyBalance[msg.sender];
        currencyBalance[msg.sender] -= currencyBalance[msg.sender];
        ( bool sent , ) =
            msg.sender.call{value : uint(currencyBalanceTmp)}(" ");
        require(sent, "MyCoffee failed to send Ether");
    } 

    function balance() external view returns(uint){
        return address(this).balance;
    }

    function getCoffeeQuantity() external view returns(uint) {
        return coffeeQuantity;
    }

    function buyCoffee() external payable {
        require(currencyBalance[msg.sender]-int(coffeePrice) > -10 * (1 gwei));
        require(coffeeQuantity > 0);
        currencyBalance[msg.sender] -= int(coffeePrice);
        coffeeQuantity -= coffeePrice;
    }

    function checkAdress(address s) private returns(bool) {
        uint length = coffeeProvider.length;
        for (uint i = 0; i < length; i++) {
            if (coffeeProvider[i] == s)
                return true;
        }
        return false;
    }

    function addCoffeeProvider(address newCoffeeProvider) external {
        require(msg.sender == owner);
        require(!checkAdress(newCoffeeProvider));
        coffeeProvider.push(newCoffeeProvider);
    }

    function fixCoffeePrice(uint newPrice) external {
        require(msg.sender == owner);
        coffeePrice = newPrice * (1 gwei);
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function addCoffee(uint newQuantity) external {
        require(checkAdress(msg.sender));
        require(int(address(this).balance) > int(coffeePrice * newQuantity));
        coffeeQuantity += newQuantity;
        currencyBalance[msg.sender] += int(coffeePrice * newQuantity);
    }
}