/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // '^' means anything above version is okay, or could set range '>=0.8.7 <0.9.0'

contract SimpleStorage {
    // boolean: true/false
    // uint: unsigned integer (just positive) if unspecifiend it will be uint256 (256 bits, lowest is 8)
    // 8 bits = 1 byte
    // int: integer positive/negative whole number
    // string represents word and has to be in " "
    // address: 0x... (eth address)
    // bytes32 represents 32 bytes (maximum size is 32)

    // if favouriteNumber is not assigned to a number, it means favouriteNumber = 0
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public favouriteNumberslist;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure no gas spent
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // 6 places to store data in solidity: calldata, memory, storage stack, code, logs (first 3 are most important)
    // calldata & memory are temporary variables, calldata cant be modified, memory can be modified
    // calldata & memory only exist in the duration of the function
    // storage is permanent variable that can be modified

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // people.push(People(_favouriteNumber, _name));
        // People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        // People memory newPerson = People(_favouriteNumber, _name);
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}