/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
    
    function invest() external payable {
        if (msg.value < 1000) {
            revert();
        }
    }
    
    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }

    function test() external view returns(uint) {
        return block.timestamp;
    }
}