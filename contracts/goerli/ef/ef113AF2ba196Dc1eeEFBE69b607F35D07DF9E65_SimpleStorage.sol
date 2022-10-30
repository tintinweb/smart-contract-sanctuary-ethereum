/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT;

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favNo;

    struct People {
        uint256 favNo;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavNo;

    function store(uint256 _favNo) public {
        favNo = _favNo;
    }

    function retrieve() public view returns (uint256) {
        return favNo;
    }

    function addPerson(string memory _name, uint256 _favNo) public {
        people.push(People(_favNo, _name));
        nameToFavNo[_name] = _favNo;
    }
}