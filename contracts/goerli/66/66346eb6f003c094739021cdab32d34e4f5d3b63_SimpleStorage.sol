/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public people;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}