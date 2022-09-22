/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    
    uint256 public favoriteNumber;
    Person public person = Person({favoriteNumber : 5, name: "Semen"});

    Person[] public people; 


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    struct Person {
        uint256 favoriteNumber;
        string name; 
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _nm, uint256 _favorite) public {
        people.push(Person(_favorite, _nm));
    }


}