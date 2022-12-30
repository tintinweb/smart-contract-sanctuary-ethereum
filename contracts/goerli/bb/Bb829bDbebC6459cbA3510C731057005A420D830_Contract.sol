// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// Author: @furkanakaldev
contract Contract {
  address payable owner;

  mapping(address => uint256) donationAmount;

  event Donation(address indexed _from, address indexed _to, uint256 _amount);

  constructor() {}

  function donate(address to, uint256 amount) public {
    donationAmount[to] += amount;

    emit Donation(msg.sender, to, amount);
  }

  function donationAmountOf(address account) external view returns (uint256) {
    return donationAmount[account];
  }
}