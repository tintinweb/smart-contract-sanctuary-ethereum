/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// you have to specify compiler the version of solidity you want to use
// if you write pragma 0.8.7 it will specifically 0.8.7 whereas pragma ^0.8.7 states
// any version of 0.8.7 or above it will work
// you can use the version in specific range as well - pragma solidity >= 0.8.7 < 0.9.0

contract SimpleStorage {
    // boolean , unit, int, address, bytes
    bool hasFavouriteNumber = false;
    uint public favouriteNumber = 24;
    //  if you don't initialise it by default it initialise to zero
    string favouriteNumberIntext = "256";
    int256 favouriteNumberInt = -5;
    address myAddress = 0x2de5d17C456dEc425393DDEA256A7e1CBA431Ee4;
    bytes32 favouriteBytes = "cat"; // strings are bytes object used only for text

    mapping(string => uint256) public nameTOFavouriteNumber;
    struct People {
        uint256 favouriteNumber; // defining user defined data type
        string name;
    }

    // People person = People({favouriteNumber : 0202, name : "Parikshit"}) ;
    // this way you add entries in variable

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addElement(uint256 _favouriteNumber, string memory _name) public {
        People memory p = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        people.push(p);
        nameTOFavouriteNumber[_name] = _favouriteNumber;
    }
}