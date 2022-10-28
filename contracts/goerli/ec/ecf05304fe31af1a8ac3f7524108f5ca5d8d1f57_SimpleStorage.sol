/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12    ^ for this verison and all 0.8s above OR >=0.8.7 <0.9.0

// EVM ETHEREUM VIRTUAL MACHINE
// Avax, fantom, polygon

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0xf9d9b493e9D7479339cA71E8c767ccc0E26c2d4C;
    // bytes32 favoriteBytes = "cat"; // 0x12315151231

    // this is the default type of variable
    // uint internal favoriteNumber;

    // This gets initialized to zero!   and as storage
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata (temporary cant be modified), memory (temporary can be modified), storage (permanent can be modified)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}