/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // Specifies the version of the compiler

contract SimpleStorage {
    //similar to Class
    /* 
    Basic Data Types
    * Boolean
    * uint
    * int
    * address
    * bytes
    */

    uint256 favouriteNumber; // Sets to default null value (0)
    // Default visibility is internal
    // Global Scope

    //mappings
    mapping(string => uint256) public nameToFavouriteNumber;

    //struct
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //array
    //uint256[] public favouriteNumbersList;
    People[] public people;

    //function
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view
    function retreive() public view returns (uint256) {
        return (favouriteNumber);
    }

    //pure
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //function to add person to array
    function addPerson(uint256 _favouriteNumber, string memory _name) public {
        People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);
        //people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber; //adding to mappings
    }
}