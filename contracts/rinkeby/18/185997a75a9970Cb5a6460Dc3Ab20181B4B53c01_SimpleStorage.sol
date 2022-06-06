/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    uint256 public favoriteNumber;
    Person public dheeraj = Person({favoriteNumber: 10, name: "Dheeraj"});

    Person[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    // By saying virtual, we mean that this method can be overridden
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    // view disallows changing the state of the blockchain
    // pure also works as view but also disallowing reading the state of the blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add(uint256 _num1, uint256 _num2) public pure returns (uint256) {
        return _num1 + _num2;
    }

    // Data Locations
    // Data Locations can only be specified for array, struct or mapping
    // string is an array of bytes in solidity
    // calldata, memory, storage
    // calldata and memory are temporary storage
    // storage is permanent storage
    // favoriteNumber by default is a storage variable
    // calldata is constant and it's value cannot be changed inside function's scope
    // whereas memory variable's value can be changed inside the function's scope
    function addPerson(uint256 _favoriteNumber, string calldata _name) public {
        Person memory newPerson = Person({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}