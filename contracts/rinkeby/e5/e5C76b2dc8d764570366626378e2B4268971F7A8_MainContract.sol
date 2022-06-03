/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MainContract {
    struct Person {
        string name;
        uint256 age;
    }

    mapping(string => Person) map;

    function add(string memory _name, uint256 _age)
        public
        returns (Person memory)
    {
        map[_name] = Person({name: _name, age: _age});
        return map[_name];
    }

    function retrieve(string memory _name) public view returns (Person memory) {
        return map[_name];
    }
}