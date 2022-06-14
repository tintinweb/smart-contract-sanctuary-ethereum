// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//^ this version or above //pragma solidity >=0.8.7 <0.9.0;

contract SimpleStorage {
    uint256 public num = 100;

    struct People {
        uint256 age;
        string name;
    }

    People public person1 = People({age: 30, name: "mazen"});

    mapping(string => uint256) public nametoage;
    People[] public persons;

    function store(uint256 _number) public virtual {
        num = _number;
    }

    function retrieve() public view returns (uint256) {
        return num;
    }

    function addPerson(string memory _name, uint256 _age) public {
        persons.push(People(_age, _name));
        nametoage[_name] = _age;
    }
}