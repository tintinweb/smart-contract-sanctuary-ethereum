/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract Vaucher {
    mapping(address => uint256) public balances;

    constructor() {
        balances[msg.sender] = 100;
    }

    function transer(address destination, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Saldo insufficiente");
        balances[msg.sender] -= amount;
        balances[destination] += amount;
    }
}