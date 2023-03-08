/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // data types
    // boolean, uint, int, address, bytes
    bool hasFavouriteNumber = true;
    uint256 favouriteNumber = 1323;
    string favouriteNumberInWords = "five";
    bytes32 favouriteBytes = "cat ";

    // EVM can access and store information in 6 places
    // - Stack
    // - Memory
    // - Storage
    // - calldata
    // - code
    // - logs

    // calldata, memory - means the variable exists temporarily
    // storage - means variable exists outside the function
    // calldata - you can't modify the temporary variable
    // memory - you can modify the temporary variable

    // memory and calldata can be used in structs, mappings and arrays

    // mapping
    // this creates a data type mapping
    // more like a dictionary where each key returns the value of the other key

    mapping(string => uint256) public nameToFavouriteNumber;

    // struct
    // this creates a data type called people
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // using the struct
    People public person = People({favouriteNumber: 894, name: "Jimy"});

    // array
    // dynamic array
    People[] public people;

    // static array
    // uint256[4] public favouriteNumbersList;

    // functions
    // this function can be overriden by child contract
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // this function adds the struct people to the array
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // people.push(People( _favouriteNumber, _name))
        People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138