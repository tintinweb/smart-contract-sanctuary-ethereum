// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint public favouriteNumber;

    struct People {
        uint favouriteNumber;
        string name;
    }
    People[] public people;
    mapping(string => uint) public nameToFavNumber;
    
    function addPerson(string calldata _name, uint _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavNumber[_name] = _favouriteNumber;
    }

    function getFavNumberWithName(string memory _name) public view returns(uint) {
        return nameToFavNumber[_name];
    }
}