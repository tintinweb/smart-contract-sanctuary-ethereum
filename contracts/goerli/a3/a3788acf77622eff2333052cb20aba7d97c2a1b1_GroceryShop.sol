/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GroceryShop {

    event Added(GroceryType groceryType, uint256 numberAdded);
    event Bought(uint256 purchaseId, GroceryType groceryType, uint256 numberOfUnitBought);

    enum GroceryType { Bread, Egg, Jam }

    address public owner;
    uint256 private purchaseId;

    struct Grocery {
        string name;
        uint256 numberOfItems;
    }

    struct PurchaseDetail {
        address buyerAddress;
        string groceryBought;
        uint256 numberOfUnitBought;
    }

    mapping (GroceryType => Grocery) public groceryType;
    mapping (uint256 => PurchaseDetail) private purchaseReceipt;

    constructor(uint256 _breadCount, uint256 _eggCount, uint256 _jamCount) {
        groceryType[GroceryType.Bread] = Grocery("Bread", _breadCount);
        groceryType[GroceryType.Egg] = Grocery("Egg", _eggCount);
        groceryType[GroceryType.Jam] = Grocery("Jam", _jamCount);
        purchaseId = 0;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner allowed make a call");
        _;
    }

    function add(GroceryType _groceryType, uint256 _numberAdded) public onlyOwner {
        require(_numberAdded > 0, "Number must be greater than zero");
        groceryType[_groceryType].numberOfItems += _numberAdded;
        emit Added(_groceryType, _numberAdded);
    }

    function buy(GroceryType _groceryType, uint256 _numberToBought) public payable {
        require(msg.value > 0, "You must sent some ether");
        require(groceryType[_groceryType].numberOfItems >= _numberToBought, "Not enough items");
        
        uint256 total = _numberToBought * (0.01 ether);
        require(msg.value >= total, "Invalid amount");

        purchaseId++;
        groceryType[_groceryType].numberOfItems -= _numberToBought;
        purchaseReceipt[purchaseId] = PurchaseDetail(msg.sender, groceryType[_groceryType].name, _numberToBought);
        emit Bought(purchaseId, _groceryType, _numberToBought);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function cashRegister(uint256 _purchaseId) public view onlyOwner returns (address, string memory, uint256) {
        require(_purchaseId <= purchaseId, "Invalid Purchase ID");

        address buyer = purchaseReceipt[_purchaseId].buyerAddress;
        string memory bought = purchaseReceipt[_purchaseId].groceryBought;
        uint256 numBought = purchaseReceipt[_purchaseId].numberOfUnitBought;

        return (
            buyer,
            bought,
            numBought
        );
    }
}