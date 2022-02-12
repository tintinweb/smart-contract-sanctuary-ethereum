/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Faucet {

  mapping(address => uint) balance_withdrawn;

  mapping (address => uint256) lastReceived;
  
  function withdraw(uint _amount) public {
    // users can only withdraw .1 ETH at a time, feel free to change this!
    require(_amount <= 100000000000000000);
    require(block.timestamp-lastReceived[msg.sender]>120,"Same address cannot withdraw within 2 minutes ");
    balance_withdrawn[msg.sender] = balance_withdrawn[msg.sender]+_amount;
    lastReceived[msg.sender] = block.timestamp;
    payable(msg.sender).transfer(_amount);
  }

  // fallback function
  receive() external payable {}
}