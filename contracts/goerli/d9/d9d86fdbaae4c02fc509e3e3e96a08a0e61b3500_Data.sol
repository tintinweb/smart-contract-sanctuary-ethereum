/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IData {
    struct Person {
        string name;
        uint8 age;
    }

    error NotOwner(address);
    event PersonSet(string name, uint256 indexed age);
}

contract Data is IData {
    address public owner;
    Person public person;

    constructor(address _owner) {
        owner = _owner;
    }

    function setPerson(Person calldata _person) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        person = _person;

        emit PersonSet(_person.name, _person.age);
    }

    function getPerson()
        external
        view
        returns (Person memory)
    {
        return person;
    }
}