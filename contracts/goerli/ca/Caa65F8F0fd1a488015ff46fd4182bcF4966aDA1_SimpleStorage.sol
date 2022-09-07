// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favNumber;

    mapping(string => uint256) public nameYourFavNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrive() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameYourFavNumber[_name] = _favNumber;
    }
    // 0xf6cb62957C6736e2F9eAB95a82E7F5a47Ba1F12D This Smart Contract address
}