/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12; // Solidity version

contract SimpleStorage {

    // bool hasFav = true;
    uint256 public favNumber; // initialised to zero
    // int256 numberInt = -100;
    // address testAccount = 0x5F5C12039F40eF58f0DF90646c627a5D674f8dbd;
    // string sNumber = "100";
    // bytes32 favBytes = "bytesFav";

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    struct People {
        uint256 favNumber;
        string name;
    }

    People public person = People({favNumber: 2,name:"Atharv"});
    People[] public people;

    mapping(string => uint256) public nameToFavNumber;


    function addPerson (string memory _name, uint256 _favNumber) public { 
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }

}