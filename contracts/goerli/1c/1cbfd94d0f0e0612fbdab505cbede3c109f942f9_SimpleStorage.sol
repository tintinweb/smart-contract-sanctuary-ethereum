/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    mapping(string => uint256) public nameToFavoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}