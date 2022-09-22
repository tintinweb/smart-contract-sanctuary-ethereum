/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // version 0.8.7 or higher

contract SimpleStorage {
    // contract: key word that defines the start of a contract in solidity
    // solidity basic types: boolean, uint, int, address, bytes ---> used to declare variables like let, const, var in JS

    //This gets initialized to 0
    // the default visibilty of a func or variable is internal, add public keyword to make it public
    uint256 public favoriteNumber; // make favorite number visible; creates a getter function for fave# i.e return the val of fave#

    mapping(string => uint256) public nameToFavoriteNumber; //dictionary; string name is being mapped to uint256 fave #

    struct People {
        // people object // new class/data type like uint256
        uint256 favoriteNumber;
        string name;
    }
    //making a people array with data type People
    People[] public people; //this is a dynamic array because size is not given at initialization; if we wrote People[3], that would be an array of size 3

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        favoriteNumber += 1;
    }

    //view and pure functions when called alone, don't spend gas; they also disallow any modification or updates to variables
    //pure func also disallow you to read from blockchain state
    //returns here is used as a keyword to show what datatype this function will be returning
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        //People memory newPerson = People( _favoriteNumber, _name); // another way of creating a new person object (an instance of people)
        //people.push(newPerson);
        people.push(People(_favoriteNumber, _name)); //// another way of creating an instance of people
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}