/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.25;
contract Faucet {
    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 10 ** 17);
        msg.sender.transfer(withdraw_amount);
    }
    function() public payable{}
}