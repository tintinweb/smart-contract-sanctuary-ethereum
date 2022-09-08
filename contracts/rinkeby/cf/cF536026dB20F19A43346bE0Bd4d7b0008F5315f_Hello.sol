pragma solidity 0.8.16;

contract Hello {

event UpdatedMessages(string newStr);
string public message;

constructor(string memory initMessage) {
  message = initMessage;
}

  function update(string memory newMessage) public {
    message = newMessage;
    emit UpdatedMessages(newMessage);
  }
}