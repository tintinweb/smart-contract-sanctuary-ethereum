//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SimpleStorage {
    uint public favoriteNumber;

    mapping(string => uint) public nameToNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint _number) external virtual {
        favoriteNumber = _number;
    }

    function addPeople(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }
}