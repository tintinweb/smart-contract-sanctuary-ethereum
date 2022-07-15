// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favNum;

    mapping(string => uint256) public nameToFavNum;

    People[] public people;
    // uint256[] public favoriteNumList;

    struct People {
        uint256 favNum;
        string name;
    }

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() external view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        People memory newPerson = People({favNum: _favNum, name: _name});
        people.push(newPerson);
        nameToFavNum[_name] = _favNum;
    }
}