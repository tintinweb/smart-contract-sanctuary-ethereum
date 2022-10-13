/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    uint256[] public numbers;

    People[] public people;

    mapping(string => uint) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    function add() public pure returns (uint) {
        return (1 + 1);
    }
}