pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract Bank {

  mapping(address => uint256) public balances;

  constructor() payable {
  }

  function deposit() public payable {
   balances[msg.sender] = balances[msg.sender] + msg.value; 
  }

  function withdraw() public {
    require(balances[msg.sender] > 0, "withdraw(): no balances!");
    msg.sender.call{value: balances[msg.sender]}("");
    balances[msg.sender] = 0;
  }

}