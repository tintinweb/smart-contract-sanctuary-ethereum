/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage  {

    // this will get initialized to 0
    uint256 favouriteNumber;

    struct People{
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;
    //Mapping names to fav numbers so that we can searh for a specific person's name and return
    // their fav number
    mapping (string => uint256) public nameToFavouriteNumber;

    // store a number to favouriteNumber
    function store(uint256 _favNumber)public {
        favouriteNumber = _favNumber;
    }

    // view returns function 
    function retrieve()public view returns(uint256){
        return favouriteNumber;
    }

    // Solidity data can be stored in memory or storage. memory means it only stores during execution
    function addPerson(string memory f_name, uint256 f_favouriteNumber) public {
        people.push(People(f_favouriteNumber, f_name));
        nameToFavouriteNumber[f_name] = f_favouriteNumber;
    }
}