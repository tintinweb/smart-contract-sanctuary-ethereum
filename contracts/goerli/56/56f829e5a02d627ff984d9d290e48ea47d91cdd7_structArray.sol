/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

contract structArray {

struct Food {
    uint256 foodid;
    string foodName;
    uint256 price;
}

mapping(uint256 =>bool) checkId;

Food[] public foodMenu;

function listFood (uint256 _foodid, string memory _foodName, uint256 _price) public {
    require(checkId[_foodid] == false);
    Food memory newFood = Food(_foodid, _foodName, _price);
    foodMenu.push(newFood);
    checkId[_foodid] = true;
}

function findFood(uint256 _foodid) public view returns (uint256, string memory, uint256) {
    uint256 index;
    for (uint256 i=0; i<= foodMenu.length-1; i++) {
        if (_foodid == foodMenu[i].foodid) {
            index = i;
        }
    }
    return (foodMenu[index].foodid, foodMenu[index].foodName, foodMenu[index].price);
} 

function returnfoodMenu() public view returns (Food[] memory){
    return foodMenu;
}

function findFoodFromIndex(uint256 _index) public view returns (uint256, string memory, uint256) {
    return (foodMenu[_index].foodid, foodMenu[_index].foodName, foodMenu[_index].price);
} 

function returnFoodName(uint256 index) public view returns (Food memory) {
    return (foodMenu[index]);
} 


}