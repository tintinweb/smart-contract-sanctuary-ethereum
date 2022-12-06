/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint favNumber;
    function setFavNumber(uint _fav) public {
        favNumber = _fav;
    }
    function getFavNumber() public view returns(uint) {
        return favNumber;
    }

    struct Person {
        string name;
        int age;
    }

    Person[] public people;
    mapping(string => int) public peopleMapping;

    function addPerson(string memory name, int age) public {
        people.push(Person(name, age));
        peopleMapping[name] = age;
    }
}