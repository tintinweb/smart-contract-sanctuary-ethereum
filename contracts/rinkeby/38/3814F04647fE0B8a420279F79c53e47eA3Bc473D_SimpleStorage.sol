/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {

    // null value is 0
    uint256 favouriteNumber;

    // a getter
    function retrieve() public view returns(uint256) {
        return favouriteNumber;
    }

    // a setter
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNUmber;
        string name;
    }

    People[] public people;

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
    
}