// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract Gong {
  function ring() external {
    emit TheDawnOfANewGoldenAge(msg.sender);
  }

  event TheDawnOfANewGoldenAge(address indexed operator);
}