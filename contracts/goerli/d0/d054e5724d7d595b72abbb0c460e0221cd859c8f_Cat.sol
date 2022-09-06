// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Cat {
  struct Meow {
    string message;
    address author;
    uint256 timestamp;
  }

  Meow[] private meows;

  function sayMeow(string calldata _message) external {
    Meow memory newMeow = Meow({
      message: _message,
      author: msg.sender,
      timestamp: block.timestamp
    });

    meows.push(newMeow);
  }

  function getAllMeows() external view returns (Meow[] memory) {
    return meows;
  }
}