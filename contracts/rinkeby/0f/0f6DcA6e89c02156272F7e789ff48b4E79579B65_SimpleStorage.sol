// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract SimpleStorage {
    uint256 public favoriteNumber;

    address public owner;

    People[] public people;

    mapping(address => uint256) public personToFavoriteNumber;

    struct People {
        address name;
        uint256 favoriteNumber;
    }

    constructor() {
        owner = msg.sender;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(address _name, uint256 _favoriteNumber) public {
        personToFavoriteNumber[_name] = _favoriteNumber;
        people.push(People(_name, _favoriteNumber));
    }
}