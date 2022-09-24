// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => string) public favoriteNumberToName;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    //functions are modules that execute a task that can be used over again in the contract
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}