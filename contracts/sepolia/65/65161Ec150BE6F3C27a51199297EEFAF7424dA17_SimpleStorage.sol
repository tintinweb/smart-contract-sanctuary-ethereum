/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Storage Types: memory, calldata, storage
    // memory means data that will not be stored on chain AND
    // can be mutable within the function

    // calldata also means data that will not be stored on chain AND
    // is NOT mutable within the function

    // both memory and calldata can only be used for arrays, structs, and mappings

    // you will never specify storage as a keyword, that is simply a data designation
    // by default all global variables are storage variables
    // (i.e. written to chain = storage)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}