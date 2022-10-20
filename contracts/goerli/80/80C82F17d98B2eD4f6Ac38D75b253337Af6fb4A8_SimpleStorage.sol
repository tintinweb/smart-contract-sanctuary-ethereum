/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoritreNumber;

    mapping(string => uint256) public nameTofavoriteNumber;

    struct People {
        uint256 favoritreNumber;
        string name;
    }

    // uint256[] public favoritreNumberList;
    People[] public people;

    function store(uint256 __favoriteNumber) public virtual {
        favoritreNumber = __favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoritreNumber;
    }

    function addPerson(string memory __name, uint256 __favoriteNumber) public {
        people.push(People(__favoriteNumber, __name));
        nameTofavoriteNumber[__name] = __favoriteNumber;
    }
}