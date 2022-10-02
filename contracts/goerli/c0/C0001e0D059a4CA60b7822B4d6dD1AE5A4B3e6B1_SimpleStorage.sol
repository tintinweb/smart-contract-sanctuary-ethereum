// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber; //is same line as -- uint256 favoriteNumber = 0
    // default visibility is -- internal
    // People public people = People({favoriteNumber: 2, name: "Patrick"})

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure keywords don't spend gas, unless you call inside them function that spends gas
    // view - can not modify but read
    // pure - can not modify and also can not read

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // calldata and memory temporarily
    // calldata can not be modified
    // memory can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}