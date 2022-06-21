// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Person {
        string name;
        uint256 favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    Person[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(Person(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}