// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // version of compiler

contract SimpleStorage {
    struct Person {
        string name;
        uint256 favnum;
    }

    mapping(string => uint256) people;

    function store(string memory _name, uint256 _favnum) public virtual {
        people[_name] = _favnum;
    }

    function retrieve(string memory _name) public view returns (uint256) {
        return people[_name];
    }
}