// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // very stable version of solidity [carat ^ means any version of this or greater will work]

contract SimpleStorage {
    // a contract is just like a class in other languages
    // boolean, uint, int and address are the four main types of Solidity "types". ALso "bytes".
    // strings are realy just bytes objects, but for text... can do bytes1 - bytes32
    // uints can be done in binary steps from 2-256
    uint256 favoriteNumber;
    //People public person = People({favoriteNumber: 2, name: "Patrick"});

    //create a mapping
    mapping(string => uint256) public nameToFavoriteNUmber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // here we're setting up an  array because [].  This is a dynamic array coz we don't give it a size e.g. [3]
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        // virtual needed so we can override in another function
        favoriteNumber = _favoriteNumber;
    }

    // view and pure just mean we're reading something from a contract [blue tabs] - no gas needed
    function retrieve() public view returns (uint256) {
        return (favoriteNumber);
    }

    // create a function to add people to our array
    // note that structs, mappings and arrays need to be given one of the following keywords...
    // calldata = temp vars can't be modified
    // memory = temp vars that can be modified
    // storage = perm vars that can be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);
        people.push(People(_favoriteNumber, _name)); // just one line version of ^ - probably more efficient/less gas!
        nameToFavoriteNUmber[_name] = _favoriteNumber; // in addition to adding to our array, also add name to mapping
    }
}