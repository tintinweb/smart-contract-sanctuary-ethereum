// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Contract {
    struct People {
        string name;
        string surname;
    }

    People[] people;

    function addPeople(string memory name, string memory surname) public {
        people.push(People(name, surname));
    }

    function getFirst() public view returns (string memory) {
        return people[0].name;
    }
}