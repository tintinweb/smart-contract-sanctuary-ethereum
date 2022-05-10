/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Testament{
    address _manager;
    mapping(address=>address) _heir; //จะต้องรู้ address ของเจ้าของมรดกก่อนจึงจะรู้ภายใน
    mapping(address=>uint) _balance;
    event Create(address indexed owner,address indexed heir,uint amount);
    event ReportOfDeath(address indexed owner,address indexed heir,uint amount);

    constructor(){
        _manager = msg.sender;
    }

    function create(address heir) public payable{
        require(msg.value>0,"Don't lie me this 0 bath");
        require(_balance[msg.sender]>=0,"not write yet");
        _heir[msg.sender] = heir;
        _balance[msg.sender] = msg.value;
        emit Create(msg.sender,heir,msg.value);
    } 

    function getTestament(address owner) public view returns(address heir,uint amount){
        return (_heir[owner],(_balance[owner]/1000000000000000000));
    }

    function reportOfDeath(address owner) public{
        require(msg.sender == _manager,"Who are you?");
        require(_balance[owner]>=0,"not write yet");

        emit ReportOfDeath(owner,_heir[owner],_balance[owner]);
        payable(_heir[owner]).transfer(_balance[owner]);
        _balance[owner] = 0;
        _heir[owner] = address(0);
    }

}