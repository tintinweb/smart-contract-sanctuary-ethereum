/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract VendingMachine {

    struct item {
        uint id;
        string name;
        uint quantity;
        uint price;
    }

    mapping (uint=>item) private items;
    mapping(address => uint) public balances;
    address public owner;

    event success(string name, uint quantity, uint price);
    event placeOrdersuccess(string name, uint quantity, uint balance);

    constructor () {
     owner = msg.sender;
    }

function registerItem(uint id, string memory name, uint quantity, uint price) public{
    item storage newItem = items[id];
    newItem.id = id;
    newItem.name=name;
    newItem.quantity=quantity;
    newItem.price=price;
}

function getItem(uint id) public view returns ( string memory name, uint quantity, uint price){
    item storage newItem = items[id];
    return( newItem.name, newItem.quantity, newItem.price);
}

function buyItem(uint id) public  payable {
    item storage newItem = items[id];
    require(msg.value>=newItem.price);
    newItem.quantity=newItem.quantity-1;
    balances[owner] += msg.value;
    emit success(newItem.name,1,newItem.price);
}

function placeOrderToMarket(uint id, uint quantity, address receiver) public {
     item storage newItem = items[id];
     require(balances[owner] >= newItem.price*quantity);
     newItem.quantity += quantity;
     balances[owner] -= newItem.price*quantity;
     balances[receiver] += newItem.price*quantity;
     emit placeOrdersuccess(newItem.name,quantity,balances[owner]);
}

}