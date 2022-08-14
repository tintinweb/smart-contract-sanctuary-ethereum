// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

// "0x488c134d4273D970c8B6eF4De196be4DE3F71a85"
contract HelloWorld {
  event UpdateMessage(string oldStr, string newStr);
  
  string public message;

  constructor (string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdateMessage(oldMsg, newMessage);
  }
}