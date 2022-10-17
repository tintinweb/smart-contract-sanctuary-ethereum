/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct User {
        string name;
        uint256 phoneNum;
    }

    User[] public usersList;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addUser(string memory _name, uint256 _phoneNum) public {
        usersList.push(User(_name, _phoneNum));
        nameToFavoriteNumber[_name] = _phoneNum;
    }
}