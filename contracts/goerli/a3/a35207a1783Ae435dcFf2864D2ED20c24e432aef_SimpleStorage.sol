// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 luckyNumber;

    struct People {
        uint256 luckyNumber;
        string name;
    }

    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToluckyNumber;

    function store(uint256 _luckyNumber) public {
        luckyNumber = _luckyNumber;
    }

    function retrieve() public view returns (uint256) {
        return luckyNumber;
    }

    function addPerson(string memory _name, uint256 _luckyNumber) public {
        people.push(People(_luckyNumber, _name));
        nameToluckyNumber[_name] = _luckyNumber;
    }
}