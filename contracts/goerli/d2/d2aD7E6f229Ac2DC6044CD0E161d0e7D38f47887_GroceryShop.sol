/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GroceryShop {

address payable public owner;

enum GroceryType{ Bread, Egg, Jam }

struct GroceryStorage {
    uint256 bread;
    uint256 egg;
    uint256 jam;
}
GroceryStorage internal groceryStorage;

struct Purchase {
    address buyer;
    GroceryType grocery;
    uint256 count;
}
mapping(uint256 => Purchase) internal groceryPurchases;
uint256 lastPurchaseId;

event Added(GroceryType grocery, uint256 count);
event Bought(uint256 purchaseId, GroceryType grocery, uint256 count);

modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}

constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount) payable {
    owner = payable(msg.sender); // store contract owner
    groceryStorage = GroceryStorage({
        bread: breadCount,
        egg: eggCount,
        jam: jamCount
    });
    lastPurchaseId = 0;
}

function add(GroceryType grocery, uint256 count) external onlyOwner {

    if (grocery == GroceryType.Bread) {
        groceryStorage.bread += count;
    }

    if (grocery == GroceryType.Egg) {
        groceryStorage.egg += count;
    }

    if (grocery == GroceryType.Jam) {
        groceryStorage.jam += count;
    }

    emit Added(grocery, count);
}

function buy(GroceryType grocery, uint256 count) external payable {
    require(msg.value == count * (10 ** 17), "Did not pay enough ETH");

    uint256 breadCount = 0;
    uint256 eggCount = 0;
    uint256 jamCount = 0;

    if (grocery == GroceryType.Bread) {
        require(groceryStorage.bread >= count, "Not enough bread");
        breadCount = count;
        groceryStorage.bread -= count;
    }

    if (grocery == GroceryType.Egg) {
        require(groceryStorage.egg >= count, "Not enough eggs");
        eggCount = count;
        groceryStorage.egg -= count;
    }

    if (grocery == GroceryType.Jam) {
        require(groceryStorage.jam >= count, "Not enough jam");
        jamCount = count;
        groceryStorage.jam -= count;
    }

    lastPurchaseId++;
    Purchase memory groceryPurchase = Purchase({
        buyer: msg.sender,
        grocery: grocery,
        count: count
    });
    groceryPurchases[lastPurchaseId] = groceryPurchase;

    emit Bought(lastPurchaseId, grocery, count);
}

function cashRegister(uint256 purchaseId) public view returns(address, GroceryType, uint256) {
    return (groceryPurchases[purchaseId].buyer, groceryPurchases[purchaseId].grocery, groceryPurchases[purchaseId].count);
}

function withdraw() external payable onlyOwner {
    owner.transfer(address(this).balance);
}

}