/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // This gets initialized to zero
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public favoriteNumbersList;
    People[] public people;

    // 0: 2, Patrick, 1:

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //uint256 textVar = 5;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory and storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}