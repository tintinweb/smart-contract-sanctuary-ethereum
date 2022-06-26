/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // boolean, uint, int, address, bytes - data types
    // bool hasFavoriteNumber = true ;

    // string fovoriteNumberinText = "Five";
    // // strings are bytes but for only text
    // bytes32 myBytes = "cat"; //byte32 is maximum size

    uint256 favoriteNumber;

    // People is like a type just as string and uint256
    // it can be used to define new variables
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // People public person = People({favoriteNumber: 2, name: "Aiva"});

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    // mapping is like a dictionary where you store values based of other data types

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions dont spend tax to run
    // They disallow reading and modification of states
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //if a view/pure function is called from another function itll cost gas

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}