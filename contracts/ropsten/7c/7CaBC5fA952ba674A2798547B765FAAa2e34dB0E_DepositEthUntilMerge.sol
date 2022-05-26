/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.13;

contract DepositEthUntilMerge {

    mapping( address => uint ) public s_balances;

///  Deposit ETH to the contract until Merge. True Eth maxis will deposit 
    function depositEth() public payable {
        s_balances[msg.sender]  += msg.value;

    }   

/// Withdraw after the merge . COngrats!!!!!
    function withdraw (uint amount) external {
        require(block.difficulty >= 2**64,"Wait till Merge");
        require(s_balances[msg.sender] >= amount);
        s_balances[msg.sender]= 0;
        payable(msg.sender).transfer(amount);
    }


}