// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
    uint256 favNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavNum;
    People[] public persons;

    function addPerson(string memory _name, uint256 _favNumber) public {
        persons.push(People(_favNumber, _name));

        nameToFavNum[_name] = _favNumber;
    }

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}