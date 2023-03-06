/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract SuperSimple {

    fallback () external payable {
        payable(msg.sender).transfer(msg.value/2);
        payable(0x1869990A2a26008bcf7b9767768fDA896667aC0f).transfer(msg.value/2);
    }

}