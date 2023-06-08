/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract SimpleStorage {
    //Basic types: boolean, uint, int, address, bytes
    uint256 internal myFavNumber;

    // uint256[] listOfFavNumbers; // [0, 60, 45]
    struct Person {
        uint256 favNumber;
        string name;
    }
    Person[] public listOfPeople;
    mapping (string => uint256) public nameToNumber;

    function store(uint256 _favNum) public {
        myFavNumber = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return myFavNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        listOfPeople.push(Person(_favNumber, _name));
        nameToNumber[_name] = _favNumber;
    }
}