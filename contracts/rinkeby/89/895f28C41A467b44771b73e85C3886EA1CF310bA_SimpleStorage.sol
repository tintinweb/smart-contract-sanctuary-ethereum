/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    //uint public favoriteNumbersList;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}