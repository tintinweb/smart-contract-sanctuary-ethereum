/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

contract SimpleStorage {
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    People[] people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // favoriteNumber = favoriteNumber + 1;
    }

    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }

    //  calldata, memory, storage
    // calldata and memory is temporary
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({name: _name, favoriteNumber: _favoriteNumber});
        nameToFavoriteNumber[_name] = _favoriteNumber;
        people.push(newPerson);
    }
}