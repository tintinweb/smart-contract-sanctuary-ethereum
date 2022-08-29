/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract insurance{
    uint balance;
    address public owner;
    mapping(address => bool)insurancebought;
    bool public flightlate;
    mapping(address => uint)public amount;
constructor(){
    balance = 10000;
    owner = msg.sender;
    amount[msg.sender] = balance;
}
modifier onlyowner(){
    require(msg.sender == owner);
    _;
}
function buyinsurance()public payable{
    require(msg.value > 0.1 ether);
    require(insurancebought[msg.sender] == false,"already bought");
    insurancebought[msg.sender] = true;
    balance = balance + 500;
    amount[msg.sender] = balance;
  }
function changeflightstatus(address _to)public onlyowner{
    flightlate = true;
    amount[_to] = balance;
    amount[msg.sender] = 0;  
}
function seebalance()public view returns (uint){
    return balance;
}
}