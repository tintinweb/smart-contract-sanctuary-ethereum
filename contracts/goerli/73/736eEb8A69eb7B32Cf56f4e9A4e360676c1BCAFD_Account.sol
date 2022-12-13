/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Account {

    People public person = People({ name: "Travis", age: 21 });

    People[] public Persons;

    mapping (string => uint) public getAge;

    struct People {
        string name;
        uint age;
    }

    function addPerson(string memory _name, uint _age) public {
        Persons.push(People(_name, _age));
        getAge[_name] = _age;
    }
}