/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
 * Author : Mantas 
 * Date   : 12/2022
 * @title ERC20 Only
 * @dev Create Instance ERC20 standard token == 77000000 POLYGON => ETHEREUM MAPPING
 */
 

contract  ICT{
   
    address payable owner;    // Owner of contract

    string public name = "INSTANT CHAIN NETWORK [ICN]";
    string public symbol = "ICT";
    uint256 public decimals = 0;                  // No decimal points
    uint public maxSupply = 77000000;                    // Maximum Total Supply allowed
    uint public currentSupply = maxSupply;
    mapping (address => uint)  balances;   // Balances of tokens at address

  constructor ()                     // Initialize owner and supply stored at owners address
    {
        owner = payable(msg.sender);
        balances[msg.sender] = currentSupply;
    }

    event Transfer(address indexed sender,address indexed receiver,uint amount);

    function transfer(address receiver,uint amount)public returns(uint senderBalance,uint receiverBalance){
     require(balances[msg.sender]>=amount,"! Insuficient Funds");
     balances[msg.sender] -=amount;
     balances[receiver] +=amount;
     emit Transfer(msg.sender,receiver,amount);
     senderBalance = balances[msg.sender];
     receiverBalance = balances[receiver];
 }
   
   function balanceOf(address sender)public view returns(uint){
       return balances[sender];
   }
}