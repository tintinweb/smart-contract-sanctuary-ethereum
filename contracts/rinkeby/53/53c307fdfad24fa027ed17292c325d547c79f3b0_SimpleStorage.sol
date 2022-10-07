/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage {
    // Variables have a default value;
    uint256 number;
    // public, private, external, internal
    function setNumber(uint256 n) public {
        number = n;
    }
    // view, returns
    function getNumber() public view returns(uint256) {
        return number;
    }
    
    bool public soliidyIsEasy;

    // Structs
    struct Person {
        uint256 id;
        string name;
    }

    Person public author = Person(1, "Vijay");

    // Arrays
    Person[] public users;
    // Mapping
    mapping(string => Person) public usersMap;

    // memory, storage
    function addUser(string memory name, uint256 id) public {
        users.push(Person(id, name));
        usersMap[name] = Person(id, name);
    }
}