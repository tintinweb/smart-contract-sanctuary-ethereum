/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank{

    mapping(address=>uint) _balances;
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);

    function deposit() public payable{
        _balances[msg.sender] = msg.value;
    }

    function showBalance() public view returns(uint){
        return _balances[msg.sender];
    }

}