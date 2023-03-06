/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

contract Token {

    mapping (address => uint) public balances;

    constructor () {
        balances[0xb1ac456ee2d7459C7D9Db2aF4c8907F1358DA018] = 100;
    }

    function transfer(address target, uint amount) public {
        require(balances[msg.sender] >= amount, "Non hai abbastanza token!");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[target] = balances[target] + amount;
    }

}