// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    struct People {
        uint256 myNum;
        string myName;
    }

    People[] public people;
    mapping(string => uint256) public manyPeople;

    function addPeople(string memory _myName, uint256 _myNum) public {
        people.push(People(_myNum, _myName));
        manyPeople[_myName] = _myNum;
    }
}