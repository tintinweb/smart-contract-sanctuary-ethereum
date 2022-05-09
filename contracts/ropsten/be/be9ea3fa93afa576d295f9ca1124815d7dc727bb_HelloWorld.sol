/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


contract HelloWorld {
    address payable private owner;
    uint256 private b;

    constructor(uint256 _b) payable {
        owner = payable(msg.sender);
        b = _b;
    }

    function helloWorld() view public returns(uint256) {
        return b;
    }

    function close() public { 
        require(msg.sender == owner, "Error");
        selfdestruct(owner); 
    }
    
}