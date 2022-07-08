/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

pragma solidity ^0.8.7; //SPDX-License-Identifier: UNLICENSED

contract SimpleStorage {
    uint256 favouriteNumber;
    People[] public people;
    mapping(string => uint256) public favNumDictionary;

    struct People {
        uint256 favNum;
        string name;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPeople(string memory _name, uint256 _favNum) public {
        People memory newPerson = People({favNum: _favNum, name: _name});
        people.push(newPerson);
        favNumDictionary[_name] = _favNum;
    }
}