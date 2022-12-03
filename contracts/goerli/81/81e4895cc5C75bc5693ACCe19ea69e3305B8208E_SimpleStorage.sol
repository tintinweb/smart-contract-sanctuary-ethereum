/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // an uint256 is the same as uint
    // uint256 can only be a positive number
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct Human {
        uint256 favoriteNumber;
        string name;
    }

    // an array of humans
    Human[] public humans;

    // stores favorite number
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // doesn't cost gas since it is only reading from the chain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // adds humans to array
    function addHuman(string memory _name, uint256 _favoriteNumber) public {
        humans.push(Human(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}