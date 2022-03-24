// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
  string public message;

  constructor(string memory _message) public {
    message = _message;
  }

  function update(string memory _message) public {
    message = _message;
  }
}