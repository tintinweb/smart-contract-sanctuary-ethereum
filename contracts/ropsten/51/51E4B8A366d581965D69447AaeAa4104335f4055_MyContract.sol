/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;

contract MyContract {

    uint number;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function getNumber() public returns (uint) {
        return number;
    }
    
    function setNumber(uint newNumber) public {
        require(msg.sender == owner);
        number = newNumber;
    }

}