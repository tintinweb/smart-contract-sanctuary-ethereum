//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; //0.8.12 solidity version.

contract SimpleStorage {
    uint256 favouriteNumber = 5;

    mapping(string => uint256) public nameToFavouriteNumber;
    People[] public people;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}