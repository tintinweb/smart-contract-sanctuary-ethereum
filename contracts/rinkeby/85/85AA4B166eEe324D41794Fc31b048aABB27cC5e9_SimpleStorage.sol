//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleStorage {
    // EVM -> Ethereum Virtual Machine
    // EVM compatible -> Avalanche, Fantom, Polygon

    // //boolean, uint, int, bytes, address
    // bool public hasFavoriteNumber = false;
    // uint8 favoriteNumber = 255;// if not specified, it defaults to 256 bits
    // string favoriteNumberInText = "Five";
    // int favoriteInt = -5;
    // address myAdress = 0x7a48751118125Aa4F5F77c3afCB3F48A27007cec;
    // bytes32 favoriteByte = "cat";

    uint256 public favoriteNumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage -> data locations
    //calldata can't change it's value once assigned
    //array, mapping and structs types need their data location specified
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        // _name = "cat";
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}