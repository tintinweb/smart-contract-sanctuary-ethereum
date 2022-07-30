// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;
 
contract Again {
     
    address public owner;
    string public karan;
    constructor() {
         owner = msg.sender;
         karan = "mykaran";
    }
    
}