/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 favoriteNumber_) public {
        favoriteNumber = favoriteNumber_;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(uint256 favoriteNumber_, string memory name_) public {
        People memory newperson = People(favoriteNumber_, name_);
        people.push(newperson);
        nameToFavoriteNumber[name_] = favoriteNumber_;
    }
}