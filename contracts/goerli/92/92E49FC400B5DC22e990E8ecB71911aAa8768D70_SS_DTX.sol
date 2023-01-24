//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SS_DTX {
    struct Person {
        string name;
        uint256 favoriteNumber;
    }

    uint256 public favoriteNumber;
    Person[] public personList;
    mapping(string => uint256) public personToFavoriteNumber;

    constructor() {
        favoriteNumber = 100;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        personList.push(Person(_name, _favoriteNumber));
        personToFavoriteNumber[_name] = _favoriteNumber;
    }
}