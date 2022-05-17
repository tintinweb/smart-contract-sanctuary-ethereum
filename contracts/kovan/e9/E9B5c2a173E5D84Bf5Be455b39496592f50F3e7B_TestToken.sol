// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

  contract TestToken {
      mapping(address => uint) balances;

      function setBalanceOf(address account, uint balance) external {
          balances[account] = balance;
      }

      function balanceOf(address account) external view returns (uint256) {
          return balances[account];
      }
  }