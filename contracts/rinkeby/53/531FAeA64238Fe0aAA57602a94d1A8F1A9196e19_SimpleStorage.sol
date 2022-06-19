// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // Latest is 0.8.14

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        // strings are really just a subset of bytes32
        // but casting between string memory and bytes not allowed
        string firstName;
        string lastName;
    }
    // uint256[] public anArray;
    Person[] public people;

    mapping(string => mapping(string => uint256)) private _nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Six places the EVM can access & store data:
    // Data location can only be specified for array, struct or mapping types
    //                                        (a string is an array of bytes)
    //            * - most important
    // - Stack
    // - Memory*    - only exists temporarily
    // - Storage*   - default for globally defined variables
    // - Calldata*  - only exists temporarily & cannot be modified
    // - Code
    // - Logs

    function nameToFavoriteNumber(
        string calldata _firstName,
        string calldata _lastName
    ) public view returns (uint256 _favoriteNumber) {
        _favoriteNumber = _nameToFavoriteNumber[_lastName][_firstName];
    }

    function addPerson(
        string memory _firstName,
        string memory _lastName,
        uint256 _favoriteNumber
    ) public {
        people.push(Person(_favoriteNumber, _firstName, _lastName));
        _nameToFavoriteNumber[_lastName][_firstName] = _favoriteNumber;
    }
}