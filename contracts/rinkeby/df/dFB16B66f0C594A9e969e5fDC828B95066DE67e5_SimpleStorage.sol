//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favNumber;
    struct Person {
        string name;
        uint256 favNum;
    }
    mapping(string => uint256) public personToNumber;
    Person[] public people;

    function store(uint256 _num) public {
        favNumber = _num;
    }

    function getNum() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(Person(_name, _favNum));
        personToNumber[_name] = _favNum;
    }
}