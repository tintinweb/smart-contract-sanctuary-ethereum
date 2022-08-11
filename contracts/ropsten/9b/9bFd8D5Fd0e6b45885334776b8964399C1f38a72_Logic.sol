// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Logic {
   address public owner;

   function changeOwner() public {
    owner = msg.sender;                 // Re-announce ownership but performed in a delegate call opcode so preserves the context and changes calling contract state variable.
   }
}