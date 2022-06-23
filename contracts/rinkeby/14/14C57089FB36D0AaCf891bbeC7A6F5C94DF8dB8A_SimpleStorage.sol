// SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        string name;
        uint favoriteNumber;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        favoriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}