// SPDX-License-Identifier: MIT

// Solidity version
pragma solidity 0.8.8;

contract SimpleStorage {
    // this will get iniatilised to 0!
    uint256 favouriteNumber;
    bool favouriteBool;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    // Changes the value of favouriteNumber to variable passed into function
    function store(uint256 _favouriteNumber) public returns (uint256) {
        favouriteNumber = _favouriteNumber;
        return _favouriteNumber;
    }

    // Retrieves the value of favouriteNumber
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // Adds a person to People array
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}