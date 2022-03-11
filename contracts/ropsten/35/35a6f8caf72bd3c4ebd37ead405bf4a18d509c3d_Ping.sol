/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

contract Ping {
    
    fallback () external payable {
        payable(msg.sender).transfer(msg.value);
    }

}