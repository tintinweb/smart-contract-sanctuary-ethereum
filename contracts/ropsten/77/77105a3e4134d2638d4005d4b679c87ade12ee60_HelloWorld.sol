/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity ^0.7.0;

contract HelloWorld {

   string public message;

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      message = newMessage;
   }

   function getMessage() public view returns (string memory) {
      return message;
   }
}