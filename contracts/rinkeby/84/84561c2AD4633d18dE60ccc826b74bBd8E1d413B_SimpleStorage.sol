/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

// Next line added to make licensing easier but not req
// SPDX-License-Identifier: MIT

// solidity version
// pragma solidity ^0.8.8; //0.8.8 version or later
// pragma solidity >=0.8.7 <0.9.0  --> any version between
pragma solidity ^0.8.7; //--> version 0.8.7 or later

// Contracts will have own address once dpeloyed
// More complex contracts will cost more gas
contract SimpleStorage {
    /*
    Data Types
    bool hasFavoriteNumber = true;
    uint256 favoriteNumber = 5;
    string favoriteNumberInText = "Five";
    int256 favoriteInt =-5;
    address myAddress = 0x01a6CF5461f96D4d82fdEcbf6472b8f666A68Dd0;
    bytes32 favoriteBites = "cat"   // bytes are strings converted to bytes 0x01asf...
    */

    /*
    Visibility Specifiers --> public, private, external, internal
    */

    uint256 public favoriteNumber = 5;
    People[] public people; //Dynamic array no fixed size

    // data structure to map a string to a uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        string name;
        uint256 faveNum;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view function same as making a variable public
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure and view functions do not cost gas
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    /*
    EVM can access and store info in 6 places
    memory -- temp variables that can be modified
    calldata -- temp variables that cannot be modified
    storage -- permanent variables that can be modified
    --> stack, code, logs
    */

    // arrays (string is  an array of bytes), structs, and mappings
    // need to specify EVM in param ("memory")
    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(People(_name, _favNum));
        nameToFavoriteNumber[_name] = _favNum;
    }
}