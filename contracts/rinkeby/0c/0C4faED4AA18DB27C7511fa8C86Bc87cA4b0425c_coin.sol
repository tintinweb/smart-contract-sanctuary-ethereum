/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
contract coin{
    address public minter;
    mapping(address => uint) public balance;
    event send(address from, address to, uint value);
    constructor(){
        minter=msg.sender;

    }
    function mint(address reciever, uint amount) public{
        require(minter==msg.sender);
        balance[reciever]+=amount;
    }
    error InsufficientBalance(uint requested, uint available);
    function Send(address reciever,uint amount)public{
        if(amount>balance[msg.sender])
            revert InsufficientBalance({
                requested:amount,
                available:balance[msg.sender]
            });
        balance[msg.sender]-=amount;
        balance[reciever]+=amount;
        emit send(msg.sender, reciever, amount);
    }
}