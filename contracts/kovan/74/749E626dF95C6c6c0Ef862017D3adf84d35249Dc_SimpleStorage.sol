//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favtoriteNumber;

    struct People {
        uint256 favtoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favNo) public virtual {
        favtoriteNumber = _favNo;
    }

    function retreive() public view returns (uint256) {
        return favtoriteNumber;
    }

    function addPerson(uint256 _favNo, string memory _name) public {
        people.push(People(_favNo, _name));
        nameToFavoriteNumber[_name] = _favNo;
    }
}