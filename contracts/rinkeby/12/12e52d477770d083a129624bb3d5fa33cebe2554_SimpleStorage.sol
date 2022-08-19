/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint numb; // by default, it is 'private'

    struct Person {
        string name;
        uint favNumber;
    }

    Person[] public persons;

    mapping(string => uint) public nameToFavNumb;

    function store(uint _numb) public {
        numb = _numb;
    }

    function retreive() public view returns (uint) {
        return numb;
    }

    function addPerson(string memory name, uint favNumb) public {
        nameToFavNumb[name] = favNumb;
        Person memory newPerson = Person(name, favNumb);
        persons.push(newPerson);
    }
}