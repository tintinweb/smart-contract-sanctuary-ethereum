// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // boolean, uint, int, address, bytes, string

    // uint256 is intialized to 0 automatically
    // public -> visibility specifier
    // internal -> default specifier
    uint256 favoriteNumber;

    // key: string
    // value: uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people; // dynamic array as size is unspecified

    // virtual - keyword allows function to be overidden
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // data location is only specified for struct, array, and mapping types (string is an array)
    // data location types: calldata, memory, storage
    function addPerson(string memory _name, uint _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        People memory newPerson = People(_favoriteNumber, _name); // another way to initialize struct variable
        people.push(newPerson);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}