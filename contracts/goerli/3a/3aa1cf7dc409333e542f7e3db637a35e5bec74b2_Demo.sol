/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Demo {
    uint256 public number;
    // Person public person = Person({name: "aa", age: 22});

    mapping(string => uint8) private nameToAge;

    struct Person {
        string name;
        uint8 age;
    }

    Person[] public persons;

    function setNumber(uint256 _number) public virtual {
        number = _number;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function setPerson(string memory name, uint8 age) public {
        // Person memory person = Person(name, age);
        // persons.push(person);

        Person memory person = Person({name: name, age: age});
        persons.push(person);

        nameToAge[name] = age;

        // persons.push(Person(name, age));
    }

    function getAgeByName(string memory name) public view returns (uint8) {
        return nameToAge[name];
    }

    function test() private pure returns (uint256) {
        return 33 * 33;
    }
}