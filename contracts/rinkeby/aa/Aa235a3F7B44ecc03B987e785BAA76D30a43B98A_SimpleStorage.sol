/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    People[] public people;
    mapping(uint256 => string) public favouriteNumberToname;
    mapping(string => uint256) public nameTofavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameTofavouriteNumber[_name] = _favouriteNumber;
        favouriteNumberToname[_favouriteNumber] = _name;
    }
}