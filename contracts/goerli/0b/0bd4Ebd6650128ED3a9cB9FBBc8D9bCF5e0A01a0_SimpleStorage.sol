// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//favnum, people struct, array of people, retrieve favnum, add

contract SimpleStorage {
    uint256 public favNum;

    struct Person {
        string name;
        uint256 favNum;
    }

    Person[] public people;

    function add(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(uint256 _favNum, string memory _name) public {
        people.push(Person(_name, _favNum));
    }
}