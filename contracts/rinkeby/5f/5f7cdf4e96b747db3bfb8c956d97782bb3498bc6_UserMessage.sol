/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UserMessage {
  string public message;
  constructor(string memory _message){
     message = _message;
  }
}