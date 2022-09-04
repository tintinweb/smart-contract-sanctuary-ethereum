/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// "contract" is the core concept in writing smart contracts.
// It's similar to classes in oop.
contract SimpleStorage {
    // declaring an unsigned integer of 256 bits (2^256).
    // If we don't specify a value, it'll automatically
    // be initialized to null (or 0 in our case).
    // If we make favoriteNumber public, we allow it to be called to be displayed
    // (i.e. we can see the blue "favoriteNumber" btn to access the integer value)
    // Public variable implicitly gets assigned a (getter)
    // function that returns its value.
    uint256 favoriteNumber;

    // "struct" can create new data types (basically objects).
    // aka "People" is considered a new data type now
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // declaring a dynamic array (since its size isn't specified)
    // "People[4]" would, for example, mean the array can only hold 4 people.
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    // declaring a function that can store a different integer in the "favoriteNumber" variable.
    // adding _ in front of variables is a solidity convention for parameters.
    // "virtual" makes the func overridable in factory contracts
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // declaring a function that reads the blockchain (due to "view" keyword)
    // it doesn't create any new transactions  (hence no gas fees)
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Pushing a new "newPerson" object into the "people" array
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        // we could also shorten it to "people.push(People(_favoriteNumber, _name}))";
        // because the People struct or object is zero-indexed.

        // connecting name and favoriteNumber via a mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// blue buttons are "view" functions