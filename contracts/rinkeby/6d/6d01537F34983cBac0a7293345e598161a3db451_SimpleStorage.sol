// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    bool hasFavoriteNumber = true;
    uint256 public favoriteNumber; // Uninitialized number get set to 0 by default

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // arrays get initialized with the brackets
    // it is automatically a view function

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //bytes have up to size 32

    // view, pure
    // view and pure do not allow any modifications to the blockchain
    // this means that they do not burn any gas

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    // calldata, memory, storage

    // calldata and memory only exist while being used in functions

    // calldata: temporary variables that can't be modified
    // memory: temporary variables that can be modified
    // storage: permanent variables that can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // EVM Overview

    // EVM can access and store information in 6 places.

    // 1. Stack
    // 2. Memory
    // 3. Storage
    // 4. Calldata
    // 5. Code
    // 6. Logs
}