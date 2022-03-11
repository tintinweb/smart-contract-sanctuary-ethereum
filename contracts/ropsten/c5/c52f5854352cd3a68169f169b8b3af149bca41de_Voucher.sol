/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Voucher {

    mapping (address => uint256) public balances;

    constructor(){
        balances[msg.sender] == 100; //invia 100 al creatore del contratto
    }

    function transfer(address destination, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Saldo insufficiente");
        // togli amountVoucher da msg.sender
        balances[msg.sender] -= amount;
        // aggiungi amountVoucher a destination
        balances[destination] += amount;
    }
}