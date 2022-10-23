/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GroceryShop {

    struct Grocery {
        uint256 gType;
        string name;
        uint256 count;
        uint256 price;
    }

    struct History {
        uint256 id;
        address buyer;
        uint256 item;
        string name;
        uint256 units;
    }

    Grocery[] public shelf;
    mapping(uint256 => History) history;

    address payable public owner;
    uint256 purchases;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier shelfIndex(uint256 groceryType) {
        require(groceryType <= shelf.length - 1, "Grocery array out of bounds");
        _;
    }

    event Added(uint256 groceryType, uint256 unitsAdded);
    event Bought(uint256 purchaseId, uint256 groceryType, uint256 units);

    constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount) {
        owner = payable(msg.sender);

        shelf.push(Grocery(0, "bread", breadCount, 0.01 ether));
        shelf.push(Grocery(1, "egg", eggCount, 0.01 ether));
        shelf.push(Grocery(2, "jam", jamCount, 0.01 ether));

    }

    function add(uint256 groceryType, uint256 units) public onlyOwner shelfIndex(groceryType) {
        shelf[groceryType].count += units;

        emit Added(groceryType, units);

    }

    function buy(uint256 groceryType, uint256 units) public payable shelfIndex(groceryType) {
        require(shelf[groceryType].count >= units, "Not enough units");
        require(msg.value == units * shelf[groceryType].price, "Incorrect amount");
        shelf[groceryType].count -= units;
        purchases++;

        history[purchases] = History(purchases, msg.sender, groceryType, shelf[groceryType].name, units);
        emit Bought(purchases, groceryType, units);

    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    function cashRegister(uint256 purchaseId) public view returns (History memory) {
        return history[purchaseId];
    }
    
}