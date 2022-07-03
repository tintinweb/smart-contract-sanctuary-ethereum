//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint favouriteNumber;

    struct People {
        uint favouriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint) public nameToFavouriteNumber;

    function store(uint _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}