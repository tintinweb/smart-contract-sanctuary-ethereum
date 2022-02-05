/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract dev5 {
    struct Person {
	string name;
	string lastName;
	uint age;
    }

    Person [] public persons;

    function addPerson(string memory _name, string memory _lastname, uint _age) public {
        persons.push(Person({name: _name, lastName: _lastname, age:_age}));
    }

    function addPerson2(string calldata _name, string calldata _lastname, uint _age) public {
        persons.push(Person({name: _name, lastName: _lastname, age:_age}));
    }

    function addPerson3(string memory _name, string memory _lastname, uint _age) public {
        Person memory person = Person(_name, _lastname, _age);
        persons.push(person);
    }

    function addPerson4(string calldata _name, string calldata _lastname, uint _age) public {
        Person memory person = Person(_name, _lastname, _age);
        persons.push(person);
    }
}