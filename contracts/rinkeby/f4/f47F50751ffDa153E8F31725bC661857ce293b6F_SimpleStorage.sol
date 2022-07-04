// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;
    mapping(string => uint256) public nameTofavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // view, pure
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(Person({name: _name, favoriteNumber: _favoriteNumber}));
        nameTofavoriteNumber[_name] = _favoriteNumber;
    }
}