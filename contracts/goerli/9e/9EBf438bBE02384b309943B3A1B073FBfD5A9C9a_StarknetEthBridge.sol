// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Common.sol";
import "StarknetTokenBridge.sol";

contract StarknetEthBridge is StarknetTokenBridge {
    using Addresses for address;

    function deposit(uint256 l2Recipient) external payable {
        // The msg.value in this transaction was already credited to the contract.
        require(address(this).balance <= maxTotalBalance(), "MAX_BALANCE_EXCEEDED");
        sendMessage(msg.value, l2Recipient);
    }

    function withdraw(uint256 amount, address recipient) public override {
        consumeMessage(amount, recipient);
        // Make sure we don't accidentally burn funds.
        require(recipient != address(0x0), "INVALID_RECIPIENT");
        require(address(this).balance - amount <= address(this).balance, "UNDERFLOW");
        recipient.performEthTransfer(amount);
    }
}