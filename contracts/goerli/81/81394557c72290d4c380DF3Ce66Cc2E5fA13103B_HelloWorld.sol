pragma solidity >=0.7.3;

contract HelloWorld {
  // Emitted when update function is called
  event UpdatedMessage(string oldStr, string newStr);

  // Declared a state variable 'message' of type 'string'
  string public message;

  constructor(string memory initMessage) {
    message = initMessage;
  }

  // A public function that accepts a string argument and updates the 'message' storage variable.
  function update(string memory newMessage) public {
    string memory oldMessage = message;
    message = newMessage;
    emit UpdatedMessage(oldMessage, newMessage);
  }
}