/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //boolean,uint,int,address,bytes

    bool hasFavoriteNumber = true;

    uint256 favoriteNumber = 8; // defualt is uint265

    string favoriteText = "hello";

    //只读函数使用view关键字，不消耗gas
    //练习写一个只读函数
    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    function setFavoriteNumber(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    struct People {
        uint256 age;
        string name;
    }

    function getPeople() public pure returns (People memory _people) {
        return People({age: 1, name: "hello"});
    }
}