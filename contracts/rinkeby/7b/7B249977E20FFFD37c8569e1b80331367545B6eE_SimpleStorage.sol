/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT

// we need to specify on the beggining on the file version of solidity as it is a new language constantly developing(^, >=, < - we can specify which versions we want to use, the range of versions...)
pragma solidity 0.8.7;

// tels compiler that the next line of code is contract
contract SimpleStorage {
    // boolean, uint, int, address, bytes
    uint256 favoriteNumber; // gets initialized with default value 0

    // People public person = People({favoriteNumber: 2, name: "Danijel"});

    // instead looping through array and searching for specific value we can use mapping to find the value by key
    // as example we are mapping name to favourite number
    mapping(string => uint256) public nameToFavouriteNumber;

    // object, similar structure to JS objects
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // array
    People[] public people;

    // for a function to be overrideble in another contract we need to add keyword virtual
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure funcntions when called alone don't spend gas -> we are just reading state of a variable
    // if view or pure functionas are called from functions that cost gas then we have to pay for gas in such cases
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // calldata - temporary variables that can't be modified
    // memory - temporary variables that can be modified
    // storage - permanent variables that can be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138