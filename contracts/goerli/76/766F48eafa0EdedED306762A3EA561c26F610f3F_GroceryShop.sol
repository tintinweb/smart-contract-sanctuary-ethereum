/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GroceryShop {

    enum GroceryType{ None, Bread, Egg, Jam } 

    event Added(GroceryShop.GroceryType groceryType, uint256 units);
    event Bought(uint256 purchaseId, GroceryShop.GroceryType groceryType, uint256 units);

    struct CashRegister {
        address buyer;
        GroceryShop.GroceryType item;
        uint256 count;
    }

    uint256 breadCount;
    uint256 eggCount;
    uint256 jamCount;
    uint256 purchaseId;
    address owner;
    mapping(uint => CashRegister) purchased;

    constructor(uint256 _breadCount, uint256 _eggCount, uint256 _jamCount) {
        breadCount = _breadCount;
        eggCount = _eggCount;
        jamCount = _jamCount;
        owner = msg.sender;
    }

    function add(GroceryType _type, uint _units) public {
        require(msg.sender == owner, "Only owner can call add");
        if (_type == GroceryType.Bread) {
            breadCount += _units;
        } else if (_type == GroceryType.Egg) {
            eggCount += _units;
        } else if (_type == GroceryType.Jam) {
            jamCount += _units;
        }
        emit Added(_type, _units);
    }

    function buy(GroceryType _type, uint _units) payable public {
        require(msg.value == 0.01 ether);
        if (_type == GroceryType.Bread) {
            require(_units < breadCount, "Not enough bread to buy");
            breadCount -= _units;
        } else if (_type == GroceryType.Egg) {
            require(_units < eggCount, "Not enough eggs to buy");
            eggCount -= _units;
        } else if (_type == GroceryType.Jam) {
            require(_units < jamCount, "Not enough jam to buy");
            jamCount -= _units;
        }
        purchaseId++;
        purchased[purchaseId] = CashRegister(msg.sender, _type, _units);
        emit Bought(purchaseId, _type, _units);
    }

    function cashRegister(uint _purchaseId) public view returns (address, GroceryShop.GroceryType, uint256) {
        require(_purchaseId > 0 && _purchaseId <= purchaseId, "Unknown purchaseId");
        CashRegister storage order = purchased[_purchaseId];
        return (order.buyer, order.item, order.count);
    }

    function withdraw() public payable {
        require(msg.sender == owner, "Only owner can call add");
        payable(address(this)).transfer(address(this).balance);
    }
}