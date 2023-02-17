/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EthersAgent {
    function forward(address recipient) public payable {
        payable(recipient).transfer(msg.value);
    }
}