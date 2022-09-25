// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favanumlist;
    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    uint256 public doubleInput;

    function doubler(uint256 num) public {
        doubleInput = num * 2;
    }

    function get() public view returns (uint256) {
        return doubleInput;
    }
}

// CONTRACTS FUNCTIONS & VISIBILITY
// after deployment, each smart contract is given an address
// must have semicolons in each line!
// public keyword makes a variable public, otherwise defaults to private
// public is actually a getter function that returns that value of that variable. 'favorite Number' button
// in blue is actuall a function. With private, only a specific contract can call the 'fav num' getter fxn
// external - outside fxns only can call this fxn
// internal - fxn and children call call this fxn
// without specifying a visibility keyword, a variable is automatically assigned 'internal'
// variables are function-scoped

// DATA TYPES
// bool favoriteNum = true;
// uint256 favNum = 123;
// // positive, whole
// //256 is the bits
// //unsigned integer
// int256 favorNum = -5;
// // positive or negative, whole
// string favText = "5";
// address myAdd = 0xca0b60B9ce318BCc9E387AbfEB22D98a9127c352:
// bytes32 favBytes = "cat";
// // 32 is max size of a byte
// // bytes obj get converted into 0x.....
// // strings get converted into bytes