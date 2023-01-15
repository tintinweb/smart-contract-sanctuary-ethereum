// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) nameToFavouriteNumber;

    People[] public people;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}