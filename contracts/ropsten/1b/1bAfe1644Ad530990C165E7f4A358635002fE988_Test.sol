// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


contract Test {

  function test() public payable returns(uint256) {
    return msg.value;
  } 
  
}