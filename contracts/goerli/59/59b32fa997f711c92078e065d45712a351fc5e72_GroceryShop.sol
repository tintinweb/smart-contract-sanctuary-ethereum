/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GroceryShop {

    enum GroceryType {Milk,Bread,Egg,Jam}

    address private _owner;
    uint private _purchaseId;
    uint256 _pricePerUnit = 0.01 ether;

    mapping(GroceryType => uint256) private inventory;

    event Added(GroceryType,uint256);
    event Bought(uint,GroceryType,uint256);

    modifier onlyOwner(){
        require(msg.sender == _owner, "restricted to owner");
        _;
    }

    constructor(uint256 breadCount, uint256 eggCount, uint256 jamCount) {
        _owner = msg.sender;
        inventory[GroceryType.Bread] = breadCount;
        inventory[GroceryType.Egg] = eggCount;
        inventory[GroceryType.Jam] = jamCount;
    }

    function add(GroceryType _groceryType, uint256 _unitsToAdd) public onlyOwner {
        inventory[_groceryType] += _unitsToAdd;

        emit Added(_groceryType,_unitsToAdd);
    }

    function buy(GroceryType _groceryType, uint256 _unitsToBuy) public payable {
        require(_unitsToBuy >0);
        require(_unitsToBuy <= inventory[_groceryType],"not in inventory");
        uint cost = _unitsToBuy * _pricePerUnit;
        require(cost == msg.value, "only exact change");
        _purchaseId++;
        inventory[_groceryType] -= _unitsToBuy;

        emit Bought(_purchaseId, _groceryType, _unitsToBuy);
    }

    function withdraw() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

}