// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHDist {
    function distributeETH(address[] calldata recipients) external payable {
        uint256 numRecipients = recipients.length;
        uint256 amount = msg.value / numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            payable(recipients[i]).transfer(amount);
        }
    }
}