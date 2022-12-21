/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint favNumber;
    Person[] public people;

    struct Person {
        uint personsFavNumber;
        string personsName;
    }

    mapping(string => uint) public nameToFavNumber;

    function store(uint _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns(uint) {
        return favNumber;
    }

    // calldata, memory and storage.

    /**
    * calldata and memory are specifying that the variable being created is going to be in the memory temporarily
    * while the function is being executed.
    * storage specifies that the variable will be kept in memory.
    * calldata is different from memory because calldata specifies that the variable will not change its value during the
    * function execution.
    */

    function addPeople(uint num, string memory name) public {
        people.push(Person(num, name));
        nameToFavNumber[name] = num;
    }
}