/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: SimpleStorage.sol

contract SimpleStorage {
    // this will get initialized to 0!
    uint256 favoriteNumber;
    bool favoriteBool;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function king() public pure returns (string memory) {
        return "Hello king Bobo!!!!";
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function inc() public returns (uint256) {
        favoriteNumber = favoriteNumber + 1;
        return favoriteNumber;
    }
}