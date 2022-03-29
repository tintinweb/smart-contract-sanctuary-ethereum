pragma solidity >=0.7.3;

/// @title Defines a contract named `HelloWorld`.
/// @author Viacheslav
/// @notice A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. 
contract HelloWorld {

   event UpdatedMessages(string oldStr, string newStr);

   string public message;

   constructor(string memory initMessage) {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}