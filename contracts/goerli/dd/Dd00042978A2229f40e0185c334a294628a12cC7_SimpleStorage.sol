// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favnum;

    struct People {
        uint256 favN;
        string name;
    }
    People[] public people;
    function fav(uint256 t) public {
       favnum = t;
    }
    function retrieve() public view returns(uint256){
        return favnum;
    }

    function addPerson(uint256 favnumber , string memory nb) public{
        people.push(People(favnumber,nb));
    } 
}