/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract SimpleBank{
    mapping(address => uint) public myAccount;

    function getBalance() public view returns(uint){
        return myAccount[msg.sender];
    }

    function deposite() public payable{
        myAccount[msg.sender]+=msg.value;
    }

    function withDraw(uint money) public{
        require(money<=myAccount[msg.sender],"out of money");
        payable(msg.sender).transfer(money);
        myAccount[msg.sender]-=money;
    }
}