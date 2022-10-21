// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import "hardhat/console.sol";

contract SimpleStorage {
    uint256 public myNumber;

    struct People {
        uint256 myNumber;
        string name;
    }

    People[] public person;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store (uint _myNumber) public {
        myNumber = _myNumber;
    }

    function retrieve() public view returns (uint256) {
        return myNumber;
    }

    function addPerson(uint256 _addNumber, string memory _addPerson) public {
        person.push(People({myNumber : _addNumber, name : _addPerson}));
        nameToFavoriteNumber[_addPerson] = _addNumber;
    }
}