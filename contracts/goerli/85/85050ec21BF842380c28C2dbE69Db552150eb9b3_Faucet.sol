/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

// Version of Solidity compiler this program was written for
pragma solidity ^0.6.4;

// Our first contract is a faucet!
contract Faucet {
    // Accept any incoming amount
    receive() external payable {}

    // Give out ether to anyone who asks
    function withdraw(uint withdrawAmount) public {
        // Limit withdrawal amount
        require(withdrawAmount <= 100000000000000000);

        // Send the amount to the address that requested it
        msg.sender.transfer(withdrawAmount);
    }
}