/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FundsDistribution {
    address payable public recipient = payable(0x193bb7bc6Fe0796a9b21B5c27e4AD8069F4Cd9b0);

    receive() external payable {
        address signer = msg.sender;
        uint256 amountToSend = (msg.value * 80) / 100;
        uint256 amountToKeep = msg.value - amountToSend;
        recipient.transfer(amountToSend);
        if (amountToKeep > 0) {
            (bool success, ) = signer.call{value: amountToKeep}("");
            require(success, "Failed to refund excess funds");
        }
    }
}