/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StorageTest{

    uint256 favoriteNumber = 21; // 0
    
    struct People {     // 1
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;     // 2
    mapping(string => uint256) public nameToFavoriteNumber;     // 3

    string staticString = "just testing storage stuff 1"; // 4

    string staticString2 = "idk what more to say blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah "; // 5

    string dynamicString1 = "dynamic dynamic dynamic dynamic dynamic dynamic dynamic dynamic dynamic dynamic dynamic "; // 6

    string dynamicString2 = "dynamic dynamic dynamic dynamic "; // 7

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function appendString1(string memory _str) public {
        dynamicString1 = string.concat(dynamicString1, '', _str);
    }

}