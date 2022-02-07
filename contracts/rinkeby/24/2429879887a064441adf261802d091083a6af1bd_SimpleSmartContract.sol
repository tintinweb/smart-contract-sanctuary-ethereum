/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleSmartContract{
    struct Person{
        string name;
        int age;
        uint256 balance;
    }

    Person[] public persons;

    function getPersons() public view returns (Person[] memory){
        return persons;
    }

    function addPerson(Person memory _person) public {
        persons.push(_person);
    }

    function updatePerson(uint256 _index, Person memory _person) public {
        persons[_index] = _person;
    }
}