// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 number;

    struct Person {
        uint256 number;
        string name;
    }

    Person[] public people;
    mapping(string => uint256) public nameToNumber;

    function store(uint256 _number) public {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    function addPerson(string memory _name, uint256 _number) public {
        people.push(Person(_number, _name));
        nameToNumber[_name] = _number;
    }
}