/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: testContract2.sol

contract test1{

    struct Person{
        address  addressId;
        uint id;
    }

    Person[] public person;

    mapping(address => uint) addressToId;

    function _generatePerson(address _address, uint _id) private{
        person.push(Person(_address, _id));
        addressToId[_address] = _id;
    }

    function _generateId(address _address) private pure returns(uint){
        uint id = uint(keccak256(abi.encodePacked(_address))); 
        return id;
    }

    function generateId(address Address) public{
        uint id = _generateId(Address);
        return _generatePerson(Address, id);
    }

}