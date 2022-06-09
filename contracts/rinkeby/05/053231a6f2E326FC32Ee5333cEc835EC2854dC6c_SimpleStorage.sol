// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Ploygon

contract SimpleStorage {
    // boolean, strings, uint, int, address, bytes : Data Types
    uint256 favouriteNumber;

    // Structure
    // People public person = People({favouriteNumber: 2, name: "Divesh"});
    struct People {
        uint256 favouriteNumber;
        string name;
    }
    People[] public people;

    // Mapping
    mapping(string => uint256) public nameToFavouriteNumber;

    // FUNCTIONS
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People({favouriteNumber: _favouriteNumber, name: _name}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}