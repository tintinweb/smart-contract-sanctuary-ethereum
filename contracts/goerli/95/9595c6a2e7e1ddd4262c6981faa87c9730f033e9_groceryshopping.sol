/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract groceryshopping{
    address owner;
    address visitor;
    uint256 price;
    uint bank;
    uint Id;

    enum GroceryType{None, Bread, Egg, Jam} 
    mapping(GroceryType => uint) grocerycount;

    constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount){
        owner = msg.sender;
        grocerycount[GroceryType.Bread] = breadCount;
        grocerycount[GroceryType.Jam] = jamCount;
        grocerycount[GroceryType.Egg] = eggCount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct receipt {
        uint purchase_id;
        address visitor;
        GroceryType grocerygroup;
        uint quantitypurchased;
    }

    receipt[] receipts;
    mapping(address => receipt) receiptid;

    event Added(address owner, GroceryType, uint gquantity);
    event Bought(uint Id, GroceryType, uint gquantity);

    address[] visitor_db;

    function add(GroceryType groceryName, uint gquantity) public onlyOwner() {
    // only owner can access
    uint intq = grocerycount[groceryName];
    grocerycount[groceryName] = intq + gquantity; // add inventory
    emit Added(msg.sender, groceryName, gquantity); //emit event
    }

    function buy(GroceryType groceryName, uint256 gquantity) public{
        uint inventory = grocerycount[groceryName];
        require(gquantity <= inventory, "Out of stock");
        price = gquantity*1/100;
        grocerycount[groceryName] = inventory - gquantity;
        Id+=1; //balance inventory
        emit Bought(Id, groceryName, gquantity);
        
        receiptid[msg.sender].purchase_id = Id;
        receiptid[msg.sender].visitor = msg.sender;
        receiptid[msg.sender].grocerygroup = groceryName;
        receiptid[msg.sender].quantitypurchased = gquantity;

        uint int_bank = bank;
        bank = int_bank + price;
        receipts.push(receipt(Id, msg.sender, groceryName, gquantity));
    }

    mapping (address => uint) balances;

    function withdraw() public onlyOwner(){
        (bool success, ) = payable(msg.sender).call{value: bank}("");
        require(success, "Failed to send Ether");
    }

    function cashRegister()public view returns (uint, address, GroceryType, uint){
        return (receiptid[msg.sender].purchase_id, receiptid[msg.sender].visitor, 
        receiptid[msg.sender].grocerygroup, receiptid[msg.sender].quantitypurchased)  ;
    } 

}