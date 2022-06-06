/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // Only this version

// pragma solidity ^0.8.7 // This version or newer
// pragma solidity >=0.8.7 <0.9.0 // Any version in the range

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    bool hasFavoriteNumber = true;

    // default value = null which is 0 in solidity
    // uint256 favoriteNumber;

    // default visibility is internal
    uint256 favoriteNumber;

    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // Struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Array
    // uint256 public favoriteNumbersList
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view & pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // function add() public pure returns (uint256) {
    //     return 1+1;
    // }

    // calldata - temp, not modifiable, memory - temp, modifiable, storage - permanent, modifiable
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name}); // Other ways to get this same data
        // People memory newPerson = People(_favoriteNumber, _name); // less explicit
        people.push(People(_favoriteNumber, _name));
        // mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
        // people.push(newPerson);
    }
}