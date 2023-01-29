//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favouriteNumber; 

    struct People {
        uint256 favouriteNumber;
        string name; 
    }

    People[] public person;

    mapping(string=>uint256) public nameToFavoriteNumber;

    //functiion
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrive() public view returns(uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public{
        person.push(People(_favouriteNumber,_name));
        nameToFavoriteNumber[_name] = _favouriteNumber;

    } 
}