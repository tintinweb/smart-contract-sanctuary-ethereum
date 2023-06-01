/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CoffeeCatalog {
    struct CoffeeBean {
        uint id;
        string name;
        string origin;
        uint price;
        uint amountInKg;
        address payable seller;
        bool isSold;
    }
    
    uint public nextId;
    mapping(uint => CoffeeBean) public coffeeBeans;
    
    event CoffeeBeanAdded(uint id, string name, string origin, uint price, uint amountInKg, address seller);
    event CoffeeBeanSold(uint id, address buyer);
    
    function addCoffeeBean(string memory _name, string memory _origin, uint _price, uint _amountInKg) public {
        uint id = nextId++;
        coffeeBeans[id] = CoffeeBean(id, _name, _origin, _price, _amountInKg, payable(msg.sender), false);
        emit CoffeeBeanAdded(id, _name, _origin, _price, _amountInKg, msg.sender);
    }
    
    function buyCoffeeBean(uint _id, uint _amountInKg) public payable {
        require(coffeeBeans[_id].id == _id, "Coffee bean not found");
        require(!coffeeBeans[_id].isSold, "Coffee bean is already sold");
        require(msg.value >= coffeeBeans[_id].price * _amountInKg, "Insufficient funds");
        require(coffeeBeans[_id].amountInKg >= _amountInKg, "Insufficient quantity available");
        
        coffeeBeans[_id].amountInKg -= _amountInKg;
        
        if (coffeeBeans[_id].amountInKg == 0) {
            coffeeBeans[_id].isSold = true;
        }
        
        address payable seller = coffeeBeans[_id].seller;
        seller.transfer(msg.value);
        
        emit CoffeeBeanSold(_id, msg.sender);
    }
}