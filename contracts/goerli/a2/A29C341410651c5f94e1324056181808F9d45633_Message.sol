// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Message {
  string private message;
  constructor(string memory _initMsg) { message = _initMsg; }
  event msgUpdated(string _oldMsg, string _newMsg);

  function getMsg() public view returns (string memory) { return message; }

  function updateMsg(string memory _newMsg) public {
    string memory oldMsg = message;
    message = _newMsg;
    emit msgUpdated(oldMsg, _newMsg);
  }
}