/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT

contract SampleFeeCollector { // 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC
    address public owner; 
    uint256 public balance; 

    constructor() {
        owner = msg.sender; 
    }

    receive() payable external {
        balance += msg.value;

    }
}