/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Store {
  event ItemSet(string key, string value);

  mapping (string => string) public items;

  function setItem(string memory key, string memory value) external {
    items[key] = value;
    emit ItemSet(key, value);
  }
}