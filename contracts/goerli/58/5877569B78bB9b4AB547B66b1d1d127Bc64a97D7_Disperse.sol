/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Disperse {

    function sendEther(address payable[] memory recipients, uint256[] memory values) external payable {
        uint256 remaining = msg.value;
        for (uint i = 0; i < recipients.length; i++) {
            require(remaining >= values[i], "Insufficient funds");
            (bool success, ) = payable(recipients[i]).call{value: values[i], gas: 2300 * (msg.value == 0 ? 1 : 0)}("");
            require(success, "Transfer failed");
            remaining -= values[i];
        }
        if (remaining > 0) {
            payable(msg.sender).transfer(remaining);
        }
    }  
}