/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorageLDI {
    uint256 FavNumber;

    struct People {
        uint256 FavNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _FavNumber) public {
        FavNumber = _FavNumber;
    }

    function retrieve() public view returns (uint256) {
        return FavNumber;
    }

    function addPerson(string memory _name, uint256 _FavNumber) public {
        people.push(People(_FavNumber, _name));
        nameToFavNumber[_name] = _FavNumber;
    }
}