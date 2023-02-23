// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public number;

    function store(uint256 num) public virtual {
        number = num;
    }

    function retrive() public view returns (uint256) {
        return number;
    }

    struct Person {
        string name;
        uint256 favNum;
    }

    Person[] public people;

    mapping(string => uint256) public nameToNum;

    function addPerson(string memory _name, uint256 num) public {
        people.push(Person(_name, num));
        nameToNum[_name] = num;
    }
}