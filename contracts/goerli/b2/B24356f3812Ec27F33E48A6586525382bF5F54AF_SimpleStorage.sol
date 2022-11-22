// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 number = 200;
    mapping(string => uint256) public nameToAge;

    struct Person {
        string name;
        uint256 age;
    }

    Person[] public people;

    function changeNumber(uint256 _number) public virtual {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    function addPerson(string memory _name, uint256 _age) public {
        people.push(Person(_name, _age));
        nameToAge[_name] = _age;
    }
}