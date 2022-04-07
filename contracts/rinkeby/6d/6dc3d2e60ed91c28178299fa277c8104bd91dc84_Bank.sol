/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    // address type is wallet address. Ex: 0x7a5F432B71e90420d091443b5FE85da2B5653Fce
    // _balances is mapping between address and uint 
    // Example:  0x7a5F432B71e90420d091433b5FE45da2B5653Fce -> 1000 wei
    //           0x8d9A5666a748b26AdA344c978E41b35E1a8b8b92 -> 500 wei
    mapping(address => uint) _balances;

    function deposit() public payable{
        // msg.sender is wallet address from request
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {

        // Check: Withdraw amout must be less than Wallet's balance
        require(amount <= _balances[msg.sender], "not enough money");

        // payable(msg.sender) : Let's sender inherit payable feature 
        // Transfer from Smart contract to msg.sender
        payable(msg.sender).transfer(amount);

        _balances[msg.sender] -= amount;
    }

    function checkBalance() public view returns (uint balance) {
        return _balances[msg.sender];
    }
}