// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNum;

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people;

    function addperson(uint256 num, string memory Name) public {
        // We use memory for string "Name" because memory/calldata only
        people.push(People(num, Name)); // need to be used for array, struct and string is somehow array
    }

    function store(uint256 _num) public virtual {
        favNum = _num;
    }

    // Memory is used to temporarily during function execution
    // Storage used to store the data after the function execution
    // Calldata store data which cannot be changed

    function retrive() public view returns (uint256) {
        return favNum;
    }

    function add(uint256 _num) public {
        favNum += _num;
    }
}