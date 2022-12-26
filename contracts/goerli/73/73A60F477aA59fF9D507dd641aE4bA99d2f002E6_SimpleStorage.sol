/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public number;

    mapping(string => uint256) public nameToNumber;

    struct People {
        uint256 number;
        string name;
    }

    People[] public people;

    function store(uint256 _number) public virtual {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    function addPeople(string memory _name, uint256 _number) public {
        people.push(People(_number, _name));
        nameToNumber[_name] = _number;
    }
}