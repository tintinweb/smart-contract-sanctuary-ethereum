// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    struct Person {
        string name;
        uint256 favoriteNumber;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function addPersonMemory(Person memory _person) public {
        people.push(_person);
        nameToFavoriteNumber[_person.name] = _person.favoriteNumber;
    }

    function addPersonCalldata(Person calldata _person) public {
        people.push(_person);
        nameToFavoriteNumber[_person.name] = _person.favoriteNumber;
    }

    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve_fave_number() public view returns (uint256) {
        return favoriteNumber;
    }
}