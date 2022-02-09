/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract King {
  address  constant  king = 0xBbAc1Ca7c7dB40caC74fc3fD97C456aF97960cFb;
  function transfer() public {
      payable(king).send(0x2386F26FC10000);
  }
}