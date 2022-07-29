/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7;

contract SimpleStorage 
{
    // uint data type is +ve integers
    // Since there is no value assigned to the variable, it will be initialized as 0
    uint256 /* public */ favoriteNumber;

    // People public person = People({favoriteNumber: 2, name: "Prabhash"});

    // Mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // Struct
    struct People{
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual{
        favoriteNumber = _favoriteNumber;
    }

    function retrieve () public view returns(uint256){
        return favoriteNumber;
    }

    /* function add() public pure returns(uint256){
        return (1+1);
    } */

    function addPeople(string memory _name, uint256 _favoriteNumber) public{
        people.push(People(_favoriteNumber, _name));
        // calling map
        nameToFavoriteNumber [_name] = _favoriteNumber;
    }
}