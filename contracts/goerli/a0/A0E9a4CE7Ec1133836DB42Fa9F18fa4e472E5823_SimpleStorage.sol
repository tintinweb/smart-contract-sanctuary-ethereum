/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // boolean, uint, int, address, byte

    uint256 favoriteNumber; // This gets initialized to zero

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
      uint favoriteNumber;
      string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
      favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
      return favoriteNumber;
    }

    // calldata --> temporary data not modifiable, memory --> temporary data modifiable, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
      people.push(People(_favoriteNumber, _name));
      nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}