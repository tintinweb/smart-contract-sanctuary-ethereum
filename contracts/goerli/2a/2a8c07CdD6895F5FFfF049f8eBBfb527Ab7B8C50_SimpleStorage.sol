// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    struct People {
        string name;
        uint8 age;
    }

    People[] public arrays;
    uint256 public num;
    mapping(string => uint8) public nameToAge;

    function store(uint256 _newNum) public virtual {
        num = _newNum;
    }

    function retrieve() public view returns (uint256) {
        return num;
    }

    // storage: Permanent variables that can be modified
    // memory: temp variables that can be modified || need for arrays (also strings), structs, and mapping
    // calldata: temp variables that cannot be modified
    function addPerson(string calldata _name, uint8 _age) public {
        arrays.push(People({age: _age, name: _name}));
        nameToAge[_name] = _age;
    }

    function getAge(string calldata _name) public view returns (uint8) {
        return nameToAge[_name];
    }
}