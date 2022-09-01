// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // Data Types : boolean, unit, int, address, bytes, string

    // Unititialized variables will be initialized with default value for that data-type.
    // Here, for uint256 it will be 0
    uint256 favoriteNumber;

    // Custom data
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 2, name: "Mani"});

    // Arrays
    People[] public personsList;

    // Mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure methods indicates that this fuction only reads data off the block chain
    // resulting in less gas price and free to use unless a non-view or pure function calls it
    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    // this function adds person to the personsList array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        personsList.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}