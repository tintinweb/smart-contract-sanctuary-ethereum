/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // init myNumber variable
    uint256 favoriteNumber;
    People public person = People({favoriteNumber: 2, name: "Billy"});

    mapping(string => uint256) public nameSearch;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public allPeople;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        allPeople.push(People(_favoriteNumber, _name));
        nameSearch[_name] = _favoriteNumber;
    }
}