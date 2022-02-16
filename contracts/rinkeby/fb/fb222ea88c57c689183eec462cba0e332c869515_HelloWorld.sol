/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract HelloWorld {

  event UpdatedMessages(string oldStr, string newStr);

  string public message;

  constructor(string memory initMessage) {
    message = initMessage;
  }

  // 读取 message
  function get() public view returns (string memory) {
    return message;
  }

  // 更新 message
  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, newMessage);
  }
}