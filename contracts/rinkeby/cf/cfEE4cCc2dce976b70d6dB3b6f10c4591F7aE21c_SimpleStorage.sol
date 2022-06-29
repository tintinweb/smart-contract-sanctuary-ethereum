// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // or we can specify the range here like ^0.8.8

contract SimpleStorage {
    uint256 favoriteNumber;

    People[] public people;

    // this is like a key-value pair
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // storage = permanent variables that can be modified
    // memory = temporary variable that can be modified
    // calldata = temporary variavle thatn cannot be modified
    // NO NEED TO put data location to uint since solidity already knows where it is located,
    //    data location is only needed in arrays, structs, maps (string is an array)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}