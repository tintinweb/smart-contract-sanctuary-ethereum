//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favNum;

    function store(uint256 num) public virtual {
        favNum = num;
    }

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public person2Num;

    function AddPerson(string memory name, uint256 num) public {
        people.push(People(num, name));
        person2Num[name] = num;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }
}