/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256 public favoriteNumber; //initialised to 0.

    mapping(string => uint256) public nameToFavoriteNumber;

    struct people {
        uint256 favoriteNumber;
        string name;
    }

    people[] public p; //array of struct

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        p.push(people(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}