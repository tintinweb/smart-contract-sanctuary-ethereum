// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favouriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // memory,calldata,storage
    // memory and calldata is used to store data of variable for temporarily

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}