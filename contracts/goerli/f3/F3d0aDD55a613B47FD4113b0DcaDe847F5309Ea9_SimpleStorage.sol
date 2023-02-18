/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.12

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNum) public virtual {
        favoriteNumber = _favNum;
    }

    mapping(string => uint256) public nameToFavNumber;

    // View function
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        //people.push(People({name: _name, favoriteNumber: _favNum}));
        people.push(People(_favNum, _name));
        nameToFavNumber[_name] = _favNum;
    }
}