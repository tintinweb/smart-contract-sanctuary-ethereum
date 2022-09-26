/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // Version

contract SimpleStorage {
    uint256 favoriteNumber; //This is initialized as Zero

    mapping(string => uint256) public findByName;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        findByName[_name] = _favoriteNumber;
    }
}