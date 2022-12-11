/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //If we do not initialise it sets equal to 0
    uint256 favoriteNumber;
    //People has a public variable, as getter function called person
    //Now we have an array so we don't need this lines of code.
    // People public person = People({favoriteNumber: 7, name: "Aman"});

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view or pure function doesn't need gas to run
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);
        //or we can do like this in below line.
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}