// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favNum;

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    struct People {
        uint256 favNum;
        string name;
    }

    mapping(string => uint256) public nameToFavNum;

    function addPerson(string memory _name, uint256 _favNum) public {
        person.push(People(_favNum, _name));
        nameToFavNum[_name] = _favNum;
    }

    People[] public person;
}