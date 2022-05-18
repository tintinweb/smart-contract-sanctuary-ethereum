/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: contracts/test2.sol

// SPDX-License-Identifier: MLT

pragma solidity ^0.8.10;

contract simple_bank
{
    mapping(address=>uint) private money;
    
    function withdraw(uint amount) external payable
    {
        require(amount <= money[msg.sender],"Not enough money in the bank!");
        (bool sent,)=msg.sender.call{value: amount}("");
        require(sent,"Send failed");
        money[msg.sender]-=amount;
    }

    function deposit() external payable
    {
        money[msg.sender]+=msg.value;
    }

    function get_balance() public view returns (uint)
    {
        return money[msg.sender];
    }
}