/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GroceryShop {

    enum GroceryType {
        Bread,
        Egg,
        Jam
    }

    struct Grocery {
        GroceryType groceryType;
        string name;
        uint256 count;
        uint256 price;
    }

    struct History {
        uint256 id;
        address buyer;
        GroceryType item;
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

    modifier shelfIndex(GroceryType groceryType) {
        require(uint(groceryType) <= shelf.length - 1, "Grocery array out of bounds");
        _;
    }

    event Added(GroceryType groceryType, uint256 unitsAdded);
    event Bought(uint256 purchaseId, GroceryType groceryType, uint256 units);

    constructor(
        uint256 breadCount,
        uint256 eggCount,
        uint256 jamCount
    ) {
        owner = payable(msg.sender);

        shelf.push(Grocery(GroceryType.Bread, "bread", breadCount, 0.01 ether));
        shelf.push(Grocery(GroceryType.Egg, "egg", eggCount, 0.01 ether));
        shelf.push(Grocery(GroceryType.Jam, "jam", jamCount, 0.01 ether));
    }

    function add(GroceryType groceryType, uint256 units)
        public
        onlyOwner
        shelfIndex(groceryType)
    {
        shelf[uint(groceryType)].count += units;

        emit Added(groceryType, units);
    }

    function buy(GroceryType groceryType, uint256 units)
        public
        payable
        shelfIndex(groceryType)
    {
        require(shelf[uint(groceryType)].count >= units, "Not enough units");
        require(
            msg.value == units * shelf[uint(groceryType)].price,
            "Incorrect amount"
        );
        shelf[uint(groceryType)].count -= units;
        purchases++;

        history[purchases] = History(
            purchases,
            msg.sender,
            groceryType,
            shelf[uint(groceryType)].name,
            units
        );
        emit Bought(purchases, groceryType, units);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    function cashRegister(uint256 purchaseId)
        public
        view
        returns (address buyer, GroceryType item, uint256 count)
    {
        History storage receipt = history[purchaseId];

        return (receipt.buyer, receipt.item, receipt.units);
    }
}