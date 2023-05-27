// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint8 public favouriteNumber;

    struct People {
        uint8 favouriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint8) public peopleData;

    function setFavNumber(uint8 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint8) {
        return favouriteNumber;
    }

    function store(uint8 _favNum, string memory _name) public {
        people.push(People(_favNum, _name));
        peopleData[_name] = _favNum;
    }
}