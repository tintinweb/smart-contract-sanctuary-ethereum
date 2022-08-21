/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

//SPDX-License-Identifier: MIT

//check licenses on github

pragma solidity ^0.8.7; //stable version

//^ - any version of 0.8.7 or above is okay
//>=0.8.7 <0.9.0 - within specific range

//similar to a class
contract SimpleStorage {
    //boolean, uint8-256, int8-256, address, bytes2-32 or more?, string

    //this gets initialized to zero
    uint256 public favoriteNumber; //default internal
    People public person = People({favoriteNumber: 2, name: "Patrick"});
    mapping(string => uint256) public nameToFavoriteNumber; //a dictionary where every single name is going to map to a specific number

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; //dynamic array - size not given. ex: [3] size given

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;

        // OR
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // OR People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);
    }

    function getFavorite() public view returns (uint256) {
        //getter function
        return favoriteNumber;
    }
}