// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
 
contract Faltu {
     
    address public owner;
    address public again;
    constructor(address _again) {
         owner = msg.sender;
         again = _again;
    }
    
}