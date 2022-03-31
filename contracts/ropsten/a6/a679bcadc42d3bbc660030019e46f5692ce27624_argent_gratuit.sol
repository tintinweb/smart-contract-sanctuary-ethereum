/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// Our first contract is a faucet!

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract argent_gratuit {

    // Accept any incoming amount

    receive () external payable {}

    // Give out ether to anyone who asks

    function withdraw(uint withdraw_amount) public {

        // Limit withdrawal amount

        require(withdraw_amount <= 100000000000000000);

        // Send the amount to the address that requested it

        msg.sender.transfer(withdraw_amount);

    }

}