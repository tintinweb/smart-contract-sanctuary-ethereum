/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract groceryshopping{
    address owner;
    address visitor;
    uint256 price;
    uint Id;
    uint bank;

    constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount){
        owner = msg.sender;
        groceries.push(grocery(1, breadCount));
        groceries.push(grocery(2, jamCount));
        groceries.push(grocery(3, eggCount));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    struct grocery {
        uint GroceryType;
        uint quantity;
    }

    struct receipt {
        uint purchase_id;
        address visitor;
        uint grocerygroup;
        uint quantitypurchased;
    }

    grocery[] groceries;
    receipt[] receipts;

    event Added(address owner, uint GroceryType, uint gquantity);
    event Bought(uint Id, uint GroceryType, uint gquantity);

    mapping(address => receipt) receiptid;
    address[] visitor_db;

    function add(uint GroceryType, uint gquantity) public onlyOwner() {
    // only owner can access
    uint test = groceries[GroceryType-1].quantity;
    groceries[GroceryType-1].quantity = test + gquantity; // add inventory
    emit Added(msg.sender, GroceryType, gquantity); //emit event

    }

    function buy(uint GroceryType, uint256 gquantity) public{
        uint inventory = groceries[GroceryType-1].quantity;
        require(gquantity <= inventory, "Out of stock");
        price = gquantity*1/100;
        groceries[GroceryType-1].quantity = inventory - gquantity;
        Id+=1; //balance inventory
        emit Bought(Id, GroceryType, gquantity);
        
        receiptid[msg.sender].purchase_id = Id;
        receiptid[msg.sender].visitor = msg.sender;
        receiptid[msg.sender].grocerygroup = GroceryType;
        receiptid[msg.sender].quantitypurchased = gquantity;

        uint int_bank = bank;
        bank = int_bank + price;

        receipts.push(receipt(Id, msg.sender, GroceryType, gquantity));
    }


    mapping (address => uint) balances;


    function withdraw() public onlyOwner(){
        (bool success, ) = payable(msg.sender).call{value: bank}("");
        require(success, "Failed to send Ether");
    }

    function cashRegister()public view returns (uint, address, uint, uint){
        return (receiptid[msg.sender].purchase_id, receiptid[msg.sender].visitor, 
        receiptid[msg.sender].grocerygroup, receiptid[msg.sender].quantitypurchased)  ;
    } 


}