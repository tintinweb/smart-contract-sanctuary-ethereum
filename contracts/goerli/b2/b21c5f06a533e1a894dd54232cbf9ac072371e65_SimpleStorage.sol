/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct People {
        string name;
        uint256 favoriteNumber;
    }
    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    function addPerson(
        string memory _name,
        uint256 _favouriteNumber //virtual: can override function in a child class.
    ) public virtual {
        People memory newPerson = People({
            name: _name,
            favoriteNumber: _favouriteNumber
        });
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function getPerson(string memory _name) public view returns (uint256) {
        return nameToFavouriteNumber[_name];
    }
}