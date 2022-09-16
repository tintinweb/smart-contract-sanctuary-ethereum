/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract FeeCollector{
    
    address public owner;
    uint256 public balances;

    constructor() {
        owner = msg.sender;
    }

    receive () external payable {
        balances += msg.value;
    }

    function withdraw(uint amount, address payable _to) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances >= amount, "Insufficient amount");
        balances -= amount;
        _to.transfer(amount);

    }
}