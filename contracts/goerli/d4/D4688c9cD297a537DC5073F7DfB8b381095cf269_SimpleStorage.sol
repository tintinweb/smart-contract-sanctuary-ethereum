// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // ^ = any version and above

contract SimpleStorage {
    //boolean, uint (whole number, +), int (whole number, + or -),
    // address, bytes
    // bool hasFavoriteNumber = true;
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x95087DFd490c67eb1E5b309531AC032E19B244b3;
    // bytes32 favoriteBytes = "cat";

    //initialized to 0
    //a getter function
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view and pure don't use gas (no modification of state)
    //pure can't read
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}