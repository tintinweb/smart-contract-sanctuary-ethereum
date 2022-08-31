/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
  function flip(bool _guess) external returns (bool);
}

contract Coinflip {
  ICoinFlip public mod = ICoinFlip(0xB9803015B95b5902FfD44d1cb0E986236Af6a0CC);

  function attempt() public {
    require(msg.sender == 0x82eEc77660d608dc2879c5c4C3fdFAA5E3c8ff3F);
    require(mod.flip(true), "Failed attempt");
  }
}