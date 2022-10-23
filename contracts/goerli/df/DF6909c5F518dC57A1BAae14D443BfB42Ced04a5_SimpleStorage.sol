/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.7 gratter than 0.8.7

// EVM, Ethereum Virtual Machine compile
// compatible EVM, Avalanche Fantom Polygon, so you can write your solidity contract and run them on these platform.

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // uint256 num = 123;
    // int num2 = 345;
    // string favoriteNumberInText = "Five";
    // address myAdress = 0x234l;
    // bytes32 favoriteBytes = "cat";

    uint256 public favoriteNumber; // initialized to zero

    // array
    // if we donot give a number than array length can be anything
    People[] public peoples;
    uint256[] public favoriteNumbers;

    // object
    People public person = People({favoriteNumber: 2, name: "wsp"});
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 1;

        // if you call view or pure in this function, will spend gas fee
        retrieve();
    }

    // view and pure functions, when called alone, don't spend gas
    // disallow modify state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure function
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // string is a byte array, struct, mapping types
    function addPersion(string memory _name, uint256 _favoriteNumber) public {
        peoples.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // EVM can access and store information in six places
    // Stack Memory Storage Calldata Code Logs
    // Calldata memory both temp store, but calldata can not been modified

    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;
}