/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; 

contract SimpleStorage{
    // This get initialized to zero
    // <- This means that this section is a comment!
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name; 
    }
    // dynamic array 
    People[] public people;


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

// view, just read state from blockchain - disallow modification of state
// pure functions disallow read from blockchain
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber; 
    }

}

// Dynamic Array []

// Basic Solidity, Memory (temp variables can be modified), Storage (permiment), Callback (can't change, temp), 
// EVM can store data in: Stack, Memory, Storage, Calldata, Code, Logs
// Basic Solidity Mappings - like a dictionary

// Address example: 0xd9145CCE52D386f254917e481eB44e9943F39138