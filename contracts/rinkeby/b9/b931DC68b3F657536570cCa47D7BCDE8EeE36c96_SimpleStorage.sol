// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // Set global uint value to 0
    uint256 favoriteNumber; // Data types: boolean, uint, int, address, bytes
    // Function visibility: public, private, external, internal

    // Create a hashmap mapping string to uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    // Create a struct People
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Create a dynamic array of structs, People
    People[] public people;

    // Setter function that stores _favoriteNumber as the global favoriteNumber variable
    function store(uint256 _favoriteNumber) public virtual {
        // Make function overridable by giving it the virtual keyword
        favoriteNumber = _favoriteNumber;
    }

    // Getter function that retrieves the favoriteNumber var
    function retrieve() public view returns (uint256) {
        // view, pure
        // view: read but cannote modify state
        // pure: cannot read or modify state
        // Costs no gas because state was not modified
        return favoriteNumber;
    }

    // EVM can store information in 6 ways
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // calldata, memory, storage
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}