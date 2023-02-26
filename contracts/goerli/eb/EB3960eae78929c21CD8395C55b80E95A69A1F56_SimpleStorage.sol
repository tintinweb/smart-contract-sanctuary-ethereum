/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People public people;
    People[] public peopleArray;

    mapping(string => uint256) public nameToFavoriteNo;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peopleArray.push(People(_name, _favoriteNumber));
        nameToFavoriteNo[_name] = _favoriteNumber;
    }
}