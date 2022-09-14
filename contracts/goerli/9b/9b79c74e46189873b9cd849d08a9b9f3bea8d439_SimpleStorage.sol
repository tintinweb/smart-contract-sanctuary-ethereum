/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favorateNumber;

    struct People {
        uint256 herNumber;
        string name;
    }
    mapping(string => uint256) public nameMap;

    People public person = People({herNumber: 1, name: "ww"});

    People[] public peopleList;

    function store(uint256 number) public virtual {
        favorateNumber = number + 1;
    }

    function addPerson(uint256 number, string memory name) public {
        peopleList.push(People(number, name));
        peopleList.push(person);
        nameMap[name] = number;
    }

    function show() public view returns (uint256) {
        return favorateNumber;
    }
}