// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ShareETH {
  function share(uint256 value, address[] calldata wallets) external payable {
    unchecked {
      require(msg.value == value * wallets.length);
      for (uint256 i = 0; i < wallets.length; i++) {
        payable(wallets[i]).transfer(value);
      }
    }
  }
}