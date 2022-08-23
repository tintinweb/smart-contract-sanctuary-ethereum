/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SimpleContract{
    address public admin;
    mapping (address => uint) private lastTransactionList;

    constructor(){
        admin = msg.sender;
    }

    function transfer() public payable{
        lastTransactionList[msg.sender] = msg.value;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function sendToAdmin() public{
        payable(admin).transfer(address(this).balance);
    }

    function getTransaction(address client) public view returns(uint){
        return(lastTransactionList[client]);
    }
}