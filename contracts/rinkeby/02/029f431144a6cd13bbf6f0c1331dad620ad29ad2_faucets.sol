/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: UNLICENSED
// declear the version of your solidity compiler

pragma solidity ^0.7.6;

// declare contract name 

contract faucets{
    // mapping the address to an unsigned integer and call the mapping balance 
    mapping(address => uint) balance;
    // declare function for accepting payment
    receive() external payable {}
    // declare a function to read and update the balance
    function balanceOf(address account) public view returns(uint){
        return balance[account];
    }
    // declare function to withdraw ether
    function withdraw(uint withdraw_amount) external payable{
    // set the maximum withdrawal amount to 0.2ether 
        require(withdraw_amount <= 200000000000000000);
    // call the transfer function to execute transaction
        msg.sender.transfer(withdraw_amount);
    }

}