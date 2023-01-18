// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // '^' means anything above version is okay, or could set range '>=0.8.7 <0.9.0'

contract SimpleStorage {
    // boolean: true/false
    // uint: unsigned integer (just positive) if unspecifiend it will be uint256 (256 bits, lowest is 8)
    // 8 bits = 1 byte
    // int: integer positive/negative whole number
    // string represents word and has to be in " "
    // address: 0x... (eth address)
    // bytes32 represents 32 bytes (maximum size is 32)

    // if favoriteNumber is not assigned to a number, it means favoriteNumber = 0
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberslist;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure no gas spent
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // 6 places to store data in solidity: calldata, memory, storage stack, code, logs (first 3 are most important)
    // calldata & memory are temporary variables, calldata cant be modified, memory can be modified
    // calldata & memory only exist in the duration of the function
    // storage is permanent variable that can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push(People(_favoriteNumber, _name));
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPerson = People(_favoriteNumber, _name);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}