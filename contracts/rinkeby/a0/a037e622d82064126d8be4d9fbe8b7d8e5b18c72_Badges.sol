// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

contract Badges {
  address owner1;
  string name;
  constructor(string memory name) {
    name = name;
    owner1 = msg.sender;
  }

  function getOwner() public view returns (address) {
    return owner1;
  }
}