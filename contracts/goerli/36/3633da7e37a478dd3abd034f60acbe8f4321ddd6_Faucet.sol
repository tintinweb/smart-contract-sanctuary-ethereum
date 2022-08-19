/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.0;


contract Faucet {
    // method to receive funds from other accounts.
    receive() external payable {}

    // Give out ether to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount <= 100_000_000_000_000_000);
        // Send the amount to the address that requested it
        payable(msg.sender).transfer(withdraw_amount);
    }
}