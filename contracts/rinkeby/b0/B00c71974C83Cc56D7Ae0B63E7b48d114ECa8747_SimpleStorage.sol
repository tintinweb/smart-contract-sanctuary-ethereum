// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Contract is like a keyword in solidity.
//  It tells solidity that the next piece of code is gonna define contract.
//  it behaves similar to a class in JAVA

contract SimpleStorage {
    //boolean, uint, int, address, bytes, strings

    // Creating a People struct
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    uint256 public favoriteNumber;

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        // Add to mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}