// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    People[] public person;

    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint216 _number) public {
        favouriteNumber = _number;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPeople(string memory _name, uint256 _number) public {
        person.push(People({favouriteNumber: _number, name: _name}));
        nameToFavouriteNumber[_name] = _number;
    }
}