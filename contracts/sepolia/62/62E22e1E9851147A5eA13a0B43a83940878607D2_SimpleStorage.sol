// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public peopleList;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        peopleList.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}