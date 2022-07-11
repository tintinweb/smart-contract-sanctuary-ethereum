/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

contract Badges {
  address owner;
  string name;
  constructor(string memory name) {
    name = name;
    owner = msg.sender;
  }

  function getOwner() public view returns (address) {
    return owner;
  }
}