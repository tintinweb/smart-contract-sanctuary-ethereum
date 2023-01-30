/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract myCoffee {
    mapping (address => int) public currencyBalance;
    
    address[] public providers;
    string[] public tickets;

    address public owner = msg.sender;
    uint public coffeePrice = 2 gwei;
    uint public coffeeAmount = 0;

    ////////////////////////////////////////////
    ////////////// User interface //////////////
    ////////////////////////////////////////////

    function sendMoney() external payable {
        require(msg.value >= 0);
        currencyBalance[msg.sender] += int(msg.value);
    }

    function getMoneyBack() external {
        require(currencyBalance[msg.sender] >= 0);
        uint currency = uint(currencyBalance[msg.sender]);
        currencyBalance[msg.sender] = 0;
        payable(msg.sender).transfer(currency);
    }

    function buyCoffee() external {
        require(currencyBalance[msg.sender] >= (-10 gwei + int(coffeePrice)));
        require(coffeeAmount > 0);
        currencyBalance[msg.sender] -= int(coffeePrice);
        coffeeAmount--;
    }

    ////////////////////////////////////////////
    ///////////// Owner functions //////////////
    ////////////////////////////////////////////

    function balance() external view returns(uint) {
        require(msg.sender == owner);
        return address(this).balance;
    }

    function addCoffeeProvider(address provider) external {
        require(msg.sender == owner);
        require(!isProvider(msg.sender));
        providers.push(provider);
    }

    function fixCoffeePrice(uint price) external {
        require(msg.sender == owner);
        coffeePrice = price;
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }

    ////////////////////////////////////////////
    ////////////// Provide Coffee //////////////
    ////////////////////////////////////////////

    function isProvider(address provider) internal view returns(bool) {
        for (uint i = 0; i < providers.length; i++)
            if (providers[i] == provider) return true;
        return false;
    }
    
    function addCoffee(uint amount, string memory ticket) external {
        require(isProvider(msg.sender));
        require(address(this).balance >= amount * coffeePrice);
        require(bytes(ticket).length > 0);
        
        coffeeAmount += amount;
        payable(msg.sender).transfer(amount * coffeePrice);
        tickets.push(ticket);
    }
}