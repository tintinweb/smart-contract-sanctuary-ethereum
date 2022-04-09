/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract MyTestContract {

    struct Person {
        string name;
        uint age;
        string sevgilisi;
    }

    mapping(string => uint) public nameToAge;

    Person[] public persons;

    constructor() {}

    function addPerson(string memory _name, uint _age, string memory _sevgilisi) public {
        persons.push(Person(_name, _age, _sevgilisi));
        nameToAge[_name] = _age;
    }

    function getPersonAgeByName(string memory _name) public view returns(uint) {
        return nameToAge[_name];
    }

}