/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // different ways are 0.8.7, >= 0.8.7 <0.9.0 for a range

//EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolesn, uint, int, address, bytes, string
    /*bool hasFavoriteNumber = false;
    uint favoriteNumber = 123;
    int256 favoriteInt = -5;
    adress my Address = ;
    bytes32 favbytes = "cat";
    */
    // get's initialized to zero
    //uint256 favNumber;
    //uint256[] public favNumberlist;


    //People public person = People({favNumber : 2, name : "Ankush"});

    mapping(string=>uint256) public nametofavNumber;
    struct People {
        uint256 favNumber;
        string name;
    }

    //Arrays
    People[] public people;

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favNumber) public
    {
        //People memory np = People({favNumber : _favNumber, name : _name});
        People memory np = People(_favNumber,_name);
        people.push(np);
        nametofavNumber[_name] = _favNumber;
    }

    /*function store(uint256 _favNumber) public{
        favNumber = _favNumber;
    }

    // view, pure
    function retrive() public view returns(uint256)
    {
        return favNumber;
    }*/


}