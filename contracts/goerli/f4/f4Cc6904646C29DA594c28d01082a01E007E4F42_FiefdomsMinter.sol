/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IFiefdomsKingdom {
  function mintBatch(address to, uint256 amount) external;
  function mint(address to) external;
}

contract FiefdomsMinter {
  IFiefdomsKingdom public fiefdomsKingdom;
  constructor() {
    fiefdomsKingdom = IFiefdomsKingdom(0x6B0a34b0dE10390053848FB63e4893f51aF020fA);
  }

  function mintBatch(address to, uint256 amount) external {
    fiefdomsKingdom.mintBatch(to, amount);
  }

  function mint(address to, uint256 amount) external {
    fiefdomsKingdom.mintBatch(to, amount);
  }
}