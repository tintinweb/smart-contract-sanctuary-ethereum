// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

contract Greeter {
  event MessageUpdated(string newMessage);
  string public message;

  constructor() {}

  function setMessage(string calldata newMessage) public {
    message = newMessage;
    emit MessageUpdated(newMessage);
  }
}