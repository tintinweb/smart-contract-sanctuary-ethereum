/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

contract SimpleStorage {
    // This will get initialized to 0!
    uint256 public favoriteNumber;

    mapping (string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    
    constructor () {
        favoriteNumber = 10;
        people.push(People(favoriteNumber, "Nathan"));
    }

    function store (uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve () public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson (string calldata _name, uint256 _favoriteNumber)external {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}