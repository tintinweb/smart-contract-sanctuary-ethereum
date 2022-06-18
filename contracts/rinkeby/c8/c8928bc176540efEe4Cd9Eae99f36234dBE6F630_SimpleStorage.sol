//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favNumber;

    struct Person {
        string name;
        uint256 favNumber;
    }

    Person[] public persons;
    mapping(string => uint256) public nameToNumber;

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        persons.push(Person(_name, _favNumber));
        nameToNumber[_name] = _favNumber;
    }
}