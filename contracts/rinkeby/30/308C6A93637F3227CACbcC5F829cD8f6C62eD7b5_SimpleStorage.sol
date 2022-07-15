// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint favoriteNumber; // public varibles create getter funciton

    mapping(string => uint) public nameToFavoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people; // people Array - used for list - dynamic: no size initialized

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name)); // push is the eqiv to adding, order varibles same as struct
        nameToFavoriteNumber[_name] = _favoriteNumber; // _name is the string key nametofavNum is mapping name
    }
}