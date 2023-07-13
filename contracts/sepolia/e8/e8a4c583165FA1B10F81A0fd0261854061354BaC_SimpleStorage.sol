// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favNum;

    mapping(string => uint256) public nameToFavNum;

    People[] public person;

    function store(uint256 _favNum) public virtual {
        favNum = _favNum;
    }

    struct People {
        uint256 favNum;
        string name;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        person.push(People(_favNum, _name));
        nameToFavNum[_name] = _favNum;
    }
}