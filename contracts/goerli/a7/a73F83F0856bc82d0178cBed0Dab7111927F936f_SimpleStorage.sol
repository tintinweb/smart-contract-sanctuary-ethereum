/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; //declaring solidity version

contract SimpleStorage {
    // writing a contract
    uint public age;
    People[] public person; //a dynamic array
    struct People {
        //created a people type
        string name;
        uint256 favouriteNumber;
    }
    mapping(string => uint256) public nameToFavouriteNumber; //mapping a string to a normal integer

    function newAge(uint256 _age) public {
        age = _age;
        age = age + 2;
    }

    function retrieve() public view returns (uint256) {
        //view functions are used to read state
        return age;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        person.push(People(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}