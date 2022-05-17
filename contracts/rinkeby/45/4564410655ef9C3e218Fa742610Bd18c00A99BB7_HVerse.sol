/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.13;

//SPDX-License-Identifier: MIT

contract HVerse {

  struct Building {
    string name;
    int8 w;
    int8 h;
    int8 d;
    int8 x;
    int8 y;
    int8 z;
  }

  Building[] public buildings;
  
  constructor() {
    buildings.push(Building("ZERO", 0,0,0,0,0,0));
    buildings.push(Building("House",1,3,2,2,0,3));
    buildings.push(Building("Jimmy House",2,5,4,10,0,6));
    buildings.push(Building("Gallery",1,6,2,10,0,0));
    buildings.push(Building("House",1,1,2,7,0,-7));
    buildings.push(Building("Cool House",2,3,1,-9,0,-9));
    buildings.push(Building("House",1,3,3,-4,0,2));
    buildings.push(Building("Ray House",2,5,2,-2,0,5));
    buildings.push(Building("House",2,6,1,-10,0,4));
    buildings.push(Building("Ghost house",4,1,4,5,0,0));
    buildings.push(Building("Beach House",3,1,3,-4,0,-5));
    buildings.push(Building("Library",2,2,3,-10,0,0));
    buildings.push(Building("House",3,2,2,-3,0,-2));
    // hello
  }

  function getBuildings() public view returns (Building[] memory) {
    return buildings;
  }
}