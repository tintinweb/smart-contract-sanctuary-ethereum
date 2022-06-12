// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public personToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public persons;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        persons.push(People(_favoriteNumber, _name));
        personToFavouriteNumber[_name] = _favoriteNumber;
    }
}