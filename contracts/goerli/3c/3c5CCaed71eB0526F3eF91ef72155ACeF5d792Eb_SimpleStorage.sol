/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    // This gets initialized to zero!
    uint256 public favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }


    People[] public people;


    People[3] public fixedSizePeopleArray;


    mapping(string => uint256) public nameToFavouriteNumber;


    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}