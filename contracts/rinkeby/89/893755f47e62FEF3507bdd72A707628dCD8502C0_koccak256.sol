/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: keccak256.sol

contract koccak256{

    uint hashDigits = 16;
    uint hashModulo = 10 ** hashDigits;

    struct Person {
        string name;
        uint id;
    }

    Person[] public person;

    function _pushPerson(string memory _name, uint _id) private{
        person.push(Person(_name,_id));
    }

    function _createId(string memory _name) private view returns(uint){
        uint id = uint(keccak256(abi.encodePacked(_name)));
        return id % hashModulo;
    }

    function createPerson(string memory name) public{
        _pushPerson(name, _createId(name));
    }
}