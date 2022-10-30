/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// cashRegister
// This should return purchase details, buyer, item they bought and number of units in the same order. 
// It can return a struct you are using to store purchase information.

contract GroceryShop{
  // enum {0 - bread,1 - Egg,2 - Jam}
  enum GroceryType{ Bread, Egg, Jam }
  mapping(GroceryType => uint256) public inventory;
  address owner;
  address buyer;
  GroceryType public grocerytype;
  uint public purchaseId;
  uint public fraether = 0.01 ether;
  struct purchase_dtl{
     string purchase_details;
     address buyer;
     GroceryType items;
     uint num_of_units;
  } 

  purchase_dtl[] public p_dtl;

    constructor(uint _breads, uint _eggs, uint _jams) {
        inventory[GroceryType.Bread] = _breads;
        inventory[GroceryType.Egg] = _eggs;
        inventory[GroceryType.Jam] = _jams;
        owner = msg.sender;
    }
    
    modifier isOwner() {
       require(msg.sender == owner, "Only the owner can add");
        _;
    }

    event added(GroceryType grocerytype, uint no_added);
    event Bought(uint purchaseId,GroceryType grocerytype, uint units);
     
    function add(GroceryType _grocerytype, uint no_of_units) public isOwner(){
        uint i = inventory[_grocerytype];
        inventory[_grocerytype] = i + no_of_units;
        emit added(_grocerytype,no_of_units);
    }
    
    function buy(GroceryType _grocerytype,uint units, uint price) public{ 
        require(fraether == price, 'Something bad happened');
        purchaseId += 1;
        emit Bought(purchaseId,_grocerytype,units);
    }

      function withdraw(uint amount) public isOwner() {
        require(amount <= address(this).balance, "Amount greater than balance");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function cashRegister(string memory _purchase_detls, address _buyer, GroceryType _items, uint _num_of_units) public returns (purchase_dtl[] memory){ 
        p_dtl.push(purchase_dtl(_purchase_detls,_buyer,_items,_num_of_units));
        return p_dtl;
    }

  //  function getPurchase_Details() public view returns (purchase_dtl[] memory) {
    //    return p_dtl;
}