//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favouriteNumber;

    People[] public person;

    mapping(string => uint256) nameToFavouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        person.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}