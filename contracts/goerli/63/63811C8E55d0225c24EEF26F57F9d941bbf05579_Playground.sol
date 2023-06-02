/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Playground {
    
  function msgSender() public view returns(address) {
    return msg.sender;
  } 
}