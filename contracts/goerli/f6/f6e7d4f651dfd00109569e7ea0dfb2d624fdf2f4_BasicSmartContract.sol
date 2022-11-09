/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract BasicSmartContract { 
    struct Person {
        string name;
        uint256 rollNumber;
        string class;
    }

    mapping(address => Person) private persons;

    function setPerson(uint256 _rollNumber, string memory _name, string memory _class) external {
        persons[msg.sender].name = _name;
        persons[msg.sender].rollNumber = _rollNumber;
        persons[msg.sender].class = _class;
    }

    function getPerson(address _person) public view returns (Person memory) {
        return persons[_person];
    }
}