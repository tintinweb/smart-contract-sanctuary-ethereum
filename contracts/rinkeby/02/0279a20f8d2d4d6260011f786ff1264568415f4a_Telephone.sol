/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    owner = _owner;
  }
}