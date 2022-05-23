/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract DepositAuctioning { 
    mapping(address => uint) balance;
   
    error NoDepositLeft();
    address owner; 

    constructor() {
        owner = msg.sender;
    }

    modifier onlOwner() {
        require(msg.sender == owner); 
        _;                             
    } 

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    function withdraw(address payable target) onlOwner public{
        if(balance[target] > 0){
            (bool success, ) = target.call{value:balance[target]}("");
            require(success, "Transfer failed.");
            balance[target] -= balance[target];   
        }
        else {
            revert NoDepositLeft();
        }          
    }

    function getDepositBalance(address target) public view returns(uint){
        return balance[target];
    }
}