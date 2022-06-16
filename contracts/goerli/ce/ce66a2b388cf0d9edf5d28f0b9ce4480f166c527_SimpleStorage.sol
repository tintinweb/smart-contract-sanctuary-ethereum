/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * Demo contract
 **/
contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    /**
     * View, Pure do not write to the blockchain and don't cost any gas
     * unless called from a function/contract that costs gas.
     *
     * Pure can be used for calculation without using properties, e.g.
     * return(1+1);
     **/
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}