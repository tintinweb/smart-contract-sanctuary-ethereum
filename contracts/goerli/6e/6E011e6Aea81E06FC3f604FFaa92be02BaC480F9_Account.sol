/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account {
  address public owner;

  constructor(address payable _owner) {
    owner = _owner;
  }

  function setOwner(address _owner) public {
    require(msg.sender == owner);
    owner = _owner;
  }

  function destroyd(address payable recipient) public {
    require(msg.sender == owner);
    selfdestruct(recipient);
  }

  receive() payable external {}
}