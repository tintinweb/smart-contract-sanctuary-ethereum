/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;



// File: payable.sol

contract MyContract {
    event Deposit(address sender, uint amount, uint balance);
    event Withdraw(uint amount, uint balance);
    event Transfer(address to, uint amount, uint balance);

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}