// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint number;
    struct People {
        uint number;
        string name;
    }

    mapping(string => uint) public nameToNumber;

    People[] public people;

    function store(uint _newNumber) public virtual {
        number = _newNumber;
    }

    function retreive() public view returns (uint) {
        return number;
    }

    function addPerson(string memory _name, uint _number) public {
        people.push(People(_number, _name));
        nameToNumber[_name] = _number;
    }
}