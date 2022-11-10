/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 num) public virtual {
        favoriteNumber = num;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // People public personData = People({7,"Shash"});
    People[] public peopleData;

    function addPerson(string memory n, uint256 fnum) public {
        People memory newPerson = People({name: n, favoriteNumber: fnum});
        peopleData.push(newPerson);
        nameToFavoriteNumber[n] = fnum;
    }
}