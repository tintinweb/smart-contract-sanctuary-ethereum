/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favNum;

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNum) public {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _nameS, uint256 _favNumS) public {
        people.push(People(_favNumS, _nameS));
        nameToFavNumber[_nameS] = _favNumS;
    }
}