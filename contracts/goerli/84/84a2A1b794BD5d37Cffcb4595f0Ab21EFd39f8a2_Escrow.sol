/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Escrow{
    address public bob;
    uint balanceReceived;
    uint lastDeposited;

    constructor(){
        bob = 0xECf74C19215C8DD2BAF16AD3a6eC1A25386d813c;
    }

    function deposit() payable public{
        require(msg.value > 0, "Amount needs to be grater than 0");
        balanceReceived += msg.value;
        lastDeposited = block.timestamp;
    }

    function withdraw() public{
        require(msg.sender == bob, "Only Bob can withdraw from this contract");
        require(balanceReceived > 0, "No funds deposited");
        require(block.timestamp >= lastDeposited + 1 days, "Last Deposit made within 24 hours, wait 1 day to withdraw");        
        address payable _to = payable(bob);
        _to.transfer(balanceReceived);
        balanceReceived = 0;
    }
}