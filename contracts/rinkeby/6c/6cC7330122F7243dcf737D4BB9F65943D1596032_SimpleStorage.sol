/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; //version

contract SimpleStorage {
    struct People {
        uint256 favNumber;
        string name;
    }

    mapping(string => uint256) public peopleMap;
    uint256 number;

    function store(uint256 _number) public virtual {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    People[] public people;

    function addPerson(uint256 _number, string memory _name) public {
        people.push(People(_number, _name));
        peopleMap[_name] = _number;
    }
}