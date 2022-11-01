/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8; // define the solidity version

contract SimpleStorage {
    // boolean, unit, int, address, bytes
    uint256  favouriteNumber;
     People public person = People({favouriteNumber: 2, name:"Marvin"});

    // mapping data structure 
    mapping(string => uint256) public nameToFavouriteNumber;
    //  struct data structure
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // array data structure 
    People [] public people;

    // function to store values 
    function store(uint256 _favouriteNumber) public virtual{
        favouriteNumber = _favouriteNumber;
        //  favouriteNumber = favouriteNumber + 1;
    }

    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }
    // calldata , memory, storage {only applies to arrays, structs }  
    function addPerson(string memory _name, uint256 _favouriteNumber) public{
        //  pushing to an array
        people.push(People(_favouriteNumber, _name));
        // add person to mapping 
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}