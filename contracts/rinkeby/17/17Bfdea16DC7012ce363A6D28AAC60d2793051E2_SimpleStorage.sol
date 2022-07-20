// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favNum;

    struct Person {
        uint256 favNum;
        string name;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavNum;

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(uint256 _favNum, string calldata _name) public {
        people.push(Person(_favNum, _name));
        nameToFavNum[_name] = _favNum;
    }
}