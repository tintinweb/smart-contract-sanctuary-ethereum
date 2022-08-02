/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7; // can also do ^0.8.8 which means 0.8.8 and up

contract SimpleStorage {
    // boolean, uint, int, address, bytes

    // Inits to zero by default
    // NOTE: Makes a getter function by default
    uint256 public favoriteNumber;
    People public person = People({favoriteNumber: 2, name: "George"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNum) public virtual {
        favoriteNumber = _favNum;
    }

    // NOTE: View and pure functions, when called alone, don't spend gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // NOTE: calldata, memory means variable will exist temporarily
    //       calldata variable cannot be reassigned
    //       memory variable can be reassigned
    // NOTE: storage variables will exist even outside function call (permanent)
    // NOTE: why does uint256 not need memory?
    //       array, struct of mapping types are special types that need to be told where to be stored
    //       string type is really an array of bytes so it needs a memory keyword
    //       uint256 is a known type to be stored in memory by default
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}