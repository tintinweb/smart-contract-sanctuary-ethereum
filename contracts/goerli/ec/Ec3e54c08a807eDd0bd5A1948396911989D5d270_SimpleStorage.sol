// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // this is how to indicate the version of solidity that we're going to be using.

contract SimpleStorage {
    uint256 favoriteNumber;
    // the variable above isnt assigned a value so in solidity gives it an intial value of zero

    mapping(string => uint256) public nameTofavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // creating an array in solidity
    People[] public people;

    // creating functions in Solidity
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieval() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameTofavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138