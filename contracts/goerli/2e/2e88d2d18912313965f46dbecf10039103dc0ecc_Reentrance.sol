/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reentrance {
  mapping(address => bool) private claims;

  function claim() public {
    if(!claims[msg.sender]) {
      payable(msg.sender).transfer(10000000000000000);
      claims[msg.sender] = true;
    }
  }

  receive() external payable {}
}