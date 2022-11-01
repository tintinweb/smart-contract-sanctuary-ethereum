/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GroceryShop {
    address public owner;
    uint private totalPurchases = 0;
    uint private totalAmount = 0;

    mapping(string => uint) private groceryTypes;

    struct PurchaseDetail {
        address user;
        string grocery;
        uint unitsBought;
    }

    mapping(uint => PurchaseDetail) private purchaseDetails;

    event Added(string groceryType, uint units);
    event Bought(uint indexed purchaseId, string groceryType, uint units);

    constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount) {
        owner = msg.sender;

        groceryTypes["bread"] = breadCount;
        groceryTypes["egg"] = eggCount;
        groceryTypes["jam"] = jamCount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can add items");
        _;
    }

    function add(string calldata groceryItem, uint units) public onlyOwner {
        groceryTypes[groceryItem] += units;
        emit Added(groceryItem, units);
    }
    
    function buy(string calldata groceryItem, uint units) public {
        // Current no of items should be greater than equal to no of units to buy.
        require(groceryTypes[groceryItem] >= units, "Either item does not exist or there's limited inventory, come back after some time.");
        require(units > 0, "No of units should be greater than 0.");

        totalPurchases += 1;
        uint currentPurchaseId = totalPurchases;

        totalAmount += units * 1/100; 
        groceryTypes[groceryItem] -= units;

        purchaseDetails[currentPurchaseId].grocery = groceryItem;
        purchaseDetails[currentPurchaseId].unitsBought = units;
        purchaseDetails[currentPurchaseId].user = msg.sender;

        emit Bought(currentPurchaseId, groceryItem, units);
    }

    function withdraw() external onlyOwner returns (uint) {
        uint amountToReturn = totalAmount;
        totalAmount = 0;
        return amountToReturn;
    }

    function cashRegister() external view returns (PurchaseDetail[] memory) {
        PurchaseDetail[] memory details = new PurchaseDetail[](totalPurchases);

        for(uint i=1; i<totalPurchases; i++) {
            uint purchaseId = i;
            PurchaseDetail storage currentPurchase = purchaseDetails[purchaseId];
            details[purchaseId] = currentPurchase;
        }
        return details;
    }
}