/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
/* 
    
    Unlimit winners
    Reward = 1
*/

interface Buyer {
  function price() external view returns (uint);
}

contract Secret1 {
  uint public price = 100;
  address[] hackers;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);
    if (_buyer.price() == price + 1000) {
    hackers.push(msg.sender);
    
      price = _buyer.price();
    }
  }

  function getWinners() public view returns(address[] memory) {
    return hackers;
  }
}