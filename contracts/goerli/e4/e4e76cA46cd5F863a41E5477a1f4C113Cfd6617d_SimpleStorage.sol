/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Solidity version ^ - from defined version to the latest

contract SimpleStorage {
    //boolean, string, uint, int, address, bytes
    uint256 public favoriteNumber; // this gets initialised to 0 if we don't define the value

    //Struct - createing your own data type!
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //mapping data structure
    mapping(string => uint256) public nameToNumber;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage (three big places to store and access info)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        //Mapping call
        nameToNumber[_name] = _favoriteNumber;
    }
}