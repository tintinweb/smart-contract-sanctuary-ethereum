// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // We need the compiler to know which solidity version we are using. ^ means any verison above and 0.8.7 will work

contract SimpleStorage {
    // This get initialized to 0
    uint256 public favouriteNumber;

    struct Person {
        uint favouriteNumber;
        string name;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    // Adding visibility to a function is important. If we dont specify visibility, it will give error
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // When we store something in the blockchain, we send a transaction

    // When we dont give a visibility specifier to func or variables it's visiblity is automalically specified to internal ( means only that contract and its func can access it).

    // view means we are reading something from the contract, pure means we are not even reading from the contract

    // Calldata is temporary variables that cant be modified, memory are temp variables which can be modified.

    // Data location (memory,calldata) can only be speicfied to array, struct or mapping types. Behind the scenes, string is an array of bytes therefore string also.

    function addPeople(uint _favouriteNumber, string memory _name) public {
        Person memory p = Person({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        people.push(p);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // The ability of contracts to interact with each other is called composability.
}