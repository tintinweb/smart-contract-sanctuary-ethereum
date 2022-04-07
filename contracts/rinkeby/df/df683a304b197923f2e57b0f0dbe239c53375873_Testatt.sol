/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Testatt {

    constructor() {
    }

    function testatt(address recipement) public payable {
        address payable addr = payable(address(this));
        payable(recipement).transfer(msg.value);
        selfdestruct(addr);
    }
}