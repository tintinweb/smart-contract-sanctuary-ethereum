// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // This get atomatically initialized to zero
    uint256 favoriteNumber;

    // mapping is like getting the unit related to the given string e.g balilkis => 22
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // function to assign uint to favoriteNumber
    function store(uint256 _favouriteNumber) public virtual {
        favoriteNumber = _favouriteNumber;
    }

    // function to retrieve favoriteNumber, view function does cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        // calling mapping function
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}