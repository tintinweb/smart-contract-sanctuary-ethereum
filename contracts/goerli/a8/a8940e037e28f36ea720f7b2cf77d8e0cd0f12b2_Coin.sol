/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


contract Coin{
    address public minter;
    mapping(address=>uint)public balances;

    event Sent(address from,address to,uint amount);

    // 构造函数
    constructor(){
         minter = msg.sender;
    }
    
    
    // Sends an amount of newly created coins to an address
    // Can only be called by the contract creator
    function mint(address receiver,uint amount)public{
        require(msg.sender==minter);
        balances[receiver]+=amount;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    error InsufficientBalances(uint requested,uint available);

    // Sends an amount of existing coins
    // from any caller to an address
    function send(address receiver ,uint amount)public{
        if(amount>(balances[msg.sender]))
            revert InsufficientBalances({
                requested:amount,
                available:balances[msg.sender]
            });

            balances[msg.sender]-=amount;
            balances[receiver]+=amount;
            emit Sent(msg.sender,receiver,amount);
    }


}