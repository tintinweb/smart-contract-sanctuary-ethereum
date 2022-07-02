/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //stating version >= or >

contract SimpleStorage {
    uint256 FavoriteNumber = 0;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        FavoriteNumber = _favoriteNumber; // pure function?
    }

    function retrieve() public view returns (uint256) {
        return FavoriteNumber; //view reads what favourite number is
    }

    // Calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}