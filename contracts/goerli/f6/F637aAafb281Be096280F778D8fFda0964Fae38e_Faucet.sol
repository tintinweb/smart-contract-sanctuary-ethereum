//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
  address payable  owner ;

  constructor(){
    owner=payable(msg.sender);
  }
  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    payable(msg.sender).transfer(_amount);
  }

  function Conselfdestruct()external{
    require(msg.sender==owner,"You'r not the owner of the contract");
    selfdestruct(owner); 
  }

  // fallback function
  receive() external payable {}
}