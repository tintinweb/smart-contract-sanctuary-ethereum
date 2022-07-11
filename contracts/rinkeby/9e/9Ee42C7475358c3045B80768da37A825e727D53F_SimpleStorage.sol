/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favorite;
        string name;
    }

    function store(uint256 _favoritenumber) public virtual {
        favoriteNumber = _favoritenumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({name:_name,favorite: _favoriteNumber});

        people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}