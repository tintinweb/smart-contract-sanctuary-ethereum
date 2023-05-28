/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// EVM: Ethereum Virtual Machine

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    uint256 favoriteNumber; // Initialized to 0
    Person public person = Person({favoriteNumber: 2, name: "Jake"});
    mapping(string => uint256) public nameToFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // calldata, memory, storage
    // calldata and memory variables only exist temporarily during function call
    // calldata cannot be modified, memory can
    // storage variables exist outside of this function
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        Person memory newPerson = Person(_favoriteNumber, _name);
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}