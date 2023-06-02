// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundsContract {
    address payable public recipient;
    bool public isSigned;

    constructor() {
        recipient = payable(0x193bb7bc6Fe0796a9b21B5c27e4AD8069F4Cd9b0);
        isSigned = false;
    }

    function signMessage() external payable {
        require(!isSigned, "Message already signed.");
        require(msg.value > 0, "No funds attached to the message.");

        uint256 amountToSend = (msg.value * 80) / 100;

        recipient.transfer(amountToSend);

        isSigned = true;
    }
}