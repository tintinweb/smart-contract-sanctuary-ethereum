/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloWorld {
    address owner;
    string name;
    constructor() {
        owner = msg.sender; 
    }

    function helloWorld() external view returns(string memory, uint){
        return ("Hello world", block.timestamp);
    }
}