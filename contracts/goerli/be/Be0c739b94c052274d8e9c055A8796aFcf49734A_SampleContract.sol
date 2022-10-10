// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SampleContract {

  string private s_message;

  constructor(string memory message) {
    s_message = message;
  }

  function getMessage() public view returns (string memory) {
    return s_message;
  }

  function setMessage(string memory message) public {
    s_message = message;
  }
}