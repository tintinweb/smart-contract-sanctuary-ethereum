/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    struct People {
        string name; // index 0
        uint256 favNumber; // index 1
    }
    uint256 public number;
    People public person = People({name: "Ramesh", favNumber: 1});

    uint256[] public numbers;

    mapping(uint256 => string) public numberToName;

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        numberToName[_favNumber] = _name;
    }

    function store(uint256 _favNumber) public {
        number = _favNumber;
    }
    function retrieve() public view returns (uint256) {
        return number;
    }
}