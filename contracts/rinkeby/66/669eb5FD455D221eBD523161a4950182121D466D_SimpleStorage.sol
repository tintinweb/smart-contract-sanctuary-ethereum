/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // uint = just positive numbers
    // int = both negative and positive numbers
    // bytes = bytes object

    // this gets initialized to 0
    uint256 public favoriteNumber;

    People public person = People({favoriteNumber: 5, name: "Edward"});

    // a struct is like a object
    // creates a new Type
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // ARRAYS
    // fixed-size array: People[3] public people;
    People[] public people;

    // Mappings
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // calling view or pure functions doesn't cost gas unless the
    // function is called within another function that costs gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // 1. calldata variables can't be modified
    // 2. memory variables can be modified
    // 4. Storage variables are stored permanently and can be modified
    // 3. calldata and memory store variables temporarily
    // similar to how function local variables usually work

    // strings, structs, arrays, mappings could use memory keyword
    // a string is secretly an array, hence why it could use memory
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //_name = 'LOL';
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}