/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//create smart contract to store peoples favourite number
//1. create variable
//2. create function to add number to variable
//3. create struct to store
//4. add function to add  numbers to array

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        string name;
        uint256 favouriteNumber;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}