/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract test2 {
    address[] private adds;

       function get() public view returns (address[] memory) {
        return adds;
    }

    function Set() public{
        adds.push(msg.sender);
    }

}