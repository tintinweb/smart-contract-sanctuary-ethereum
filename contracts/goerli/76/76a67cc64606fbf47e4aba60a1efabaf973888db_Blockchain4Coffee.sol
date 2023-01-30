/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Blockchain4Coffee{
    address owner;
    bool locked = false;
    mapping(address => uint) public currencyBalance;
    mapping(address => uint) public debt;
    mapping(address => bool) isProvider;
    uint coffeeStock;
    uint coffeeValue;
    uint available_money;
    string[] proofs;
    
    uint DEBT_LIMIT = 10 gwei;

    constructor(uint stock, uint value){
        require(stock > 0 && value > 0, "Coffee price and stock must be greater than 1");
        coffeeStock = stock;
        coffeeValue = value;
        owner = msg.sender;
        available_money = 0;
    }

    function sendMoney() external payable {
        if(debt[msg.sender] >= msg.value){
            debt[msg.sender] -= msg.value;
            available_money += msg.value;
        }else if (debt[msg.sender] > 0){
            currencyBalance[msg.sender] += msg.value - debt[msg.sender];
            available_money += debt[msg.sender];
            debt[msg.sender] = 0;
        }else{
            currencyBalance[msg.sender] += msg.value;
        }
    }

    modifier unlocked{
        require(!locked, "The contract is locked for now on");
        _;
    }

    function getMoneyBack() external unlocked{
        require(currencyBalance[msg.sender] > 0, "The balance of your acount is negative or null"); 
        locked = true;

        uint transfer = currencyBalance[msg.sender];
        currencyBalance[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: transfer}("");
        require(sent);
        locked = false; 
    }

    function buyCoffee() external {
        if(coffeeValue > currencyBalance[msg.sender]){
            uint left = coffeeValue - currencyBalance[msg.sender];
            require(debt[msg.sender]  + left <= DEBT_LIMIT, "Too much debt");
        }
        
        require(coffeeStock > 0, "Not enought coffee");
       
        coffeeStock -= 1;
        if(coffeeValue > currencyBalance[msg.sender]){
            available_money += currencyBalance[msg.sender];
            debt[msg.sender] += coffeeValue - currencyBalance[msg.sender];
            currencyBalance[msg.sender] = 0;
        }else{
            available_money += coffeeValue;
            currencyBalance[msg.sender] -= coffeeValue;
        }  
    }

    modifier ownership {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function addCoffeeProvider(address provider) external ownership{
        isProvider[provider] = true;    
    }

    function fixCoffeePrice(uint price) external ownership{
        coffeeValue = price;
    }

    function changeOwner(address o) external ownership{
        owner = o;
    }

    function addCoffee(uint unitsCoffee, string memory proof) external unlocked{
        locked = true;
        uint cost = unitsCoffee * coffeeValue;
        require(isProvider[msg.sender], "You are not a provider");
        require(available_money >= cost, "Not enought fund available");

        coffeeStock += unitsCoffee;
        proofs.push(proof);
        available_money -= cost;

        (bool sent, ) = msg.sender.call{value: cost}("");
        require(sent);
        locked = false;
    }
}