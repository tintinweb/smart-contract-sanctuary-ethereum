// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // uint256 favoriteNumber = 5;
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0xCE4797cb8f8593a8946A80dea0Cda88BcC6b7bd5;
    // bytes32 = favoriteBytes = "cat";

    // This gets initialized to zero
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPerson = People(_favoriteNumber, _name);
        // people.push(newPerson);
        // people.push(People(_favoriteNumber, _name));
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}