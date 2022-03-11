/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract Voucher {
    mapping(address => uint256) public balances;

    constructor(){
        balances[msg.sender] = 100; // invio 100 voucer al creatore del contratto
    }

    function transfer(address destination, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Saldo insufficiente");
        //togli amount da msg.sender
        balances[msg.sender] -= amount;
        
        //aggiungi amount a destination
        balances[destination] += amount;
    }
}