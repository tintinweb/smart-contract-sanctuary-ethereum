// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // mention the version of solidity

// contract will help solidity to understand "it is contract"
contract SimpleStorage {
    // First let's discuss about data types
    // Basic types: Boolean, String, uint, int, bytes
    /* access modifiers -> public, private, external, internal(default) */
    uint256 favoriteNumber;

    // by default the value of uint is "zero"
    // People public people = Person({favoriteNumber: 25, name: "praneeth"});

    // Array is used to sequence of objects
    People[] public people;

    // mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // custom data type using "struct"
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // computational functions leads to high gas fee
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure functions doesn't need a gas fee
    /* view: A function which cannot alter the state of the contract just return the variables.
       pure: A function which cannot alter as well as read values from the contract*/
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function sum() public pure returns (uint256) {
        return 2 + 3;
    }

    // memory -> temporary, can be modified
    // calldata -> temporary, cannot be modified
    // sotrage -> default, permanent (global scope)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });

        // short way of creating people object.
        // people.push(People(_favoriteNumber,_name));
        people.push(newPerson);

        // adding to mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

/* EVM  - Ehereum Virtual Machine 
    EVM compatible -> Avalanche, Fantom, Polygon
    EVM can access and store information in six places
        stack
        memory
        storage
        calldata
        code
        logs
*/