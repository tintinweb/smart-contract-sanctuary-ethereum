// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // by default gets initialized to zero
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

    // pure, view
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata - temporary variable that can NOT be modified
    // memory - temp variable that CAN be modified
    // storage - permanent variable that CAN be modified
    // structs, mappings, and/or arrays need to have be given one of these types.. and string's are actually array's
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}