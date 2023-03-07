/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract cgMultiSender {
    function sendNative(address[] calldata receivers, uint256 amount) external payable {
        require(receivers.length > 0, "No receivers");
        require(msg.value == amount * receivers.length, "Amount !== value");
        for (uint i = 0; i < receivers.length; ++i) {
          payable(receivers[i]).transfer(amount);
        }
    }
}