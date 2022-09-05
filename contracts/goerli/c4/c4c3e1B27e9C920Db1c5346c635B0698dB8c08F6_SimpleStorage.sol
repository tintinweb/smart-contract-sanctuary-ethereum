/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // you can add a carrot ^ if you want to use a certain version and above

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) nameToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        People memory person = People(_favoriteNumber, _name);
        people.push(person);
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }
}