// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // boolean, uint (unsigned integer whole number only prositive),
    // int(+- whole number), address, bytes
    // bool hasFavoriteNumber = false;
    // uint favoriteNumber = 9; // default to uint256
    // string favoriteNumberInText = "9";
    // address myAdress = 0x76093d23292B4595f395FE73aa77d408EFbcea9D;
    // bytes32 favoriteBytes= "cat";

    //this gets initialized to zero
    uint256 favoriteNumber;
    People[] public people;

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

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}