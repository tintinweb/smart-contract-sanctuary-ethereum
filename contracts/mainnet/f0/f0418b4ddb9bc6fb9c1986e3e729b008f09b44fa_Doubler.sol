/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Doubler {
  address payable public bank;
  address payable public owner;
  
  event BalanceDeposited();
  event BalanceWithdrawn();
  event PaymentDoubled();
  event PaymentLost();

  constructor() payable {
    bank = payable(address(this));
    owner = payable(msg.sender);
  }
  
  function deposit() external payable {
    emit BalanceDeposited();
  }

  function doublePayment() external payable {
    uint256 payment = msg.value;
    uint256 win = payment * 2;
    require(win < bank.balance, "Payment too large.");
    uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, payment))) % 100;
    if (rand <= 45) {
      address payable user = payable(msg.sender);
      (bool success, ) = user.call{value: win}("");
      require(success, "Failed to send doubled payment.");
      emit PaymentDoubled();
    } else {
      emit PaymentLost();
    }
  }

  function withdraw() external {
    uint256 amount = bank.balance - 1000000;
    require(amount > 0, "Not enough balance to withdraw.");
    (bool success, ) = owner.call{value: amount}("");
    require(success, "Failed to withdraw to owner.");
    emit BalanceWithdrawn();
  }
}