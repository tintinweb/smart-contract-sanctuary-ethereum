// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract store {
    uint256 favouriteNumber;

    struct People {
        string person;
        uint256 number;
    }

    mapping(string => uint256) public nameToNumber;
    People[] public people;

    function addNumber(uint256 _num) public {
        favouriteNumber = _num;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function adderson(uint256 _number, string memory _name) public {
        people.push(People(_name, _number));
        nameToNumber[_name] = _number;
    }
}