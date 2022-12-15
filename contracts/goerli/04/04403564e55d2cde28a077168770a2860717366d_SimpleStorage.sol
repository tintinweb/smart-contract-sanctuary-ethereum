/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function ShowNumber() public view returns (uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name) public {
        people.push(People(favoriteNumber, _name));
        nameToFavoriteNumber[_name] = favoriteNumber;
    }
}