// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AuthOracle {

    address public owner; 
    mapping(address => bool) public isValid;
    mapping(address => uint) public isRevoked;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addAddress(address signer) public {
        require(msg.sender == owner);
        isValid[signer] = true;
    }
    
    function revokeAddress(address signer) public{
        require(msg.sender == owner);
        isRevoked[signer] = block.timestamp;
    }
}