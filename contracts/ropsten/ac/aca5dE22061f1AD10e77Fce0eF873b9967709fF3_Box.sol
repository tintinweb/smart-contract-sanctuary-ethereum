// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
contract Box {
   event UpdatedMsg(string oldStr, string newStr);
   string public msgs;
   constructor(string memory initMessage) {
      msgs = initMessage;
   }
   function upd(string memory newMessage) public {
      string memory oldMsg = msgs;
      msgs = newMessage;
      emit UpdatedMsg(oldMsg, newMessage);
   }
}