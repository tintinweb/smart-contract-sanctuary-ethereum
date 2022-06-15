/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct Person {
        string name;
        uint age;
    }

    Person[] public peopleList;
    address public immutable i_owner;
    mapping( string => uint ) public nameToAge;

    constructor(){
        i_owner = msg.sender;
    }

    function addPerson(string calldata newName, uint newAge) public {
        if (msg.sender!=i_owner) {
            revert();
        }
        peopleList.push(Person(newName,newAge));
        nameToAge[newName] = newAge;
    }
}