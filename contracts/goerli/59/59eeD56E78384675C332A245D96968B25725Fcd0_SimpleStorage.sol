/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favNumber;

    mapping(string => uint256) public listPersons;

    struct People {
        uint256 age;
        string name;
    }

    People[] public person;

    function store(uint256 x) public virtual {
        favNumber = x;
        favNumber += 2;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    //People public person = People({age: 25, name: "dave"});

    function addPerson(uint256 _age, string memory _name) public {
        // USE THIS
        /*
        People memory single_person = People({age: _age, name: _name});
        person.push(single_person);
        */

        // OR THIS
        person.push(People(_age, _name));
        listPersons[_name] = _age;
    }
}