// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favNumber;

    // object or structure
    struct People {
        uint256 myAge;
        string myName;
    }

    // maps (key object pairs)
    mapping(string => uint256) public nameToAge;

    // people array of type People(object or structure)
    People[] public people;

    // adding person function
    function addPerson(string memory _myName, uint256 _myAge) public {
        people.push(People(_myAge, _myName));
        nameToAge[_myName] = _myAge;
    }

    // storing the favNumber
    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    // View function
    // Note : Pure & View functions doesn't needs GAS until and unless they are called inside the regular functions which needs gas
    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}