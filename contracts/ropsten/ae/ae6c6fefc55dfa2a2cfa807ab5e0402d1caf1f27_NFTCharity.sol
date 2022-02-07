/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.9;

contract NFTCharity {

    address payable user;
    address payable charity_organization = payable(0x934B80edC8ba22166DAC3A0AF994FE27C4eEa96C);
    uint public balance;
    
    event Deposit(address issuer, uint amount, uint final_balance);
    event Withdraw(address beneficiary, uint amount, uint limit);

    function deposit () public payable {
        user = payable(msg.sender);
        balance += msg.value;
        emit Deposit(msg.sender, msg.value, balance);
    }

    function withdraw (uint amount) public {
        require(msg.sender == charity_organization, "You are not allowed");
        require(amount <= balance, "Too much!");
        balance -= amount;
        user.transfer(amount);
        emit Withdraw(msg.sender, amount, balance);
    }

}