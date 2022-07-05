//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EthWallet {
  address payable public owner;

  constructor() {
    owner = payable(msg.sender);
  } 

  event ReceiptEvent (
    address _sender,
    uint _value
  );

  receive() external payable {
    emit ReceiptEvent(msg.sender, msg.value);
  }

  function withdraw(uint amount) external {
    require(msg.sender == owner, "Only owner can withdraw");
    owner.transfer(amount);
  }

  function getAvailableBalance() external view returns (uint) {
    return address(this).balance;
  }
}