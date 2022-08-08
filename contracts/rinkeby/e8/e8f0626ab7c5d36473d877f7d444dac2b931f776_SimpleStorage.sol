/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12 latest version maybe

contract SimpleStorage {
    // Types: boolean, uint (positive values only, int, address, bytes (32 is the max size), string
    uint256 favoriteNumber; // = 0, if not specified, the visibility is internal, storage variable

    mapping(string => uint256) public nameToFavoriteNumber; // dictionary

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure: gasless, only a call, unless a non view/pure function calls a view/pure function
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage: important data storage keywords
    // memory: temporary modifiable variables
    // storage: exists even outside
    // calldata: temporary not modifiable variables
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}