/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favnumber = 10;
    struct Student {
        string name;
        uint256 number;
    }
    Student[] public list;
    mapping(string => uint256) public nameToNumber;

    function addDetails(string memory _name, uint256 _number) public {
        list.push(Student(_name, _number));
        nameToNumber[_name] = _number;
        _number = favnumber;
    }

    function store(uint256 _favoriteNumber) public {
        favnumber = _favoriteNumber;
    }

    function retrive() public view returns (uint256) {
        return favnumber;
    }
}