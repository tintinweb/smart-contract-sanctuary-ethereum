// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library MyLibrary {
  function add(uint256 a) external pure returns (uint256 number) {
    number = a++;
  }
}