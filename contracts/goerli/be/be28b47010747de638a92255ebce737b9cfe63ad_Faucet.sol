/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// our first contract is a faucet!
contract Faucet {

    // accept any incoming amount
    receive() external payable {}

    // give out ether to anyone who asks
    function withdraw(uint256 withdraw_amount) public payable {

        // limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);

        // send coins
        payable(msg.sender).transfer(withdraw_amount);
    }
}