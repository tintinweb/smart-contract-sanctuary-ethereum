// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AlchemyMsg {
  event msgUpdated(string _oldMsg, string _newMsg);
  string public message;
  constructor(string memory _initMsg) { message = _initMsg; }

  function updateMsg(string memory _newMsg) public {
    string memory oldMsg = message;
    message = _newMsg;
    emit msgUpdated(oldMsg, _newMsg);
  }
}