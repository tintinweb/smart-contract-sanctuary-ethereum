/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage {

    uint256 favoriteNumber;

    struct Person {
        string name;
        uint256 favoriteNumber;
    }

    Person[] public person;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        person.push(Person(_name,_favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}