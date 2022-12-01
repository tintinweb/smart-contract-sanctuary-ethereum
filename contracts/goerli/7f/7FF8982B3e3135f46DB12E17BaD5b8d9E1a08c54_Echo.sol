// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Echo {
  constructor() {}

  event EchoEvent(string s);

  function echo(string calldata s) public {
    emit EchoEvent(s);
  }
}