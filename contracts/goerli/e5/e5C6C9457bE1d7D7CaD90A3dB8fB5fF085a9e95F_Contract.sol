/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//this contract is a simple saving contract. User can deposit their ETH, withdraw, and transfer their deposit to another address

contract Contract {
    address owner;
    mapping(address=>uint) balance;
    
    event Deposit(address _user, uint _value);

    constructor(){
        owner = msg.sender;
    }

    modifier ownerable(){
        require(owner==msg.sender);
        _;
    }

    receive() external payable {   
    }

    function deposit() external payable{
        balance[msg.sender]+=msg.value;
        emit Deposit(msg.sender, balance[msg.sender]);
        
    }

    function getbalance() external view returns(uint){
        return balance[msg.sender];
    }

    function withdraw(uint _amount) external {
        require(balance[msg.sender]>=_amount,"Not enought balance");
        payable(msg.sender).transfer(_amount);
        balance[msg.sender]-=_amount;
    }

    function transfer(address _to, uint _amount) external{    //user can transfer their deposit to another address
        require(balance[msg.sender]>=_amount,"Not enought balance");
        balance[msg.sender]-=_amount;
        balance[_to]+=_amount;
        emit Deposit(_to, balance[_to]);
        
    }

    function dismiss() external ownerable{
        selfdestruct(payable(owner));
    }
}