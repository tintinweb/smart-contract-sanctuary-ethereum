//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // contract keyword in solidity
    // initialized to default (0)
    // public keyword is also creating a getter function to get this value
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    // array of people
    // dynamic array which can be any length
    // we can limit it to 3 for example by doing People[3] ...
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view function - we are not chaning anything so we are not paying the gas
    // caling this function is free, but not if you call it inside contract
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        nameToFavoriteNumber[_name] = _favoriteNumber;
        people.push(People(_favoriteNumber, _name));
    }
}