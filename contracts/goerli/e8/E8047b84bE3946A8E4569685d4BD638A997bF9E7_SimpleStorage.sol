// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favouriteNumber;

    struct Person {
        string name;
        uint256 favouriteNumber;
    }

    Person[] public people;

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(Person(_name, _favouriteNumber));
    }

    function incrementNumber() public {
        favouriteNumber++;
    }

    function decrementNumber() public {
        favouriteNumber--;
    }
}