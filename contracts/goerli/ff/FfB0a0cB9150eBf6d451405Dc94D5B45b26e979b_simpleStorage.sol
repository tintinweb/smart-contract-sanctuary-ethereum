// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract simpleStorage {
    struct People {
        string name;
        uint256 favNum;
    }

    People[] public people;

    mapping(string => uint) name_to_number;
    address private immutable s_owner;

    constructor() {
        s_owner = msg.sender;
    }

    function storeNumber(string memory _name, uint256 _favNumber) public {
        name_to_number[_name] = _favNumber;
    }

    function getNumber(string memory _name) public view returns (uint256) {
        return name_to_number[_name];
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function appPerson(string memory _name, uint256 _favNum) public {
        people.push(People(_name, _favNum));
    }
}