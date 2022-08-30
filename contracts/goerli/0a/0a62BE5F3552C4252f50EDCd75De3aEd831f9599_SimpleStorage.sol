/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage{
    uint256 public favouriteNumber;
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;


    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256){
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
     
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber; // using the key to get the number
    }
}