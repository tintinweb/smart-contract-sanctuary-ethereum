/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    // Variables
    uint256 favouriteNumber;
    struct Person {
        uint256 favNum;
        string name;
    }
    Person[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    // setter to set the fav number
    function setFavouriteNumber(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // getter to get the fav number
    function getFavNum() public view returns (uint256) {
        return favouriteNumber;
    }

    // adding a person to the people array
    function addPerson(uint256 _favNum, string memory _name) public {
        people.push(Person(_favNum, _name));
        nameToFavouriteNumber[_name] = _favNum;
    }
}