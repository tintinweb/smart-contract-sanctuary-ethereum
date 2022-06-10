// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favNumber;

    struct People {
        string name;
        uint256 favNumber;
    }

    People[] public peopleArray;

    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        peopleArray.push(People(_name, _favNumber));
        nameToFavNumber[_name] = _favNumber;
    }
}