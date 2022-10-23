/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// compiler version
// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; //array
    mapping(string => uint256) public nameToFavoriteNumber; //mapping

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name)); // adding to array
        nameToFavoriteNumber[_name] = _favoriteNumber; // adding to mapping
    }
}