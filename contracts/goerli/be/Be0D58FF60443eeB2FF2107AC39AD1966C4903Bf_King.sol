/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    function attack(address _to, uint _amount) public {
        payable(address(_to)).transfer(_amount);
    }
}