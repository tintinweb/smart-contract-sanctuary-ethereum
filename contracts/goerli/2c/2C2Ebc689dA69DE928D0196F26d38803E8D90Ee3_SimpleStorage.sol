/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    // People public people1 = People({
    //     favoriteNumber: 3,
    //     name: "Ukatane"
    // });
    // People public people2 = People({
    //     favoriteNumber: 4,
    //     name: "Patrick"
    // });

    // instead of doing this 👆 over and over, we can simply use an array

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 1;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage etc
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}