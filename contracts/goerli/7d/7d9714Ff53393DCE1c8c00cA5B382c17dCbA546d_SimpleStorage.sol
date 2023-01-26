/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favouriteNumber;
    mapping(string => uint) public NameToFavourite;

    struct People {
        string name;
        uint favNum;
    }

    function store(uint _favNum) public virtual {
        favouriteNumber = _favNum;
    }

    function retrieve() public view returns (uint) {
        return favouriteNumber;
    }

    People[] public people;

    function addPerson(string memory _name, uint _favNum) public {
        people.push(People(_name, _favNum));
        NameToFavourite[_name] = _favNum;
    }
}