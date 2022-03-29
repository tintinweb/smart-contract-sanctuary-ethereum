/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Khunbank{
    


    mapping(address=>uint) _balances;
    event Deposit(address indexed owner,uint amount);
    event Withdraw(address indexed owner,uint amount);

    function deposit()public payable{
        require(msg.value>0,"Why you deposit 0 ETH??");
        _balances[msg.sender]+=msg.value;
        emit Deposit(msg.sender,msg.value);
    }

    function withdraw()public payable{
        require(msg.value>0 && msg.value <= _balances[msg.sender],"not enough");
        payable(msg.sender).transfer(msg.value);
        _balances[msg.sender]-=msg.value;
        emit Withdraw(msg.sender,msg.value);
    }

    function balance()public view returns(uint){
        return _balances[msg.sender];
    }

    function balanceof(address owner)public view returns(uint){
        return _balances[owner];
    }

}