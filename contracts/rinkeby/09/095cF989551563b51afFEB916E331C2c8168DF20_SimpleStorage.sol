// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // versioning: ^, >= 0.8.x < 0.8.x

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public mapPersonToNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People( _favoriteNumber, _name));
        mapPersonToNumber[_name] = _favoriteNumber;
    }
}