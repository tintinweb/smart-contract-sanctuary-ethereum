/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MyCoffee {
    mapping (address => int) public currencyBalance;
    address owner;
    uint coffeeCapa; 
    uint coffeePrice; 
    
    address[] coffeeProvider;
    
    constructor() {
        owner = msg.sender; 
        coffeePrice = 10**9; 
        coffeeCapa = 0;
    }

    function getCoffeeCapa() external view returns(uint){
        return coffeeCapa;
    }
    
    function sendMoney() external payable{
        currencyBalance[msg.sender] += int(msg.value);
    }
    
    function getMoneyBack() external {
        require(currencyBalance[msg.sender] > 0);
        uint value = uint(currencyBalance[msg.sender]);
        currencyBalance[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }
        
    function buyCoffee() external {
        require((currencyBalance[msg.sender] - int(coffeePrice))  >= -10**9);
        require(coffeeCapa > 0);
        currencyBalance[msg.sender]-= int(coffeePrice);
        coffeeCapa -= 1;
    }
    
    function addCoffeeProvider(address newCoffeeProvider) external returns(bool){
        uint length = coffeeProvider.length; 
        for(uint i=0;i<length; i++){
            if(coffeeProvider[i] == newCoffeeProvider) return false;
        }
        coffeeProvider.push(newCoffeeProvider);
        return true; 
    }
    
    function fixCoffeePrice(uint amount) external {
        require(msg.sender == owner);
        require(amount < ((2**256)/2)); // Coffee cost should not create a negative number when casted to int. 
        coffeePrice = amount;
    }
    
    function changeOwner(address newOwner) external {
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    function addCoffee(uint addedCoffee) external returns(bool){
        require(int(address(this).balance) > int(addedCoffee * coffeePrice));
        uint length = coffeeProvider.length; 
        for(uint i=0; i<length; i++){
            if(coffeeProvider[i] == msg.sender) {
                coffeeCapa += addedCoffee;
                currencyBalance[msg.sender] += int(addedCoffee * coffeePrice);
                return true;
            }
        }
        return false; 
    }
}