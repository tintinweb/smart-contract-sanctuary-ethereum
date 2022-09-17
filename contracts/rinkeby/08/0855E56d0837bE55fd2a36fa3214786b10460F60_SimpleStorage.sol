// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract SimpleStorage {
    struct Person {
        uint256 number;
        string name;
    }
    Person[] public person;

    function addPeople(string memory _name, uint256 _number) public {
        person.push(Person(_number, _name));
    }
}