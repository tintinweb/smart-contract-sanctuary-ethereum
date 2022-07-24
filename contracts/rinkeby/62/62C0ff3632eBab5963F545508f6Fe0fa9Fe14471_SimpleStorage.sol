/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    People[] public people;

    mapping(string => uint256) public fN;

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        fN[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}