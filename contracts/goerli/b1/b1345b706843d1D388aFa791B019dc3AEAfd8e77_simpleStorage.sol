// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract simpleStorage {

    mapping (address => uint) address_to_number;
    address private immutable s_owner;

    constructor() {
        s_owner = msg.sender;
    }

    function storeNumber(uint256 favNumber) public {
        address_to_number[msg.sender] = favNumber;
    }

    function getNumber() public view returns (uint256) {
        return address_to_number[msg.sender];
    }

    function getOwner() public view returns (address){
        return s_owner;
    }
}