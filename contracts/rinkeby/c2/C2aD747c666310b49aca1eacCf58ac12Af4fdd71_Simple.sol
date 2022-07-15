/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Simple {
    //this get initialized to zero!
    uint256 public favoriteNumber;

    struct People {
        uint256 age;
        string name;
    }

    People[] public man;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view,pure don't spend gas to run
    function retrieveUnit() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldate, memory, storage
    function addMan(uint256 _age, string memory _name) public {
        man.push(People(_age, _name));
    }

    struct Strawberry {
        string date;
        string info;
    }
    Strawberry[] public straw;

    function addStraw(string memory _date, string memory _info) public {
        straw.push(Strawberry(_date, _info));
    }
}