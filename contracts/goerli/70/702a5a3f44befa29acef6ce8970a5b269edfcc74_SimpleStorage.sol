/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract SimpleStorage {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    uint storedData;
    
    function getOwner() public view returns (address) {
        return owner;
    }

    function getOwnerNotView() public returns (address) {
        return owner;
    }

    function setData(uint x) public {
        storedData = x;
    }

    function setDataMe(uint x) public {
        require(msg.sender==owner, 'You are not owner');
        storedData = x;
    }

    function getSender() public view returns (address) {
        return msg.sender;
    }

    function getData() public view returns (uint) {
        return storedData;
    }
}