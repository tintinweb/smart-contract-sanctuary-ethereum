/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: fund_me.sol

contract SimpleStorage {
    uint256 favoriteNumber;
    struct Person {
        string name;
        uint256 age;
    }
    Person[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(string memory personName, uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        nameToFavoriteNumber[personName] = favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function createPerson(string memory _name, uint256 _age) public {
        people.push(Person(_name, _age));
    }

    function getPeople(uint256 index) public view returns (string memory) {
        return people[index].name;
    }
}